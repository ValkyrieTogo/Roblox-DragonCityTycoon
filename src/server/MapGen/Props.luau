--!strict
-- Reusable scenery: trees, huts, eggs, fires, lava, bridges, statues, gold,
-- the throne, pillars, ice crystals and the win pad. Natural shapes (rocks,
-- lava, the volcano) are carved from terrain; built things are parts.
-- Positions are the point on the ground the prop stands on.

local CollectionService = game:GetService("CollectionService")

local Parts = require(script.Parent.Parts)
local Terrain = require(script.Parent.Terrain)

local Props = {}

local WOOD = Color3.fromRGB(112, 76, 44)
local DARK_WOOD = Color3.fromRGB(66, 44, 28)
local LEAF = Color3.fromRGB(78, 142, 62)
local PINE = Color3.fromRGB(40, 92, 54)
local STONE = Color3.fromRGB(98, 96, 100)
local DARK_STONE = Color3.fromRGB(55, 50, 52)
local STRAW = Color3.fromRGB(196, 158, 78)
local EGG = Color3.fromRGB(214, 212, 220)
local EGG_SPECK = Color3.fromRGB(128, 112, 140)
local LAVA = Color3.fromRGB(255, 120, 20)
local LAVA_LIGHT = Color3.fromRGB(255, 150, 50)
local IRON = Color3.fromRGB(60, 62, 70)
local GOLD = Color3.fromRGB(235, 190, 60)
local GOLD_DARK = Color3.fromRGB(190, 145, 40)
local ICE = Color3.fromRGB(170, 220, 255)
local CRIMSON = Color3.fromRGB(150, 30, 40)

local function yawToward(from: Vector3, to: Vector3): number
	return math.atan2(from.X - to.X, from.Z - to.Z)
end

-- Slight random tint so repeated props do not look identical.
local function vary(color: Color3, rng: Random, amount: number): Color3
	local t = rng:NextNumber(-amount, amount)
	return if t > 0 then color:Lerp(Color3.new(1, 1, 1), t) else color:Lerp(Color3.new(0, 0, 0), -t)
end

-- Vegetation and rocks ------------------------------------------------------

function Props.tree(parent: Instance, position: Vector3, rng: Random)
	local model = Parts.model(parent, "Tree")
	local lean = CFrame.Angles(rng:NextNumber(-0.06, 0.06), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.06, 0.06))
	local base = CFrame.new(position) * lean
	local trunkColor = vary(WOOD, rng, 0.12)

	local lower = rng:NextNumber(5, 7)
	local upper = rng:NextNumber(6, 9)
	Parts.cylinder(
		model,
		"Trunk",
		rng:NextNumber(1.3, 1.7),
		lower,
		base * CFrame.new(0, lower / 2, 0),
		trunkColor,
		Enum.Material.Wood
	)
	Parts.cylinder(
		model,
		"Trunk",
		rng:NextNumber(0.9, 1.1),
		upper,
		base * CFrame.new(0, lower + upper / 2 - 0.3, 0),
		trunkColor,
		Enum.Material.Wood
	)
	-- Root flare and two branches.
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		Parts.cylinder(
			model,
			"Root",
			0.6,
			2.4,
			base
				* CFrame.new(math.cos(a) * 1.2, 0.6, math.sin(a) * 1.2)
				* CFrame.Angles(math.cos(a) * 0.9, 0, -math.sin(a) * 0.9),
			trunkColor,
			Enum.Material.Wood
		)
	end
	for _ = 1, 2 do
		local a = rng:NextNumber(0, math.pi * 2)
		local h = lower + upper * rng:NextNumber(0.45, 0.8)
		Parts.cylinder(
			model,
			"Branch",
			0.5,
			4.5,
			base
				* CFrame.new(math.cos(a) * 1.6, h, math.sin(a) * 1.6)
				* CFrame.Angles(math.sin(a) * 0.9, 0, math.cos(a) * 0.9),
			trunkColor,
			Enum.Material.Wood
		)
	end

	local crownY = lower + upper + 1
	local crown = rng:NextNumber(11, 15)
	for i = 1, 6 do
		local offset = if i == 1
			then Vector3.zero
			else Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.5, 0.6), rng:NextNumber(-1, 1)) * crown * 0.32
		local d = if i == 1 then crown else crown * rng:NextNumber(0.55, 0.8)
		local leaf = Parts.ball(
			model,
			"Leaves",
			d,
			(base * CFrame.new(offset + Vector3.new(0, crownY + crown * 0.25, 0))).Position,
			vary(LEAF, rng, 0.14),
			Enum.Material.LeafyGrass
		)
		Parts.noCollide(leaf)
	end
end

