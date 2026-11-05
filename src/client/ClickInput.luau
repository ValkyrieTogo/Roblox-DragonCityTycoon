--!strict
-- Turns mouse clicks and screen taps into Click remotes. Plays the fire effect
-- at once, before the server replies, so clicking feels instant. The same rate
-- limit as the server is applied here so the effect never plays for a click
-- the server will drop.

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
	return numberAttribute("FirePerClick", Config.BaseFirePerClick) * numberAttribute("ZoneMultiplier", 1)
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

function ClickInput.Init()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- gameProcessed is true when the click landed on a GUI button.
		if gameProcessed then
			return
		end
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			onClick()
		end
	end)
end

return ClickInput
