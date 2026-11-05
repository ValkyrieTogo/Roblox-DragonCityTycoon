--!strict
-- Pushes the camera out as the local dragon grows so it never fills the
-- screen. The zoom limits follow the character's actual scale (which the
-- server changes in steps) and glide to the new value instead of snapping.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraScale = {}

local GLIDE_SPEED = 3 -- fraction of the remaining distance closed per second, roughly

local localPlayer = Players.LocalPlayer

local currentScale = 1

local function targetScale(): number
	local character = localPlayer.Character
	return if character then character:GetScale() else 1
end

function CameraScale.Init()
	localPlayer.CameraMinZoomDistance = Config.CameraMinZoom
	localPlayer.CameraMaxZoomDistance = Config.CameraMaxZoom

	RunService.RenderStepped:Connect(function(dt)
		local target = targetScale()
		if math.abs(target - currentScale) < 0.001 then
			return
		end
		-- Exponential ease toward the target; frame rate independent.
		local alpha = 1 - math.exp(-GLIDE_SPEED * dt)
		currentScale += (target - currentScale) * alpha
		localPlayer.CameraMinZoomDistance = Config.CameraMinZoom * currentScale
		localPlayer.CameraMaxZoomDistance = Config.CameraMaxZoom * currentScale
	end)
end

return CameraScale
