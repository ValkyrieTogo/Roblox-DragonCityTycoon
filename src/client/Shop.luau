--!strict
-- Upgrade shop panel on the left of the screen. One card per upgrade with its
-- level, bonus and a buy button. Levels and Fire are replicated attributes and
-- leaderstats, so the panel only reads them and sends buy requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Shop = {}

local localPlayer = Players.LocalPlayer

local PANEL_WIDTH = 250
local CARD_HEIGHT = 92
local CARD_GAP = 8

local AFFORD_COLOR = Color3.fromRGB(70, 170, 80)
local CANNOT_AFFORD_COLOR = Color3.fromRGB(90, 90, 90)
local MAXED_COLOR = Color3.fromRGB(190, 150, 60)

type Card = {
	Upgrade: Config.Upgrade,
	LevelLabel: TextLabel,
	BuyButton: TextButton,
}

local cards: { Card } = {}
local currentFire = 0

local function makeText(parent: Instance, name: string, text: string, size: UDim2, position: UDim2, textSize: number)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

local function makeCard(parent: Instance, index: number, upgrade: Config.Upgrade): Card
	local card = Instance.new("Frame")
	card.Name = upgrade.Id
	card.Size = UDim2.new(1, 0, 0, CARD_HEIGHT)
	card.Position = UDim2.fromOffset(0, (index - 1) * (CARD_HEIGHT + CARD_GAP))
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	makeText(card, "Name", upgrade.Name, UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 6), 18)
	makeText(card, "Description", upgrade.Description, UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 28), 14)
	local levelLabel = makeText(card, "Level", "", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 46), 14)
	levelLabel.TextColor3 = Color3.fromRGB(255, 170, 40)

	local button = Instance.new("TextButton")
	button.Name = "Buy"
	button.Size = UDim2.new(1, -20, 0, 24)
	button.Position = UDim2.fromOffset(10, 64)
	button.BackgroundColor3 = CANNOT_AFFORD_COLOR
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = ""
	button.AutoButtonColor = true
	button.Parent = card

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	button.Activated:Connect(function()
		Remotes.BuyUpgrade():FireServer(upgrade.Id)
	end)

	card.Parent = parent
	return { Upgrade = upgrade, LevelLabel = levelLabel, BuyButton = button }
end

local function levelOf(upgrade: Config.Upgrade): number
	local value = localPlayer:GetAttribute(Config.UpgradeAttribute(upgrade.Id))
	return if typeof(value) == "number" then value else 0
end

local function refreshCard(card: Card)
	local upgrade = card.Upgrade
	local level = levelOf(upgrade)
	card.LevelLabel.Text = `Level {level} / {upgrade.MaxLevel}  (+{Format.Short(level * upgrade.PerLevel)} per click)`

	if level >= upgrade.MaxLevel then
		card.BuyButton.Text = "MAXED"
		card.BuyButton.BackgroundColor3 = MAXED_COLOR
		card.BuyButton.Active = false
		return
	end

	local cost = Config.UpgradeCost(upgrade, level)
	card.BuyButton.Text = `Buy for {Format.Short(cost)} Fire`
	card.BuyButton.Active = true
	card.BuyButton.BackgroundColor3 = if currentFire >= cost then AFFORD_COLOR else CANNOT_AFFORD_COLOR
end

local function refreshAll()
	for _, card in cards do
		refreshCard(card)
	end
end

function Shop.Init()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "Shop"
	screen.ResetOnSpawn = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, #Config.Upgrades * (CARD_HEIGHT + CARD_GAP) + 30)
	panel.Position = UDim2.new(0, 16, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.BackgroundTransparency = 1

	local title = makeText(panel, "Title", "UPGRADES", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 0), 20)
	title.TextColor3 = Color3.fromRGB(255, 170, 40)

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Size = UDim2.new(1, 0, 1, -30)
	list.Position = UDim2.fromOffset(0, 30)
	list.BackgroundTransparency = 1
	list.Parent = panel

	for index, upgrade in Config.Upgrades do
		local card = makeCard(list, index, upgrade)
		table.insert(cards, card)
		localPlayer:GetAttributeChangedSignal(Config.UpgradeAttribute(upgrade.Id)):Connect(function()
			refreshCard(card)
		end)
	end

	panel.Parent = screen
	screen.Parent = playerGui

	refreshAll()

	task.spawn(function()
		local leaderstats = localPlayer:WaitForChild("leaderstats", 30)
		local fire = if leaderstats then leaderstats:WaitForChild("Fire", 30) else nil
		if fire and fire:IsA("IntValue") then
			currentFire = fire.Value
			refreshAll()
			fire.Changed:Connect(function(value)
				currentFire = value
				refreshAll()
			end)
		end
	end)
end

return Shop