function Props.pine(parent: Instance, position: Vector3, rng: Random)
	local model = Parts.model(parent, "Pine")
	local trunk = rng:NextNumber(4, 6)
	local color = vary(PINE, rng, 0.12)
	Parts.cylinder(
		model,
		"Trunk",
		0.9,
		trunk + 2,
		CFrame.new(position + Vector3.new(0, (trunk + 2) / 2, 0)),
		DARK_WOOD,
		Enum.Material.Wood
	)

	local height = rng:NextNumber(16, 24)
	local baseRadius = rng:NextNumber(5.5, 7.5)
	local layers = 9
	local step = height / layers
	for i = 0, layers - 1 do
		local t = i / layers
		local radius = baseRadius * (1 - t) * (1 + 0.08 * math.sin(i * 2.1))
		local tier = Parts.cylinder(
			model,
			"Tier",
			math.max(radius, 0.8),
			step * 1.3,
			CFrame.new(position + Vector3.new(0, trunk + i * step + step / 2, 0)),
			vary(color, rng, 0.05),
			Enum.Material.Grass
		)
		Parts.noCollide(tier)
	end
end

-- Terrain boulder cluster, half sunk into the ground.
function Props.rock(_parent: Instance, position: Vector3, size: number, rng: Random, material: Enum.Material?)
	Terrain.Boulder(position + Vector3.new(0, size * 0.15, 0), size, material or Enum.Material.Rock, rng)
end

function Props.egg(parent: Instance, position: Vector3, scale: number, rng: Random)
	local model = Parts.model(parent, "Egg")
	local size = Vector3.new(3, 4.2, 3) * scale
	local tilt = CFrame.Angles(rng:NextNumber(-0.14, 0.14), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.14, 0.14))
	local center = CFrame.new(position + Vector3.new(0, size.Y * 0.46, 0)) * tilt
	local shell = vary(EGG, rng, 0.08)
	Parts.egg(model, "Shell", size, center, shell, Enum.Material.Marble)

	-- Speckles pressed into the shell.
	local speckColor = vary(EGG_SPECK, rng, 0.1)
	for _ = 1, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		local v = rng:NextNumber(-0.35, 0.75) -- mostly on the upper half
		local dir = Vector3.new(math.cos(a) * math.sqrt(1 - v * v), v, math.sin(a) * math.sqrt(1 - v * v))
		local radial = Vector3.new(dir.X * size.X / 2, dir.Y * size.Y / 2, dir.Z * size.Z / 2)
		local d = rng:NextNumber(0.5, 1) * scale
		local speck = Parts.egg(
			model,
			"Speck",
			Vector3.new(d, d * 0.6, d),
			center * CFrame.new(radial * 0.96) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			speckColor,
			Enum.Material.Marble
		)
		Parts.noCollide(speck)
	end

	-- A nest of twigs around the base.
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local r = size.X * 0.55
		local twig = Parts.cylinder(
			model,
			"Twig",
			0.22 * scale,
			rng:NextNumber(2.5, 3.5) * scale,
			CFrame.new(position + Vector3.new(math.cos(a) * r, 0.25 * scale, math.sin(a) * r))
				* CFrame.Angles(0, -a + rng:NextNumber(-0.4, 0.4), math.rad(90 + rng:NextNumber(-15, 15))),
			vary(DARK_WOOD, rng, 0.15),
			Enum.Material.Wood
		)
		Parts.noCollide(twig)
	end
end

-- Buildings -----------------------------------------------------------------

