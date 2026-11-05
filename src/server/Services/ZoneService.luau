--!strict
-- Tracks which zone each player stands in and what their clicks are worth
-- there. Zones are found by tag so a Studio-built map works the same as the
-- placeholder. The multiplier is granted only when the player has the zone's
-- RequiredFire: an exploiter who walks through an ice wall locally still
-- clicks at x1, because this check is the one that matters.
--
-- Attributes set on the player, replicated for the HUD and click prediction:
--   ZoneIndex       number, 0 when outside every zone
--   ZoneName        string
--   ZoneMultiplier  number, the effective multiplier (1 when not qualified)

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.Parent.Parent.MapGen.Builder)
local StatService = require(script.Parent.StatService)

local ZoneService = {}

local SCAN_INTERVAL = 0.2 -- seconds between position checks
local HEIGHT_ALLOWANCE = 160 -- how far above a floor a player still counts as in the zone (volcano top)

type ZoneBox = { Index: number, Min: Vector3, Max: Vector3 }

local boxes: { ZoneBox } = {}

local function ensureMap()
	local existing = Workspace:FindFirstChild("Map")
	if existing then
		return
	end
	print("[ZoneService] No Map folder in Workspace, building the code-generated map")
	MapBuilder.Build()
end

local function collectZones()
	boxes = {}
	for _, part in CollectionService:GetTagged("ZoneFloor") do
		local index = part:GetAttribute("ZoneIndex")
		if part:IsA("BasePart") and typeof(index) == "number" then
			local half = part.Size / 2
			table.insert(boxes, {
				Index = index,
				Min = part.Position - half,
				Max = part.Position + half,
			})
		end
	end
	print(`[ZoneService] Found {#boxes} zone floors`)
end

local function zoneIndexAt(position: Vector3): number
	for _, box in boxes do
		if
			position.X >= box.Min.X
			and position.X <= box.Max.X
			and position.Z >= box.Min.Z
			and position.Z <= box.Max.Z
			and position.Y >= box.Min.Y
			and position.Y <= box.Max.Y + HEIGHT_ALLOWANCE
		then
			return box.Index
		end
	end
	return 0
end

local function updatePlayer(player: Player)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return
	end

	local index = zoneIndexAt(root.Position)
	local zone = Config.Zones[index]
	local name = if zone then zone.Name else ""
	local multiplier = 1
	if zone and StatService.GetFire(player) >= zone.RequiredFire then
		multiplier = zone.Multiplier
	end

	if player:GetAttribute("ZoneIndex") ~= index then
		player:SetAttribute("ZoneIndex", index)
		player:SetAttribute("ZoneName", name)
	end
	if player:GetAttribute("ZoneMultiplier") ~= multiplier then
		player:SetAttribute("ZoneMultiplier", multiplier)
	end
end

-- Effective click multiplier for the zone the player is in right now.
function ZoneService.GetMultiplier(player: Player): number
	local value = player:GetAttribute("ZoneMultiplier")
	return if typeof(value) == "number" then value else 1
end

function ZoneService.GetZoneIndex(player: Player): number
	local value = player:GetAttribute("ZoneIndex")
	return if typeof(value) == "number" then value else 0
end

function ZoneService.Init()
	ensureMap()
	collectZones()
	CollectionService:GetInstanceAddedSignal("ZoneFloor"):Connect(collectZones)
	CollectionService:GetInstanceRemovedSignal("ZoneFloor"):Connect(collectZones)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < SCAN_INTERVAL then
			return
		end
		elapsed = 0
		for _, player in Players:GetPlayers() do
			updatePlayer(player)
		end
	end)
end

return ZoneService
