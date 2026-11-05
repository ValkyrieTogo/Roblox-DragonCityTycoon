--!strict
-- Owns every player's cash. All changes go through here so the client can never
-- edit money. Cash is exposed through leaderstats, which Roblox replicates
-- automatically, so the client needs no remotes to display it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CashService = {}

local function getCashValue(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	return leaderstats:FindFirstChild("Cash") :: IntValue?
end

local function setupPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = Config.StartingCash
	cash.Parent = leaderstats

	leaderstats.Parent = player
end

function CashService.GetCash(player: Player): number
	local cash = getCashValue(player)
	return if cash then cash.Value else 0
end

function CashService.AddCash(player: Player, amount: number)
	assert(amount >= 0, "AddCash amount must not be negative")
	local cash = getCashValue(player)
	if cash then
		cash.Value += math.floor(amount)
	end
end

-- Returns true and debits the amount if the player can afford it, otherwise false.
function CashService.TrySpend(player: Player, amount: number): boolean
	assert(amount >= 0, "TrySpend amount must not be negative")
	local cash = getCashValue(player)
	if not cash or cash.Value < amount then
		return false
	end
	cash.Value -= math.floor(amount)
	return true
end

function CashService.Init()
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return CashService
