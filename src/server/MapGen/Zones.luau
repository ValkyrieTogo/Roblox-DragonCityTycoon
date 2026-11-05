--!strict
-- Dresses each arena zone with scenery that matches the concept art:
-- Hatchery village, Campfire ring, Lava Pit, Volcano and the Dragon Throne.
-- Each decorator gets a Region describing the zone's slab and places props on
-- it, keeping the centre path clear so players can always walk through.
-- Layouts were drawn for a 220-stud-wide zone; positions and counts scale
-- with the real width so a huge arena is still full.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Parts = require(script.Parent.Parts)
local Props = require(script.Parent.Props)

export type Region = {
	Index: number,
	Zone: Config.Zone,
	Width: number,
	Length: number,
	StartZ: number, -- entrance edge (larger Z)
	EndZ: number, -- far edge (smaller Z)
	CenterZ: number,
	Top: number, -- Y of the walkable floor surface
	Rng: Random,
	Parent: Folder,
}

local Zones = {}

local BASE_WIDTH = 220
local PATH_HALF = Config.PathWidth / 2
local EDGE_MARGIN = 24
local END_MARGIN = 40

local ASH_ROCK = Color3.fromRGB(70, 62, 62)
local EMBER = Color3.fromRGB(255, 150, 50)
local GOLD = Color3.fromRGB(235, 190, 60)
local THRONE_STONE = Color3.fromRGB(150, 122, 70)

-- Terrain materials per zone name: the ground and the centre path.
Zones.FloorMaterial = {
	["Hatchery"] = Enum.Material.LeafyGrass, -- Grass grows tall blades with Decoration on; LeafyGrass stays flat
	["Campfire"] = Enum.Material.Ground,
	["Lava Pit"] = Enum.Material.Basalt,
	["Volcano"] = Enum.Material.Slate,
	["Dragon Throne"] = Enum.Material.Sandstone,
} :: { [string]: Enum.Material }

Zones.PathMaterial = {
	["Hatchery"] = Enum.Material.Pavement,
	["Campfire"] = Enum.Material.Pavement,
	["Lava Pit"] = Enum.Material.Slate,
	["Volcano"] = Enum.Material.Basalt,
	["Dragon Throne"] = Enum.Material.Limestone,
} :: { [string]: Enum.Material }

local function ground(r: Region, x: number, z: number): Vector3
	return Vector3.new(x, r.Top, z)
end

-- Z at a fraction of the way through the zone (0 = entrance, 1 = far end).
local function along(r: Region, fraction: number): number
	return r.StartZ - r.Length * fraction
end

-- How much wider this zone is than the layouts were drawn for.
local function scale(r: Region): number
	return r.Width / BASE_WIDTH
end

-- A layout offset scaled to the zone's real size.
local function s(r: Region, value: number): number
	return value * scale(r)
end

-- A prop count scaled with the zone's size.
local function count(r: Region, n: number): number
	return math.round(n * scale(r) * 1.6)
end

-- Ground rectangles ({minX, maxX, minZ, maxZ}) that random scatter must avoid,
-- such as the training yard. Reset for every zone.
local reserved: { { number } } = {}

local function reserve(x1: number, x2: number, z1: number, z2: number)
	table.insert(reserved, { math.min(x1, x2), math.max(x1, x2), math.min(z1, z2), math.max(z1, z2) })
end

local function isReserved(x: number, z: number): boolean
	for _, rect in reserved do
		if x >= rect[1] and x <= rect[2] and z >= rect[3] and z <= rect[4] then
			return true
		end
	end
	return false
end

-- Random ground point off the centre path, away from the edges, ends and
-- reserved areas.
local function scatterPoint(r: Region, keepClear: number?): Vector3
	local half = r.Width / 2 - EDGE_MARGIN
	local clear = keepClear or PATH_HALF
	local x, z = 0, 0
	for _ = 1, 40 do
		x = r.Rng:NextNumber(-half, half)
		z = r.Rng:NextNumber(r.EndZ + END_MARGIN, r.StartZ - END_MARGIN)
		if math.abs(x) > clear and not isReserved(x, z) then
			break
		end
	end
	return ground(r, x, z)
end

-- Random ground point near one of the long edges.
local function edgePoint(r: Region): Vector3
	local x, z = 0, 0
	for _ = 1, 40 do
		local side = if r.Rng:NextNumber() < 0.5 then -1 else 1
		x = side * (r.Width / 2 - r.Rng:NextNumber(EDGE_MARGIN, EDGE_MARGIN + 30))
		z = r.Rng:NextNumber(r.EndZ + END_MARGIN, r.StartZ - END_MARGIN)
		if not isReserved(x, z) then
			break
		end
	end
	return ground(r, x, z)
