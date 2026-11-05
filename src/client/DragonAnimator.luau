--!strict
-- Procedural animation for every mesh dragon the client can see: players
-- and NPCs alike. The Meshy rig has no animations yet, so each frame this
-- drives Bone.Transform directly: wings flap, the tail sways, the neck bobs,
-- and the legs stride when the dragon moves. Purely visual and local, so the
-- server never touches it. When real animations arrive, this can go.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DragonRig = require(ReplicatedStorage.Shared.DragonRig)
local Flight = require(script.Parent.Flight)

local DragonAnimator = {}

local COSTUME_NAME = "DragonCostume"

-- Wing pose, in radians. The rest pose has the wings spread and raised;
-- these tuck them down along the flanks. The sweep is applied first, so the
-- wing goes back along the body, then the fold drops what still sticks out.
local WING_SWEEP = 0.8 -- shoulder back along the body
local WING_FOLD = 1.0 -- shoulder down
local WING_FOLD_WALK = 0.1 -- extra when walking
local WING_ELBOW_FOLD = 0.35 -- forearm down further, hugging the flank
local WING_ELBOW_SWEEP = 0.35 -- forearm back along the body
local WING_TIP = 0.25 -- outer segments curled down

-- Flying: wings spread near the rest pose and beat about it.
local FLAP_LIFT = 0.1 -- shoulder held a little above rest
local FLAP_SWING = 0.5 -- beat amplitude at the shoulder
local FLAP_RATE = 7 -- radians per second at scale 1, slower for big dragons
local FLY_BLEND_RATE = 4 -- how fast the pose crosses between folded and flying
local FLY_LEG_TUCK = 0.7 -- legs drawn back under the body

-- A bone plus the mesh's axes expressed in the bone's own space, so a swing
-- "about the body's sideways axis" is the same call for every bone.
type Driven = {
	Bone: Bone,
	Side: number, -- +1 on the mesh's +X side, -1 on its -X side
	AxisX: Vector3, -- mesh sideways axis, in bone space
	AxisY: Vector3, -- mesh up axis
	AxisZ: Vector3, -- mesh back axis (the dragon faces -Z)
}

type Rig = {
	Model: Model,
	Mesh: MeshPart,
	Root: BasePart?,
	Wings: { { Driven } },
	FrontLegs: { { Driven } },
	BackLegs: { { Driven } },
	Tail: { Driven },
	Neck: Driven?,
	Head: Driven?,
	Hips: Driven?,
	Body: Driven?,
	Phase: number, -- so dragons do not flap in unison
	Stride: number, -- accumulated walk cycle, in cycles
	Flap: number, -- accumulated wing cycle, in radians
	Fly: number, -- 0 on the ground, 1 in the air, blended between
	IsLocal: boolean, -- the local player's own dragon
}

local rigs: { [Model]: Rig } = {}
local rng = Random.new()

local function describe(mesh: MeshPart, bone: Bone): Driven
	local rel = mesh.CFrame:ToObjectSpace(bone.WorldCFrame)
	return {
		Bone = bone,
		Side = if rel.Position.X >= 0 then 1 else -1,
		AxisX = rel:VectorToObjectSpace(Vector3.xAxis),
		AxisY = rel:VectorToObjectSpace(Vector3.yAxis),
		AxisZ = rel:VectorToObjectSpace(Vector3.zAxis),
	}
end

local function find(mesh: MeshPart, name: string): Driven?
	local bone = mesh:FindFirstChild(name, true)
	return if bone and bone:IsA("Bone") then describe(mesh, bone) else nil
end

local function findChain(mesh: MeshPart, names: { string }): { Driven }
	local chain = {}
	for _, name in names do
		local driven = find(mesh, name)
		if driven then
			table.insert(chain, driven)
		end
	end
	return chain
end

local function findChains(mesh: MeshPart, lists: { { string } }): { { Driven } }
	local chains = {}
	for _, names in lists do
		table.insert(chains, findChain(mesh, names))
	end
	return chains
end

