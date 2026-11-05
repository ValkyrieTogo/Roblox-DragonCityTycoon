--!strict
-- Reusable scenery built from parts: trees, huts, eggs, fires, lava, bridges,
-- statues, gold, the throne, pillars, ice crystals and the win pad.
-- Positions are the point on the ground the prop stands on.

local CollectionService = game:GetService("CollectionService")

local Parts = require(script.Parent.Parts)

local Props = {}

local WOOD = Color3.fromRGB(105, 70, 40)
local DARK_WOOD = Color3.fromRGB(70, 48, 30)
local LEAF = Color3.fromRGB(70, 140, 60)
local PINE = Color3.fromRGB(38, 88, 50)
local STONE = Color3.fromRGB(95, 95, 100)
local DARK_STONE = Color3.fromRGB(55, 50, 52)
local STRAW = Color3.fromRGB(190, 150, 70)
local EGG = Color3.fromRGB(205, 205, 212)
local LAVA = Color3.fromRGB(255, 120, 20)
local LAVA_LIGHT = Color3.fromRGB(255, 150, 50)
local IRON = Color3.fromRGB(60, 62, 70)
local GOLD = Color3.fromRGB(235, 190, 60)
local GOLD_DARK = Color3.fromRGB(190, 145, 40)
local ICE = Color3.fromRGB(160, 215, 255)
local CRIMSON = Color3.fromRGB(150, 30, 40)

local function yawToward(from: Vector3, to: Vector3): number
	return math.atan2(from.X - to.X, from.Z - to.Z)
end

-- Vegetation and rocks ------------------------------------------------------

function Props.tree(parent: Instance, position: Vector3, rng: Random)
	local model = Parts.model(parent, "Tree")
	local height = rng:NextNumber(10, 15)
	local trunkRadius = rng:NextNumber(1, 1.5)
	Parts.cylinder(
		model,
		"Trunk",
		trunkRadius,
		height,
		CFrame.new(position + Vector3.new(0, height / 2, 0)),
		WOOD,
		Enum.Material.Wood
	)

	local crown = rng:NextNumber(10, 14)
	local top = position + Vector3.new(0, height + crown * 0.3, 0)
	Parts.ball(model, "Leaves", crown, top, LEAF, Enum.Material.Grass)
	Parts.ball(
		model,
		"Leaves",
		crown * 0.7,
		top + Vector3.new(crown * 0.35, -crown * 0.1, crown * 0.2),
		LEAF,
		Enum.Material.Grass
	)
	Parts.ball(
		model,
		"Leaves",
		crown * 0.65,
		top + Vector3.new(-crown * 0.3, crown * 0.05, -crown * 0.25),
		LEAF,
		Enum.Material.Grass
	)
end

function Props.pine(parent: Instance, position: Vector3, rng: Random)
	local model = Parts.model(parent, "Pine")
	local trunk = rng:NextNumber(5, 8)
	Parts.cylinder(
		model,
		"Trunk",
		1,
		trunk,
		CFrame.new(position + Vector3.new(0, trunk / 2, 0)),
		DARK_WOOD,
		Enum.Material.Wood
	)

	local tiers = 3
	local baseRadius = rng:NextNumber(5.5, 7.5)
	local tierHeight = rng:NextNumber(4.5, 6)
	for i = 0, tiers - 1 do
		local radius = baseRadius * (1 - i * 0.28)
		local y = trunk + i * tierHeight * 0.8 + tierHeight / 2
		Parts.cylinder(
			model,
			"Tier",
			radius,
			tierHeight,
			CFrame.new(position + Vector3.new(0, y, 0)),
			PINE,
			Enum.Material.Grass
		)
	end
end

function Props.rock(parent: Instance, position: Vector3, size: number, rng: Random, color: Color3?)
	local rock = Parts.egg(
		parent,
		"Rock",
		Vector3.new(size, size * rng:NextNumber(0.55, 0.8), size * rng:NextNumber(0.8, 1.1)),
		CFrame.new(position + Vector3.new(0, size * 0.22, 0))
			* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.15, 0.15)),
		color or STONE,
		Enum.Material.Slate
	)
	return rock
