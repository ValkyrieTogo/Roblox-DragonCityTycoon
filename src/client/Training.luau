--!strict
-- Presentation of training. The server sets the Training attribute while
-- the local player stands on a dummy's pad, with TrainingSpot and
-- TrainingTarget saying where. This snaps the dragon to the pad centre
-- facing the dummy, holds it there, and plays a breath with the predicted
-- Fire every tick, in step with the server's awards. Space (flight) lets go.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local FireEffects = require(script.Parent.FireEffects)

local Training = {}

local localPlayer = Players.LocalPlayer

local active = false
local held = false -- the root is anchored on the pad

local function numberAttribute(name: string, default: number): number
	local value = localPlayer:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function vectorAttribute(name: string): Vector3?
	local value = localPlayer:GetAttribute(name)
	return if typeof(value) == "Vector3" then value else nil
end

-- Mirrors ClickService.GetClickValue times the clicks per training tick.
local function predictedValue(): number
	local perClick = numberAttribute("FirePerClick", Config.BaseFirePerClick)
	local zone = numberAttribute("ZoneMultiplier", 1)
	local wins = numberAttribute("WinMultiplier", 1)
	return math.floor(perClick * zone * wins) * Config.TrainingClicksPerTick
end

local function character(): (Model?, BasePart?, Humanoid?)
	local model = localPlayer.Character
	if not model then
		return nil, nil, nil
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return model, if root and root:IsA("BasePart") then root else nil, humanoid
end

-- Stands the dragon on the pad centre, facing the dummy, and anchors it.
local function hold()
	local _, root, humanoid = character()
	local spot = vectorAttribute("TrainingSpot")
	local target = vectorAttribute("TrainingTarget")
	if not root or not humanoid or not spot or not target then
		return
	end
	local position = Vector3.new(spot.X, root.Position.Y, spot.Z)
	local look = Vector3.new(target.X, position.Y, target.Z)
	if (look - position).Magnitude > 0.5 then
		root.CFrame = CFrame.lookAt(position, look)
	else
		root.CFrame = CFrame.new(position) * root.CFrame.Rotation
	end
	root.AssemblyLinearVelocity = Vector3.zero
	humanoid.AutoRotate = false
	root.Anchored = true
	held = true
end

-- Lets the dragon move again. Called when training ends and before flight.
function Training.Release()
	if not held then
		return
	end
	held = false
	local _, root, humanoid = character()
	if root then
		root.Anchored = false
	end
	if humanoid then
		humanoid.AutoRotate = true
	end
end

local function breathLoop()
	while active do
		local model = character()
		if model and held then
			FireEffects.Burst(model, predictedValue())
		end
		task.wait(Config.TrainingTick)
	end
end

local function update()
	local now = localPlayer:GetAttribute("Training") == true
	if now == active then
		return
	end
	active = now
	if active then
		hold()
		task.spawn(breathLoop)
	else
		Training.Release()
	end
end

function Training.Init()
	localPlayer:GetAttributeChangedSignal("Training"):Connect(update)
	localPlayer.CharacterAdded:Connect(function()
		-- A fresh character is free; the server will re-flag training.
		active = false
		held = false
	end)
	update()
end

return Training
