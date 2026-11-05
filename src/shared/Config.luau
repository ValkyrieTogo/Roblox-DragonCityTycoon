--!strict
-- Shared game configuration. Readable from both server and client.
-- Tuning numbers live here so the game can be balanced without touching logic.

local Config = {}

Config.GameName = "Dragon City Tycoon"

-- Clicking
Config.BaseFirePerClick = 1
Config.MaxClicksPerSecond = 12 -- server ignores clicks above this rate

-- Growth. The player is the dragon: their whole character is scaled by this.
-- Scale is 1 at zero Fire and grows with the log of Fire, so early clicks show
-- big changes and later ones taper off toward the cap.
Config.DragonGrowthRate = 0.6
Config.MaxDragonScale = 5

function Config.DragonScale(fire: number): number
	local scale = 1 + Config.DragonGrowthRate * math.log10(1 + math.max(fire, 0))
	return math.clamp(scale, 1, Config.MaxDragonScale)
end

-- Movement at scale 1. Bigger dragons walk a little faster and jump higher.
Config.BaseWalkSpeed = 16
Config.BaseJumpHeight = 7.2
Config.BaseJumpPower = 50

-- Camera distance limits at scale 1, multiplied by the dragon's scale so a big
-- dragon does not fill the screen.
Config.CameraMinZoom = 8
Config.CameraMaxZoom = 80

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
	{ Name = "Hatchery", Multiplier = 1, RequiredFire = 0, Length = 150, Color = Color3.fromRGB(96, 160, 72) },
	{ Name = "Campfire", Multiplier = 2, RequiredFire = 50, Length = 180, Color = Color3.fromRGB(130, 92, 60) },
	{ Name = "Lava Pit", Multiplier = 5, RequiredFire = 500, Length = 200, Color = Color3.fromRGB(70, 50, 48) },
	{ Name = "Volcano", Multiplier = 20, RequiredFire = 5000, Length = 250, Color = Color3.fromRGB(45, 35, 35) },
	{
		Name = "Dragon Throne",
		Multiplier = 50,
		RequiredFire = 50000,
		Length = 180,
		Color = Color3.fromRGB(190, 150, 60),
	},
} :: { Zone }

Config.ZoneWidth = 120
Config.IceWallHeight = 28

return Config
