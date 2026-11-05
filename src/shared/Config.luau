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

-- Zones, in order along the map. Each zone is a training ground: clicks made
-- inside it are worth Multiplier times more, but only once the player has
-- RequiredFire, which is also what melts the ice wall at its entrance.
-- Length is the placeholder floor length in studs, used only by DevMap.
export type Zone = {
	Name: string,
	Multiplier: number,
	RequiredFire: number,
	Length: number,
	Color: Color3,
}

Config.Zones = {
	{ Name = "Hatchery", Multiplier = 1, RequiredFire = 0, Length = 60, Color = Color3.fromRGB(96, 160, 72) },
	{ Name = "Campfire", Multiplier = 2, RequiredFire = 50, Length = 60, Color = Color3.fromRGB(130, 92, 60) },
	{ Name = "Lava Pit", Multiplier = 5, RequiredFire = 500, Length = 70, Color = Color3.fromRGB(70, 50, 48) },
	{ Name = "Volcano", Multiplier = 20, RequiredFire = 5000, Length = 80, Color = Color3.fromRGB(45, 35, 35) },
	{
		Name = "Dragon Throne",
		Multiplier = 50,
		RequiredFire = 50000,
		Length = 60,
		Color = Color3.fromRGB(190, 150, 60),
	},
} :: { Zone }

Config.ZoneWidth = 48
Config.IceWallHeight = 14

return Config
