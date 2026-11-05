--!strict
-- Builds a grey placeholder plot entirely from code so the game loop can be
-- tested before any art exists. Used only when ServerStorage has no model
-- named "PlotTemplate". Build the real one in Studio with the same child names.
--
-- Required children of a plot template:
--   Base       (BasePart, the PrimaryPart; the plot is pivoted by it)
--   Spawn      (SpawnLocation, Neutral = false)
--   OwnerSign  (BasePart with a BillboardGui containing a TextLabel named "Label")
--   Buttons    (Folder, buy buttons go here in milestone 2)
--   Unlocks    (Folder, purchasable models go here in milestone 2)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DevPlotTemplate = {}

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

function DevPlotTemplate.Build(): Model
	local model = Instance.new("Model")
	model.Name = "PlotTemplate"

	local size = Config.PlotSize

	local base = makePart("Base", Vector3.new(size, 1, size), CFrame.new(0, 0, 0), Color3.fromRGB(99, 95, 98))
	base.Material = Enum.Material.Concrete
	base.Parent = model
	model.PrimaryPart = base

	-- Spawn pad near the front edge of the plot.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, 0.5, size / 2 - 6)
	spawn.Color = Color3.fromRGB(75, 151, 75)
	spawn.Anchored = true
	spawn.Neutral = false -- only used through Player.RespawnLocation
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = model

	-- Sign post with a floating label showing who owns the plot.
	local sign =
		makePart("OwnerSign", Vector3.new(1, 8, 1), CFrame.new(0, 4.5, size / 2 - 1), Color3.fromRGB(60, 60, 60))
	sign.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Billboard"
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Text = "Unclaimed"
	label.Parent = billboard

	local buttons = Instance.new("Folder")
	buttons.Name = "Buttons"
	buttons.Parent = model

	local unlocks = Instance.new("Folder")
	unlocks.Name = "Unlocks"
	unlocks.Parent = model

	return model
end

return DevPlotTemplate