local function swing(driven: Driven, axis: Vector3, angle: number)
	driven.Bone.Transform = CFrame.fromAxisAngle(axis, angle)
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Whether this dragon is off the ground. The local player's own uses the
-- flight controller; everyone else is judged by a short ray under the feet.
local function airborne(rig: Rig, scale: number): boolean
	if rig.IsLocal then
		return Flight.IsFlying()
	end
	local root = rig.Root
	if not root then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { rig.Model }
	return Workspace:Raycast(root.Position, Vector3.new(0, -(3 * scale + 2.5), 0), params) == nil
end

local function animate(rig: Rig, dt: number, now: number)
	local root = rig.Root
	local speed = 0
	local verticalSpeed = 0
	if root then
		local velocity = root.AssemblyLinearVelocity
		speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		verticalSpeed = velocity.Y
	end
	local scale = rig.Model:GetScale()
	local flyTarget = if airborne(rig, scale) then 1 else 0
	rig.Fly = lerp(rig.Fly, flyTarget, math.min(dt * FLY_BLEND_RATE, 1))
	local fly = rig.Fly
	local unit = rig.Mesh.Size.Y / DragonRig.ModelHeight -- model units to studs
	-- 0 standing, 1 at a normal walk, a little more when sprinting.
	local walk = math.clamp(speed / (16 * math.sqrt(scale)), 0, 1.4)
	rig.Stride += dt * (2.2 * walk)
	local stride = rig.Stride * math.pi * 2
	local t = now + rig.Phase

	-- Wings. On the ground: folded down and swept back along the body, lower
	-- still when walking, with a soft breathing lift. In the air: spread and
	-- beating, each segment lagging the one before. The phase accumulates so
	-- a change of speed never snaps the angle, and the two poses blend.
	rig.Flap += dt * lerp(1.6 + 1.2 * walk, FLAP_RATE / math.sqrt(scale), fly)
	local breathe = math.sin(rig.Flap) * (0.035 + 0.03 * walk)
	local fold = WING_FOLD + WING_FOLD_WALK * walk + breathe
	local sweep = WING_SWEEP + 0.1 * walk
	local beat = math.sin(rig.Flap)
	for _, wing in rig.Wings do
		for i, segment in wing do
			local side = segment.Side
			if i == 1 then
				-- Shoulder: back about the body's up axis, then down about its forward axis.
				local down = lerp(-fold, FLAP_LIFT + FLAP_SWING * beat, fly)
				local back = lerp(-sweep, -0.15, fly)
				segment.Bone.Transform = CFrame.fromAxisAngle(segment.AxisZ, down * side)
					* CFrame.fromAxisAngle(segment.AxisY, back * side)
			elseif i == 2 then
				-- Elbow: folded it hugs the flank; flying it lags the shoulder's beat.
				local down = lerp(-(WING_ELBOW_FOLD + breathe * 0.5), 0.35 * math.sin(rig.Flap - 0.8) - 0.05, fly)
				local back = lerp(-WING_ELBOW_SWEEP, 0, fly)
				segment.Bone.Transform = CFrame.fromAxisAngle(segment.AxisZ, down * side)
					* CFrame.fromAxisAngle(segment.AxisY, back * side)
			else
				swing(segment, segment.AxisZ, lerp(-WING_TIP, 0.25 * math.sin(rig.Flap - 1.4), fly) * side)
			end
		end
	end

	-- Body: pitch the whole dragon with its climb or dive while flying.
	if rig.Body then
		local pitch = math.clamp(verticalSpeed / 30, -0.35, 0.35) - 0.1 * math.min(speed / 20, 1)
		swing(rig.Body, rig.Body.AxisX, pitch * fly)
	end

	-- Tail: a wave travelling down the chain, side to side with a little lift,
	-- straighter in the air.
	for i, segment in rig.Tail do
		local sway = math.sin(t * 1.8 - i * 0.45) * (0.09 + 0.05 * walk) * (1 - 0.6 * fly)
		local lift = math.sin(t * 1.1 - i * 0.3) * 0.03
		segment.Bone.Transform = CFrame.fromAxisAngle(segment.AxisY, sway) * CFrame.fromAxisAngle(segment.AxisX, lift)
	end

	-- Legs: diagonal gait, upper bone swings, lower bone bends on the back swing.
	local function stepLegs(legs: { { Driven } }, isFront: boolean)
		for _, leg in legs do
			local upper, lower = leg[1], leg[2]
			if not upper then
				continue
			end
			local phase = if (upper.Side > 0) == isFront then 0 else math.pi
			local s = math.sin(stride + phase)
			-- Striding on the ground, drawn back under the body in the air.
			swing(upper, upper.AxisX, lerp(s * 0.5 * walk, -FLY_LEG_TUCK, fly))
			if lower then
				swing(lower, lower.AxisX, lerp(math.max(0, -s) * 0.6 * walk, 0.5, fly))
			end
		end
	end
	stepLegs(rig.FrontLegs, true)
	stepLegs(rig.BackLegs, false)

	-- Neck and head: breathing bob, a nod with each stride.
	if rig.Neck then
		swing(rig.Neck, rig.Neck.AxisX, math.sin(t * 1.6) * 0.04 + math.sin(stride * 2) * 0.03 * walk - 0.15 * fly)
	end
	if rig.Head then
		swing(rig.Head, rig.Head.AxisX, math.sin(t * 1.6 + 1) * 0.04)
	end

	-- Hips: the body rises and falls with each step.
	if rig.Hips then
		local bob = math.abs(math.sin(stride)) * 0.05 * unit * walk
		rig.Hips.Bone.Transform = CFrame.new(rig.Hips.AxisY * bob)
	end
