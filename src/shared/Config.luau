--!strict
-- Shared game configuration. Readable from both server and client.
-- Tuning numbers live here so the game can be balanced without touching logic.

local Config = {}

Config.GameName = "Dragon City Tycoon"

-- Clicking
Config.BaseFirePerClick = 1
Config.MaxClicksPerSecond = 12 -- server ignores clicks above this rate

-- Dragon growth. Scale is 1 at zero Fire and grows with the log of Fire,
-- so early clicks show big changes and later ones taper off.
Config.DragonGrowthRate = 0.8
Config.MaxDragonScale = 8

function Config.DragonScale(fire: number): number
	local scale = 1 + Config.DragonGrowthRate * math.log10(1 + math.max(fire, 0))
	return math.clamp(scale, 1, Config.MaxDragonScale)
end

return Config