end

-- A row of training dummies beside the path, torches at both ends, a sign on
-- the path side and the zone's trainer at the head of the row.
local function trainingYard(r: Region, side: number, fraction: number, count_: number)
	local f = r.Parent
	local x = side * (PATH_HALF + 20)
	local spacing = 12
	local headZ = along(r, fraction)
	local tailZ = headZ - (count_ - 1) * spacing
	local tier = if r.Index <= 2 then 1 elseif r.Index <= 4 then 2 else 3

	for i = 0, count_ - 1 do
		local z = headZ - i * spacing
		Props.trainingDummy(f, ground(r, x, z), ground(r, 0, z), tier, r.Rng)
	end
	Props.torch(f, ground(r, x + side * 7, headZ + 9), 7)
	Props.torch(f, ground(r, x + side * 7, tailZ - 9), 7)

	local post = Parts.block(
		f,
		"YardSign",
		Vector3.new(0.8, 6, 0.8),
		CFrame.new(ground(r, side * (PATH_HALF + 5), headZ + 10) + Vector3.new(0, 3, 0)),
		Color3.fromRGB(66, 44, 28),
		Enum.Material.Wood
	)
	Parts.sign(post, "Training Yard\nStand by a dummy to breathe on it", 5, 240)

	Props.npcSpawn(f, ground(r, x + side * 9, headZ + 15), ground(r, x, headZ - spacing), "Trainer", r.Index)
	reserve(side * (PATH_HALF + 2), x + side * 20, headZ + 24, tailZ - 16)
end

local decorators: { [string]: (Region) -> () } = {}

-- Hatchery: a grassy village of huts, stone eggs, trees, a welcome fire, the
-- first training yard and a few hatchlings wandering about.
decorators["Hatchery"] = function(r)
	local f = r.Parent
	trainingYard(r, -1, 0.3, 6)
	Props.campfire(f, ground(r, s(r, 24), along(r, 0.14)), 3, r.Rng)
	for seat = 1, #Config.Villagers do
		local p = scatterPoint(r, PATH_HALF + 6)
		Props.npcSpawn(f, p, ground(r, 0, p.Z), "Villager", r.Index, seat)
	end

	local huts = {
		{ -64, 0.16 },
		{ 68, 0.24 },
		{ -84, 0.4 },
		{ 80, 0.5 },
		{ -60, 0.66 },
		{ 72, 0.78 },
		{ -78, 0.9 },
		{ 40, 0.08 },
		{ -40, 0.52 },
		{ 44, 0.64 },
		{ 92, 0.88 },
		{ -96, 0.24 },
	}
	for _, spot in huts do
		local pos = ground(r, s(r, spot[1]), along(r, spot[2]))
		Props.hut(f, pos, ground(r, 0, pos.Z), r.Rng)
		for _ = 1, 2 do
			local a = r.Rng:NextNumber(0, math.pi * 2)
			local d = r.Rng:NextNumber(9, 13)
			Props.egg(f, pos + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d), r.Rng:NextNumber(0.7, 1.1), r.Rng)
		end
	end

	for _ = 1, count(r, 12) do
		Props.egg(f, scatterPoint(r, PATH_HALF + 4), r.Rng:NextNumber(0.8, 1.7), r.Rng)
	end
	for _ = 1, count(r, 18) do
		Props.tree(f, edgePoint(r), r.Rng)
	end
	for _ = 1, count(r, 8) do
		Props.tree(f, scatterPoint(r, PATH_HALF + 10), r.Rng)
	end
	for _ = 1, count(r, 10) do
		Props.rock(f, scatterPoint(r, PATH_HALF + 6), r.Rng:NextNumber(4, 9), r.Rng)
	end
end

