--!strict
-- The hub town where players spawn: a round floating island with a fountain
-- plaza, the egg gacha and pet shop, the skill shop, an inn, market stalls, a
-- training pen, teleport circles and a stone arch portal north to the arena.
-- Everything is laid out relative to Config.TownCenter. Buildings here are
-- the town's own; shared scenery (trees, dummies, crystals) comes from Props.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Parts = require(script.Parent.Parts)
local Props = require(script.Parent.Props)
local Terrain = require(script.Parent.Terrain)

local Town = {}

local FLOOR_THICKNESS = 16
local UNDERSIDE_THICKNESS = 28
local PLAZA_RADIUS = 70
local PATH_WIDTH = 18
local WALL_HEIGHT = 9
local ROOF_HEIGHT = 6

local STONE = Color3.fromRGB(150, 148, 150)
local DARK_STONE = Color3.fromRGB(90, 88, 92)
local WOOD = Color3.fromRGB(112, 76, 44)
local DARK_WOOD = Color3.fromRGB(66, 44, 28)
local PLASTER = Color3.fromRGB(236, 224, 196)
local GLASS = Color3.fromRGB(150, 205, 240)
local IRON = Color3.fromRGB(60, 62, 70)
local WATER = Color3.fromRGB(70, 160, 235)
local WARM = Color3.fromRGB(255, 200, 120)
local PURPLE = Color3.fromRGB(150, 70, 220)
local BLUE = Color3.fromRGB(50, 110, 230)
local RED = Color3.fromRGB(210, 50, 45)
local GREEN = Color3.fromRGB(70, 210, 90)
local GOLD = Color3.fromRGB(240, 195, 60)
local PINK = Color3.fromRGB(240, 110, 190)
local CYAN = Color3.fromRGB(80, 220, 255)
local WHITE = Color3.fromRGB(245, 245, 245)

local GACHA_COLORS = { PINK, BLUE, GOLD }
local CAPSULE_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(120, 200, 255),
	Color3.fromRGB(255, 230, 110),
	Color3.fromRGB(150, 240, 140),
	Color3.fromRGB(220, 140, 255),
	WHITE,
}
local PET_COLORS = {
	Color3.fromRGB(230, 70, 60),
	Color3.fromRGB(90, 190, 90),
	Color3.fromRGB(80, 130, 230),
	Color3.fromRGB(240, 200, 60),
	Color3.fromRGB(170, 90, 220),
	Color3.fromRGB(240, 130, 60),
}
local FLOWER_COLORS = { PINK, GOLD, WHITE, Color3.fromRGB(200, 120, 255), Color3.fromRGB(255, 150, 90) }

local function vary(color: Color3, rng: Random, amount: number): Color3
	local t = rng:NextNumber(-amount, amount)
	return if t > 0 then color:Lerp(Color3.new(1, 1, 1), t) else color:Lerp(Color3.new(0, 0, 0), -t)
end

-- Ground point in town space.
local function at(x: number, z: number): Vector3
	return Config.TownCenter + Vector3.new(x, 0, z)
end

-- A frame standing at `position` with its -Z toward `toward`.
local function facing(position: Vector3, toward: Vector3): CFrame
	return CFrame.lookAt(position, Vector3.new(toward.X, position.Y, toward.Z))
end

-- Buildings ----------------------------------------------------------------

