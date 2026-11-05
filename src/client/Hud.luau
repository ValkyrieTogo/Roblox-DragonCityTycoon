--!strict
-- On-screen Fire counter. Built in code for now; reads leaderstats and player
-- attributes, all replicated by Roblox, so it needs no remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local Hud = {}

local localPlayer = Players.LocalPlayer

local function makeLabel(name: string, size: UDim2, position: UDim2, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Text = ""
	return label
end

local function numberAttribute(name: string, default: number): number
	local value = localPlayer:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

function Hud.Init()
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "FireHud"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true

	local fireLabel =
		makeLabel("Fire", UDim2.fromOffset(400, 60), UDim2.new(0.5, 0, 0, 24), 48, Color3.fromRGB(255, 170, 40))
	fireLabel.Parent = screen

	local perClickLabel =
		makeLabel("PerClick", UDim2.fromOffset(400, 30), UDim2.new(0.5, 0, 0, 84), 22, Color3.new(1, 1, 1))
	perClickLabel.Parent = screen

	local zoneLabel =
		makeLabel("Zone", UDim2.fromOffset(400, 30), UDim2.new(0.5, 0, 0, 112), 20, Color3.fromRGB(150, 210, 255))
	zoneLabel.Parent = screen

	local hint =
		makeLabel("Hint", UDim2.fromOffset(500, 30), UDim2.new(0.5, 0, 1, -60), 20, Color3.fromRGB(220, 220, 220))
	hint.Text = "Click or tap anywhere to breathe fire"
	hint.Parent = screen

	screen.Parent = playerGui

	local function updateFire(value: number)
		fireLabel.Text = `{Format.Short(value)} Fire`
	end

	local function updateClickInfo()
		local perClick = numberAttribute("FirePerClick", Config.BaseFirePerClick)
		local multiplier = numberAttribute("ZoneMultiplier", 1)
		perClickLabel.Text = `+{Format.Short(perClick * multiplier)} per click`

		local zoneName = localPlayer:GetAttribute("ZoneName")
		if typeof(zoneName) == "string" and zoneName ~= "" then
			zoneLabel.Text = `{zoneName}  x{multiplier}`
		else
			zoneLabel.Text = ""
		end
	end

	updateFire(0)
	updateClickInfo()
	for _, name in { "FirePerClick", "ZoneMultiplier", "ZoneName" } do
		localPlayer:GetAttributeChangedSignal(name):Connect(updateClickInfo)
	end

	task.spawn(function()
		local leaderstats = localPlayer:WaitForChild("leaderstats", 30)
		local fire = if leaderstats then leaderstats:WaitForChild("Fire", 30) else nil
		if fire and fire:IsA("IntValue") then
			updateFire(fire.Value)
			fire.Changed:Connect(updateFire)
		end
	end)
end

return Hud
