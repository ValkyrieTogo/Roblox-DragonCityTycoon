--!strict
-- Owns every player's Fire and Wins. All changes go through here so the client
-- can never edit them. Both sit in leaderstats, which Roblox replicates
-- automatically, and FirePerClick and WinMultiplier are attributes on the
-- player for the same reason.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local StatService = {}

local function getStat(player: Player, name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	return leaderstats:FindFirstChild(name) :: IntValue?
end

local function setupPlayer(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local fire = Instance.new("IntValue")
	fire.Name = "Fire"
	fire.Value = 0
	fire.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	leaderstats.Parent = player
	player:SetAttribute("FirePerClick", Config.BaseFirePerClick)
	player:SetAttribute("WinMultiplier", Config.WinMultiplier(0))
end

-- Fire ---------------------------------------------------------------------

function StatService.GetFire(player: Player): number
	local fire = getStat(player, "Fire")
	return if fire then fire.Value else 0
end

function StatService.SetFire(player: Player, value: number)
	local fire = getStat(player, "Fire")
	if fire then
		fire.Value = math.max(math.floor(value), 0)
	end
end

function StatService.AddFire(player: Player, amount: number)
	assert(amount >= 0, "AddFire amount must not be negative")
	local fire = getStat(player, "Fire")
	if fire then
		fire.Value += math.floor(amount)
	end
end

-- Returns true and debits the amount if the player can afford it, otherwise false.
function StatService.TrySpendFire(player: Player, amount: number): boolean
	assert(amount >= 0, "TrySpendFire amount must not be negative")
	local fire = getStat(player, "Fire")
	if not fire or fire.Value < amount then
		return false
	end
	fire.Value -= math.floor(amount)
	return true
end

-- Calls back with the new Fire whenever it changes. Used by GrowthService.
function StatService.OnFireChanged(player: Player, callback: (number) -> ()): RBXScriptConnection?
	local fire = getStat(player, "Fire")
	if not fire then
		return nil
	end
	return fire.Changed:Connect(callback)
end

-- Fire per click -----------------------------------------------------------

function StatService.GetFirePerClick(player: Player): number
	local value = player:GetAttribute("FirePerClick")
	return if typeof(value) == "number" then value else Config.BaseFirePerClick
end

function StatService.SetFirePerClick(player: Player, amount: number)
	player:SetAttribute("FirePerClick", math.max(math.floor(amount), 1))
end

-- Wins ---------------------------------------------------------------------

function StatService.GetWins(player: Player): number
	local wins = getStat(player, "Wins")
	return if wins then wins.Value else 0
end

function StatService.SetWins(player: Player, value: number)
	local wins = getStat(player, "Wins")
	if wins then
		wins.Value = math.max(math.floor(value), 0)
		player:SetAttribute("WinMultiplier", Config.WinMultiplier(wins.Value))
	end
end

function StatService.AddWin(player: Player)
	StatService.SetWins(player, StatService.GetWins(player) + 1)
end

function StatService.GetWinMultiplier(player: Player): number
	local value = player:GetAttribute("WinMultiplier")
	return if typeof(value) == "number" then value else 1
end

function StatService.Init()
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return StatService
