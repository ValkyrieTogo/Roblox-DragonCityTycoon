--!strict
-- Builds a placeholder dragon from plain parts so growth and fire can be tested
-- before a real model exists. Used only when ServerStorage has no model named
-- "Dragon". Build the real one in Studio with the same child names.
--
-- Required layout of a dragon model:
--   Body       (BasePart, the PrimaryPart; everything else welded to it)
--   Head       (BasePart) containing
--     Mouth    (Attachment, where fire comes out, facing the model's -Z)
--       Flame  (ParticleEmitter with Rate 0, emitted on click)
--       Glow   (PointLight, flashed on click)
-- The model faces -Z, like a character. It is welded beside the player.

local DevDragon = {}

local BODY_COLOR = Color3.fromRGB(170, 40, 40)
local BELLY_COLOR = Color3.fromRGB(230, 180, 90)
local WING_COLOR = Color3.fromRGB(120, 25, 25)

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
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

local function weld(a: BasePart, b: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = a
	constraint.Part1 = b
	constraint.Parent = a
end

function DevDragon.Build(): Model
	local model = Instance.new("Model")
	model.Name = "Dragon"

	local body = makePart("Body", Vector3.new(2, 1.6, 3), CFrame.new(0, 0, 0), BODY_COLOR)
	body.Shape = Enum.PartType.Block
	body.Parent = model
	model.PrimaryPart = body

	local belly = makePart("Belly", Vector3.new(1.4, 0.6, 2.2), CFrame.new(0, -0.6, 0), BELLY_COLOR)
	belly.Parent = model
	weld(body, belly)

	local head = makePart("Head", Vector3.new(1.2, 1.1, 1.4), CFrame.new(0, 0.7, -2), BODY_COLOR)
	head.Parent = model
	weld(body, head)

	local snout = makePart("Snout", Vector3.new(0.8, 0.6, 0.8), CFrame.new(0, 0.5, -2.9), BELLY_COLOR)
	snout.Parent = model
	weld(body, snout)

	local wingLeft = makePart(
		"WingLeft",
		Vector3.new(2.6, 0.15, 1.6),
		CFrame.new(-2, 0.7, 0) * CFrame.Angles(0, 0, math.rad(20)),
		WING_COLOR
	)
	wingLeft.Parent = model
	weld(body, wingLeft)

	local wingRight = makePart(
		"WingRight",
		Vector3.new(2.6, 0.15, 1.6),
		CFrame.new(2, 0.7, 0) * CFrame.Angles(0, 0, math.rad(-20)),
		WING_COLOR
	)
	wingRight.Parent = model
	weld(body, wingRight)

	local tail = makePart(
		"Tail",
		Vector3.new(0.6, 0.5, 2.4),
		CFrame.new(0, 0.1, 2.6) * CFrame.Angles(math.rad(15), 0, 0),
		BODY_COLOR
	)
	tail.Parent = model
	weld(body, tail)

	-- Fire comes out of the mouth, pointing forward (-Z).
	local mouth = Instance.new("Attachment")
	mouth.Name = "Mouth"
	mouth.CFrame = CFrame.new(0, -0.2, -1.2)
	mouth.Parent = snout

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

	return model
end

return DevDragon