end

function Props.egg(parent: Instance, position: Vector3, scale: number, rng: Random)
	local size = Vector3.new(3, 4.1, 3) * scale
	local egg = Parts.egg(
		parent,
		"Egg",
		size,
		CFrame.new(position + Vector3.new(0, size.Y * 0.45, 0))
			* CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.12, 0.12)),
		EGG,
		Enum.Material.Marble
	)
	return egg
end

-- Buildings -----------------------------------------------------------------

-- A round hut with a straw roof. Its door faces `faceToward`.
function Props.hut(parent: Instance, position: Vector3, faceToward: Vector3, rng: Random)
	local model = Parts.model(parent, "Hut")
	local radius = rng:NextNumber(5.5, 7)
	local wallHeight = rng:NextNumber(6, 7.5)
	Parts.cylinder(
		model,
		"Wall",
		radius,
		wallHeight,
		CFrame.new(position + Vector3.new(0, wallHeight / 2, 0)),
		WOOD,
		Enum.Material.WoodPlanks
	)

	local yaw = yawToward(position, faceToward)
	local doorFrame = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	Parts.block(
		model,
		"Door",
		Vector3.new(3, 5, 0.8),
		doorFrame * CFrame.new(0, 2.5, -radius + 0.2),
		DARK_WOOD,
		Enum.Material.Wood
	)

	local roofBase = wallHeight
	local layers = 4
	for i = 0, layers - 1 do
		local r = (radius + 1.8) * (1 - i * 0.23)
		local y = roofBase + i * 1.8 + 1
		Parts.cylinder(model, "Roof", r, 2, CFrame.new(position + Vector3.new(0, y, 0)), STRAW, Enum.Material.Fabric)
	end
	Parts.ball(
		model,
		"Finial",
		1.6,
		position + Vector3.new(0, roofBase + layers * 1.8 + 0.8, 0),
		DARK_WOOD,
		Enum.Material.Wood
	)
end

-- Fire ----------------------------------------------------------------------

function Props.campfire(parent: Instance, position: Vector3, size: number, rng: Random)
	local model = Parts.model(parent, "Campfire")
	local ring = 6
	for i = 1, ring do
		local a = (i / ring) * math.pi * 2
		Parts.ball(
			model,
			"Stone",
			size * 0.55,
			position + Vector3.new(math.cos(a) * size * 0.9, size * 0.15, math.sin(a) * size * 0.9),
			STONE,
			Enum.Material.Slate
		)
	end
	for i = 1, 3 do
		local a = (i / 3) * math.pi * 2 + rng:NextNumber(0, 0.5)
		local log = Parts.cylinder(
			model,
			"Log",
			size * 0.14,
			size * 1.3,
			CFrame.new(position + Vector3.new(0, size * 0.35, 0)) * CFrame.Angles(0, a, math.rad(65)),
			DARK_WOOD,
			Enum.Material.Wood
		)
		log.Name = "Log"
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

-- Lava ----------------------------------------------------------------------

function Props.lavaPool(parent: Instance, position: Vector3, radius: number)
	local model = Parts.model(parent, "LavaPool")
	Parts.disc(model, "Rim", radius + 2.5, 0.8, position + Vector3.new(0, 0.1, 0), DARK_STONE, Enum.Material.Basalt)
	local lava = Parts.disc(model, "Lava", radius, 0.6, position + Vector3.new(0, 0.4, 0), LAVA, Enum.Material.Neon)
	Parts.noCollide(lava)
	Parts.light(lava, LAVA_LIGHT, radius * 3, 2)
	Parts.motes(lava, radius * 0.6, LAVA_LIGHT, 0.5)
end

