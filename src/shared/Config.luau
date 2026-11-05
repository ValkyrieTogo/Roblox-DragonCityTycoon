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

-- Wins. Touching the win pad at the end of the last zone, with enough Fire for
-- that zone, awards a Win, resets Fire and upgrades, and respawns the player.
-- Every Win permanently multiplies all Fire gained.
Config.WinMultiplierPerWin = 0.5 -- +50% per win
Config.WinCooldownSeconds = 3

function Config.WinMultiplier(wins: number): number
	return 1 + math.max(wins, 0) * Config.WinMultiplierPerWin
end

-- Upgrades bought with Fire. Each level adds PerLevel to Fire per click.
-- Cost for the next level is BaseCost * CostGrowth ^ currentLevel.
export type Upgrade = {
	Id: string,
	Name: string,
	Description: string,
	PerLevel: number,
	BaseCost: number,
	CostGrowth: number,
	MaxLevel: number,
}

Config.Upgrades = {
	{
		Id = "Breath",
		Name = "Dragon Breath",
		Description = "+1 Fire per click",
		PerLevel = 1,
		BaseCost = 25,
		CostGrowth = 1.3,
		MaxLevel = 200,
	},
	{
		Id = "Fangs",
		Name = "Fangs",
		Description = "+5 Fire per click",
		PerLevel = 5,
		BaseCost = 600,
		CostGrowth = 1.45,
		MaxLevel = 100,
	},
	{
		Id = "Inferno",
		Name = "Inferno",
		Description = "+25 Fire per click",
		PerLevel = 25,
		BaseCost = 8000,
		CostGrowth = 1.6,
		MaxLevel = 50,
	},
} :: { Upgrade }

function Config.GetUpgrade(id: string): Upgrade?
	for _, upgrade in Config.Upgrades do
		if upgrade.Id == id then
			return upgrade
		end
	end
	return nil
end

function Config.UpgradeCost(upgrade: Upgrade, currentLevel: number): number
	return math.floor(upgrade.BaseCost * upgrade.CostGrowth ^ currentLevel)
end

-- Name of the player attribute that holds an upgrade's level.
function Config.UpgradeAttribute(id: string): string
	return `Upgrade_{id}`
end

return Config
