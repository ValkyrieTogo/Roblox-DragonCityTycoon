--!strict
-- Server entry point. Runs once when the server starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

print(`[{Config.GameName}] server started`)

Players.PlayerAdded:Connect(function(player: Player)
	print(`{player.Name} joined`)
end)
