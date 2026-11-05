--!strict
-- Turns a character into a dragon. With the mesh dragon in
-- ReplicatedStorage.Shared.Assets.Dragon (a Model holding a skinned MeshPart
-- with Bones, imported from Meshy), the avatar is hidden and the dragon is
-- welded to its root, so walking, jumping and Model:ScaleTo all keep working.
-- Without it, placeholder wings, tail and horns are welded on instead.
-- Either way the character gets an ObjectValue "Mouth" pointing at the
-- attachment the fire comes from, which holds:
--   Flame   ParticleEmitter with Rate 0, emitted on click
--   Glow    PointLight, flashed on click
-- Works with R15 and R6 rigs, players and NPCs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DragonCostume = {}

local COSTUME_NAME = "DragonCostume"

-- Mesh dragon tuning. The Meshy model is 1.7 studs tall at scale 1, so it is
-- enlarged to hatchling size; growth scales the whole character on top.
local MESH_SCALE = 3
local MESH_YAW = 0 -- the import already faces -Z, Roblox's forward
local MOUTH_BONE = "Bone_039" -- last bone of the head chain, at the snout
local MOUTH_EMISSION = Enum.NormalId.Top -- a bone's Y axis runs along the bone, out of the snout

local WING_COLOR = Color3.fromRGB(140, 30, 30)
local HORN_COLOR = Color3.fromRGB(230, 200, 140)
local TAIL_COLOR = Color3.fromRGB(170, 40, 40)

local function makePart(name: string, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Welds `part` to `to` at `offset` in the body part's local space.
local function attach(part: BasePart, to: BasePart, offset: CFrame, parent: Instance)
	part.CFrame = to.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = to
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = parent
end

-- The fire effects, parented to the mouth attachment or bone.
local function addFire(mouth: Attachment, emission: Enum.NormalId)
	local flame = Instance.new("ParticleEmitter")
	flame.Name = "Flame"
	flame.Texture = "rbxasset://textures/particles/fire_main.dds"
	flame.Rate = 0
	flame.Lifetime = NumberRange.new(0.35, 0.6)
	flame.Speed = NumberRange.new(18, 26)
	flame.SpreadAngle = Vector2.new(12, 12)
	flame.EmissionDirection = emission
	flame.Acceleration = Vector3.new(0, 6, 0)
	flame.Drag = 4
	flame.LightEmission = 1
	flame.LightInfluence = 0
	flame.Rotation = NumberRange.new(0, 360)
	flame.RotSpeed = NumberRange.new(-120, 120)
	flame.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 140, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 10)),
	})
	flame.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.4, 1.6),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	flame.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	flame.Parent = mouth

	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Color = Color3.fromRGB(255, 150, 60)
	glow.Brightness = 4
	glow.Range = 12
	glow.Enabled = false
	glow.Parent = mouth
end

local function setMouth(character: Model, mouth: Attachment)
	local ref = Instance.new("ObjectValue")
	ref.Name = "Mouth"
	ref.Value = mouth
	ref.Parent = character
end

-- Placeholder costume ------------------------------------------------------

local function dressBlocks(character: Model, head: BasePart, upperTorso: BasePart)
	local lowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")

	local costume = Instance.new("Model")
	costume.Name = COSTUME_NAME

	-- Wings sweep back and out from the shoulder blades.
	local wingSize = Vector3.new(2.8, 0.15, 1.8)
	local wingLeft = makePart("WingLeft", wingSize, WING_COLOR)
	attach(wingLeft, upperTorso, CFrame.new(-1.6, 0.5, 0.9) * CFrame.Angles(0, math.rad(-35), math.rad(25)), costume)
	local wingRight = makePart("WingRight", wingSize, WING_COLOR)
	attach(wingRight, upperTorso, CFrame.new(1.6, 0.5, 0.9) * CFrame.Angles(0, math.rad(35), math.rad(-25)), costume)

	-- Tail trails behind and down from the lower back.
	local tailBase: BasePart = if lowerTorso and lowerTorso:IsA("BasePart") then lowerTorso else upperTorso
	local tail = makePart("Tail", Vector3.new(0.5, 0.45, 2.6), TAIL_COLOR)
	attach(tail, tailBase, CFrame.new(0, -0.2, 1.6) * CFrame.Angles(math.rad(-20), 0, 0), costume)
	local tailTip = makePart("TailTip", Vector3.new(0.7, 0.2, 0.9), WING_COLOR)
	attach(tailTip, tailBase, CFrame.new(0, 0.4, 3.1) * CFrame.Angles(math.rad(-20), 0, 0), costume)

	-- Horns tilt outward from the top of the head.
	local hornSize = Vector3.new(0.25, 0.8, 0.25)
	local hornLeft = makePart("HornLeft", hornSize, HORN_COLOR)
	attach(hornLeft, head, CFrame.new(-0.35, 0.75, 0) * CFrame.Angles(0, 0, math.rad(25)), costume)
	local hornRight = makePart("HornRight", hornSize, HORN_COLOR)
	attach(hornRight, head, CFrame.new(0.35, 0.75, 0) * CFrame.Angles(0, 0, math.rad(-25)), costume)

	costume.Parent = character

	local mouth = Instance.new("Attachment")
	mouth.Name = "Mouth"
	mouth.CFrame = CFrame.new(0, -0.25, -0.65)
	mouth.Parent = head
	addFire(mouth, Enum.NormalId.Front)
	setMouth(character, mouth)