-- A lava river along a polyline of ground points, sunk slightly into the floor.
function Props.lavaRiver(parent: Instance, points: { Vector3 }, width: number)
	local model = Parts.model(parent, "LavaRiver")
	for i = 1, #points - 1 do
		local a = points[i]
		local b = points[i + 1]
		local mid = (a + b) / 2
		local length = (b - a).Magnitude + width * 0.6
		local bed = Parts.block(
			model,
			"Bed",
			Vector3.new(width + 4, 1, length + 2),
			CFrame.lookAt(mid, b),
			DARK_STONE,
			Enum.Material.Basalt
		)
		bed.CFrame = bed.CFrame * CFrame.new(0, -0.2, 0)
		local lava = Parts.block(
			model,
			"Lava",
			Vector3.new(width, 0.8, length),
			CFrame.lookAt(mid + Vector3.new(0, 0.3, 0), b + Vector3.new(0, 0.3, 0)),
			LAVA,
			Enum.Material.Neon
		)
		Parts.noCollide(lava)
		if i % 2 == 1 then
			Parts.light(lava, LAVA_LIGHT, width * 3, 1.5)
		end
	end
end

-- A glowing crack in the floor.
function Props.lavaCrack(parent: Instance, position: Vector3, length: number, yaw: number)
	local crack = Parts.block(
		parent,
		"Crack",
		Vector3.new(0.8, 0.4, length),
		CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, yaw, 0),
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
	-- Ramps at both ends so the deck is walkable.
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

-- A cone mountain with a glowing crater and lava running down its sides.
function Props.volcano(parent: Instance, position: Vector3, radius: number, height: number, rng: Random)
	local model = Parts.model(parent, "Volcano")
	local tiers = 7
	local tierHeight = height / tiers
	local rockColor = Color3.fromRGB(62, 50, 50)
	for i = 0, tiers - 1 do
		local r = radius * (1 - i / tiers * 0.82)
		local y = i * tierHeight + tierHeight / 2
		Parts.cylinder(
			model,
			"Tier",
			r,
			tierHeight,
			CFrame.new(position + Vector3.new(0, y, 0)),
			rockColor,
			Enum.Material.Slate
		)
	end

	local craterRadius = radius * 0.16
	local top = position + Vector3.new(0, height, 0)
	local crater = Parts.disc(model, "Crater", craterRadius, 1, top + Vector3.new(0, 0.3, 0), LAVA, Enum.Material.Neon)
	Parts.noCollide(crater)
	Parts.light(crater, LAVA_LIGHT, radius * 3, 3)
	Parts.fire(crater, craterRadius * 2.5, 25)
	Parts.motes(crater, 25, LAVA_LIGHT, 0.9)

	-- Streams: glowing blobs stepping down the tiers.
	local streams = 4
	for s = 1, streams do
		local a = (s / streams) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		for i = tiers - 1, 1, -1 do
			local r = radius * (1 - i / tiers * 0.82)
			local y = i * tierHeight + 0.4
			local blob = Parts.block(
				model,
				"Stream",
				Vector3.new(4.5, 0.8, 5),
				CFrame.new(position + Vector3.new(math.cos(a) * (r - 1.5), y, math.sin(a) * (r - 1.5)))
					* CFrame.Angles(0, -a, 0),
				LAVA,
				Enum.Material.Neon
			)
			Parts.noCollide(blob)
		end
	end
end

-- Statues and treasure --------------------------------------------------------

