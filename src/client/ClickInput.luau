--!strict
-- Turns mouse clicks and screen taps into Click remotes. Holding the button
-- or finger down keeps breathing at Config.HoldClicksPerSecond. Plays the
-- fire effect at once, before the server replies, so clicking feels instant.
-- The same rate limit as the server is applied here so the effect never
-- plays for a click the server will drop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FireEffects = require(script.Parent.FireEffects)

local ClickInput = {}

local localPlayer = Players.LocalPlayer

local tokens = Config.MaxClicksPerSecond
local lastRefill = os.clock()
local holding = false

local function takeToken(): boolean
	local now = os.clock()
	local max = Config.MaxClicksPerSecond
	tokens = math.min(tokens + (now - lastRefill) * max, max)
	lastRefill = now
	if tokens < 1 then
		return false
	end
	tokens -= 1
	return true
end

local function numberAttribute(name: string, default: number): number
	local value = localPlayer:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- Mirrors ClickService.GetClickValue so the popup matches what the server adds.
local function predictedClickValue(): number
	return math.floor(
		numberAttribute("FirePerClick", Config.BaseFirePerClick)
			* numberAttribute("ZoneMultiplier", 1)
			* numberAttribute("WinMultiplier", 1)
	)
end

local function onClick()
	if not takeToken() then
		return
	end

	Remotes.Click():FireServer()

	local character = localPlayer.Character
	if character then
		FireEffects.Burst(character, predictedClickValue())
	end
end

local function isBreathInput(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

-- Keeps breathing while the button stays down, after the first click.
local function holdLoop()
	local interval = 1 / Config.HoldClicksPerSecond
	task.wait(interval)
	while holding do
		onClick()
		task.wait(interval)
	end
end

function ClickInput.Init()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- gameProcessed is true when the click landed on a GUI button.
		if gameProcessed or not isBreathInput(input) then
			return
		end
		onClick()
		if not holding then
			holding = true
			task.spawn(holdLoop)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isBreathInput(input) then
			holding = false
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		holding = false
	end)
end

return ClickInput
