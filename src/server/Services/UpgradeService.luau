--!strict
-- Upgrades bought with Fire. Levels live as player attributes (replicated for
-- the shop UI) and the resulting Fire per click is pushed into StatService.
-- Only the server changes levels; the client just asks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatService = require(script.Parent.StatService)

local UpgradeService = {}

function UpgradeService.GetLevel(player: Player, id: string): number
	local value = player:GetAttribute(Config.UpgradeAttribute(id))
	return if typeof(value) == "number" then value else 0
end

local function setLevel(player: Player, id: string, level: number)
	player:SetAttribute(Config.UpgradeAttribute(id), level)
end

-- Base click value plus every upgrade's contribution.
local function recomputeFirePerClick(player: Player)
	local total = Config.BaseFirePerClick
	for _, upgrade in Config.Upgrades do
		total += UpgradeService.GetLevel(player, upgrade.Id) * upgrade.PerLevel
	end
	StatService.SetFirePerClick(player, total)
end

-- Returns all levels, for saving.
function UpgradeService.GetLevels(player: Player): { [string]: number }
	local levels = {}
	for _, upgrade in Config.Upgrades do
		levels[upgrade.Id] = UpgradeService.GetLevel(player, upgrade.Id)
	end
	return levels
end

-- Replaces all levels, for loading saved data and for resets.
function UpgradeService.SetLevels(player: Player, levels: { [string]: number })
	for _, upgrade in Config.Upgrades do
		local level = levels[upgrade.Id]
		if typeof(level) ~= "number" then
			level = 0
		end
		setLevel(player, upgrade.Id, math.clamp(math.floor(level), 0, upgrade.MaxLevel))
	end
	recomputeFirePerClick(player)
end

function UpgradeService.ResetAll(player: Player)
	UpgradeService.SetLevels(player, {})
end

-- Buys one level if the player can afford it. Returns true on success.
function UpgradeService.TryBuy(player: Player, id: string): boolean
	local upgrade = Config.GetUpgrade(id)
	if not upgrade then
		return false
	end

	local level = UpgradeService.GetLevel(player, id)
	if level >= upgrade.MaxLevel then
		return false
	end

	local cost = Config.UpgradeCost(upgrade, level)
	if not StatService.TrySpendFire(player, cost) then
		return false
	end

	setLevel(player, id, level + 1)
	recomputeFirePerClick(player)
	return true
end

local function onBuyRequest(player: Player, id: unknown)
	if typeof(id) ~= "string" then
		return
	end
	UpgradeService.TryBuy(player, id)
end

local function setupPlayer(player: Player)
	-- Start at zero; DataService replaces these once a save is loaded.
	if player:GetAttribute(Config.UpgradeAttribute(Config.Upgrades[1].Id)) == nil then
		UpgradeService.SetLevels(player, {})
	end
end

function UpgradeService.Init()
	Remotes.BuyUpgrade().OnServerEvent:Connect(onBuyRequest)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return UpgradeService