end

-- Builds the rig description once the costume mesh and bones exist.
local function track(model: Model)
	if rigs[model] then
		return
	end
	task.spawn(function()
		local costume = model:WaitForChild(COSTUME_NAME, 30)
		if not costume then
			return
		end
		local mesh = costume:FindFirstChildWhichIsA("MeshPart", true)
		if not mesh then
			return -- the blocky fallback costume, nothing to animate
		end
		-- Bones replicate with the mesh; give the last of them a moment.
		local deadline = os.clock() + 10
		while not mesh:FindFirstChild(DragonRig.Tail[#DragonRig.Tail], true) and os.clock() < deadline do
			task.wait(0.1)
		end
		if not model.Parent then
			return
		end
		local root = model:FindFirstChild("HumanoidRootPart")
		rigs[model] = {
			Model = model,
			Mesh = mesh,
			Root = if root and root:IsA("BasePart") then root else nil,
			Wings = findChains(mesh, DragonRig.Wings),
			FrontLegs = findChains(mesh, DragonRig.FrontLegs),
			BackLegs = findChains(mesh, DragonRig.BackLegs),
			Tail = findChain(mesh, DragonRig.Tail),
			Neck = find(mesh, DragonRig.Neck),
			Head = find(mesh, DragonRig.Head),
			Hips = find(mesh, DragonRig.Hips),
			Body = find(mesh, DragonRig.Root),
			Phase = rng:NextNumber(0, 10),
			Stride = rng:NextNumber(0, 1),
			Flap = rng:NextNumber(0, math.pi * 2),
			Fly = 0,
			IsLocal = model == Players.LocalPlayer.Character,
		}
		local rig = rigs[model]
		if rig then
			print(
				`[DragonAnimator] {model.Name}: wings {#rig.Wings[1] or 0}/{#rig.Wings[2] or 0} legs {#rig.FrontLegs}/{#rig.BackLegs} tail {#rig.Tail} neck {rig.Neck ~= nil} mesh {mesh:GetFullName()} size {mesh.Size}`
			)
		end
	end)
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(track)
	if player.Character then
		track(player.Character)
	end
end

function DragonAnimator.Init()
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end

	task.spawn(function()
		local npcs = Workspace:WaitForChild("Npcs", 60)
		if not npcs then
			return
		end
		npcs.ChildAdded:Connect(function(child)
			if child:IsA("Model") then
				track(child)
			end
		end)
		for _, child in npcs:GetChildren() do
			if child:IsA("Model") then
				track(child)
			end
		end
	end)

	-- Stepped runs after the engine's animation step, so these transforms are
	-- the last word each frame.
	RunService.Stepped:Connect(function(_, dt)
		local now = os.clock()
		for model, rig in rigs do
			if not model.Parent or not rig.Mesh.Parent then
				rigs[model] = nil
				continue
			end
			animate(rig, dt, now)
		end
	end)
end

return DragonAnimator
