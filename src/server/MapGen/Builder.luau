--!strict
-- Builds the whole map from code: a long floating island of zones laid end to
-- end along -Z, each with its own scenery, separated by ice gates. Used when
-- Workspace has no folder named "Map". A Studio-built map replaces it by
-- following the same contract:
--
--   Zone floors   BasePart tagged "ZoneFloor" with attribute ZoneIndex (1-based).
--                 A player standing within its footprint is in that zone.
--   Ice walls     BasePart tagged "IceWall" with attributes ZoneIndex (the zone
--                 it leads into) and RequiredFire. Optional BillboardGui "Sign"
--                 with a TextLabel "Label" that the client updates.
--   Win pad       BasePart tagged "WinPad".
--   Spawn         any SpawnLocation; other spawns in the place are disabled.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Parts = require(script.Parent.Parts)
local Props = require(script.Parent.Props)
local Zones = require(script.Parent.Zones)

local Builder = {}

local FLOOR_TOP = 1 -- Y of the walkable surface
local FLOOR_THICKNESS = 14
local UNDERSIDE_THICKNESS = 24
local RAIL_HEIGHT = 140
local PATH_WIDTH = 28
local GATE_DOOR_WIDTH = 40
local GATE_THICKNESS = 5

local ISLAND_ROCK = Color3.fromRGB(72, 66, 68)
local ISLAND_UNDER = Color3.fromRGB(52, 46, 48)
local ICE = Color3.fromRGB(160, 215, 255)
local ICE_DEEP = Color3.fromRGB(120, 180, 240)
local LAVA = Color3.fromRGB(255, 120, 20)
local POST = Color3.fromRGB(60, 60, 60)

local function lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

local function buildFloor(
	map: Folder,
	index: number,
	zone: Config.Zone,
	startZ: number,
	endZ: number,
	width: number
): Part
	local length = startZ - endZ
	local centerZ = (startZ + endZ) / 2

	local floor = Parts.block(
		map,
		`Zone{index}Floor`,
		Vector3.new(width, FLOOR_THICKNESS, length),
		CFrame.new(0, FLOOR_TOP - FLOOR_THICKNESS / 2, centerZ),
		zone.Color,
		Zones.FloorMaterial[zone.Name] or Enum.Material.Slate
	)
	floor:SetAttribute("ZoneIndex", index)
	CollectionService:AddTag(floor, "ZoneFloor")

	-- Thick dark underside so the island reads as floating rock.
	Parts.block(
		map,
		"Underside",
		Vector3.new(width * 0.86, UNDERSIDE_THICKNESS, length * 0.94),
		CFrame.new(0, FLOOR_TOP - FLOOR_THICKNESS - UNDERSIDE_THICKNESS / 2 + 1, centerZ),
		ISLAND_UNDER,
		Enum.Material.Slate
	)

	-- Centre path, slightly lighter, flush enough to walk over without a bump.
	local path = Parts.block(
		map,
		"Path",
		Vector3.new(PATH_WIDTH, 0.3, length),
		CFrame.new(0, FLOOR_TOP + 0.1, centerZ),
		lighten(zone.Color, 0.25),
		Enum.Material.Cobblestone
	)
	Parts.noCollide(path)

	return floor
end