-- Campfire: a great fire ring on packed dirt, torches all around, pines at the edges.
decorators["Campfire"] = function(r)
	local f = r.Parent
	local cz = r.CenterZ
	local k = scale(r)
	trainingYard(r, 1, 0.12, 6)
	Props.campfire(f, ground(r, 0, cz), 6 * k ^ 0.6, r.Rng)

	local stones = 16
	local ringRadius = s(r, 40)
	for i = 1, stones do
		local a = (i / stones) * math.pi * 2
		local d = r.Rng:NextNumber(4.5, 6.5) * k ^ 0.6
		Parts.egg(
			f,
			"RingStone",
			Vector3.new(d, d * 0.55, d * r.Rng:NextNumber(0.8, 1.2)),
			CFrame.new(ground(r, math.cos(a) * ringRadius, cz + math.sin(a) * ringRadius) + Vector3.new(0, d * 0.18, 0))
				* CFrame.Angles(0, r.Rng:NextNumber(0, math.pi), 0),
			Color3.fromRGB(110, 105, 100),
			Enum.Material.Rock
		)
		if i % 2 == 0 then
			local tr = ringRadius - 6
			Props.torch(f, ground(r, math.cos(a + math.pi / stones) * tr, cz + math.sin(a + math.pi / stones) * tr))
		end
	end

	for _, spot in { { -58, -70 }, { 58, -70 }, { -58, 70 }, { 58, 70 } } do
		Props.campfire(f, ground(r, s(r, spot[1]), cz + s(r, spot[2])), 3, r.Rng)
	end
	Props.torch(f, ground(r, -PATH_HALF - 4, along(r, 0.08)))
	Props.torch(f, ground(r, PATH_HALF + 4, along(r, 0.08)))

	for _ = 1, count(r, 16) do
		Props.pine(f, edgePoint(r), r.Rng)
	end
	for _ = 1, count(r, 6) do
		Props.pine(f, scatterPoint(r, ringRadius + 20), r.Rng)
	end
	for _ = 1, count(r, 8) do
		Props.rock(f, scatterPoint(r, ringRadius + 10), r.Rng:NextNumber(4, 8), r.Rng)
	end
end

-- Lava Pit: black rock cut by lava rivers, crossed by iron bridges, glowing pools and cracks.
decorators["Lava Pit"] = function(r)
	local f = r.Parent
	local half = r.Width / 2
	local k = scale(r)
	trainingYard(r, -1, 0.42, 6)

	for _, pool in
		{ { -62, 0.2, 14 }, { 66, 0.42, 12 }, { -72, 0.72, 18 }, { 58, 0.88, 10 }, { 30, 0.08, 9 }, { -30, 0.55, 11 } }
	do
		Props.lavaPool(f, ground(r, s(r, pool[1]), along(r, pool[2])), pool[3] * k ^ 0.7)
	end

	local riverWidth = 11 * k ^ 0.7
	local bridgeLength = riverWidth * 1.6 + 10
	for _, fraction in { 0.33, 0.66 } do
		local z = along(r, fraction)
		local points = {}
		local x = -half + 4
		while x < half - 4 do
			-- Keep the river straight where the bridge crosses so the deck lines up.
			local jitter = if math.abs(x) < bridgeLength / 2 + 12 then 0 else r.Rng:NextNumber(-10, 10) * k
			table.insert(points, ground(r, x, z + jitter))
			x += 34
		end
		table.insert(points, ground(r, half - 4, z))
		Props.lavaRiver(f, points, riverWidth)
		Props.bridge(f, CFrame.new(ground(r, 0, z)), bridgeLength)
	end

	for _ = 1, count(r, 18) do
		local p = scatterPoint(r, PATH_HALF + 2)
		Props.lavaCrack(f, p, r.Rng:NextNumber(6, 16), r.Rng:NextNumber(0, math.pi))
	end
	for _ = 1, count(r, 12) do
		Props.rock(f, scatterPoint(r, PATH_HALF + 6), r.Rng:NextNumber(5, 11), r.Rng, Enum.Material.Basalt)
	end
	Parts.moteField(
		f,
		"Embers",
		Vector3.new(r.Width * 0.8, 2, r.Length * 0.9),
		ground(r, 0, r.CenterZ) + Vector3.new(0, 3, 0),
		14 * k,
		EMBER,
		0.45
	)
end

