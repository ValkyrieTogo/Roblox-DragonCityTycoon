--!strict
-- Receives clicks from clients and turns them into Fire. The server cannot see
-- clicks itself, so this is the one place the client is trusted at all, and
-- only up to a fixed rate: a token bucket per player drops anything faster
-- than Config.MaxClicksPerSecond so an exploiter spamming the remote gains
-- nothing over a normal player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatService = require(script.Parent.StatService)
local ZoneService = require(script.Parent.ZoneService)

local ClickService = {}

type Bucket = { tokens: number, lastRefill: number }

local buckets: { [Player]: Bucket } = {}

local function takeToken(player: Player): boolean
	local now = os.clock()
	local max = Config.MaxClicksPerSecond

	local bucket = buckets[player]
	if not bucket then
		bucket = { tokens = max, lastRefill = now }
		buckets[player] = bucket
	end

	-- Refill at max tokens per second, capped at a one second burst.
	local refill = (now - bucket.lastRefill) * max
	bucket.tokens = math.min(bucket.tokens + refill, max)
	bucket.lastRefill = now

	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

-- What one click is worth for this player right now:
-- upgrades, times the training ground they stand in, times their wins.
function ClickService.GetClickValue(player: Player): number
	return math.floor(
		StatService.GetFirePerClick(player) * ZoneService.GetMultiplier(player) * StatService.GetWinMultiplier(player)
	)
end

local function onClick(player: Player)
	if not takeToken(player) then
		return
	end
	StatService.AddFire(player, ClickService.GetClickValue(player))
end

function ClickService.Init()
	Remotes.Click().OnServerEvent:Connect(onClick)
	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)
end

return ClickService