-- Boulders along the edges and jagged rock hanging below.
local function buildCliffs(
	map: Folder,
	rng: Random,
	startZ: number,
	endZ: number,
	width: number,
	isFirst: boolean,
	isLast: boolean
)
	local half = width / 2

	local z = startZ - 12
	while z > endZ + 12 do
		for _, side in { -1, 1 } do
			local size = rng:NextNumber(14, 26)
			local x = side * (half - rng:NextNumber(0, 6))
			Props.rock(map, Vector3.new(x, FLOOR_TOP - size * 0.4, z + rng:NextNumber(-8, 8)), size, rng, ISLAND_ROCK)
		end
		z -= 28
	end

	z = startZ - 24
	while z > endZ + 24 do
		for _, side in { -1, 1 } do
			local h = rng:NextNumber(22, 40)
			local w = rng:NextNumber(14, 24)
			local x = side * (half - rng:NextNumber(10, 40))
			local spike = Parts.wedge(
				map,
				"Underside",
				Vector3.new(w, h, w),
				CFrame.new(x, FLOOR_TOP - FLOOR_THICKNESS - UNDERSIDE_THICKNESS - h / 2 + 6, z)
					* CFrame.Angles(math.pi, rng:NextNumber(0, math.pi * 2), 0),
				ISLAND_UNDER,
				Enum.Material.Slate
			)
			Parts.noCollide(spike)
		end
		z -= 48
	end

	local function capEdge(edgeZ: number)
		local x = -half + 8
		while x < half - 8 do
			local size = rng:NextNumber(14, 26)
			Props.rock(
				map,
				Vector3.new(x + rng:NextNumber(-6, 6), FLOOR_TOP - size * 0.4, edgeZ),
				size,
				rng,
				ISLAND_ROCK
			)
			x += 26
		end
	end
	if isFirst then
		capEdge(startZ - 2)
	end
	if isLast then
		capEdge(endZ + 2)
	end
end

local function buildSignPost(map: Folder, zone: Config.Zone, z: number)
	local post = Parts.block(
		map,
		"ZonePost",
		Vector3.new(1.2, 14, 1.2),
		CFrame.new(PATH_WIDTH / 2 + 10, FLOOR_TOP + 7, z),
		POST,
		Enum.Material.Wood
	)
	Parts.sign(post, `{zone.Name}  x{zone.Multiplier}`, 9, 260)
end

-- An ice wall across the zone entrance with a melting door in the middle.
local function buildGate(map: Folder, rng: Random, index: number, zone: Config.Zone, startZ: number, width: number)
	local gate = Parts.model(map, `Gate{index}`)
	local height = Config.IceWallHeight
	local half = width / 2
	local sideWidth = half - GATE_DOOR_WIDTH / 2

	for _, side in { -1, 1 } do
		local cx = side * (GATE_DOOR_WIDTH / 2 + sideWidth / 2)
		local slab = Parts.block(
			gate,
			"IceSide",
			Vector3.new(sideWidth, height + 6, GATE_THICKNESS),
			CFrame.new(cx, FLOOR_TOP + (height + 6) / 2, startZ),
			ICE_DEEP,
			Enum.Material.Ice
		)
		slab.Transparency = 0.3

		for _ = 1, 7 do
			local x = side * rng:NextNumber(GATE_DOOR_WIDTH / 2 + 6, half - 8)
			Props.crystal(
				gate,
				Vector3.new(x, FLOOR_TOP + height + 4, startZ + rng:NextNumber(-2, 2)),
				rng:NextNumber(10, 24),
				rng
			)
		end
		for _ = 1, 5 do
			local x = side * rng:NextNumber(GATE_DOOR_WIDTH / 2 + 4, half - 10)
			Props.crystal(gate, Vector3.new(x, FLOOR_TOP, startZ + rng:NextNumber(5, 14)), rng:NextNumber(6, 16), rng)
		end
	end

	local lintel = Parts.block(
		gate,
		"Lintel",
		Vector3.new(GATE_DOOR_WIDTH + 10, 8, GATE_THICKNESS + 2),
		CFrame.new(0, FLOOR_TOP + height + 4, startZ),
		ICE_DEEP,
		Enum.Material.Ice
	)
	lintel.Transparency = 0.25
	for _, x in { -GATE_DOOR_WIDTH / 2 - 2, 0, GATE_DOOR_WIDTH / 2 + 2 } do
		Props.crystal(gate, Vector3.new(x, FLOOR_TOP + height + 8, startZ), rng:NextNumber(10, 18), rng)
	end

	local door = Parts.block(
		gate,
		`IceWall{index}`,
		Vector3.new(GATE_DOOR_WIDTH, height, GATE_THICKNESS - 1),
		CFrame.new(0, FLOOR_TOP + height / 2, startZ),
		ICE,
		Enum.Material.Ice
	)
	door.Transparency = 0.2
	door:SetAttribute("ZoneIndex", index)
	door:SetAttribute("RequiredFire", zone.RequiredFire)
	CollectionService:AddTag(door, "IceWall")
	Parts.sign(door, `{zone.Name}\nNeeds {Format.Short(zone.RequiredFire)} Fire`, height / 2 + 5, 340)

	local glow = Parts.block(
		gate,
		"Glow",
		Vector3.new(GATE_DOOR_WIDTH + 2, 0.5, GATE_THICKNESS + 3),
		CFrame.new(0, FLOOR_TOP + 0.25, startZ),
		LAVA,
		Enum.Material.Neon
	)
	Parts.noCollide(glow)
	Parts.light(glow, Color3.fromRGB(255, 150, 50), 40, 2)

	Props.torch(gate, Vector3.new(-GATE_DOOR_WIDTH / 2 - 5, FLOOR_TOP, startZ + 7), 9)
	Props.torch(gate, Vector3.new(GATE_DOOR_WIDTH / 2 + 5, FLOOR_TOP, startZ + 7), 9)
