--!strict
-- Auto-breathing at training dummies. Every dummy (a Model or BasePart
-- tagged "TrainingDummy") has a pad in front of it: a descendant BasePart
-- named "Pad", whose footprint is the trigger. A player standing on a pad
-- trains on that dummy: every Config.TrainingTick seconds they gain a
-- click's worth of Fire at their current click value, times
-- Config.TrainingClicksPerTick, while the dummy's "Blaze" effects burn.
-- The client holds the dragon on the pad facing the dummy; Space lets go.
-- A dummy without a Pad falls back to Config.TrainingRadius around itself.
--
-- Player attributes, replicated for the HUD and the client:
--   Training        boolean, true while on a pad
--   TrainingSpot    Vector3, the pad centre to stand on
--   TrainingTarget  Vector3, the dummy to face

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ClickService = require(script.Parent.ClickService)
local StatService = require(script.Parent.StatService)

local TrainingService = {}

local TAG = "TrainingDummy"
local HEIGHT_ALLOWANCE = 30 -- a giant dragon's root sits well above the pad
local LEAVING_SPEED = 3 -- rising faster than this means the player is flying off

type Effect = Fire | PointLight
type Dummy = { Target: Vector3, Spot: Vector3, Radius: number, Effects: { Effect }, Lit: boolean }

local dummies: { [Instance]: Dummy } = {}

local function register(instance: Instance)
	if not (instance:IsA("Model") or instance:IsA("BasePart")) then
		return
	end
	local effects: { Effect } = {}
	local pad: BasePart? = nil
	for _, descendant in instance:GetDescendants() do
		local holder = descendant.Parent
		if (descendant:IsA("Fire") or descendant:IsA("PointLight")) and holder and holder.Name == "Blaze" then
			table.insert(effects, descendant)
		elseif descendant:IsA("BasePart") and descendant.Name == "Pad" then
			pad = descendant
		end
	end
	local target = instance:GetPivot().Position
	dummies[instance] = {
		Target = target,
		Spot = if pad then pad.Position else target,
		Radius = if pad then math.max(pad.Size.X, pad.Size.Z) / 2 else Config.TrainingRadius,
		Effects = effects,
		Lit = false,
	}
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

-- The dummy whose pad the player stands on, if any.
local function padUnder(position: Vector3): Dummy?
	local best: Dummy? = nil
	local bestDistance = math.huge
	for _, dummy in dummies do
		local delta = dummy.Spot - position
		if math.abs(delta.Y) > HEIGHT_ALLOWANCE then
			continue
		end
		local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
		if distance <= dummy.Radius and distance < bestDistance then
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
		local dummy: Dummy? = nil
		if root and root:IsA("BasePart") and alive and root.AssemblyLinearVelocity.Y < LEAVING_SPEED then
			dummy = padUnder(root.Position)
		end

		local training = dummy ~= nil
		if dummy then
			if player:GetAttribute("TrainingSpot") ~= dummy.Spot then
				player:SetAttribute("TrainingSpot", dummy.Spot)
				player:SetAttribute("TrainingTarget", dummy.Target)
			end
			active[dummy] = true
			StatService.AddFire(player, ClickService.GetClickValue(player) * Config.TrainingClicksPerTick)
		end
		if player:GetAttribute("Training") ~= training then
			player:SetAttribute("Training", training)
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
