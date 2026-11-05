--!strict
-- Builds the whole map from code: a long floating island of zones laid end to
-- end along -Z, each with its own scenery, separated by ice gates. The ground,
-- cliffs and natural shapes are terrain; built things are parts. Used when
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
local Terrain = require(script.Parent.Terrain)
local Town = require(script.Parent.Town)
local Zones = require(script.Parent.Zones)

local Builder = {}

local FLOOR_TOP = 0 -- Y of the walkable surface, on the 4-stud terrain grid
local FLOOR_THICKNESS = 16
local UNDERSIDE_THICKNESS = 28
local RAIL_HEIGHT = 320
local PATH_WIDTH = Config.PathWidth
local GATE_DOOR_WIDTH = Config.GateDoorWidth
local GATE_THICKNESS = 6

local ICE = Color3.fromRGB(170, 220, 255)
local ICE_DEEP = Color3.fromRGB(130, 190, 245)
local LAVA = Color3.fromRGB(255, 120, 20)
local POST = Color3.fromRGB(60, 60, 60)

-- Terrain ground for one zone plus an invisible slab for zone detection.
local function buildFloor(map: Folder, index: number, zone: Config.Zone, startZ: number, endZ: number, width: number)
	local length = startZ - endZ
	local centerZ = (startZ + endZ) / 2
	local material = Zones.FloorMaterial[zone.Name] or Enum.Material.Slate

	Terrain.Block(
		CFrame.new(0, FLOOR_TOP - FLOOR_THICKNESS / 2, centerZ),
		Vector3.new(width, FLOOR_THICKNESS, length),
		material
	)
	Terrain.Block(
		CFrame.new(0, FLOOR_TOP - 2, centerZ),
		Vector3.new(PATH_WIDTH, 4, length),
		Zones.PathMaterial[zone.Name] or Enum.Material.Pavement
	)
	-- Darker rock below so the island reads as a thick floating mass.
	Terrain.Block(
		CFrame.new(0, FLOOR_TOP - FLOOR_THICKNESS - UNDERSIDE_THICKNESS / 2 + 2, centerZ),
		Vector3.new(width * 0.84, UNDERSIDE_THICKNESS, length * 0.94),
		Enum.Material.Rock
	)

	local sensor = Parts.block(
		map,
		`Zone{index}Floor`,
		Vector3.new(width, 2, length),
		CFrame.new(0, FLOOR_TOP - 1, centerZ),
		zone.Color
	)
	Parts.invisible(sensor)
	sensor:SetAttribute("ZoneIndex", index)
	CollectionService:AddTag(sensor, "ZoneFloor")
end

-- Boulders along the edges and lumpy rock hanging below.
local function buildCliffs(rng: Random, startZ: number, endZ: number, width: number, isFirst: boolean, isLast: boolean)
	local half = width / 2

	local z = startZ - 10
	while z > endZ + 10 do
		for _, side in { -1, 1 } do
			local size = rng:NextNumber(16, 30)
			local x = side * (half - rng:NextNumber(-2, 6))
			Terrain.Boulder(
				Vector3.new(x, FLOOR_TOP - size * 0.3, z + rng:NextNumber(-8, 8)),
				size,
				Enum.Material.Rock,
				rng
			)
		end
		z -= 24
	end

	z = startZ - 20
	while z > endZ + 20 do
		for _, side in { -1, 1 } do
			local r = rng:NextNumber(12, 22)
			local x = side * (half - rng:NextNumber(14, 50))
			Terrain.Ball(
				Vector3.new(x, FLOOR_TOP - FLOOR_THICKNESS - UNDERSIDE_THICKNESS - r * 0.4, z),
				r,
				Enum.Material.Rock
			)
		end
		z -= 40
	end

	local function capEdge(edgeZ: number)
		local x = -half + 6
		while x < half - 6 do
			local size = rng:NextNumber(16, 28)
			Terrain.Boulder(
				Vector3.new(x + rng:NextNumber(-6, 6), FLOOR_TOP - size * 0.3, edgeZ + rng:NextNumber(-3, 3)),
				size,
				Enum.Material.Rock,
				rng
			)
			x += 24
		end
	end
	if isFirst then
		capEdge(startZ + 2)
	end
	if isLast then
		capEdge(endZ - 2)
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

