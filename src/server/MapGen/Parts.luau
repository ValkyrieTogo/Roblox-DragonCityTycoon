--!strict
-- Small helpers for building anchored parts and effects from code.
-- Every function parents the result and returns it.

local Parts = {}

local function finish(part: BasePart, parent: Instance, name: string, color: Color3, material: Enum.Material?)
	part.Name = name
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
end

function Parts.block(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Size = size
	part.CFrame = cframe
	finish(part, parent, name, color, material)
	return part
end

-- A cylinder standing on its end. `cframe` is its centre with Y as the axis.
function Parts.cylinder(
	parent: Instance,
	name: string,
	radius: number,
	height: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(height, radius * 2, radius * 2)
	part.CFrame = cframe * CFrame.Angles(0, 0, math.rad(90))
	finish(part, parent, name, color, material)
	return part
end

-- A flat disc lying on the ground, centred at `position` (its top at position.Y + thickness/2).
function Parts.disc(
	parent: Instance,
	name: string,
	radius: number,
	thickness: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	return Parts.cylinder(parent, name, radius, thickness, CFrame.new(position), color, material)
end

function Parts.ball(
	parent: Instance,
	name: string,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(diameter, diameter, diameter)
	part.CFrame = CFrame.new(position)
	finish(part, parent, name, color, material)
	return part
end

-- A stretched sphere, for eggs and boulders.
function Parts.egg(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local largest = math.max(size.X, size.Y, size.Z)
	local part = Instance.new("Part")
	part.Size = Vector3.new(largest, largest, largest)
	part.CFrame = cframe
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = size / largest
	mesh.Parent = part
	finish(part, parent, name, color, material)
	return part
end

-- Wedge: the slope rises toward -Z in its own space (the thin edge faces +Z).
function Parts.wedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): WedgePart
	local part = Instance.new("WedgePart")
	part.Size = size
	part.CFrame = cframe
	finish(part, parent, name, color, material)
	return part
end

function Parts.invisible(part: BasePart)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

function Parts.noCollide(part: BasePart)
	part.CanCollide = false
	part.CanQuery = false
end

function Parts.fire(part: BasePart, size: number, heat: number, color: Color3?, secondary: Color3?): Fire
	local fire = Instance.new("Fire")
	fire.Size = size
	fire.Heat = heat
	fire.Color = color or Color3.fromRGB(255, 140, 40)
	fire.SecondaryColor = secondary or Color3.fromRGB(255, 60, 20)
	fire.Parent = part
	return fire
end

function Parts.light(part: BasePart, color: Color3, range: number, brightness: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = part
	return light
end

-- Slow glowing motes drifting upward from the part's volume (embers, sparkles).
function Parts.motes(part: BasePart, rate: number, color: Color3, size: number): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(2, 4)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(25, 25)
	emitter.Acceleration = Vector3.new(0, 1.5, 0)
	emitter.Drag = 0.5
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, size * 0.3),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = part
	return emitter
end

-- An invisible box that fills `size` at `position` and emits motes from its volume.
function Parts.moteField(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	rate: number,
	color: Color3,
	moteSize: number
): Part
	local field = Parts.block(parent, name, size, CFrame.new(position), Color3.new(1, 1, 1))
	Parts.invisible(field)
	Parts.motes(field, rate, color, moteSize)
	return field
end

function Parts.model(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

-- Floating text above a part.
function Parts.sign(part: BasePart, text: string, height: number, width: number, textColor: Color3?): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Sign"
	billboard.Size = UDim2.fromOffset(width, 80)
	billboard.StudsOffset = Vector3.new(0, height, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 400

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = billboard

	billboard.Parent = part
	return billboard
end

return Parts
