--!strict
-- Client entry point. Runs once per player when they join.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CameraScale = require(script.Parent.CameraScale)
local ClickInput = require(script.Parent.ClickInput)
local FireEffects = require(script.Parent.FireEffects)
local Hud = require(script.Parent.Hud)
local IceWalls = require(script.Parent.IceWalls)
local Shop = require(script.Parent.Shop)
local Training = require(script.Parent.Training)

local localPlayer = Players.LocalPlayer

-- Other players' breaths: their Fire going up means they clicked, so play the
-- effect on their character. The local player's effect is played on input instead.
local function watchOtherPlayer(player: Player)
	if player == localPlayer then
		return
	end
	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 30)
		local fire = if leaderstats then leaderstats:WaitForChild("Fire", 30) else nil
		if not fire or not fire:IsA("IntValue") then
			return
		end
		local last = fire.Value
		fire.Changed:Connect(function(value)
			local gained = value - last
			last = value
			if gained > 0 and player.Character then
				FireEffects.Burst(player.Character, gained)
			end
		end)
	end)
end

print(`[{Config.GameName}] client starting`)

Hud.Init()
Shop.Init()
CameraScale.Init()
IceWalls.Init()
ClickInput.Init()
Training.Init()

Players.PlayerAdded:Connect(watchOtherPlayer)
for _, player in Players:GetPlayers() do
	watchOtherPlayer(player)
end
