--!strict
-- Presentation of auto-breathing. The server sets the Training attribute
-- while the local player stands at a dummy; this turns the dragon to face
-- the nearest dummy when standing still and plays a breath with the
-- predicted Fire every tick, in step with the server's awards.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local FireEffects = require(script.Parent.FireEffects)

local Training = {}

local TAG = "TrainingDummy"
local TURN_RATE = 10 -- how quickly the dragon turns toward the dummy

local localPlayer = Players.LocalPlayer

local active = false
local target: Vector3? = nil

local function numberAttribute(name: string, default: number): number
	local value = localPlayer:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- Mirrors ClickService.GetClickValue times the clicks per training tick.
local function predictedValue(): number
	local perClick = numberAttribute("FirePerClick", Config.BaseFirePerClick)
	local zone = numberAttribute("ZoneMultiplier", 1)
	local wins = numberAttribute("WinMultiplier", 1)
	return math.floor(perClick * zone * wins) * Config.TrainingClicksPerTick
end

local function nearestDummy(from: Vector3): Vector3?
	local best: Vector3? = nil
	local bestDistance = math.huge
	for _, instance in CollectionService:GetTagged(TAG) do
		if not (instance:IsA("Model") or instance:IsA("BasePart")) then
			continue
		end
		local position = instance:GetPivot().Position
		local distance = (position - from).Magnitude
		if distance < bestDistance then
			best = position
			bestDistance = distance
		end
	end
	return best
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

local function setAutoRotate(enabled: boolean)
	local _, _, humanoid = character()
	if humanoid then
		humanoid.AutoRotate = enabled
	end
end

-- Turns the dragon toward the dummy while it stands still, so the breath
-- lands on the target instead of wherever it was last walking.
local function faceTarget(dt: number)
	local _, root, humanoid = character()
	if not root or not humanoid or not target or humanoid.MoveDirection.Magnitude > 0 then
		return
	end
	local position = root.Position
	local look = Vector3.new(target.X, position.Y, target.Z)
	if (look - position).Magnitude < 0.5 then
		return
	end
	local goal = CFrame.lookAt(position, look)
	root.CFrame = root.CFrame:Lerp(goal, math.min(dt * TURN_RATE, 1))
end

local function breathLoop()
	while active do
		local model, root = character()
		if model and root then
			target = nearestDummy(root.Position)
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
		setAutoRotate(false)
		task.spawn(breathLoop)
	else
		target = nil
		setAutoRotate(true)
	end
end

function Training.Init()
	localPlayer:GetAttributeChangedSignal("Training"):Connect(update)
	localPlayer.CharacterAdded:Connect(function()
		-- A fresh character has AutoRotate on; the server will re-flag training.
		active = false
		target = nil
	end)
	RunService.Heartbeat:Connect(function(dt)
		if active then
			faceTarget(dt)
		end
	end)
	update()
end

return Training