end

-- Mesh costume ------------------------------------------------------------

local function findTemplate(): Model?
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local assets = if shared then shared:FindFirstChild("Assets") else nil
	local dragon = if assets then assets:FindFirstChild("Dragon") else nil
	if dragon and dragon:IsA("Model") and dragon:FindFirstChildWhichIsA("MeshPart", true) then
		return dragon
	end
	return nil
end

-- Hides an avatar part, decal or accessory so only the dragon shows.
local function hide(instance: Instance, costume: Model)
	if instance:IsDescendantOf(costume) then
		return
	end
	if instance:IsA("BasePart") then
		instance.Transparency = 1
	elseif instance:IsA("Decal") then
		instance.Transparency = 1
	end
end

-- How far the root's centre sits above the ground for this rig.
local function groundOffset(humanoid: Humanoid, root: BasePart): number
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return root.Size.Y / 2 + 2
	end
	return humanoid.HipHeight + root.Size.Y / 2
end

local function dressMesh(character: Model, template: Model, root: BasePart, humanoid: Humanoid): boolean
	local costume = template:Clone()
	costume.Name = COSTUME_NAME
	local mesh = costume:FindFirstChildWhichIsA("MeshPart", true)
	if not mesh then
		costume:Destroy()
		return false
	end

	costume:ScaleTo(MESH_SCALE)
	-- The template's pivot is the scene origin, between the dragon's feet.
	costume:PivotTo(root.CFrame * CFrame.new(0, -groundOffset(humanoid, root), 0) * CFrame.Angles(0, MESH_YAW, 0))

	for _, descendant in costume:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end

	local weld = Instance.new("Weld")
	weld.Name = "RootWeld"
	weld.Part0 = root
	weld.Part1 = mesh
	weld.C0 = root.CFrame:ToObjectSpace(mesh.CFrame)
	weld.Parent = mesh

	costume.Parent = character

	for _, descendant in character:GetDescendants() do
		hide(descendant, costume)
	end
	-- Accessories and clothing can load after the costume; hide those too.
	character.DescendantAdded:Connect(function(descendant)
		hide(descendant, costume)
	end)

	local bone = mesh:FindFirstChild(MOUTH_BONE, true)
	if bone and bone:IsA("Attachment") then
		addFire(bone, MOUTH_EMISSION)
		setMouth(character, bone)
	else
		warn(`[DragonCostume] Mouth bone {MOUTH_BONE} not found on the dragon mesh; fire has nowhere to come from`)
	end
	return true
end

-- Adds the costume to a character that already has its body parts loaded.
function DragonCostume.Dress(character: Model)
	if character:FindFirstChild(COSTUME_NAME) then
		return
	end

	local head = character:FindFirstChild("Head")
	local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not head or not head:IsA("BasePart") or not upperTorso or not upperTorso:IsA("BasePart") then
		warn(`[DragonCostume] {character.Name} is missing a Head or Torso`)
		return
	end

	local template = findTemplate()
	if template and root and root:IsA("BasePart") and humanoid then
		if dressMesh(character, template, root, humanoid) then
			return
		end
	end
	dressBlocks(character, head, upperTorso)
end

return DragonCostume
