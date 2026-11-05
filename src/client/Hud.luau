--!strict
-- On-screen Fire counter, zone line, wins line and the win banner. Built in
-- code for now; reads leaderstats and player attributes, all replicated by
-- Roblox, so the only remote involved is the Won event for the banner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Hud = {}

local localPlayer = Players.LocalPlayer

local BANNER_SECONDS = 2.5

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

local function watchStat(name: string, callback: (number) -> ())
	task.spawn(function()
		local leaderstats = localPlayer:WaitForChild("leaderstats", 30)
		local stat = if leaderstats then leaderstats:WaitForChild(name, 30) else nil
		if stat and stat:IsA("IntValue") then
			callback(stat.Value)
			stat.Changed:Connect(callback)
		end
	end)
end

local function showWinBanner(screen: ScreenGui, wins: number)
	local banner =
		makeLabel("WinBanner", UDim2.fromOffset(600, 90), UDim2.new(0.5, 0, 0.3, 0), 72, Color3.fromRGB(255, 220, 90))
	banner.Text = `WIN #{wins}!`
	banner.TextStrokeTransparency = 0
	banner.TextTransparency = 1
	banner.Parent = screen

	local sub = makeLabel("WinSub", UDim2.fromOffset(600, 40), UDim2.new(0.5, 0, 0.3, 90), 26, Color3.new(1, 1, 1))
	sub.Text = `All Fire now x{Config.WinMultiplier(wins)}`
	sub.TextTransparency = 1
	sub.Parent = screen

	local fadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(banner, fadeIn, { TextTransparency = 0 }):Play()
	TweenService:Create(sub, fadeIn, { TextTransparency = 0 }):Play()

	task.delay(BANNER_SECONDS, function()
		local fadeOut = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(banner, fadeOut, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(sub, fadeOut, { TextTransparency = 1 }):Play()
		task.delay(0.6, function()
			banner:Destroy()
			sub:Destroy()
		end)
	end)
end

local toastScreen: ScreenGui? = nil
local toastLabel: TextLabel? = nil
local toastToken = 0

local function ensureToast(screen: ScreenGui): TextLabel
	local existing = toastLabel
	if existing then
		return existing
	end
	local label = makeLabel("Toast", UDim2.fromOffset(640, 70), UDim2.new(0.5, 0, 0.62, 0), 24, Color3.new(1, 1, 1))
	label.TextWrapped = true
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	label.BackgroundTransparency = 0.3
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = label
	label.Parent = screen
	toastLabel = label
	return label
end

-- A short message in the middle of the screen that fades after a moment.
function Hud.Toast(text: string)
	local screen = toastScreen
	if not screen then
		return
	end
	local label = ensureToast(screen)
	toastToken += 1
	local token = toastToken
	label.Text = text
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.4
	label.BackgroundTransparency = 0.3
	label.Visible = true
	task.delay(3, function()
		if token ~= toastToken then
			return
		end
		local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService
			:Create(label, fade, { TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1 })
			:Play()
		task.delay(0.5, function()
			if token == toastToken then
				label.Visible = false
			end
		end)
	end)
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

	local winsLabel =
		makeLabel("Wins", UDim2.fromOffset(400, 30), UDim2.new(0.5, 0, 0, 138), 20, Color3.fromRGB(255, 220, 90))
	winsLabel.Parent = screen

	local hint =
		makeLabel("Hint", UDim2.fromOffset(500, 30), UDim2.new(0.5, 0, 1, -60), 20, Color3.fromRGB(220, 220, 220))
	hint.Text = "Click or tap anywhere to breathe fire"
	hint.Parent = screen

	screen.Parent = playerGui
	toastScreen = screen

	local function updateFire(value: number)
		fireLabel.Text = `{Format.Short(value)} Fire`
	end

	local function updateWins(value: number)
		winsLabel.Text = `Wins: {value}  (x{Config.WinMultiplier(value)} Fire)`
	end

	local function updateClickInfo()
		local perClick = numberAttribute("FirePerClick", Config.BaseFirePerClick)
		local zoneMultiplier = numberAttribute("ZoneMultiplier", 1)
		local winMultiplier = numberAttribute("WinMultiplier", 1)
		local clickValue = math.floor(perClick * zoneMultiplier * winMultiplier)
		perClickLabel.Text = `+{Format.Short(clickValue)} per click`

		local zoneName = localPlayer:GetAttribute("ZoneName")
		if typeof(zoneName) == "string" and zoneName ~= "" then
			zoneLabel.Text = `{zoneName}  x{zoneMultiplier}`
		else
			zoneLabel.Text = ""
		end

		if localPlayer:GetAttribute("Flying") == true then
			hint.Text = "Flying!  Fly where the camera looks.  Space to climb"
			hint.TextColor3 = Color3.fromRGB(150, 210, 255)
		elseif localPlayer:GetAttribute("Training") == true then
			local perSecond = clickValue * Config.TrainingClicksPerTick / Config.TrainingTick
			hint.Text = `Training!  +{Format.Short(perSecond)} Fire per second.  Space to leave`
			hint.TextColor3 = Color3.fromRGB(255, 170, 40)
		else
			hint.Text = "Click or tap anywhere to breathe fire.  Space to fly"
			hint.TextColor3 = Color3.fromRGB(220, 220, 220)
		end
	end

	updateFire(0)
	updateWins(0)
	updateClickInfo()
	for _, name in { "FirePerClick", "ZoneMultiplier", "ZoneName", "WinMultiplier", "Training", "Flying" } do
		localPlayer:GetAttributeChangedSignal(name):Connect(updateClickInfo)
	end
	watchStat("Fire", updateFire)
	watchStat("Wins", updateWins)

	-- Waiting for the remote must not block the rest of client startup.
	task.spawn(function()
		Remotes.Won().OnClientEvent:Connect(function(wins: unknown)
			showWinBanner(screen, if typeof(wins) == "number" then wins else 0)
		end)
	end)
end

return Hud