-- A round plank hut with a thatched cone roof. Its door faces `faceToward`.
function Props.hut(parent: Instance, position: Vector3, faceToward: Vector3, rng: Random)
	local model = Parts.model(parent, "Hut")
	local radius = rng:NextNumber(6, 7.5)
	local wallHeight = rng:NextNumber(6.5, 8)
	local yaw = yawToward(position, faceToward)
	local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	local wood = vary(WOOD, rng, 0.1)

	Parts.disc(
		model,
		"Foundation",
		radius + 1.2,
		1,
		position + Vector3.new(0, 0.5, 0),
		STONE,
		Enum.Material.Cobblestone
	)

	-- Walls from vertical planks, leaving a gap for the door at the front (-Z).
	local planks = 20
	local doorPlanks = 2
	local plankWidth = 2 * math.pi * radius / planks + 0.15
	for i = 0, planks - 1 do
		local a = (i + 0.5) / planks * math.pi * 2
		-- Front is -Z in local space, which is angle pi here.
		local fromDoor = math.abs(((a - math.pi + math.pi) % (math.pi * 2)) - math.pi)
		if fromDoor < (doorPlanks / planks) * math.pi then
			continue
		end
		local plank = Parts.block(
			model,
			"Plank",
			Vector3.new(plankWidth, wallHeight, 0.5),
			base * CFrame.Angles(0, -a, 0) * CFrame.new(0, wallHeight / 2 + 1, -radius),
			vary(wood, rng, 0.08),
			Enum.Material.WoodPlanks
		)
		plank.Name = "Plank"
	end
	-- Rope bands holding the planks.
	for _, h in { 2.2, wallHeight - 1.2 } do
		local band = Parts.cylinder(
			model,
			"Band",
			radius + 0.35,
			0.35,
			CFrame.new(position + Vector3.new(0, 1 + h, 0)),
			DARK_WOOD,
			Enum.Material.Fabric
		)
		Parts.noCollide(band)
	end

	-- Door frame and door.
	local doorWidth = 3.2
	for _, x in { -doorWidth / 2 - 0.3, doorWidth / 2 + 0.3 } do
		Parts.block(
			model,
			"DoorPost",
			Vector3.new(0.6, wallHeight * 0.8, 0.8),
			base * CFrame.new(x, 1 + wallHeight * 0.4, -radius),
			DARK_WOOD,
			Enum.Material.Wood
		)
	end
	Parts.block(
		model,
		"DoorLintel",
		Vector3.new(doorWidth + 1.4, 0.6, 0.8),
		base * CFrame.new(0, 1 + wallHeight * 0.8 + 0.3, -radius),
		DARK_WOOD,
		Enum.Material.Wood
	)
	Parts.block(
		model,
		"Door",
		Vector3.new(doorWidth, wallHeight * 0.78, 0.4),
		base * CFrame.new(0, 1 + wallHeight * 0.39, -radius + 0.5),
		vary(DARK_WOOD, rng, 0.1),
		Enum.Material.WoodPlanks
	)

	-- A window on the side with a cross bar.
	local windowFrame = base * CFrame.Angles(0, math.rad(100), 0) * CFrame.new(0, 1 + wallHeight * 0.55, -radius - 0.1)
	Parts.block(
		model,
		"Window",
		Vector3.new(2.2, 2.2, 0.4),
		windowFrame,
		Color3.fromRGB(40, 36, 44),
		Enum.Material.Glass
	)
	Parts.block(model, "WindowBar", Vector3.new(2.4, 0.3, 0.5), windowFrame, DARK_WOOD, Enum.Material.Wood)
	Parts.block(model, "WindowBar", Vector3.new(0.3, 2.4, 0.5), windowFrame, DARK_WOOD, Enum.Material.Wood)

	-- Thatched cone roof from overlapping petals meeting at the apex.
	local eave = radius + 2.2
	local roofHeight = rng:NextNumber(5.5, 7)
	local roofBase = 1 + wallHeight - 0.4
	local apex = position + Vector3.new(0, roofBase + roofHeight, 0)
	local petals = 16
	local slope = math.sqrt(eave * eave + roofHeight * roofHeight)
	local chord = 2 * math.pi * eave / petals
	local thatch = vary(STRAW, rng, 0.08)
	for i = 0, petals - 1 do
		local a = i / petals * math.pi * 2
		local foot = position + Vector3.new(math.cos(a) * eave, roofBase, math.sin(a) * eave)
		local mid = (foot + apex) / 2
		local petal = Parts.block(
			model,
			"Thatch",
			Vector3.new(chord * 1.35, 0.6, slope + 1),
			CFrame.lookAt(mid, apex),
			vary(thatch, rng, 0.05),
			Enum.Material.Fabric
		)
		petal.Name = "Thatch"
	end
	Parts.ball(model, "Cap", 2, apex + Vector3.new(0, 0.2, 0), DARK_WOOD, Enum.Material.Wood)
	Parts.cylinder(model, "Finial", 0.3, 2.5, CFrame.new(apex + Vector3.new(0, 1.4, 0)), DARK_WOOD, Enum.Material.Wood)
end

-- Fire ----------------------------------------------------------------------

function Props.campfire(parent: Instance, position: Vector3, size: number, rng: Random)
	local model = Parts.model(parent, "Campfire")
	local ring = 7
	for i = 1, ring do
		local a = (i / ring) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local d = size * rng:NextNumber(0.45, 0.7)
		Parts.egg(
			model,
			"Stone",
			Vector3.new(d, d * 0.7, d * rng:NextNumber(0.8, 1.2)),
			CFrame.new(position + Vector3.new(math.cos(a) * size * 0.95, d * 0.25, math.sin(a) * size * 0.95))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			vary(STONE, rng, 0.12),
			Enum.Material.Rock
		)
	end
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2 + rng:NextNumber(0, 0.5)
		Parts.cylinder(
			model,
			"Log",
			size * 0.13,
			size * 1.3,
			CFrame.new(position + Vector3.new(0, size * 0.32, 0)) * CFrame.Angles(0, a, math.rad(62)),
			vary(DARK_WOOD, rng, 0.12),
			Enum.Material.Wood
		)
	end

	local core = Parts.block(
		model,
		"Flame",
		Vector3.new(size * 0.6, 1, size * 0.6),
		CFrame.new(position + Vector3.new(0, size * 0.5, 0)),
		LAVA
	)
	Parts.invisible(core)
	Parts.fire(core, size * 2.2, 12)
	Parts.light(core, LAVA_LIGHT, size * 8, 2)
end

