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

local DragonAnimator = {}

local COSTUME_NAME = "DragonCostume"

-- Wing pose, in radians. The rest pose has the wings spread and raised;
-- these tuck them down along the flanks. The sweep is applied first, so the
-- wing goes back along the body, then the fold drops what still sticks out.
local WING_SWEEP = 1.05 -- shoulder back along the body
local WING_FOLD = 1.2 -- shoulder down
local WING_FOLD_WALK = 0.1 -- extra when walking
local WING_ELBOW_FOLD = 0.5 -- forearm down further, hugging the flank
local WING_ELBOW_SWEEP = 0.35 -- forearm back along the body
local WING_TIP = 0.25 -- outer segments curled down

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
	Phase: number, -- so dragons do not flap in unison
	Stride: number, -- accumulated walk cycle, in cycles
	Flap: number, -- accumulated wing cycle, in radians
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

local function animate(rig: Rig, dt: number, now: number)
	local root = rig.Root
	local speed = 0
	if root then
		local velocity = root.AssemblyLinearVelocity
		speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	end
	local scale = rig.Model:GetScale()
	local unit = rig.Mesh.Size.Y / DragonRig.ModelHeight -- model units to studs
	-- 0 standing, 1 at a normal walk, a little more when sprinting.
	local walk = math.clamp(speed / (16 * math.sqrt(scale)), 0, 1.4)
	rig.Stride += dt * (2.2 * walk)
	local stride = rig.Stride * math.pi * 2
	local t = now + rig.Phase

	-- Wings: held folded down and swept back along the body, lower still when
	-- walking, with a soft breathing lift. The phase accumulates so a change
	-- of speed never snaps the angle.
	rig.Flap += dt * (1.6 + 1.2 * walk)
	local breathe = math.sin(rig.Flap) * (0.035 + 0.03 * walk)
	local fold = WING_FOLD + WING_FOLD_WALK * walk + breathe
	local sweep = WING_SWEEP + 0.1 * walk
	for _, wing in rig.Wings do
		for i, segment in wing do
			local side = segment.Side
			if i == 1 then
				-- Shoulder: back about the body's up axis, then down about its forward axis.
				segment.Bone.Transform = CFrame.fromAxisAngle(segment.AxisZ, -fold * side)
					* CFrame.fromAxisAngle(segment.AxisY, -sweep * side)
			elseif i == 2 then
				-- Elbow: keeps going down and back so the forearm lies along the flank.
				segment.Bone.Transform = CFrame.fromAxisAngle(segment.AxisZ, -(WING_ELBOW_FOLD + breathe * 0.5) * side)
					* CFrame.fromAxisAngle(segment.AxisY, -WING_ELBOW_SWEEP * side)
			else
				swing(segment, segment.AxisZ, -WING_TIP * side)
			end
		end
	end

	-- Tail: a wave travelling down the chain, side to side with a little lift.
	for i, segment in rig.Tail do
		local sway = math.sin(t * 1.8 - i * 0.45) * (0.09 + 0.05 * walk)
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
			swing(upper, upper.AxisX, s * 0.5 * walk)
			if lower then
				swing(lower, lower.AxisX, math.max(0, -s) * 0.6 * walk)
			end
		end
	end
	stepLegs(rig.FrontLegs, true)
	stepLegs(rig.BackLegs, false)

	-- Neck and head: breathing bob, a nod with each stride.
	if rig.Neck then
		swing(rig.Neck, rig.Neck.AxisX, math.sin(t * 1.6) * 0.04 + math.sin(stride * 2) * 0.03 * walk)
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
			Phase = rng:NextNumber(0, 10),
			Stride = rng:NextNumber(0, 1),
			Flap = rng:NextNumber(0, math.pi * 2),
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
