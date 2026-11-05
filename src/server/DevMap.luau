--!strict
-- Builds a placeholder map from plain parts so zones and ice walls can be
-- tested before the real map exists. Used only when Workspace has no folder
-- named "Map". Build the real one in Studio using the same tags and attributes.
--
-- What the code needs from a map, placeholder or real:
--   Zone floors   BasePart tagged "ZoneFloor" with attribute ZoneIndex (1-based).
--                 A player standing within its footprint is in that zone.
--   Ice walls     BasePart tagged "IceWall" with attributes ZoneIndex (the zone
--                 it leads into) and RequiredFire. Optional BillboardGui "Sign"
--                 with a TextLabel "Label" that the client updates.
--   Spawn         any SpawnLocation; other spawns in the place are disabled.
-- The placeholder runs along -Z from the origin, one zone after another.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local DevMap = {}

local FLOOR_THICKNESS = 1
local SIDE_WALL_HEIGHT = 24

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function makeSign(parent: BasePart, text: string, height: number, width: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Sign"
	billboard.Size = UDim2.fromOffset(width, 70)
	billboard.StudsOffset = Vector3.new(0, height, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 200

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = billboard

	billboard.Parent = parent
end

local function disableOtherSpawns(keep: SpawnLocation)
	for _, instance in Workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") and instance ~= keep and instance.Enabled then
			instance.Enabled = false
			warn(`[DevMap] Disabled spawn {instance:GetFullName()} so players start in the Hatchery`)
		end
	end
end

function DevMap.Build(): Folder
	local map = Instance.new("Folder")
	map.Name = "Map"

	local width = Config.ZoneWidth
	local floorY = FLOOR_THICKNESS / 2
	local topY = FLOOR_THICKNESS
	local cursorZ = 0 -- the map grows toward -Z from here

	for index, zone in Config.Zones do
		local startZ = cursorZ
		local endZ = cursorZ - zone.Length
		local centerZ = (startZ + endZ) / 2

		local floor = makePart(
			`Zone{index}Floor`,
			Vector3.new(width, FLOOR_THICKNESS, zone.Length),
			CFrame.new(0, floorY, centerZ),
			zone.Color
		)
		floor.Material = Enum.Material.Slate
		floor:SetAttribute("ZoneIndex", index)
		CollectionService:AddTag(floor, "ZoneFloor")
		floor.Parent = map

		-- Name post just inside the zone, off to the right of the path.
		local post = makePart(
			`Zone{index}Post`,
			Vector3.new(1, 10, 1),
			CFrame.new(width / 2 - 4, topY + 5, startZ - 6),
			Color3.fromRGB(60, 60, 60)
		)
		makeSign(post, `{zone.Name}  x{zone.Multiplier}`, 6, 220)
		post.Parent = map

		-- Ice wall across the entrance of every zone after the first.
		if index > 1 then
			local wall = makePart(
				`IceWall{index}`,
				Vector3.new(width, Config.IceWallHeight, 3),
				CFrame.new(0, topY + Config.IceWallHeight / 2, startZ),
				Color3.fromRGB(150, 210, 255)
			)
			wall.Material = Enum.Material.Ice
			wall.Transparency = 0.3
			wall:SetAttribute("ZoneIndex", index)
			wall:SetAttribute("RequiredFire", zone.RequiredFire)
			CollectionService:AddTag(wall, "IceWall")
			makeSign(
				wall,
				`{zone.Name}\nNeeds {Format.Short(zone.RequiredFire)} Fire`,
				Config.IceWallHeight / 2 + 3,
				260
			)
			wall.Parent = map
		end

		cursorZ = endZ
	end

	local totalLength = -cursorZ
	local centerZ = -totalLength / 2

	-- Invisible rails so nobody walks off the sides or the far end.
	for _, side in { -1, 1 } do
		local rail = makePart(
			"Rail",
			Vector3.new(1, SIDE_WALL_HEIGHT, totalLength),
			CFrame.new(side * (width / 2 + 0.5), SIDE_WALL_HEIGHT / 2, centerZ),
			Color3.new(1, 1, 1)
		)
		rail.Transparency = 1
		rail.Parent = map
	end
	local endRail = makePart(
		"Rail",
		Vector3.new(width + 2, SIDE_WALL_HEIGHT, 1),
		CFrame.new(0, SIDE_WALL_HEIGHT / 2, -totalLength - 0.5),
		Color3.new(1, 1, 1)
	)
	endRail.Transparency = 1
	endRail.Parent = map

	-- Win pad at the end of the last zone. No logic yet; milestone 4 uses it.
	local pad = Instance.new("Part")
	pad.Name = "WinPad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(0.4, 12, 12)
	pad.CFrame = CFrame.new(0, topY + 0.2, -totalLength + 10) * CFrame.Angles(0, 0, math.rad(90))
	pad.Color = Color3.fromRGB(255, 200, 80)
	pad.Material = Enum.Material.Neon
	pad.Anchored = true
	CollectionService:AddTag(pad, "WinPad")
	pad.Parent = map

	-- Spawn at the start of the Hatchery.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, topY + 0.5, -10)
	spawn.Color = Color3.fromRGB(120, 200, 120)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	map.Parent = Workspace
	disableOtherSpawns(spawn)

	return map
end

return DevMap
