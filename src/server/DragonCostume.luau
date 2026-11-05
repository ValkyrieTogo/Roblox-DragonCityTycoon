--!strict
-- Dresses a character as a dragon with placeholder parts: wings, a tail, horns
-- and a Mouth attachment on the head that the fire comes from. Everything is
-- welded to body parts, so Model:ScaleTo on the character scales it all.
-- Works with R15 and R6 rigs. Replace the parts with real meshes or
-- accessories later; the only thing the code relies on is:
--   Head.Mouth          (Attachment, facing the head's -Z)
--     Flame             (ParticleEmitter with Rate 0, emitted on click)
--     Glow              (PointLight, flashed on click)

local DragonCostume = {}

local COSTUME_NAME = "DragonCostume"
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

local function addMouth(head: BasePart)
	local mouth = Instance.new("Attachment")
	mouth.Name = "Mouth"
	mouth.CFrame = CFrame.new(0, -0.25, -0.65)
	mouth.Parent = head

	local flame = Instance.new("ParticleEmitter")
	flame.Name = "Flame"
	flame.Texture = "rbxasset://textures/particles/fire_main.dds"
	flame.Rate = 0
	flame.Lifetime = NumberRange.new(0.35, 0.6)
	flame.Speed = NumberRange.new(18, 26)
	flame.SpreadAngle = Vector2.new(12, 12)
	flame.EmissionDirection = Enum.NormalId.Front
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

-- Adds the costume to a character that already has its body parts loaded.
function DragonCostume.Dress(character: Model)
	if character:FindFirstChild(COSTUME_NAME) then
		return
	end

	local head = character:FindFirstChild("Head")
	local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local lowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if not head or not head:IsA("BasePart") or not upperTorso or not upperTorso:IsA("BasePart") then
		warn(`[DragonCostume] {character.Name} is missing a Head or Torso`)
		return
	end

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

	if not head:FindFirstChild("Mouth") then
		addMouth(head)
	end
end

return DragonCostume