-- Glacier walls across the zone entrance with a melting ice door in the middle.
local function buildGate(map: Folder, rng: Random, index: number, zone: Config.Zone, startZ: number, width: number)
	local gate = Parts.model(map, `Gate{index}`)
	local height = Config.IceWallHeight
	local half = width / 2
	local sideWidth = half - GATE_DOOR_WIDTH / 2

	for _, side in { -1, 1 } do
		local cx = side * (GATE_DOOR_WIDTH / 2 + sideWidth / 2)
		Terrain.Block(
			CFrame.new(cx, FLOOR_TOP + (height + 8) / 2, startZ),
			Vector3.new(sideWidth + 2, height + 8, GATE_THICKNESS + 2),
			Enum.Material.Glacier
		)
		-- Ice lumps along the top and foot so the wall is not a flat slab.
		for _ = 1, math.max(6, math.floor(sideWidth / 16)) do
			local x = side * rng:NextNumber(GATE_DOOR_WIDTH / 2 + 8, half - 6)
			Terrain.Ball(
				Vector3.new(x, FLOOR_TOP + height + 6, startZ + rng:NextNumber(-3, 3)),
				rng:NextNumber(5, 10),
				Enum.Material.Glacier
			)
			Terrain.Ball(
				Vector3.new(x, FLOOR_TOP + rng:NextNumber(0, 4), startZ + rng:NextNumber(3, 9)),
				rng:NextNumber(4, 8),
				Enum.Material.Ice
			)
		end
		for _ = 1, math.max(7, math.floor(sideWidth / 14)) do
			local x = side * rng:NextNumber(GATE_DOOR_WIDTH / 2 + 6, half - 8)
			Props.crystal(
				gate,
				Vector3.new(x, FLOOR_TOP + height + 8, startZ + rng:NextNumber(-2, 2)),
				rng:NextNumber(14, 34),
				rng
			)
		end
		for _ = 1, math.max(5, math.floor(sideWidth / 20)) do
			local x = side * rng:NextNumber(GATE_DOOR_WIDTH / 2 + 4, half - 10)
			Props.crystal(gate, Vector3.new(x, FLOOR_TOP, startZ + rng:NextNumber(8, 16)), rng:NextNumber(8, 22), rng)
		end
	end

	local lintel = Parts.block(
		gate,
		"Lintel",
		Vector3.new(GATE_DOOR_WIDTH + 10, 8, GATE_THICKNESS + 2),
		CFrame.new(0, FLOOR_TOP + height + 4, startZ),
		ICE_DEEP,
		Enum.Material.Glass
	)
	lintel.Transparency = 0.3
	lintel.Reflectance = 0.15
	for _, x in { -GATE_DOOR_WIDTH / 2 - 2, 0, GATE_DOOR_WIDTH / 2 + 2 } do
		Props.crystal(gate, Vector3.new(x, FLOOR_TOP + height + 8, startZ), rng:NextNumber(14, 26), rng)
	end

	local door = Parts.block(
		gate,
		`IceWall{index}`,
		Vector3.new(GATE_DOOR_WIDTH, height, GATE_THICKNESS - 1),
		CFrame.new(0, FLOOR_TOP + height / 2, startZ),
		ICE,
		Enum.Material.Glass
	)
	door.Transparency = 0.25
	door.Reflectance = 0.1
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

	Props.torch(gate, Vector3.new(-GATE_DOOR_WIDTH / 2 - 5, FLOOR_TOP, startZ + 7), 14)
	Props.torch(gate, Vector3.new(GATE_DOOR_WIDTH / 2 + 5, FLOOR_TOP, startZ + 7), 14)
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
			warn(`[MapGen] Disabled spawn {instance:GetFullName()} so players start in the town`)
		end
	end
end

-- A glowing circle at the arena's start that sends players back to town.
local function buildReturnPortal(map: Folder)
	local model = Parts.model(map, "ReturnPortal")
	local position = Vector3.new(0, FLOOR_TOP, -16)
	local color = Color3.fromRGB(150, 70, 220)
	local outer = Parts.disc(model, "Outer", 9, 0.25, position + Vector3.new(0, 0.12, 0), POST, Enum.Material.Slate)
	Parts.noCollide(outer)
	local glow = Parts.disc(model, "Glow", 8, 0.3, position + Vector3.new(0, 0.2, 0), color, Enum.Material.Neon)
	glow.Transparency = 0.35
	Parts.noCollide(glow)
	glow.CanTouch = true
	glow:SetAttribute("Destination", "TownGate")
	CollectionService:AddTag(glow, "Portal")
	Parts.light(glow, color, 24, 1.5)
	Parts.motes(glow, 12, color, 0.5)
	Parts.sign(glow, "Back to Town", 6, 220, color)
	for _, x in { -11, 11 } do
		Props.torch(model, Vector3.new(x, FLOOR_TOP, -16), 8)
	end