-- A timber-framed house with a tiled gable roof, door, windows and chimney.
-- `base` stands on the ground, front toward its -Z. Returns the model.
local function house(
	parent: Instance,
	name: string,
	base: CFrame,
	width: number,
	depth: number,
	roofColor: Color3,
	rng: Random
): Model
	local model = Parts.model(parent, name)
	local plaster = vary(PLASTER, rng, 0.05)
	local timber = vary(DARK_WOOD, rng, 0.08)
	local top = 1 + WALL_HEIGHT

	Parts.block(
		model,
		"Foundation",
		Vector3.new(width + 2, 1, depth + 2),
		base * CFrame.new(0, 0.5, 0),
		STONE,
		Enum.Material.Cobblestone
	)
	Parts.block(
		model,
		"Walls",
		Vector3.new(width, WALL_HEIGHT, depth),
		base * CFrame.new(0, 1 + WALL_HEIGHT / 2, 0),
		plaster,
		Enum.Material.Concrete
	)

	-- Timber frame: corner posts, beams at the middle and top, studs between.
	for _, x in { -width / 2, width / 2 } do
		for _, z in { -depth / 2, depth / 2 } do
			Parts.block(
				model,
				"Post",
				Vector3.new(1, WALL_HEIGHT, 1),
				base * CFrame.new(x, 1 + WALL_HEIGHT / 2, z),
				timber,
				Enum.Material.Wood
			)
		end
	end
	for _, y in { 1 + WALL_HEIGHT * 0.55, top - 0.3 } do
		for _, z in { -depth / 2, depth / 2 } do
			Parts.block(
				model,
				"Beam",
				Vector3.new(width + 1, 0.6, 1),
				base * CFrame.new(0, y, z),
				timber,
				Enum.Material.Wood
			)
		end
		for _, x in { -width / 2, width / 2 } do
			Parts.block(
				model,
				"Beam",
				Vector3.new(1, 0.6, depth + 1),
				base * CFrame.new(x, y, 0),
				timber,
				Enum.Material.Wood
			)
		end
	end
	for _, z in { -depth / 2, depth / 2 } do
		for i = 1, 3 do
			local x = -width / 2 + width * i / 4
			if z < 0 and i == 2 then
				continue -- door
			end
			Parts.block(
				model,
				"Stud",
				Vector3.new(0.6, WALL_HEIGHT * 0.55 - 0.6, 0.8),
				base * CFrame.new(x, 1 + WALL_HEIGHT * 0.275, z),
				timber,
				Enum.Material.Wood
			)
		end
	end

	-- Door on the front.
	local front = -depth / 2
	Parts.block(
		model,
		"DoorFrame",
		Vector3.new(4.2, 6.6, 0.7),
		base * CFrame.new(0, 1 + 3.3, front - 0.1),
		timber,
		Enum.Material.Wood
	)
	Parts.block(
		model,
		"Door",
		Vector3.new(3.2, 6, 0.5),
		base * CFrame.new(0, 1 + 3, front - 0.3),
		vary(WOOD, rng, 0.1),
		Enum.Material.WoodPlanks
	)
	Parts.ball(model, "Knob", 0.4, (base * CFrame.new(1, 4, front - 0.6)).Position, GOLD, Enum.Material.Metal)
	-- Step and a lantern beside the door.
	Parts.block(
		model,
		"Step",
		Vector3.new(5, 0.6, 2),
		base * CFrame.new(0, 1.3, front - 1.5),
		STONE,
		Enum.Material.Slate
	)

	-- Windows: two on the front, two on each side, one at the back.
	local function window(cframe: CFrame)
		Parts.block(model, "WindowFrame", Vector3.new(3, 3, 0.6), cframe, timber, Enum.Material.Wood)
		local glass = Parts.block(
			model,
			"Glass",
			Vector3.new(2.4, 2.4, 0.4),
			cframe * CFrame.new(0, 0, -0.2),
			GLASS,
			Enum.Material.Glass
		)
		glass.Transparency = 0.3
		glass.Reflectance = 0.25
		Parts.block(
			model,
			"Mullion",
			Vector3.new(0.25, 2.4, 0.5),
			cframe * CFrame.new(0, 0, -0.2),
			timber,
			Enum.Material.Wood
		)
		Parts.block(
			model,
			"Mullion",
			Vector3.new(2.4, 0.25, 0.5),
			cframe * CFrame.new(0, 0, -0.2),
			timber,
			Enum.Material.Wood
		)
		Parts.block(
			model,
			"Sill",
			Vector3.new(3.4, 0.4, 1),
			cframe * CFrame.new(0, -1.6, -0.2),
			STONE,
			Enum.Material.Slate
		)
	end
	local sillY = 1 + 5.4
	for _, x in { -width / 2 + width / 4 + 0.5, width / 2 - width / 4 - 0.5 } do
		window(base * CFrame.new(x, sillY, front - 0.1))
	end
	for _, side in { -1, 1 } do
		for _, z in { -depth / 4, depth / 4 } do
			window(
				base
					* CFrame.new(side * width / 2, sillY, z)
					* CFrame.Angles(0, side * -math.pi / 2, 0)
					* CFrame.new(0, 0, -0.1)
			)
		end
	end
	window(base * CFrame.new(width / 4, sillY, depth / 2) * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, -0.1))

	-- Gable roof: two wedge halves, rows of tiles on each slope, a ridge beam.
	local halfDepth = depth / 2 + 1.5
	local roofWidth = width + 3
	Parts.wedge(
		model,
		"RoofFront",
		Vector3.new(roofWidth, ROOF_HEIGHT, halfDepth),
		base * CFrame.new(0, top + ROOF_HEIGHT / 2, -halfDepth / 2) * CFrame.Angles(0, math.pi, 0),
		roofColor,
		Enum.Material.Slate
	)
	Parts.wedge(
		model,
		"RoofBack",
		Vector3.new(roofWidth, ROOF_HEIGHT, halfDepth),
		base * CFrame.new(0, top + ROOF_HEIGHT / 2, halfDepth / 2),
		roofColor,
		Enum.Material.Slate
	)
	local rows = 5
	local ridge = (base * CFrame.new(0, top + ROOF_HEIGHT, 0)).Position
	for _, side in { -1, 1 } do
		local eave = (base * CFrame.new(0, top, side * halfDepth)).Position
		local slope = (eave - ridge)
		local rowLength = slope.Magnitude / rows
		for i = 1, rows do
			local point = ridge:Lerp(eave, (i - 0.5) / rows)
			local cframe = CFrame.lookAt(point, point + slope.Unit)
			Parts.block(
				model,
				"Tiles",
				Vector3.new(roofWidth + 0.4, 0.35, rowLength + 0.5),
				cframe + cframe.UpVector * 0.2,
				vary(roofColor, rng, 0.07),
				Enum.Material.Slate
			)
		end
	end
	Parts.block(
		model,
		"Ridge",
		Vector3.new(roofWidth + 1, 0.8, 1.2),
		base * CFrame.new(0, top + ROOF_HEIGHT + 0.2, 0),
		timber,
		Enum.Material.Wood
	)

	-- Chimney on the back slope.
	local chimney = Parts.block(
		model,
		"Chimney",
		Vector3.new(2.2, 6, 2.2),
		base * CFrame.new(width / 4, top + ROOF_HEIGHT * 0.5 + 2, depth / 4),
		DARK_STONE,
		Enum.Material.Cobblestone
	)
	Parts.block(
		model,
		"ChimneyCap",
		Vector3.new(2.8, 0.6, 2.8),
		chimney.CFrame * CFrame.new(0, 3.2, 0),
		STONE,
		Enum.Material.Slate
	)
	local smoke = Parts.block(model, "Smoke", Vector3.new(1, 1, 1), chimney.CFrame * CFrame.new(0, 3.8, 0), WHITE)
	Parts.invisible(smoke)
	local puff = Parts.motes(smoke, 2, Color3.fromRGB(200, 200, 205), 1.6)
	puff.LightEmission = 0
	puff.Speed = NumberRange.new(1, 2)
	puff.Lifetime = NumberRange.new(3, 5)

	return model
