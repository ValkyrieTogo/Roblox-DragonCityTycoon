--!strict
-- Wins: the prestige loop. Touching a part tagged "WinPad" while legitimately
-- in the last zone awards a Win, resets Fire and upgrades, respawns the player
-- at the start, and raises their permanent multiplier. The zone check is what
-- stops an exploiter who teleports to the pad: ZoneService only reports the
-- last zone's multiplier when they have its RequiredFire.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatService = require(script.Parent.StatService)
local UpgradeService = require(script.Parent.UpgradeService)
local ZoneService = require(script.Parent.ZoneService)

local WinService = {}

local TAG = "WinPad"

local lastWinAt: { [Player]: number } = {}

local function canWin(player: Player): boolean
	local now = os.clock()
	local last = lastWinAt[player]
	if last and now - last < Config.WinCooldownSeconds then
		return false
	end

	local lastZoneIndex = #Config.Zones
	if ZoneService.GetZoneIndex(player) ~= lastZoneIndex then
		return false
	end
	return StatService.GetFire(player) >= Config.Zones[lastZoneIndex].RequiredFire
end

local function award(player: Player)
	lastWinAt[player] = os.clock()

	StatService.AddWin(player)
	StatService.SetFire(player, 0)
	UpgradeService.ResetAll(player)

	local wins = StatService.GetWins(player)
	print(`[WinService] {player.Name} won, now {wins} wins`)
	Remotes.Won():FireClient(player, wins)

	-- Respawn at the start of the map with scale 1. Deferred so it does not run
	-- inside the Touched handler of a part the character is standing on.
	task.defer(function()
		if player.Parent then
			player:LoadCharacter()
		end
	end)
end

local function onTouched(hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = if character then Players:GetPlayerFromCharacter(character) else nil
	if not player then
		return
	end
	if canWin(player) then
		award(player)
	end
end

local function watchPad(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Touched:Connect(onTouched)
	end
end

function WinService.Init()
	-- Create the remote now so clients never wait on it.
	Remotes.Won()
	for _, pad in CollectionService:GetTagged(TAG) do
		watchPad(pad)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(watchPad)

	Players.PlayerRemoving:Connect(function(player)
		lastWinAt[player] = nil
	end)
end

return WinService
