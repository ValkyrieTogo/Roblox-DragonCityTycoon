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
-- Growth happens in steps of this size. Rescaling a character causes a small
-- physics hitch, so it must not happen on every click.
Config.DragonScaleStep = 0.1
-- Shortest time between two rescales of the same character, in seconds.
Config.DragonScaleInterval = 1

function Config.DragonScale(fire: number): number
	local scale = 1 + Config.DragonGrowthRate * math.log10(1 + math.max(fire, 0))
	scale = math.floor(scale / Config.DragonScaleStep + 1e-6) * Config.DragonScaleStep
	return math.clamp(scale, 1, Config.MaxDragonScale)
end

-- Movement at scale 1. Bigger dragons walk a little faster and jump higher.
Config.BaseWalkSpeed = 16
Config.BaseJumpHeight = 7.2
Config.BaseJumpPower = 50

-- Camera distance limits at scale 1, multiplied by the dragon's scale so a big
-- dragon does not fill the screen.
Config.CameraMinZoom = 8
Config.CameraMaxZoom = 120

-- Zones, in order along the map. Each zone is a training ground: clicks made
-- inside it are worth Multiplier times more, but only once the player has
-- RequiredFire, which is also what melts the ice wall at its entrance.
-- Length is the floor length in studs, used by the code-built map.
export type Zone = {
	Name: string,
	Multiplier: number,
	RequiredFire: number,
	Length: number,
	Color: Color3,
}

Config.Zones = {
	{ Name = "Hatchery", Multiplier = 1, RequiredFire = 0, Length = 820, Color = Color3.fromRGB(96, 160, 72) },
	{ Name = "Campfire", Multiplier = 2, RequiredFire = 50, Length = 900, Color = Color3.fromRGB(125, 90, 58) },
	{ Name = "Lava Pit", Multiplier = 5, RequiredFire = 500, Length = 1060, Color = Color3.fromRGB(44, 38, 40) },
	{ Name = "Volcano", Multiplier = 20, RequiredFire = 5000, Length = 1240, Color = Color3.fromRGB(58, 48, 48) },
	{
		Name = "Dragon Throne",
		Multiplier = 50,
		RequiredFire = 50000,
		Length = 900,
		Color = Color3.fromRGB(205, 165, 75),
	},
} :: { Zone }

-- The arena is sized for many dragons at MaxDragonScale (about 25 studs tall).
Config.ZoneWidth = 560
Config.PathWidth = 60
Config.GateDoorWidth = 100
Config.IceWallHeight = 60

-- The hub town is its own floating island south of the arena. Players spawn
-- there and reach the arena through the gate portal.
Config.TownCenter = Vector3.new(0, 0, 480)
Config.TownRadius = 170
-- Seed for the code-built map so it is the same every server.
Config.MapSeed = 7
-- Hide the template Baseplate so the island appears to float.
Config.HideBaseplate = true

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

-- Training. Standing within TrainingRadius studs of a training dummy breathes
-- fire on it automatically: every TrainingTick seconds the player gains
-- TrainingClicksPerTick clicks' worth of Fire at their current click value.
-- Idle income, slower than clicking by hand, so clicking still matters.
Config.TrainingRadius = 20
Config.TrainingTick = 0.5
Config.TrainingClicksPerTick = 1

-- NPC dragons. A trainer stands at every training yard and hatchlings wander
-- the Hatchery. Each cycles through its lines; walking up and pressing the
-- prompt skips to the next one.
Config.NpcTurnRadius = 24
Config.NpcWalkSpeed = 8
Config.NpcLineSeconds = 7
Config.NpcBreathSeconds = 4

export type NpcSpeech = { Name: string, Lines: { string } }

Config.Trainers = {
	["Hatchery"] = {
		Name = "Ember",
		Lines = {
			"Welcome, hatchling! Click to breathe fire.",
			"Stand by my logs and you breathe on your own.",
			"Training is slow but it never sleeps.",
			"Spend Fire on Dragon Breath. Every click counts.",
		},
	},
	["Campfire"] = {
		Name = "Ash",
		Lines = {
			"Everything you breathe here is worth double.",
			"Rest by the fire. Or better, train by it.",
			"The ice ahead melts at 500 Fire.",
		},
	},
	["Lava Pit"] = {
		Name = "Cinder",
		Lines = {
			"Mind the rivers. Lava is not for swimming.",
			"Five times the Fire for every breath here.",
			"My totems have taken worse than you.",
		},
	},
	["Volcano"] = {
		Name = "Magma",
		Lines = {
			"Twenty times! Feel the mountain in your chest.",
			"The throne needs 50K Fire. Keep breathing.",
			"Bigger dragons breathe bigger. Grow.",
		},
	},
	["Dragon Throne"] = {
		Name = "Aurum",
		Lines = {
			"Fifty times the Fire. You have earned it.",
			"Touch the pad with enough Fire to claim a Win.",
			"Every Win makes all your Fire burn hotter.",
		},
	},
} :: { [string]: NpcSpeech }