end

-- A capsule-toy machine full of coloured eggs. The prompt shows a notice
-- until pets exist.
local function gachaMachine(parent: Instance, base: CFrame, color: Color3, rng: Random)
	local model = Parts.model(parent, "GachaMachine")
	Parts.block(model, "Base", Vector3.new(4.4, 3.2, 4.4), base * CFrame.new(0, 1.6, 0), color)
	Parts.block(model, "Trim", Vector3.new(4.8, 0.5, 4.8), base * CFrame.new(0, 3.4, 0), IRON, Enum.Material.Metal)
	Parts.block(model, "Trim", Vector3.new(4.8, 0.5, 4.8), base * CFrame.new(0, 0.25, 0), IRON, Enum.Material.Metal)
	Parts.block(model, "Slot", Vector3.new(1.8, 1.1, 0.4), base * CFrame.new(0, 1.1, -2.3), DARK_STONE)
	Parts.block(
		model,
		"SlotLip",
		Vector3.new(2.2, 0.2, 0.8),
		base * CFrame.new(0, 0.5, -2.4),
		IRON,
		Enum.Material.Metal
	)
	Parts.cylinder(
		model,
		"Crank",
		0.7,
		0.5,
		base * CFrame.new(1.3, 2.4, -2.4) * CFrame.Angles(math.pi / 2, 0, 0),
		IRON,
		Enum.Material.Metal
	)
	Parts.block(
		model,
		"Handle",
		Vector3.new(0.3, 1, 0.3),
		base * CFrame.new(1.3, 2.8, -2.75),
		IRON,
		Enum.Material.Metal
	)

	local domeCenter = (base * CFrame.new(0, 5.8, 0)).Position
	local dome = Parts.ball(model, "Dome", 4.6, domeCenter, GLASS, Enum.Material.Glass)
	dome.Transparency = 0.45
	dome.Reflectance = 0.1
	for _ = 1, 18 do
		local offset = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 0.3), rng:NextNumber(-1, 1))
		if offset.Magnitude > 1 then
			offset = offset.Unit * rng:NextNumber(0.5, 1)
		end
		local capsule = Parts.ball(
			model,
			"Capsule",
			0.95,
			domeCenter + offset * 1.55,
			CAPSULE_COLORS[rng:NextInteger(1, #CAPSULE_COLORS)]
		)
		Parts.noCollide(capsule)
	end
	Parts.cylinder(model, "Cap", 1.2, 0.6, base * CFrame.new(0, 8.3, 0), IRON, Enum.Material.Metal)
	Parts.light(dome, color, 10, 0.8)
	Parts.sign(dome, "Egg Gacha", 4, 180)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hatch Egg"
	prompt.ObjectText = "Egg Gacha"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Notice", "Egg hatching is coming soon. Pets will follow you and boost your Fire!")
	prompt.Parent = dome
end

-- A market stall with a striped awning and crates of goods on the counter.
local function stall(parent: Instance, base: CFrame, stripe: Color3, rng: Random)
	local model = Parts.model(parent, "Stall")
	local w, d, h = 11, 7, 7.5
	for _, x in { -w / 2, w / 2 } do
		for _, z in { -d / 2, d / 2 } do
			Parts.cylinder(model, "Post", 0.35, h, base * CFrame.new(x, h / 2, z), DARK_WOOD, Enum.Material.Wood)
		end
	end
	Parts.block(
		model,
		"Counter",
		Vector3.new(w, 2.6, 2.6),
		base * CFrame.new(0, 1.3, -d / 2 + 1.3),
		WOOD,
		Enum.Material.WoodPlanks
	)
	Parts.block(
		model,
		"CounterTop",
		Vector3.new(w + 0.4, 0.3, 3),
		base * CFrame.new(0, 2.75, -d / 2 + 1.3),
		DARK_WOOD,
		Enum.Material.Wood
	)
	Parts.block(
		model,
		"Shelf",
		Vector3.new(w, 3.4, 1.2),
		base * CFrame.new(0, 4.2, d / 2 - 0.6),
		WOOD,
		Enum.Material.WoodPlanks
	)
	Parts.block(
		model,
		"ShelfTop",
		Vector3.new(w, 0.3, 1.6),
		base * CFrame.new(0, 6, d / 2 - 0.6),
		DARK_WOOD,
		Enum.Material.Wood
	)

	local stripes = 8
	local stripeWidth = w / stripes
	for i = 0, stripes - 1 do
		local x = -w / 2 + (i + 0.5) * stripeWidth
		Parts.block(
			model,
			"Awning",
			Vector3.new(stripeWidth + 0.05, 0.25, d + 3),
			base * CFrame.new(x, h + 0.6, -0.6) * CFrame.Angles(math.rad(-12), 0, 0),
			if i % 2 == 0 then stripe else WHITE,
			Enum.Material.Fabric
		)
	end

	-- Crates of goods: fruit, gems and bread.
	for i, x in { -3.4, 0, 3.4 } do
		local crate = Parts.block(
			model,
			"Crate",
			Vector3.new(2.2, 1.5, 2.2),
			base * CFrame.new(x, 3.65, -d / 2 + 1.3),
			vary(WOOD, rng, 0.1),
			Enum.Material.WoodPlanks
		)
		local goods = if i == 1
			then Color3.fromRGB(240, 90, 70)
			elseif i == 2 then Color3.fromRGB(150, 90, 230)
			else Color3.fromRGB(230, 180, 90)
		for _ = 1, 5 do
			local ball = Parts.ball(
				model,
				"Goods",
				rng:NextNumber(0.6, 0.9),
				(crate.CFrame * CFrame.new(rng:NextNumber(-0.6, 0.6), 0.9, rng:NextNumber(-0.6, 0.6))).Position,
				vary(goods, rng, 0.15),
				if i == 2 then Enum.Material.Glass else Enum.Material.SmoothPlastic
			)
			Parts.noCollide(ball)
		end
	end
	for _ = 1, 4 do
		local ball = Parts.ball(
			model,
			"Shelved",
			rng:NextNumber(0.8, 1.2),
			(base * CFrame.new(rng:NextNumber(-4, 4), 6.6, d / 2 - 0.6)).Position,
			CAPSULE_COLORS[rng:NextInteger(1, #CAPSULE_COLORS)]
		)
		Parts.noCollide(ball)
	end
end

-- A wooden fence around a rectangle, with a gap in the middle of one side.
local function fence(parent: Instance, minX: number, maxX: number, minZ: number, maxZ: number, gapSide: string)
	local model = Parts.model(parent, "Fence")
	local function post(x: number, z: number)
		Parts.block(
			model,
			"FencePost",
			Vector3.new(0.7, 3.2, 0.7),
			CFrame.new(at(x, z) + Vector3.new(0, 1.6, 0)),
			DARK_WOOD,
			Enum.Material.Wood
		)
	end
	local function rail(from: Vector3, to: Vector3)
		local mid = (from + to) / 2
		local length = (to - from).Magnitude
		for _, y in { 1.1, 2.4 } do
			Parts.block(
				model,
				"Rail",
				Vector3.new(0.4, 0.5, length),
				CFrame.lookAt(mid + Vector3.new(0, y, 0), to + Vector3.new(0, y, 0)),
				WOOD,
				Enum.Material.Wood
			)
		end
	end
	local function side(ax: number, az: number, bx: number, bz: number, isGap: boolean)
		local a, b = at(ax, az), at(bx, bz)
		local length = (b - a).Magnitude
		local steps = math.max(1, math.round(length / 5))
		for i = 0, steps do
			local p = a:Lerp(b, i / steps)
			post(p.X - Config.TownCenter.X, p.Z - Config.TownCenter.Z)
		end
		if isGap then
			local gapHalf = 4
			local mid = a:Lerp(b, 0.5)
			local dir = (b - a).Unit
			rail(a, mid - dir * gapHalf)
			rail(mid + dir * gapHalf, b)
		else
			rail(a, b)
		end
	end
	side(minX, minZ, maxX, minZ, gapSide == "north")
	side(maxX, minZ, maxX, maxZ, gapSide == "east")
	side(maxX, maxZ, minX, maxZ, gapSide == "south")
	side(minX, maxZ, minX, minZ, gapSide == "west")
end

local function lampPost(parent: Instance, position: Vector3)
	local model = Parts.model(parent, "LampPost")
	Parts.cylinder(
		model,
		"Foot",
		0.9,
		0.6,
		CFrame.new(position + Vector3.new(0, 0.3, 0)),
		DARK_STONE,
		Enum.Material.Slate
	)
	Parts.cylinder(model, "Post", 0.3, 8, CFrame.new(position + Vector3.new(0, 4.3, 0)), IRON, Enum.Material.Metal)
	Parts.block(
		model,
		"Cap",
		Vector3.new(1.6, 0.4, 1.6),
		CFrame.new(position + Vector3.new(0, 9.7, 0)),
		IRON,
		Enum.Material.Metal
	)
	local lantern = Parts.block(
		model,
		"Lantern",
		Vector3.new(1.3, 1.5, 1.3),
		CFrame.new(position + Vector3.new(0, 8.8, 0)),
		WARM,
		Enum.Material.Neon
	)
	Parts.light(lantern, WARM, 22, 1.2)
end

local function flowerPatch(parent: Instance, position: Vector3, rng: Random)
	local model = Parts.model(parent, "Flowers")
	local patch = Parts.disc(
		model,
		"Patch",
		rng:NextNumber(1.8, 2.6),
		0.3,
		position + Vector3.new(0, 0.15, 0),
		Color3.fromRGB(80, 150, 60),
		Enum.Material.Grass
	)
	Parts.noCollide(patch)
	for _ = 1, rng:NextInteger(5, 8) do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0, 1.8)
		local stem = Parts.cylinder(
			model,
			"Stem",
			0.08,
			0.9,
			CFrame.new(position + Vector3.new(math.cos(a) * d, 0.7, math.sin(a) * d)),
			Color3.fromRGB(70, 140, 60)
		)
		Parts.noCollide(stem)
		local bloom = Parts.ball(
			model,
			"Bloom",
			rng:NextNumber(0.45, 0.7),
			position + Vector3.new(math.cos(a) * d, 1.3, math.sin(a) * d),
			FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
		)
		Parts.noCollide(bloom)
	end
end

-- A glowing rune circle on the ground. Optionally a portal to `destination`
-- or an arrival pad named `arrival`.
local function magicCircle(parent: Instance, position: Vector3, radius: number, color: Color3, label: string): Part
	local model = Parts.model(parent, "MagicCircle")
	local outer = Parts.disc(
		model,
		"Outer",
		radius + 1.2,
		0.25,
		position + Vector3.new(0, 0.12, 0),
		DARK_STONE,
		Enum.Material.Slate
	)
	Parts.noCollide(outer)
	local glow = Parts.disc(model, "Glow", radius, 0.3, position + Vector3.new(0, 0.2, 0), color, Enum.Material.Neon)
	glow.Transparency = 0.35
	Parts.noCollide(glow)
	local inner = Parts.disc(
		model,
		"Inner",
		radius * 0.55,
		0.32,
		position + Vector3.new(0, 0.2, 0),
		DARK_STONE,
		Enum.Material.Slate
	)
	Parts.noCollide(inner)
	local core =
		Parts.disc(model, "Core", radius * 0.3, 0.34, position + Vector3.new(0, 0.2, 0), color, Enum.Material.Neon)
	Parts.noCollide(core)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local rune = Parts.block(
			model,
			"Rune",
			Vector3.new(0.8, 0.36, 1.6),
			CFrame.new(position + Vector3.new(math.cos(a) * radius * 0.78, 0.2, math.sin(a) * radius * 0.78))
				* CFrame.Angles(0, -a, 0),
			color,
			Enum.Material.Neon
		)
		Parts.noCollide(rune)
	end
	Parts.light(glow, color, radius * 3, 1.5)
	Parts.motes(glow, 12, color, 0.5)
	Parts.sign(glow, label, 6, 240, color)
	return glow
end

-- The stone arch with the swirling portal to the arena, on a raised step.
local function archPortal(parent: Instance, base: CFrame, rng: Random)
	local model = Parts.model(parent, "ArenaGate")
	Parts.block(model, "Platform", Vector3.new(34, 2, 16), base * CFrame.new(0, 1, 0), STONE, Enum.Material.Cobblestone)
	for i = 1, 3 do
		Parts.block(
			model,
			"Step",
			Vector3.new(26, 0.7 * (4 - i) + 0.1, 2.6),
			base * CFrame.new(0, (0.7 * (4 - i)) / 2, -8 - i * 2.6 + 1.3),
			STONE,
			Enum.Material.Slate
		)
	end

	local top = 2
	for _, x in { -9, 9 } do
		local y = top
		for _ = 1, 7 do
			local h = rng:NextNumber(2, 2.6)
			local w = rng:NextNumber(3.6, 4.4)
			Parts.block(
				model,
				"Stone",
				Vector3.new(w, h, rng:NextNumber(3.4, 4.2)),
				base
					* CFrame.new(x + rng:NextNumber(-0.25, 0.25), y + h / 2, rng:NextNumber(-0.2, 0.2))
					* CFrame.Angles(0, rng:NextNumber(-0.05, 0.05), 0),
				vary(STONE, rng, 0.1),
				Enum.Material.Cobblestone
			)
			y += h
		end
		Parts.block(
			model,
			"Capital",
			Vector3.new(5.4, 1.2, 5.2),
			base * CFrame.new(x, y + 0.6, 0),
			DARK_STONE,
			Enum.Material.Slate
		)
	end
	local lintelY = top + 17.6
	Parts.block(
		model,
		"Lintel",
		Vector3.new(24, 3.2, 4.4),
		base * CFrame.new(0, lintelY, 0),
		vary(STONE, rng, 0.05),
		Enum.Material.Cobblestone
	)
	Parts.block(
		model,
		"Keystone",
		Vector3.new(4, 4.6, 4.8),
		base * CFrame.new(0, lintelY + 0.6, 0),
		DARK_STONE,
		Enum.Material.Slate
	)
	for _, x in { -9, 9 } do
		Props.crystal(model, (base * CFrame.new(x, lintelY + 1.6, 0)).Position, 6, rng)
	end
	Props.torch(model, (base * CFrame.new(-13, 2, -4)).Position, 8)
	Props.torch(model, (base * CFrame.new(13, 2, -4)).Position, 8)

	local portal = Parts.block(
		model,
		"Portal",
		Vector3.new(14, lintelY - 3.6 - 2, 0.6),
		base * CFrame.new(0, 2 + (lintelY - 3.6) / 2, 0),
		CYAN,
		Enum.Material.Neon
	)
	portal.Transparency = 0.3
	portal.CanCollide = false
	portal.CanQuery = false
	portal:SetAttribute("Destination", "Arena")
	CollectionService:AddTag(portal, "Portal")
	Parts.light(portal, CYAN, 30, 2)
	local swirl = Parts.motes(portal, 40, CYAN, 0.8)
	swirl.Speed = NumberRange.new(1, 3)
	swirl.Acceleration = Vector3.new(0, 0, 0)
	Parts.sign(portal, "ARENA\nStep through to train", 11, 300, CYAN)
end

local function fountain(parent: Instance, center: Vector3, rng: Random)
	local model = Parts.model(parent, "Fountain")
	Parts.disc(model, "Basin", 16, 2.2, center + Vector3.new(0, 1.1, 0), STONE, Enum.Material.Cobblestone)
	local water = Parts.disc(model, "Water", 14.5, 0.6, center + Vector3.new(0, 2.0, 0), WATER, Enum.Material.Glass)
	water.Transparency = 0.35
	water.Reflectance = 0.2
	Parts.noCollide(water)
	local segments = 24
	for i = 1, segments do
		local a = i / segments * math.pi * 2
		Parts.block(
			model,
			"Curb",
			Vector3.new(4.4, 1.3, 2),
			CFrame.new(center + Vector3.new(math.cos(a) * 15.2, 2.85, math.sin(a) * 15.2))
				* CFrame.Angles(0, -a + math.pi / 2, 0),
			vary(STONE, rng, 0.08),
			Enum.Material.Slate
		)
	end
	Parts.cylinder(
		model,
		"Pedestal",
		3.2,
		3,
		CFrame.new(center + Vector3.new(0, 3.7, 0)),
		DARK_STONE,
		Enum.Material.Slate
	)
	Parts.disc(model, "Bowl", 6.5, 0.9, center + Vector3.new(0, 5.6, 0), STONE, Enum.Material.Slate)
	local upper = Parts.disc(model, "BowlWater", 5.6, 0.4, center + Vector3.new(0, 6.1, 0), WATER, Enum.Material.Glass)
	upper.Transparency = 0.35
	Parts.noCollide(upper)
	Parts.cylinder(
		model,
		"Column",
		1.3,
		5,
		CFrame.new(center + Vector3.new(0, 8.5, 0)),
		DARK_STONE,
		Enum.Material.Slate
	)
	Parts.disc(model, "Cap", 2.4, 0.8, center + Vector3.new(0, 11.2, 0), STONE, Enum.Material.Slate)

	-- Floating eggs circling the top, the town's emblem.
	local colors = { PURPLE, GOLD, CYAN }
	for i, color in colors do
		local a = i / 3 * math.pi * 2
		local egg = Parts.egg(
			model,
			"Emblem",
			Vector3.new(2.2, 3, 2.2),
			CFrame.new(center + Vector3.new(math.cos(a) * 4.5, 13 + (i % 2), math.sin(a) * 4.5))
				* CFrame.Angles(0, 0, math.rad(12)),
			color,
			Enum.Material.Neon
		)
		Parts.noCollide(egg)
		Parts.light(egg, color, 14, 1)
	end
	local spray = Parts.block(model, "Spray", Vector3.new(2, 1, 2), CFrame.new(center + Vector3.new(0, 12, 0)), WATER)
	Parts.invisible(spray)
	local jet = Parts.motes(spray, 40, Color3.fromRGB(200, 235, 255), 0.5)
	jet.Speed = NumberRange.new(10, 14)
	jet.Acceleration = Vector3.new(0, -20, 0)
	jet.Lifetime = NumberRange.new(1, 1.4)
	jet.SpreadAngle = Vector2.new(20, 20)
	Parts.motes(water, 10, Color3.fromRGB(220, 240, 255), 0.4)
end

-- Shelves of small dragon figures outside the pet shop.
local function petDisplay(parent: Instance, base: CFrame, rng: Random)
	local model = Parts.model(parent, "PetDisplay")
	Parts.block(
		model,
		"Back",
		Vector3.new(16, 7, 0.8),
		base * CFrame.new(0, 3.5, 1.2),
		DARK_WOOD,
		Enum.Material.WoodPlanks
	)
	for tier, y in { 0.6, 3.8 } do
		Parts.block(model, "Shelf", Vector3.new(16, 0.5, 3.2), base * CFrame.new(0, y, 0), WOOD, Enum.Material.Wood)
		for i = 1, 3 do
			local x = -5.3 + (i - 1) * 5.3
			local color = PET_COLORS[(tier - 1) * 3 + i]
			Props.dragonStatue(
				model,
				base * CFrame.new(x, y + 0.25, -0.2) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0),
				0.28,
				color,
				Enum.Material.SmoothPlastic
			)
		end
	end
	Parts.sign(model:FindFirstChild("Back") :: BasePart, "Pet Shop", 5, 180)
end

-- The skill shop counter with crystals, whose prompt opens the upgrade panel.
local function skillCounter(parent: Instance, base: CFrame, rng: Random)
	local model = Parts.model(parent, "SkillCounter")
	local counter = Parts.block(
		model,
		"Counter",
		Vector3.new(12, 2.8, 3),
		base * CFrame.new(0, 1.4, 0),
		DARK_STONE,
		Enum.Material.Slate
	)
	Parts.block(model, "Top", Vector3.new(12.6, 0.3, 3.6), base * CFrame.new(0, 2.95, 0), STONE, Enum.Material.Marble)
	for i, x in { -4, 0, 4 } do
		Props.crystal(model, (base * CFrame.new(x, 3.1, 0)).Position, 2.5 + i * 0.7, rng)
	end
	Parts.sign(counter, "Skill Shop\nBreath, Fangs, Inferno", 7, 240, BLUE)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Browse Skills"
	prompt.ObjectText = "Skill Shop"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", "ToggleShop")
	prompt.Parent = counter
end

-- Layout -------------------------------------------------------------------

-- Terrain island and the spawn, built right away.
function Town.BuildGround(map: Folder)
	local center = Config.TownCenter
	local radius = Config.TownRadius
	Terrain.Clear(center + Vector3.new(0, -40, 0), Vector3.new(radius * 2 + 120, 260, radius * 2 + 120))
	Terrain.Column(center + Vector3.new(0, -FLOOR_THICKNESS / 2, 0), FLOOR_THICKNESS, radius, Enum.Material.LeafyGrass)
	Terrain.Column(center + Vector3.new(0, -2, 0), 4, PLAZA_RADIUS, Enum.Material.Pavement)
	-- Paths out of the plaza: north to the gate, east, west and south.
	for _, dir in { Vector3.new(0, 0, -1), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1) } do
		local length = 80
		local mid = center + dir * (PLAZA_RADIUS + length / 2 - 10) + Vector3.new(0, -2, 0)
		local size = if dir.X == 0 then Vector3.new(PATH_WIDTH, 4, length) else Vector3.new(length, 4, PATH_WIDTH)
		Terrain.Block(CFrame.new(mid), size, Enum.Material.Pavement)
	end
	Terrain.Column(
		center + Vector3.new(0, -FLOOR_THICKNESS - UNDERSIDE_THICKNESS / 2 + 2, 0),
		UNDERSIDE_THICKNESS,
		radius * 0.82,
		Enum.Material.Rock
	)

	local spawnPoint = at(0, 98)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(spawnPoint + Vector3.new(0, 0.5, 0))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map
end

-- Everything on the island, built in the background.
function Town.Decorate(map: Folder, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "Town"
	folder.Parent = map
	local center = Config.TownCenter
	local radius = Config.TownRadius

	-- Cliffs around the edge and lumps below.
	local steps = math.floor(2 * math.pi * radius / 24)
	for i = 1, steps do
		local a = i / steps * math.pi * 2
		local size = rng:NextNumber(16, 30)
		Terrain.Boulder(
			center
				+ Vector3.new(
					math.cos(a) * (radius - 4 + rng:NextNumber(-3, 5)),
					-size * 0.3,
					math.sin(a) * (radius - 4 + rng:NextNumber(-3, 5))
				),
			size,
			Enum.Material.Rock,
			rng
		)
		if i % 2 == 0 then
			local r = rng:NextNumber(12, 22)
			Terrain.Ball(
				center
					+ Vector3.new(
						math.cos(a) * (radius - 40),
						-FLOOR_THICKNESS - UNDERSIDE_THICKNESS - r * 0.4,
						math.sin(a) * (radius - 40)
					),
				r,
				Enum.Material.Rock
			)
		end
	end

	-- A pond in the south-west corner.
	local pond = at(-118, 118)
	Terrain.Column(pond + Vector3.new(0, -2, 0), 5, 20, Enum.Material.Air)
	Terrain.Column(pond + Vector3.new(0, -2.5, 0), 3, 19, Enum.Material.Water)
	Terrain.Column(pond + Vector3.new(0, -5, 0), 2, 20, Enum.Material.Sand)

	fountain(folder, at(0, 0), rng)

	-- Spawn and arrival circle south of the fountain, the arena gate north.
	local arrival = magicCircle(folder, at(0, 98), 7, PURPLE, "Town Square")
	arrival:SetAttribute("Name", "Town")
	CollectionService:AddTag(arrival, "PortalArrival")
	archPortal(folder, facing(at(0, -126), at(0, 0)), rng)
	local gateArrival = magicCircle(folder, at(0, -100), 6, CYAN, "")
	gateArrival:SetAttribute("Name", "TownGate")
	CollectionService:AddTag(gateArrival, "PortalArrival")

	-- West: the pet shop with its gacha machines and display shelves.
	house(folder, "PetShop", facing(at(-116, -36), at(0, -36)), 22, 16, PURPLE, rng)
	petDisplay(folder, facing(at(-110, -8), at(0, -8)), rng)
	for i, z in { -40, -27, -14 } do
		gachaMachine(folder, facing(at(-58, z), at(0, z)), GACHA_COLORS[i], rng)
	end
	Props.npcSpawn(folder, at(-72, -50), at(-58, -27), "Keeper", 1, 1)
	for _, p in { at(-128, -56), at(-100, -56), at(-88, -22) } do
		Props.tree(folder, p, rng)
	end

	-- East: the skill shop and, further north, the inn with a stall.
	house(folder, "SkillShop", facing(at(116, 12), at(0, 12)), 22, 16, BLUE, rng)
	skillCounter(folder, facing(at(96, 12), at(0, 12)), rng)
	Props.npcSpawn(folder, at(100, 24), at(0, 24), "Keeper", 1, 2)
	house(folder, "Inn", facing(at(108, -78), at(0, -78)), 26, 18, RED, rng)
	local innStall = facing(at(76, -66), at(0, -66))
	stall(folder, innStall, RED, rng)
	Props.npcSpawn(
		folder,
		(innStall * CFrame.new(0, 0, 2)).Position,
		(innStall * CFrame.new(0, 0, -10)).Position,
		"Keeper",
		1,
		3
	)
	for _, p in { at(132, -48), at(136, 40), at(100, 48) } do
		Props.tree(folder, p, rng)
	end

	-- South-west: market stalls.
	-- Each stall has its keeper standing behind the counter.
	type StallSpot = { At: Vector3, Toward: Vector3, Stripe: Color3 }
	local stalls: { StallSpot } = {
		{ At = at(-86, 64), Toward = at(0, 30), Stripe = RED },
		{ At = at(-54, 94), Toward = at(0, 50), Stripe = BLUE },
	}
	for i, spot in stalls do
		local base = facing(spot.At, spot.Toward)
		stall(folder, base, spot.Stripe, rng)
		Props.npcSpawn(
			folder,
			(base * CFrame.new(0, 0, 2)).Position,
			(base * CFrame.new(0, 0, -10)).Position,
			"Keeper",
			1,
			3 + i
		)
	end

	-- South-east: the training pen and the green circle.
	fence(folder, 52, 98, 54, 92, "north")
	for _, x in { 62, 75, 88 } do
		Props.trainingDummy(folder, at(x, 76), at(x, 40), 1, rng)
	end
	local pen = Parts.block(
		folder,
		"PenSign",
		Vector3.new(0.8, 6, 0.8),
		CFrame.new(at(50, 50) + Vector3.new(0, 3, 0)),
		DARK_WOOD,
		Enum.Material.Wood
	)
	Parts.sign(pen, "Training Pen\nStand by a dummy to breathe on it", 5, 240)
	local green = magicCircle(folder, at(118, 118), 7, GREEN, "Pet Arena\nComing soon")
	local greenPrompt = Instance.new("ProximityPrompt")
	greenPrompt.ActionText = "Enter"
	greenPrompt.ObjectText = "Pet Arena"
	greenPrompt.MaxActivationDistance = 10
	greenPrompt.RequiresLineOfSight = false
	greenPrompt:SetAttribute("Notice", "The Pet Arena opens once pets hatch. Keep training!")
	greenPrompt.Parent = green

	-- Lamps around the plaza, flowers and trees around the rim, townsfolk about.
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2 + math.pi / 8
		lampPost(folder, at(math.cos(a) * (PLAZA_RADIUS + 5), math.sin(a) * (PLAZA_RADIUS + 5)))
	end
	for _ = 1, 16 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(PLAZA_RADIUS + 12, PLAZA_RADIUS + 40)
		local x, z = math.cos(a) * d, math.sin(a) * d
		if math.abs(x) < PATH_WIDTH or math.abs(z) < PATH_WIDTH then
			continue
		end
		flowerPatch(folder, at(x, z), rng)
	end
	for i = 1, 30 do
		local a = i / 30 * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
		local d = radius - rng:NextNumber(14, 30)
		local x, z = math.cos(a) * d, math.sin(a) * d
		-- Leave the gate clear and keep out of the pond.
		if (z < -80 and math.abs(x) < 40) or (at(x, z) - pond).Magnitude < 26 then
			continue
		end
		Props.tree(folder, at(x, z), rng)
	end
	for _ = 1, 10 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(radius - 40, radius - 12)
		Props.rock(folder, at(math.cos(a) * d, math.sin(a) * d), rng:NextNumber(3, 6), rng)
	end
end

return Town