function Props.torch(parent: Instance, position: Vector3, height: number?)
	local model = Parts.model(parent, "Torch")
	local h = height or 7
	Parts.cylinder(
		model,
		"Post",
		0.45,
		h,
		CFrame.new(position + Vector3.new(0, h / 2, 0)),
		DARK_WOOD,
		Enum.Material.Wood
	)
	Parts.cylinder(
		model,
		"Bowl",
		1.1,
		0.9,
		CFrame.new(position + Vector3.new(0, h + 0.4, 0)),
		IRON,
		Enum.Material.Metal
	)
	local core =
		Parts.block(model, "Flame", Vector3.new(1, 1, 1), CFrame.new(position + Vector3.new(0, h + 1.2, 0)), LAVA)
	Parts.invisible(core)
	Parts.fire(core, 4, 10)
	Parts.light(core, LAVA_LIGHT, 18, 1.5)
end

-- A tall stone pillar with a flame bowl on top.
function Props.pillar(parent: Instance, position: Vector3, height: number, color: Color3, material: Enum.Material)
	local model = Parts.model(parent, "Pillar")
	Parts.block(model, "Base", Vector3.new(7, 1.5, 7), CFrame.new(position + Vector3.new(0, 0.75, 0)), color, material)
	Parts.cylinder(
		model,
		"Shaft",
		2.4,
		height,
		CFrame.new(position + Vector3.new(0, height / 2 + 1.5, 0)),
		color,
		material
	)
	Parts.block(
		model,
		"Capital",
		Vector3.new(7, 1.5, 7),
		CFrame.new(position + Vector3.new(0, height + 2.25, 0)),
		color,
		material
	)
	local core =
		Parts.block(model, "Flame", Vector3.new(2, 1, 2), CFrame.new(position + Vector3.new(0, height + 3.5, 0)), LAVA)
	Parts.invisible(core)
	Parts.fire(core, 8, 12)
	Parts.light(core, LAVA_LIGHT, 30, 2)
end

-- Lava (terrain) --------------------------------------------------------------

-- A sunken pool of cracked lava with a glow above it.
function Props.lavaPool(parent: Instance, position: Vector3, radius: number)
	Terrain.Column(position + Vector3.new(0, -1, 0), 3, radius + 1, Enum.Material.Air)
	Terrain.Column(position + Vector3.new(0, -3.5, 0), 3, radius, Enum.Material.CrackedLava)
	local glow = Parts.block(
		parent,
		"LavaGlow",
		Vector3.new(radius, 1, radius),
		CFrame.new(position + Vector3.new(0, 1, 0)),
		LAVA
	)
	Parts.invisible(glow)
	Parts.light(glow, LAVA_LIGHT, radius * 3, 2)
	Parts.motes(glow, radius * 0.6, LAVA_LIGHT, 0.5)
end

-- A lava river along a polyline of ground points, cut into the floor.
function Props.lavaRiver(parent: Instance, points: { Vector3 }, width: number)
	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i + 1]
		local mid = (a + b) / 2
		local length = (b - a).Magnitude + width * 0.5
		Terrain.Block(
			CFrame.lookAt(mid + Vector3.new(0, -1, 0), b + Vector3.new(0, -1, 0)),
			Vector3.new(width + 2, 3, length),
			Enum.Material.Air
		)
		Terrain.Block(
			CFrame.lookAt(mid + Vector3.new(0, -3.5, 0), b + Vector3.new(0, -3.5, 0)),
			Vector3.new(width, 3, length),
			Enum.Material.CrackedLava
		)
		if i % 2 == 1 then
			local glow =
				Parts.block(parent, "LavaGlow", Vector3.new(1, 1, 1), CFrame.new(mid + Vector3.new(0, 1, 0)), LAVA)
			Parts.invisible(glow)
			Parts.light(glow, LAVA_LIGHT, width * 3, 1.5)
		end
	end
end

-- A glowing crack in the floor.
function Props.lavaCrack(parent: Instance, position: Vector3, length: number, yaw: number)
	local crack = Parts.block(
		parent,
		"Crack",
		Vector3.new(0.8, 0.5, length),
		CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, yaw, 0),
		LAVA,
		Enum.Material.Neon
	)
	Parts.noCollide(crack)
end

