--!strict
-- The few RemoteEvents the client and server share. The server creates them,
-- the client waits for them, so both sides use the same names.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local Remotes = {}

local function getFolder(): Folder
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing then
			return existing :: Folder
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function getEvent(name: string): RemoteEvent
	local folder = getFolder()
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing :: RemoteEvent
		end
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
		return event
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

-- Client -> server: one click. No arguments; the server decides what it is worth.
function Remotes.Click(): RemoteEvent
	return getEvent("Click")
end

-- Client -> server: buy one level of an upgrade. Argument: upgrade id (string).
function Remotes.BuyUpgrade(): RemoteEvent
	return getEvent("BuyUpgrade")
end

-- Server -> client: the player just won. Argument: total wins (number).
function Remotes.Won(): RemoteEvent
	return getEvent("Won")
end

return Remotes
