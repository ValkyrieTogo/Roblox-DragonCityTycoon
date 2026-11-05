--!strict
-- Pushes the camera out as the local dragon grows so it never fills the
-- screen. The zoom limits are multiplied by the same scale curve the server
-- uses, computed here from the replicated Fire value.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraScale = {}

local localPlayer = Players.LocalPlayer

local function apply(fire: number)
	local scale = Config.DragonScale(fire)
	localPlayer.CameraMinZoomDistance = Config.CameraMinZoom * scale
	localPlayer.CameraMaxZoomDistance = Config.CameraMaxZoom * scale
end

function CameraScale.Init()
	apply(0)
	task.spawn(function()
		local leaderstats = localPlayer:WaitForChild("leaderstats", 30)
		local fire = if leaderstats then leaderstats:WaitForChild("Fire", 30) else nil
		if fire and fire:IsA("IntValue") then
			apply(fire.Value)
			fire.Changed:Connect(apply)
			-- Respawning resets the camera, so apply again for each character.
			localPlayer.CharacterAdded:Connect(function()
				apply(fire.Value)
			end)
		end
	end)
end

return CameraScale