-- An iron bridge. `cframe` is the centre on the ground; the deck runs along its -Z.
function Props.bridge(parent: Instance, cframe: CFrame, length: number)
	local model = Parts.model(parent, "Bridge")
	local deckY = 1.6
	Parts.block(
		model,
		"Deck",
		Vector3.new(9, 0.8, length),
		cframe * CFrame.new(0, deckY, 0),
		IRON,
		Enum.Material.DiamondPlate
	)
	for _, side in { -1, 1 } do
		Parts.block(
			model,
			"Rail",
			Vector3.new(0.4, 0.4, length),
			cframe * CFrame.new(side * 4.3, deckY + 2.6, 0),
			IRON,
			Enum.Material.Metal
		)
		for _, z in { -length / 2 + 0.5, 0, length / 2 - 0.5 } do
			Parts.block(
				model,
				"Post",
				Vector3.new(0.5, 2.8, 0.5),
				cframe * CFrame.new(side * 4.3, deckY + 1.4, z),
				IRON,
				Enum.Material.Metal
			)
		end
	end
	local rampLength = 5
	Parts.wedge(
		model,
		"Ramp",
		Vector3.new(9, deckY + 0.4, rampLength),
		cframe * CFrame.new(0, (deckY + 0.4) / 2, length / 2 + rampLength / 2) * CFrame.Angles(0, math.pi, 0),
		IRON,
		Enum.Material.DiamondPlate
	)
	Parts.wedge(
		model,
		"Ramp",
		Vector3.new(9, deckY + 0.4, rampLength),
		cframe * CFrame.new(0, (deckY + 0.4) / 2, -length / 2 - rampLength / 2),
		IRON,
		Enum.Material.DiamondPlate
	)
end

-- A terrain mountain with a glowing crater and lava running down its sides.
function Props.volcano(parent: Instance, position: Vector3, radius: number, height: number, rng: Random)
	local tiers = 10
	local tierHeight = height / tiers
	for i = 0, tiers - 1 do
		local t = i / tiers
		local r = radius * (1 - t * 0.85) * (1 + rng:NextNumber(-0.04, 0.04))
		local material = if t < 0.5 then Enum.Material.Rock else Enum.Material.Basalt
		Terrain.Column(
			position + Vector3.new(rng:NextNumber(-2, 2), i * tierHeight + tierHeight / 2, rng:NextNumber(-2, 2)),
			tierHeight + 2,
			r,
			material
		)
	end
	-- Lumps around the foot so it does not look like a stack of discs.
	for _ = 1, 8 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = radius * rng:NextNumber(0.7, 1.05)
		Terrain.Ball(
			position + Vector3.new(math.cos(a) * d, rng:NextNumber(0, 4), math.sin(a) * d),
			rng:NextNumber(6, 12),
			Enum.Material.Rock
		)
	end

	local top = position + Vector3.new(0, height, 0)
	local craterRadius = radius * 0.18
	Terrain.Column(top + Vector3.new(0, -2, 0), 6, craterRadius + 2, Enum.Material.Air)
	Terrain.Column(top + Vector3.new(0, -6, 0), 4, craterRadius, Enum.Material.CrackedLava)

	-- Streams of lava down the slope, oriented boxes from the rim to the foot.
	local streams = 4
	for s = 1, streams do
		local a = (s / streams) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local rim = top + Vector3.new(math.cos(a) * craterRadius, -1, math.sin(a) * craterRadius)
		local foot = position + Vector3.new(math.cos(a) * radius * 0.95, 1, math.sin(a) * radius * 0.95)
		local mid = (rim + foot) / 2
		Terrain.Block(CFrame.lookAt(mid, foot), Vector3.new(5, 3, (foot - rim).Magnitude), Enum.Material.CrackedLava)
	end

	local core = Parts.block(
		parent,
		"CraterGlow",
		Vector3.new(craterRadius, 1, craterRadius),
		CFrame.new(top + Vector3.new(0, -3, 0)),
		LAVA
	)
	Parts.invisible(core)
	Parts.light(core, LAVA_LIGHT, radius * 3, 3)
	Parts.fire(core, craterRadius * 2.5, 25)
	Parts.motes(core, 25, LAVA_LIGHT, 0.9)
end

-- Statues and treasure --------------------------------------------------------

-- A blocky dragon statue. `cframe` is the ground centre; it faces its -Z.
function Props.dragonStatue(parent: Instance, cframe: CFrame, scale: number, color: Color3, material: Enum.Material)
	local model = Parts.model(parent, "DragonStatue")
	local s = scale
	Parts.disc(model, "Pedestal", 7 * s, 2 * s, cframe.Position + Vector3.new(0, s, 0), DARK_STONE, Enum.Material.Slate)
	local base = cframe * CFrame.new(0, 2 * s, 0)

	Parts.egg(model, "Body", Vector3.new(5, 4.5, 10) * s, base * CFrame.new(0, 4 * s, 0), color, material)
	Parts.cylinder(
		model,
		"Neck",
		1.4 * s,
		6 * s,
		base * CFrame.new(0, 7.5 * s, -4.5 * s) * CFrame.Angles(math.rad(-25), 0, 0),
		color,
		material
	)
	Parts.egg(model, "Head", Vector3.new(3, 2.6, 4.5) * s, base * CFrame.new(0, 10.5 * s, -6.8 * s), color, material)
	Parts.block(
		model,
		"HornL",
		Vector3.new(0.5, 2, 0.5) * s,
		base * CFrame.new(-1 * s, 12.3 * s, -6 * s) * CFrame.Angles(0, 0, math.rad(20)),
		color,
		material
	)
	Parts.block(
		model,
		"HornR",
		Vector3.new(0.5, 2, 0.5) * s,
		base * CFrame.new(1 * s, 12.3 * s, -6 * s) * CFrame.Angles(0, 0, math.rad(-20)),
		color,
		material
	)
	Parts.wedge(
		model,
		"WingL",
		Vector3.new(10, 0.6, 7) * s,
		base * CFrame.new(-6 * s, 7 * s, 0) * CFrame.Angles(0, 0, math.rad(35)),
		color,
		material
	)
	Parts.wedge(
		model,
		"WingR",
		Vector3.new(10, 0.6, 7) * s,
		base * CFrame.new(6 * s, 7 * s, 0) * CFrame.Angles(0, 0, math.rad(-35)),
		color,
		material
	)
	Parts.cylinder(
		model,
		"Tail",
		0.8 * s,
		8 * s,
		base * CFrame.new(0, 3.2 * s, 8.5 * s) * CFrame.Angles(math.rad(75), 0, 0),
		color,
		material
	)
	for _, x in { -1.6, 1.6 } do
		for _, z in { -3, 3 } do
			Parts.cylinder(model, "Leg", 0.8 * s, 2 * s, base * CFrame.new(x * s, 1 * s, z * s), color, material)
		end
	end
