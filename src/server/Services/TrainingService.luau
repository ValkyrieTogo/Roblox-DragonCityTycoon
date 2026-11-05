--!strict
-- Auto-breathing. A player standing near a training dummy breathes on it
-- without clicking: every Config.TrainingTick seconds they gain a click's
-- worth of Fire, at their current click value, times
-- Config.TrainingClicksPerTick. Server-authoritative: the client only
-- decorates. Dummies are any Model or BasePart tagged "TrainingDummy"; a
-- descendant named "Blaze" holding a Fire and PointLight is lit while
-- someone trains on it.
--
-- Player attribute, replicated for the HUD and the breath effect:
--   Training  boolean, true while standing at a dummy

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ClickService = require(script.Parent.ClickService)
local StatService = require(script.Parent.StatService)

local TrainingService = {}

local TAG = "TrainingDummy"
local HEIGHT_ALLOWANCE = 14

type Effect = Fire | PointLight
type Dummy = { Position: Vector3, Effects: { Effect }, Lit: boolean }

local dummies: { [Instance]: Dummy } = {}

local function register(instance: Instance)
	if not (instance:IsA("Model") or instance:IsA("BasePart")) then
		return
	end
	local effects: { Effect } = {}
	for _, descendant in instance:GetDescendants() do
		local holder = descendant.Parent
		if (descendant:IsA("Fire") or descendant:IsA("PointLight")) and holder and holder.Name == "Blaze" then
			table.insert(effects, descendant)
		end
	end
	dummies[instance] = { Position = instance:GetPivot().Position, Effects = effects, Lit = false }
end

local function unregister(instance: Instance)
	dummies[instance] = nil
end

local function setLit(dummy: Dummy, lit: boolean)
	if dummy.Lit == lit then
		return
	end
	dummy.Lit = lit
	for _, effect in dummy.Effects do
		if effect:IsA("Fire") then
			effect.Enabled = lit
		else
			(effect :: PointLight).Enabled = lit
		end
	end
end

local function nearestDummy(position: Vector3): Dummy?
	local best: Dummy? = nil
	local bestDistance = Config.TrainingRadius
	for _, dummy in dummies do
		local delta = dummy.Position - position
		if math.abs(delta.Y) > HEIGHT_ALLOWANCE then
			continue
		end
		local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
		if distance < bestDistance then
			best = dummy
			bestDistance = distance
		end
	end
	return best
end

local function tick()
	local active: { [Dummy]: boolean } = {}

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local alive = humanoid ~= nil and humanoid.Health > 0
		local dummy = if root and root:IsA("BasePart") and alive then nearestDummy(root.Position) else nil

		local training = dummy ~= nil
		if player:GetAttribute("Training") ~= training then
			player:SetAttribute("Training", training)
		end
		if dummy then
			active[dummy] = true
			StatService.AddFire(player, ClickService.GetClickValue(player) * Config.TrainingClicksPerTick)
		end
	end

	for _, dummy in dummies do
		setLit(dummy, active[dummy] == true)
	end
end

function TrainingService.Init()
	for _, instance in CollectionService:GetTagged(TAG) do
		register(instance)
	end
	-- The map dresses itself in the background, so dummies keep arriving.
	CollectionService:GetInstanceAddedSignal(TAG):Connect(register)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(unregister)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("Training", false)
	end)

	task.spawn(function()
		while true do
			task.wait(Config.TrainingTick)
			tick()
		end
	end)
end

return TrainingService
