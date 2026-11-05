--!strict
-- Creates the plots at startup, hands one to each player on join, and resets it
-- when they leave. One template model is cloned onto each anchor part so every
-- plot is identical and only one model needs maintaining.
--
-- Studio setup (both optional, placeholders are generated when missing):
--   ServerStorage.PlotTemplate   the plot model, see DevPlotTemplate for required children
--   Workspace.PlotAnchors        folder of parts; a plot is pivoted onto each one

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local DevPlotTemplate = require(script.Parent.Parent.DevPlotTemplate)

type PlotState = Types.PlotState

local PlotService = {}

local template: Model
local anchors: { BasePart } = {}
local plots: { PlotState } = {}
local plotsFolder: Folder

-- Template -----------------------------------------------------------------

local function getTemplate(): Model
	local existing = ServerStorage:FindFirstChild("PlotTemplate")
	if existing and existing:IsA("Model") then
		return existing
	end

	warn("[PlotService] No PlotTemplate in ServerStorage, using the code-built placeholder")
	local built = DevPlotTemplate.Build()
	built.Parent = ServerStorage
	return built
end

-- Anchors ------------------------------------------------------------------

local function createAnchors(): { BasePart }
	local folder = Instance.new("Folder")
	folder.Name = "PlotAnchors"

	local pitch = Config.PlotSize + Config.PlotSpacing
	local perRow = Config.PlotsPerRow
	local rows = math.ceil(Config.PlotCount / perRow)

	local created = {}
	for index = 1, Config.PlotCount do
		local col = (index - 1) % perRow
		local row = (index - 1) // perRow
		local x = (col - (perRow - 1) / 2) * pitch
		local z = (row - (rows - 1) / 2) * pitch

		local anchor = Instance.new("Part")
		anchor.Name = `Anchor{index}`
		anchor.Size = Vector3.new(4, 1, 4)
		anchor.CFrame = CFrame.new(x, 0.5, z)
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.Transparency = 1
		anchor.Parent = folder
		table.insert(created, anchor)
	end

	folder.Parent = Workspace
	return created
end

local function getAnchors(): { BasePart }
	local folder = Workspace:FindFirstChild("PlotAnchors")
	if folder then
		local found = {}
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(found, child)
			end
		end
		if #found > 0 then
			table.sort(found, function(a, b)
				return a.Name < b.Name
			end)
			return found
		end
	end

	warn("[PlotService] No Workspace.PlotAnchors with parts, generating a grid")
	return createAnchors()
end

-- Plots --------------------------------------------------------------------

local function setSignText(model: Model, text: string)
	local sign = model:FindFirstChild("OwnerSign")
	local label = if sign then sign:FindFirstChild("Label", true) else nil
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function buildPlotModel(index: number, anchor: BasePart): Model
	local model = template:Clone()
	model.Name = `Plot{index}`
	model:SetAttribute("Index", index)
	model:PivotTo(anchor.CFrame)
	setSignText(model, "Unclaimed")
	model.Parent = plotsFolder
	return model
end

local function findPlotByOwner(player: Player): PlotState?
	for _, plot in plots do
		if plot.Owner == player then
			return plot
		end
	end
	return nil
end

local function getSpawn(plot: PlotState): SpawnLocation?
	local spawn = plot.Model:FindFirstChild("Spawn")
	return if spawn and spawn:IsA("SpawnLocation") then spawn else nil
end

local function teleportToPlot(player: Player, plot: PlotState)
	local character = player.Character
	local spawn = getSpawn(plot)
	if not character or not spawn then
		return
	end
	-- Wait briefly for the root part so a freshly loaded character can be moved.
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 3, 0))
	end
end

local function assignPlot(player: Player)
	for _, plot in plots do
		if plot.Owner == nil then
			plot.Owner = player
			plot.Model:SetAttribute("OwnerUserId", player.UserId)
			setSignText(plot.Model, `{player.DisplayName}`)

			local spawn = getSpawn(plot)
			if spawn then
				player.RespawnLocation = spawn
			end

			player.CharacterAdded:Connect(function()
				teleportToPlot(player, plot)
			end)
			teleportToPlot(player, plot)

			print(`[PlotService] {player.Name} got Plot{plot.Index}`)
			return
		end
	end

	warn(`[PlotService] No free plot for {player.Name}; server has {#plots} plots`)
end

local function releasePlot(player: Player)
	local plot = findPlotByOwner(player)
	if not plot then
		return
	end

	plot.Owner = nil
	-- Rebuild from the template so the next owner gets an untouched plot.
	plot.Model:Destroy()
	plot.Model = buildPlotModel(plot.Index, anchors[plot.Index])
	print(`[PlotService] Plot{plot.Index} reset after {player.Name} left`)
end

-- Public API ---------------------------------------------------------------

function PlotService.GetPlot(player: Player): PlotState?
	return findPlotByOwner(player)
end

function PlotService.GetOwner(model: Model): Player?
	for _, plot in plots do
		if plot.Model == model then
			return plot.Owner
		end
	end
	return nil
end

function PlotService.GetPlots(): { PlotState }
	return plots
end

function PlotService.Init()
	template = getTemplate()
	anchors = getAnchors()

	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace

	for index, anchor in anchors do
		table.insert(plots, {
			Index = index,
			Model = buildPlotModel(index, anchor),
			Owner = nil,
		})
	end
	print(`[PlotService] Built {#plots} plots`)

	Players.PlayerAdded:Connect(assignPlot)
	Players.PlayerRemoving:Connect(releasePlot)
	for _, player in Players:GetPlayers() do
		assignPlot(player)
	end
end

return PlotService
