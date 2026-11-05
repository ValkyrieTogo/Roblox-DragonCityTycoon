--!strict
-- Portals move a character between the town and the arena. Any BasePart
-- tagged "Portal" with a string attribute Destination teleports a touching
-- player to the BasePart tagged "PortalArrival" whose Name attribute matches,
-- standing where that pad faces. A short cooldown stops bouncing between a
-- portal and a pad placed close together.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local PortalService = {}

local PORTAL_TAG = "Portal"
local ARRIVAL_TAG = "PortalArrival"
local COOLDOWN = 2

local arrivals: { [string]: CFrame } = {}
local lastUse: { [Player]: number } = {}

local function registerArrival(instance: Instance)
	local name = instance:GetAttribute("Name")
	if instance:IsA("BasePart") and typeof(name) == "string" then
		local position = instance.Position
		local look = instance.CFrame.LookVector
		arrivals[name] = CFrame.lookAt(position, position + Vector3.new(look.X, 0, look.Z))
	end
end

local function teleport(player: Player, destination: string)
	local arrival = arrivals[destination]
	local character = player.Character
	if not arrival or not character then
		return
	end
	local now = os.clock()
	if now - (lastUse[player] or 0) < COOLDOWN then
		return
	end
	lastUse[player] = now
	local height = 2.5 * character:GetScale() + 1
	character:PivotTo(arrival * CFrame.new(0, height, 0))
end

local function registerPortal(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	instance.Touched:Connect(function(hit)
		local destination = instance:GetAttribute("Destination")
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if player and typeof(destination) == "string" then
			teleport(player, destination)
		end
	end)
end

-- Sends a player to a named arrival pad, for other services.
function PortalService.Send(player: Player, destination: string)
	teleport(player, destination)
end

function PortalService.Init()
	for _, instance in CollectionService:GetTagged(ARRIVAL_TAG) do
		registerArrival(instance)
	end
	for _, instance in CollectionService:GetTagged(PORTAL_TAG) do
		registerPortal(instance)
	end
	-- The map dresses itself in the background, so these keep arriving.
	CollectionService:GetInstanceAddedSignal(ARRIVAL_TAG):Connect(registerArrival)
	CollectionService:GetInstanceAddedSignal(PORTAL_TAG):Connect(registerPortal)
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return PortalService