-- Townsfolk keyed by the Speech attribute of their spawn.
Config.Townsfolk = {
	["Gacha"] = {
		Name = "Mina",
		Lines = {
			"Eggs from every zone! Hatching opens soon.",
			"A pet dragon will follow you and share its Fire.",
			"The rarer the egg, the hotter the hatchling.",
		},
	},
	["SkillShop"] = {
		Name = "Orrin",
		Lines = {
			"Breath, Fangs, Inferno. Browse at the counter.",
			"Every level adds to each breath. Buy early, buy often.",
			"Your upgrades reset on a Win, but the Win is forever.",
		},
	},
	["Inn"] = {
		Name = "Tansy",
		Lines = {
			"Welcome to the Ember Inn! Mind the chimney.",
			"The arena is through the north gate.",
			"Big dragons get a bigger room. That is the rule.",
		},
	},
	["Market"] = {
		Name = "Bram",
		Lines = {
			"Fresh fruit, fresh gems, fresh bread!",
			"Heard the throne pays fifty times.",
			"Everything half price. Tomorrow.",
		},
	},
	["Market2"] = {
		Name = "Wren",
		Lines = {
			"Have you seen the fountain eggs glow?",
			"Portals tickle my scales.",
			"Try the training pen before the arena.",
		},
	},
} :: { [string]: NpcSpeech }

Config.Walkers = {
	{ Name = "Bram", Lines = { "Fine day on the island.", "Heard the throne pays fifty times." } },
	{ Name = "Lio", Lines = { "I train at the pen every morning.", "The lava pit is too hot for me." } },
	{ Name = "Wren", Lines = { "Have you seen the fountain eggs glow?", "Portals tickle my scales." } },
	{ Name = "Dax", Lines = { "I almost reached the volcano once.", "Keep clicking, friend." } },
} :: { NpcSpeech }

-- Townsfolk keyed by the Speech attribute of their spawn.
Config.Townsfolk = {
	["Gacha"] = {
		Name = "Mina",
		Lines = {
			"Eggs from every zone! Hatching opens soon.",
			"A pet dragon will follow you and share its Fire.",
			"The rarer the egg, the hotter the hatchling.",
		},
	},
	["SkillShop"] = {
		Name = "Orrin",
		Lines = {
			"Breath, Fangs, Inferno. Browse at the counter.",
			"Every level adds to each breath. Buy early, buy often.",
			"Your upgrades reset on a Win, but the Win is forever.",
		},
	},
	["Inn"] = {
		Name = "Tansy",
		Lines = {
			"Welcome to the Ember Inn! Mind the chimney.",
			"The arena is through the north gate.",
			"Big dragons get a bigger room. That is the rule.",
		},
	},
	["Market"] = {
		Name = "Bram",
		Lines = {
			"Fresh fruit, fresh gems, fresh bread!",
			"Heard the throne pays fifty times.",
			"Everything half price. Tomorrow.",
		},
	},
	["Market2"] = {
		Name = "Wren",
		Lines = {
			"Have you seen the fountain eggs glow?",
			"Portals tickle my scales.",
			"Try the training pen before the arena.",
		},
	},
} :: { [string]: NpcSpeech }

Config.Walkers = {
	{ Name = "Bram", Lines = { "Fine day on the island.", "Heard the throne pays fifty times." } },
	{ Name = "Lio", Lines = { "I train at the pen every morning.", "The lava pit is too hot for me." } },
	{ Name = "Wren", Lines = { "Have you seen the fountain eggs glow?", "Portals tickle my scales." } },
	{ Name = "Dax", Lines = { "I almost reached the volcano once.", "Keep clicking, friend." } },
} :: { NpcSpeech }

Config.Villagers = {
	{ Name = "Pip", Lines = { "I hatched yesterday!", "Can you breathe fire yet?", "Ember says click a lot." } },
	{ Name = "Sprout", Lines = { "I like the eggs. They are warm.", "Someday I will see the volcano." } },
	{ Name = "Nibble", Lines = { "The ice wall is cold. Melt it!", "Race you to the campfire!" } },
} :: { NpcSpeech }

return Config