end

-- Runs one build stage, reporting a failure instead of aborting the map, and
-- yields afterwards so the generator never trips Studio's script timeout.
local function stage(name: string, work: () -> ())
	local ok, err = pcall(function()
		work()
		return nil
	end)
	if not ok then
		warn(`[MapGen] {name} failed: {err}`)
	end
	task.wait()
end

-- Builds the ground, zone sensors, spawn and rails right away so players
-- spawn on the island and zones work, then dresses the island in the
-- background one stage at a time.
function Builder.Build(): Folder
	local started = os.clock()
	local map = Instance.new("Folder")
	map.Name = "Map"

	local rng = Random.new(Config.MapSeed)
	local width = Config.ZoneWidth
	local zoneCount = #Config.Zones

	local totalLength = 0
	for _, zone in Config.Zones do
		totalLength += zone.Length
	end

	type Lane = { Index: number, Zone: Config.Zone, StartZ: number, EndZ: number }
	local lanes: { Lane } = {}
	local cursorZ = 0
	for index, zone in Config.Zones do
		local lane = { Index = index, Zone = zone, StartZ = cursorZ, EndZ = cursorZ - zone.Length }
		table.insert(lanes, lane)
		-- Clear any terrain in the zone's volume so the build is deterministic.
		Terrain.Clear(
			Vector3.new(0, FLOOR_TOP - 40, (lane.StartZ + lane.EndZ) / 2),
			Vector3.new(width + 120, 260, zone.Length + (if index == 1 or index == zoneCount then 120 else 0))
		)
		buildFloor(map, index, zone, lane.StartZ, lane.EndZ, width)
		cursorZ = lane.EndZ
	end

	buildRails(map, width, totalLength)
	Town.BuildGround(map)

	-- Arrival pad from the town, just inside the Hatchery, facing down the arena.
	local arrival =
		Parts.block(map, "ArenaArrival", Vector3.new(4, 2, 4), CFrame.new(0, FLOOR_TOP + 1, -44), Color3.new(1, 1, 1))
	Parts.invisible(arrival)
	arrival:SetAttribute("Name", "Arena")
	CollectionService:AddTag(arrival, "PortalArrival")

	map.Parent = Workspace
	hideBaseplate()
	local spawn = map:FindFirstChild("Spawn")
	if spawn and spawn:IsA("SpawnLocation") then
		disableOtherSpawns(spawn)
	end
	print(
		`[MapGen] Ground ready for the town and {zoneCount} zones, {totalLength} studs long, in {math.round(
			(os.clock() - started) * 1000
		)} ms`
	)

	task.spawn(function()
		stage("Town", function()
			Town.Decorate(map, Random.new(Config.MapSeed + 2))
		end)
		stage("Arena entrance", function()
			buildReturnPortal(map)
		end)
		for _, lane in lanes do
			local index, zone = lane.Index, lane.Zone
			stage(`Zone {index} cliffs`, function()
				buildCliffs(rng, lane.StartZ, lane.EndZ, width, index == 1, index == zoneCount)
			end)

			local zoneFolder = Instance.new("Folder")
			zoneFolder.Name = `Zone{index}_{zone.Name:gsub(" ", "")}`
			zoneFolder.Parent = map
			stage(`Zone {index} scenery`, function()
				Zones.Decorate({
					Index = index,
					Zone = zone,
					Width = width,
					Length = zone.Length,
					StartZ = lane.StartZ,
					EndZ = lane.EndZ,
					CenterZ = (lane.StartZ + lane.EndZ) / 2,
					Top = FLOOR_TOP,
					Rng = rng,
					Parent = zoneFolder,
				})
			end)

			stage(`Zone {index} sign and gate`, function()
				buildSignPost(map, zone, lane.StartZ - 18)
				if index > 1 then
					buildGate(map, rng, index, zone, lane.StartZ, width)
				end
			end)
		end

		local partCount = 0
		for _, instance in map:GetDescendants() do
			if instance:IsA("BasePart") then
				partCount += 1
			end
		end
		print(
			`[MapGen] Map complete: {partCount} parts plus terrain, in {math.round((os.clock() - started) * 1000)} ms`
		)
	end)

	return map
end

return Builder