end

function Props.goldPile(parent: Instance, position: Vector3, radius: number, rng: Random)
	local model = Parts.model(parent, "GoldPile")
	local mound = Parts.egg(
		model,
		"Mound",
		Vector3.new(radius * 2, radius * 0.9, radius * 2),
		CFrame.new(position + Vector3.new(0, radius * 0.1, 0)),
		GOLD_DARK,
		Enum.Material.Metal
	)
	mound.Reflectance = 0.15
	Parts.light(mound, GOLD, radius * 3, 0.8)
	local coins = math.floor(radius * 1.8)
	for _ = 1, coins do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0, radius * 0.95)
		local size = rng:NextNumber(1.2, 2.6)
		local y = math.max(0, radius * 0.45 * (1 - d / radius))
		local coin = Parts.disc(
			model,
			"Coin",
			size / 2,
			0.35,
			position + Vector3.new(math.cos(a) * d, y + 0.3, math.sin(a) * d),
			vary(GOLD, rng, 0.08),
			Enum.Material.Metal
		)
		coin.CFrame = coin.CFrame * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5), 0)
		coin.Reflectance = 0.25
	end
	for _ = 1, math.floor(radius * 0.6) do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(radius * 0.3, radius * 1.1)
		local ingot = Parts.block(
			model,
			"Ingot",
			Vector3.new(3, 1, 1.6),
			CFrame.new(position + Vector3.new(math.cos(a) * d, 0.5, math.sin(a) * d))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			GOLD,
			Enum.Material.Metal
		)
		ingot.Reflectance = 0.3
	end
	for _ = 1, 3 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0, radius * 0.5)
		Parts.ball(
			model,
			"Gem",
			rng:NextNumber(1, 1.8),
			position + Vector3.new(math.cos(a) * d, radius * 0.4, math.sin(a) * d),
			Color3.fromRGB(200, 40, 60),
			Enum.Material.Glass
		)
	end
end

-- The dragon throne. `cframe` is the ground centre of the bottom step; it faces its -Z.
function Props.throne(parent: Instance, cframe: CFrame, scale: number?)
	local model = Parts.model(parent, "Throne")
	local steps = { Vector3.new(30, 2, 16), Vector3.new(24, 2, 12), Vector3.new(18, 2, 9) }
	local y = 0
	for i, size in steps do
		local step = Parts.block(
			model,
			"Step",
			size,
			cframe * CFrame.new(0, y + size.Y / 2, (i - 1) * 1.2),
			GOLD_DARK,
			Enum.Material.Metal
		)
		step.Reflectance = 0.1
		y += size.Y
	end
	local seatBase = cframe * CFrame.new(0, y, 2)
	Parts.block(model, "Seat", Vector3.new(9, 3.5, 7), seatBase * CFrame.new(0, 1.75, 0), GOLD, Enum.Material.Metal).Reflectance =
		0.2
	Parts.block(
		model,
		"Cushion",
		Vector3.new(7.5, 0.8, 5.5),
		seatBase * CFrame.new(0, 3.9, 0.3),
		CRIMSON,
		Enum.Material.Fabric
	)
	Parts.block(model, "Back", Vector3.new(9, 14, 2), seatBase * CFrame.new(0, 7, 4.5), GOLD, Enum.Material.Metal).Reflectance =
		0.2
	for _, x in { -3.5, 0, 3.5 } do
		Parts.wedge(
			model,
			"Spike",
			Vector3.new(2, 5, 2),
			seatBase * CFrame.new(x, 16.5, 4.5),
			GOLD,
			Enum.Material.Metal
		)
	end
	for _, x in { -5.2, 5.2 } do
		Parts.block(model, "Arm", Vector3.new(1.4, 2, 7), seatBase * CFrame.new(x, 4.5, 0), GOLD, Enum.Material.Metal)
		Parts.ball(model, "ArmOrb", 1.8, (seatBase * CFrame.new(x, 5.8, -3)).Position, CRIMSON, Enum.Material.Neon)
	end
	Props.torch(model, (cframe * CFrame.new(-17, 0, -4)).Position, 9)
	Props.torch(model, (cframe * CFrame.new(17, 0, -4)).Position, 9)
	if scale and scale ~= 1 then
		model.WorldPivot = cframe
		model:ScaleTo(scale)
	end
