--!strict
-- The few RemoteEvents the client and server share. The server creates them,
-- the client waits for them, so both sides use the same names.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local Remotes = {}

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local function getEvent(name: string): RemoteEvent
	local folder = getFolder()
	if RunService:IsServer() then
		local event = folder:FindFirstChild(name)
		if not event then
			event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = folder
		end
		return event :: RemoteEvent
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

-- Client -> server: one click. No arguments; the server decides what it is worth.
function Remotes.Click(): RemoteEvent
	return getEvent("Click")
end

return Remotes