-- Volcano: a smoking mountain beside the path, guarded by stone dragons.
decorators["Volcano"] = function(r)
	local f = r.Parent
	local k = scale(r)
	local m = k ^ 0.65 -- mountains grow with the zone, a little less than it
	trainingYard(r, -1, 0.3, 6)
	Props.volcano(f, ground(r, s(r, 64), along(r, 0.55)), 48 * m, 66 * m, r.Rng)
	Props.volcano(f, ground(r, s(r, -78), along(r, 0.22)), 26 * m, 34 * m, r.Rng)
	Props.volcano(f, ground(r, s(r, 70), along(r, 0.9)), 22 * m, 30 * m, r.Rng)

	for _, x in { -26, 26 } do
		Props.dragonStatue(
			f,
			CFrame.new(ground(r, s(r, x), along(r, 0.1))) * CFrame.Angles(0, math.pi, 0),
			1.1 * m,
			ASH_ROCK,
			Enum.Material.Slate
		)
	end
	Props.dragonStatue(
		f,
		CFrame.new(ground(r, s(r, -70), along(r, 0.8))) * CFrame.Angles(0, math.rad(60), 0),
		1.4 * m,
		ASH_ROCK,
		Enum.Material.Slate
	)

	Props.lavaPool(f, ground(r, s(r, -54), along(r, 0.5)), 13 * m)
	Props.lavaPool(f, ground(r, s(r, -34), along(r, 0.92)), 10 * m)
	Props.lavaPool(f, ground(r, s(r, 40), along(r, 0.72)), 9 * m)
	for _ = 1, count(r, 10) do
		local p = scatterPoint(r, PATH_HALF + 2)
		Props.lavaCrack(f, p, r.Rng:NextNumber(6, 14), r.Rng:NextNumber(0, math.pi))
	end
	for _ = 1, count(r, 14) do
		Props.rock(f, scatterPoint(r, PATH_HALF + 6), r.Rng:NextNumber(5, 12), r.Rng, Enum.Material.Basalt)
	end
	Parts.moteField(
		f,
		"Embers",
		Vector3.new(r.Width * 0.8, 2, r.Length * 0.9),
		ground(r, 0, r.CenterZ) + Vector3.new(0, 3, 0),
		24 * k,
		EMBER,
		0.5
	)
end

-- Dragon Throne: a golden hall ending in a raised dais with the throne, a
-- golden dragon, hoards of gold, and the victory pad in front.
decorators["Dragon Throne"] = function(r)
	local f = r.Parent
	local half = r.Width / 2
	local k = scale(r)
	local m = k ^ 0.8 -- the throne and dais are built for the biggest dragons
	trainingYard(r, 1, 0.3, 5)

	local daisDepth = 72 * m
	local daisZ = r.EndZ + 40 + daisDepth / 2
	local daisHeight = 6 * m
	local daisTop = r.Top + daisHeight
	local rampDepth = 18 * m

	Parts.block(
		f,
		"Dais",
		Vector3.new(110 * m, daisHeight, daisDepth),
		CFrame.new(0, r.Top + daisHeight / 2, daisZ),
		THRONE_STONE,
		Enum.Material.Marble
	)
	-- Ramp up the front of the dais, rising toward -Z.
	Parts.wedge(
		f,
		"DaisRamp",
		Vector3.new(44 * m, daisHeight, rampDepth),
		CFrame.new(0, r.Top + daisHeight / 2, daisZ + daisDepth / 2 + rampDepth / 2),
		THRONE_STONE,
		Enum.Material.Marble
	)

	Props.throne(f, CFrame.new(0, daisTop, daisZ - 6 * m) * CFrame.Angles(0, math.pi, 0), m)
	Props.dragonStatue(f, CFrame.new(0, daisTop, daisZ - 24 * m), 1.9 * m, GOLD, Enum.Material.Metal)
	for _, x in { -40, 40 } do
		Props.goldPile(f, Vector3.new(x * m, daisTop, daisZ + 4 * m), 9 * m, r.Rng)
		Props.pillar(f, Vector3.new(x * m, daisTop, daisZ - 26 * m), 16 * m, THRONE_STONE, Enum.Material.Marble)
	end

	local padZ = daisZ + daisDepth / 2 + rampDepth + 40 * m
	Props.winPad(f, ground(r, 0, padZ), 11 * m)
	for _, x in { -26, 26 } do
		Props.pillar(f, ground(r, x * m, padZ), 14 * m, THRONE_STONE, Enum.Material.Marble)
	end

	for i = 0, 3 do
		local z = along(r, 0.12 + i * 0.16)
		for _, side in { -1, 1 } do
			Props.pillar(f, ground(r, side * (half - 34), z), 18 * m, THRONE_STONE, Enum.Material.Marble)
			Props.torch(f, ground(r, side * (PATH_HALF + 6), z + 20), 8)
		end
	end

	for _ = 1, count(r, 12) do
		Props.goldPile(f, scatterPoint(r, PATH_HALF + 14), r.Rng:NextNumber(5, 10), r.Rng)
	end
	Parts.moteField(
		f,
		"Sparkles",
		Vector3.new(r.Width * 0.7, 2, r.Length * 0.8),
		ground(r, 0, r.CenterZ) + Vector3.new(0, 4, 0),
		10 * k,
		Color3.fromRGB(255, 230, 140),
		0.4
	)
end

function Zones.Decorate(region: Region)
	reserved = {}
	local decorate = decorators[region.Zone.Name]
	if decorate then
		decorate(region)
	else
		warn(`[MapGen] No decorator for zone "{region.Zone.Name}"`)
	end
end

return Zones