end

-- Ice -----------------------------------------------------------------------

-- A glassy ice spike: a tall tapered body with a tilted tip.
function Props.crystal(parent: Instance, position: Vector3, height: number, rng: Random)
	local model = Parts.model(parent, "Crystal")
	local w = rng:NextNumber(2.5, 4.5)
	local tilt = CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.2, 0.2))
	local base = CFrame.new(position) * tilt
	local body = Parts.block(
		model,
		"Body",
		Vector3.new(w, height * 0.7, w * rng:NextNumber(0.8, 1.2)),
		base * CFrame.new(0, height * 0.35, 0),
		ICE,
		Enum.Material.Glass
	)
	body.Transparency = 0.25
	body.Reflectance = 0.2
	local tip = Parts.wedge(
		model,
		"Tip",
		Vector3.new(w, height * 0.35, w),
		base * CFrame.new(0, height * 0.7 + height * 0.175, 0),
		ICE,
		Enum.Material.Glass
	)
	tip.Transparency = 0.25
	tip.Reflectance = 0.2
	Parts.noCollide(tip)
	return body
end

-- Win pad --------------------------------------------------------------------

function Props.winPad(parent: Instance, position: Vector3, radius: number)
	local model = Parts.model(parent, "WinPadModel")
	local ring =
		Parts.disc(model, "Ring", radius + 4, 0.4, position + Vector3.new(0, 0.2, 0), GOLD_DARK, Enum.Material.Metal)
	Parts.noCollide(ring)
	ring.Reflectance = 0.2
	local pad = Parts.disc(model, "WinPad", radius, 0.8, position + Vector3.new(0, 0.4, 0), GOLD, Enum.Material.Neon)
	CollectionService:AddTag(pad, "WinPad")
	Parts.light(pad, GOLD, radius * 4, 3)
	Parts.motes(pad, 20, Color3.fromRGB(255, 230, 120), 0.7)
	Parts.sign(pad, "VICTORY", 12, 300, GOLD)
	return pad
end

-- Training and NPCs --------------------------------------------------------

local SCORCH = Color3.fromRGB(28, 24, 22)
local BASALT = Color3.fromRGB(48, 44, 48)
local PAD_RADIUS = 5 -- before the dummy's scale
local PAD_DISTANCE = 9.5 -- pad centre in front of the dummy, before scale

