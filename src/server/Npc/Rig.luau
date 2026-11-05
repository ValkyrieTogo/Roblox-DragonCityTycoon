--!strict
-- Builds a classic R6 character from parts. R6 is the simplest rig Roblox
-- animates with its own public idle and walk animations, and it has a Head
-- and Torso, so DragonCostume dresses it exactly like a player. Joint
-- offsets are the standard R6 values; change them and the animations break.

local Rig = {}

export type Palette = { Skin: Color3, Shirt: Color3, Pants: Color3 }

-- Roblox's own R6 animations, free to use in any experience.
local IDLE_ANIMATION = "http://www.roblox.com/asset/?id=180435571"
local WALK_ANIMATION = "http://www.roblox.com/asset/?id=180426354"

local function limb(name: string, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	return part
end

local function joint(name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = part0
end

-- Rotation parts of the standard R6 joint offsets.
local ROOT_ROT = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
local RIGHT_ROT = CFrame.new(0, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local LEFT_ROT = CFrame.new(0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)

-- A rig standing with its feet at the origin, facing -Z, not yet parented.
function Rig.Create(name: string, palette: Palette): Model
	local model = Instance.new("Model")
	model.Name = name

	local root = limb("HumanoidRootPart", Vector3.new(2, 2, 1), palette.Skin)
	root.Transparency = 1
	root.CanCollide = true
	local torso = limb("Torso", Vector3.new(2, 2, 1), palette.Shirt)
	local head = limb("Head", Vector3.new(2, 1, 1), palette.Skin)
	local leftArm = limb("Left Arm", Vector3.new(1, 2, 1), palette.Skin)
	local rightArm = limb("Right Arm", Vector3.new(1, 2, 1), palette.Skin)
	local leftLeg = limb("Left Leg", Vector3.new(1, 2, 1), palette.Pants)
	local rightLeg = limb("Right Leg", Vector3.new(1, 2, 1), palette.Pants)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head

	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	-- Feet on the ground: the root sits 3 studs up.
	local origin = CFrame.new(0, 3, 0)
	root.CFrame = origin
	torso.CFrame = origin
	head.CFrame = origin * CFrame.new(0, 1.5, 0)
	leftArm.CFrame = origin * CFrame.new(-1.5, 0, 0)
	rightArm.CFrame = origin * CFrame.new(1.5, 0, 0)
	leftLeg.CFrame = origin * CFrame.new(-0.5, -2, 0)
	rightLeg.CFrame = origin * CFrame.new(0.5, -2, 0)

	joint("RootJoint", root, torso, ROOT_ROT, ROOT_ROT)
	joint("Neck", torso, head, CFrame.new(0, 1, 0) * ROOT_ROT, CFrame.new(0, -0.5, 0) * ROOT_ROT)
	joint("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0) * RIGHT_ROT, CFrame.new(-0.5, 0.5, 0) * RIGHT_ROT)
	joint("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0) * LEFT_ROT, CFrame.new(0.5, 0.5, 0) * LEFT_ROT)
	joint("Right Hip", torso, rightLeg, CFrame.new(1, -1, 0) * RIGHT_ROT, CFrame.new(0.5, 1, 0) * RIGHT_ROT)
	joint("Left Hip", torso, leftLeg, CFrame.new(-1, -1, 0) * LEFT_ROT, CFrame.new(-0.5, 1, 0) * LEFT_ROT)

	for _, part in { root, torso, head, leftArm, rightArm, leftLeg, rightLeg } do
		part.Parent = model
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	model.PrimaryPart = root
	return model
end

-- Starts the idle loop and returns the walk track for the caller to play
-- while moving. Either may be nil if an animation fails to load.
function Rig.Animate(model: Model): (AnimationTrack?, AnimationTrack?)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not animator then
		return nil, nil
	end

	local function load(id: string, priority: Enum.AnimationPriority): AnimationTrack?
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok then
			warn(`[Rig] Could not load animation {id}: {track}`)
			return nil
		end
		track.Priority = priority
		track.Looped = true
		return track
	end

	local idle = load(IDLE_ANIMATION, Enum.AnimationPriority.Idle)
	local walk = load(WALK_ANIMATION, Enum.AnimationPriority.Movement)
	if idle then
		idle:Play()
	end
	return idle, walk
end

return Rig
