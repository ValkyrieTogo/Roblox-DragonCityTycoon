--!strict
-- Owns every player's Fire. All changes go through here so the client can never
-- edit it. Fire sits in leaderstats, which Roblox replicates automatically, and
-- FirePerClick is an attribute on the player for the same reason.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local StatService = {}

local function getFireValue(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end
	return leaderstats:FindFirstChild("Fire") :: IntValue?
end

local function setupPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local fire = Instance.new("IntValue")
	fire.Name = "Fire"
	fire.Value = 0
	fire.Parent = leaderstats

	leaderstats.Parent = player
	player:SetAttribute("FirePerClick", Config.BaseFirePerClick)
end

function StatService.GetFire(player: Player): number
	local fire = getFireValue(player)
	return if fire then fire.Value else 0
end

function StatService.AddFire(player: Player, amount: number)
	assert(amount >= 0, "AddFire amount must not be negative")
	local fire = getFireValue(player)
	if fire then
		fire.Value += math.floor(amount)
	end
end

-- Returns true and debits the amount if the player can afford it, otherwise false.
function StatService.TrySpendFire(player: Player, amount: number): boolean
	assert(amount >= 0, "TrySpendFire amount must not be negative")
	local fire = getFireValue(player)
	if not fire or fire.Value < amount then
		return false
	end
	fire.Value -= math.floor(amount)
	return true
end

function StatService.GetFirePerClick(player: Player): number
	local value = player:GetAttribute("FirePerClick")
	return if typeof(value) == "number" then value else Config.BaseFirePerClick
end

function StatService.SetFirePerClick(player: Player, amount: number)
	player:SetAttribute("FirePerClick", math.max(math.floor(amount), 1))
end

-- Calls back with the new Fire whenever it changes. Used by GrowthService.
function StatService.OnFireChanged(player: Player, callback: (number) -> ()): RBXScriptConnection?
	local fire = getFireValue(player)
	if not fire then
		return nil
	end
	return fire.Changed:Connect(callback)
end

function StatService.Init()
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return StatService