-- A target players breathe fire on. Tier 1 is a straw-wrapped log on a
-- stump, tier 2 a carved basalt totem with a glowing dragon face, tier 3 the
-- same totem gilded. Tagged TrainingDummy; the server lights its Blaze while
-- someone trains on it.
function Props.trainingDummy(
	parent: Instance,
	position: Vector3,
	faceToward: Vector3,
	tier: number,
	rng: Random,
	scale: number?
): Model
	local model = Parts.model(parent, "TrainingDummy")
	local yaw = yawToward(position, faceToward)
	local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	local height = 7

	Parts.disc(
		model,
		"Mat",
		4.5,
		0.4,
		position + Vector3.new(0, 0.2, 0),
		if tier == 1 then vary(STONE, rng, 0.1) else DARK_STONE,
		if tier == 1 then Enum.Material.Cobblestone else Enum.Material.Slate
	)

	local body: BasePart
	local faceZ: number
	if tier == 1 then
		Parts.cylinder(
			model,
			"Stump",
			2.3,
			1.4,
			base * CFrame.new(0, 0.7, 0),
			vary(DARK_WOOD, rng, 0.1),
			Enum.Material.Wood
		)
		body = Parts.cylinder(
			model,
			"Log",
			1.25,
			height,
			base * CFrame.new(0, height / 2 + 1, 0) * CFrame.Angles(rng:NextNumber(-0.04, 0.04), 0, 0),
			vary(WOOD, rng, 0.12),
			Enum.Material.Wood
		)
		-- Straw bundle tied around the middle: the part that burns.
		Parts.egg(
			model,
			"Straw",
			Vector3.new(3.6, 3, 3.6),
			base * CFrame.new(0, height * 0.55 + 1, 0) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			vary(STRAW, rng, 0.1),
			Enum.Material.Fabric
		)
		for _, y in { height * 0.4 + 1, height * 0.7 + 1 } do
			Parts.cylinder(model, "Rope", 1.9, 0.35, base * CFrame.new(0, y, 0), DARK_WOOD, Enum.Material.Fabric)
		end
		-- Charred top where past breaths landed.
		Parts.cylinder(model, "Char", 1.3, 1.2, base * CFrame.new(0, height + 0.6, 0), SCORCH, Enum.Material.Slate)
		faceZ = -1.85
	else
		local color = if tier >= 3 then GOLD else BASALT
		local material = if tier >= 3 then Enum.Material.Metal else Enum.Material.Basalt
		Parts.block(
			model,
			"Plinth",
			Vector3.new(4.4, 1.6, 4.4),
			base * CFrame.new(0, 0.8, 0),
			DARK_STONE,
			Enum.Material.Slate
		)
		body = Parts.block(
			model,
			"Totem",
			Vector3.new(2.8, height, 2.8),
			base * CFrame.new(0, height / 2 + 1.6, 0),
			vary(color, rng, 0.08),
			material
		)
		for _, y in { 0.3, 0.6, 0.85 } do
			Parts.block(
				model,
				"Band",
				Vector3.new(3.1, 0.5, 3.1),
				base * CFrame.new(0, 1.6 + height * y, 0),
				if tier >= 3 then GOLD_DARK else DARK_STONE,
				material
			)
		end
		-- A carved dragon face toward the path: glowing eyes, a seam, a snout.
		for _, x in { -0.7, 0.7 } do
			local eye = Parts.block(
				model,
				"Eye",
				Vector3.new(0.5, 0.25, 0.3),
				base * CFrame.new(x, 1.6 + height * 0.78, -1.5),
				LAVA,
				Enum.Material.Neon
			)
			Parts.noCollide(eye)
		end
		local seam = Parts.block(
			model,
			"Seam",
			Vector3.new(0.4, height * 0.45, 0.3),
			base * CFrame.new(0, 1.6 + height * 0.3, -1.5),
			LAVA,
			Enum.Material.Neon
		)
		Parts.noCollide(seam)
		Parts.block(
			model,
			"Snout",
			Vector3.new(1.4, 0.9, 1),
			base * CFrame.new(0, 1.6 + height * 0.66, -1.8),
			vary(color, rng, 0.08),
			material
		)
		faceZ = -2.3
	end

	-- Scorch mark on the side players stand at.
	local scorch = Parts.block(
		model,
		"Scorch",
		Vector3.new(2, 2.4, 0.1),
		base * CFrame.new(0, height * 0.5 + 1, faceZ),
		SCORCH,
		Enum.Material.Slate
	)
	Parts.noCollide(scorch)

	-- The blaze lit while training, off until then.
	local core =
		Parts.block(model, "Blaze", Vector3.new(2.5, 2.5, 2.5), base * CFrame.new(0, height * 0.6 + 1, 0), LAVA)
	Parts.invisible(core)
	Parts.fire(core, 5, 12).Enabled = false
	Parts.light(core, LAVA_LIGHT, 20, 2).Enabled = false

	-- The training pad: a glowing ring on the ground in front of the dummy.
	-- Standing on it is what starts training. Its light joins the blaze.
	local padCenter = (base * CFrame.new(0, 0, -PAD_DISTANCE)).Position
	local pad = Parts.model(model, "TrainingPad")
	local glow = Parts.button(pad, "Pad", padCenter, PAD_RADIUS, LAVA)
	local padBlaze = Parts.block(pad, "Blaze", Vector3.new(1, 1, 1), CFrame.new(padCenter + Vector3.new(0, 2, 0)), LAVA)
	Parts.invisible(padBlaze)
	Parts.light(padBlaze, LAVA_LIGHT, PAD_RADIUS * 3, 2).Enabled = false
	Parts.sign(glow, "TRAIN", 4, 160, LAVA_LIGHT)

	model.PrimaryPart = body
	if scale and scale ~= 1 then
		model.WorldPivot = CFrame.new(position)
		model:ScaleTo(scale)
		local fire = core:FindFirstChildOfClass("Fire")
		if fire then
			fire.Size = 5 * scale
		end
	end
	CollectionService:AddTag(model, "TrainingDummy")
	return model
end

-- Where an NPC appears, facing `faceToward`. Invisible, tagged NpcSpawn with
-- attributes Role ("Trainer" or "Villager"), ZoneIndex and Seat (which
-- villager). NpcService builds the dragon there.
function Props.npcSpawn(
	parent: Instance,
	position: Vector3,
	faceToward: Vector3,
	role: string,
	zoneIndex: number,
	seat: number?
): Part
	local eye = position + Vector3.new(0, 1, 0)
	local look = Vector3.new(faceToward.X, eye.Y, faceToward.Z)
	local spawn = Parts.block(parent, "NpcSpawn", Vector3.new(2, 2, 2), CFrame.lookAt(eye, look), CRIMSON)
	Parts.invisible(spawn)
	spawn:SetAttribute("Role", role)
	spawn:SetAttribute("ZoneIndex", zoneIndex)
	spawn:SetAttribute("Seat", seat or 1)
	CollectionService:AddTag(spawn, "NpcSpawn")
	return spawn
end

return Props