-- A blocky dragon statue. `cframe` is the ground centre; it faces its -Z.
function Props.dragonStatue(parent: Instance, cframe: CFrame, scale: number, color: Color3, material: Enum.Material)
	local model = Parts.model(parent, "DragonStatue")
	local s = scale
	Parts.disc(model, "Pedestal", 7 * s, 2 * s, cframe.Position + Vector3.new(0, s, 0), DARK_STONE, Enum.Material.Slate)
	local base = cframe * CFrame.new(0, 2 * s, 0)

	Parts.block(model, "Body", Vector3.new(5, 4.5, 10) * s, base * CFrame.new(0, 4 * s, 0), color, material)
	Parts.block(
		model,
		"Neck",
		Vector3.new(2.6, 6, 2.6) * s,
		base * CFrame.new(0, 7.5 * s, -4.5 * s) * CFrame.Angles(math.rad(-25), 0, 0),
		color,
		material
	)
	Parts.block(model, "Head", Vector3.new(3, 2.6, 4.5) * s, base * CFrame.new(0, 10.5 * s, -6.8 * s), color, material)
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
	Parts.wedge(
		model,
		"Tail",
		Vector3.new(1.6, 1.6, 8) * s,
		base * CFrame.new(0, 3.2 * s, 8.5 * s) * CFrame.Angles(math.rad(-15), math.pi, 0),
		color,
		material
	)
	for _, x in { -1.6, 1.6 } do
		for _, z in { -3, 3 } do
			Parts.block(
				model,
				"Leg",
				Vector3.new(1.6, 2, 1.8) * s,
				base * CFrame.new(x * s, 1 * s, z * s),
				color,
				material
			)
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
	Parts.light(mound, GOLD, radius * 3, 0.8)
	local coins = math.floor(radius * 1.6)
	for _ = 1, coins do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0, radius * 0.9)
		local size = rng:NextNumber(1.2, 2.8)
		local y = math.max(0, radius * 0.45 * (1 - d / radius))
		Parts.ball(
			model,
			"Coin",
			size,
			position + Vector3.new(math.cos(a) * d, y + size * 0.3, math.sin(a) * d),
			GOLD,
			Enum.Material.Metal
		)
	end
	for _ = 1, math.floor(radius * 0.5) do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(radius * 0.3, radius * 1.1)
		Parts.block(
			model,
			"Ingot",
			Vector3.new(3, 1, 1.6),
			CFrame.new(position + Vector3.new(math.cos(a) * d, 0.5, math.sin(a) * d))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			GOLD,
			Enum.Material.Metal
		)
	end
end

-- The dragon throne. `cframe` is the ground centre of the bottom step; it faces its -Z.
function Props.throne(parent: Instance, cframe: CFrame)
	local model = Parts.model(parent, "Throne")
	local steps = { Vector3.new(30, 2, 16), Vector3.new(24, 2, 12), Vector3.new(18, 2, 9) }
	local y = 0
	for i, size in steps do
		Parts.block(
			model,
			"Step",
			size,
			cframe * CFrame.new(0, y + size.Y / 2, (i - 1) * 1.2),
			GOLD_DARK,
			Enum.Material.Metal
		)
		y += size.Y
	end
	local seatBase = cframe * CFrame.new(0, y, 2)
	Parts.block(model, "Seat", Vector3.new(9, 3.5, 7), seatBase * CFrame.new(0, 1.75, 0), GOLD, Enum.Material.Metal)
	Parts.block(
		model,
		"Cushion",
		Vector3.new(7.5, 0.8, 5.5),
		seatBase * CFrame.new(0, 3.9, 0.3),
		CRIMSON,
		Enum.Material.Fabric
	)
	Parts.block(model, "Back", Vector3.new(9, 14, 2), seatBase * CFrame.new(0, 7, 4.5), GOLD, Enum.Material.Metal)
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
end

-- Ice -----------------------------------------------------------------------

function Props.crystal(parent: Instance, position: Vector3, height: number, rng: Random)
	local w = rng:NextNumber(2.5, 5)
	local crystal = Parts.block(
		parent,
		"Crystal",
		Vector3.new(w, height, w * rng:NextNumber(0.8, 1.2)),
		CFrame.new(position + Vector3.new(0, height * 0.45, 0))
			* CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.2, 0.2)),
		ICE,
		Enum.Material.Ice
	)
	crystal.Transparency = 0.15
	crystal.Reflectance = 0.1
	return crystal
end

-- Win pad --------------------------------------------------------------------

function Props.winPad(parent: Instance, position: Vector3, radius: number)
	local model = Parts.model(parent, "WinPadModel")
	local ring =
		Parts.disc(model, "Ring", radius + 4, 0.4, position + Vector3.new(0, 0.2, 0), GOLD_DARK, Enum.Material.Metal)
	Parts.noCollide(ring)
	local pad = Parts.disc(model, "WinPad", radius, 0.8, position + Vector3.new(0, 0.4, 0), GOLD, Enum.Material.Neon)
	CollectionService:AddTag(pad, "WinPad")
	Parts.light(pad, GOLD, radius * 4, 3)
	Parts.motes(pad, 20, Color3.fromRGB(255, 230, 120), 0.7)
	Parts.sign(pad, "VICTORY", 12, 300, GOLD)
	return pad
end

return Props