end

local function buildRails(map: Folder, width: number, totalLength: number)
	local half = width / 2
	local centerZ = -totalLength / 2
	for _, side in { -1, 1 } do
		local rail = Parts.block(
			map,
			"Rail",
			Vector3.new(1, RAIL_HEIGHT, totalLength + 2),
			CFrame.new(side * (half + 0.5), FLOOR_TOP + RAIL_HEIGHT / 2 - 10, centerZ),
			Color3.new(1, 1, 1)
		)
		rail.Transparency = 1
		rail.CanQuery = false
	end
	for _, z in { 0.5, -totalLength - 0.5 } do
		local rail = Parts.block(
			map,
			"Rail",
			Vector3.new(width + 2, RAIL_HEIGHT, 1),
			CFrame.new(0, FLOOR_TOP + RAIL_HEIGHT / 2 - 10, z),
			Color3.new(1, 1, 1)
		)
		rail.Transparency = 1
		rail.CanQuery = false
	end
end

local function hideBaseplate()
	if not Config.HideBaseplate then
		return
	end
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		print("[MapGen] Hid the Baseplate so the island floats; delete it in Studio when ready")
	end
end

local function disableOtherSpawns(keep: SpawnLocation)
	for _, instance in Workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") and instance ~= keep and instance.Enabled then
			instance.Enabled = false
			warn(`[MapGen] Disabled spawn {instance:GetFullName()} so players start in the Hatchery`)
		end
	end
end

function Builder.Build(): Folder
	local map = Instance.new("Folder")
	map.Name = "Map"

	local rng = Random.new(Config.MapSeed)
	local width = Config.ZoneWidth
	local cursorZ = 0
	local zoneCount = #Config.Zones

	for index, zone in Config.Zones do
		local startZ = cursorZ
		local endZ = cursorZ - zone.Length

		buildFloor(map, index, zone, startZ, endZ, width)

		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = `Zone{index}_{zone.Name:gsub(" ", "")}`
		zoneFolder.Parent = map
		Zones.Decorate({
			Index = index,
			Zone = zone,
			Width = width,
			Length = zone.Length,
			StartZ = startZ,
			EndZ = endZ,
			CenterZ = (startZ + endZ) / 2,
			Top = FLOOR_TOP,
			Rng = rng,
			Parent = zoneFolder,
		})

		buildCliffs(map, rng, startZ, endZ, width, index == 1, index == zoneCount)
		buildSignPost(map, zone, startZ - 18)
		if index > 1 then
			buildGate(map, rng, index, zone, startZ, width)
		end

		cursorZ = endZ
	end

	buildRails(map, width, -cursorZ)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, FLOOR_TOP + 0.5, -30)
	spawn.Color = Color3.fromRGB(120, 200, 120)
	spawn.Material = Enum.Material.Grass
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	map.Parent = Workspace
	hideBaseplate()
	disableOtherSpawns(spawn)

	local partCount = 0
	for _, instance in map:GetDescendants() do
		if instance:IsA("BasePart") then
			partCount += 1
		end
	end
	print(`[MapGen] Built {zoneCount} zones, {-cursorZ} studs long, {partCount} parts`)

	return map
end

return Builder
