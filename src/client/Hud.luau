--!strict
-- On-screen Fire counter. Built in code for now; reads leaderstats and the
-- FirePerClick attribute, both replicated by Roblox, so it needs no remotes.

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

	local hint =
		makeLabel("Hint", UDim2.fromOffset(500, 30), UDim2.new(0.5, 0, 1, -60), 20, Color3.fromRGB(220, 220, 220))
	hint.Text = "Click or tap anywhere to breathe fire"
	hint.Parent = screen

	screen.Parent = playerGui

	local function updateFire(value: number)
		fireLabel.Text = `{Format.Short(value)} Fire`
	end

	local function updatePerClick()
		local value = localPlayer:GetAttribute("FirePerClick")
		local amount = if typeof(value) == "number" then value else Config.BaseFirePerClick
		perClickLabel.Text = `+{Format.Short(amount)} per click`
	end

	updateFire(0)
	updatePerClick()
	localPlayer:GetAttributeChangedSignal("FirePerClick"):Connect(updatePerClick)

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
