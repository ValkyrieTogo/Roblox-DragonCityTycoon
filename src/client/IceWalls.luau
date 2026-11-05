--!strict
-- Melts ice walls for the local player once their Fire meets the wall's
-- requirement, and freezes them again when Fire drops below it (after a win).
-- The character's physics run on the client, so collision is changed here,
-- locally only. This is cosmetic: the server grants the zone multiplier by its
-- own Fire check, so walking through early gains nothing.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local IceWalls = {}

local TAG = "IceWall"
local MELT_SECONDS = 1.2
local FROZEN_TRANSPARENCY = 0.3
local MELTED_TRANSPARENCY = 0.92

local localPlayer = Players.LocalPlayer

type WallState = { Part: BasePart, Melted: boolean, SignText: string }

local walls: { WallState } = {}
local currentFire = 0

local function requiredFire(wall: BasePart): number
	local value = wall:GetAttribute("RequiredFire")
	return if typeof(value) == "number" then value else math.huge
end

local function findLabel(wall: BasePart): TextLabel?
	local label = wall:FindFirstChild("Label", true)
	return if label and label:IsA("TextLabel") then label else nil
end

local function melt(state: WallState)
	state.Melted = true
	state.Part.CanCollide = false
	TweenService:Create(state.Part, TweenInfo.new(MELT_SECONDS, Enum.EasingStyle.Quad), {
		Transparency = MELTED_TRANSPARENCY,
	}):Play()

	local label = findLabel(state.Part)
	if label then
		label.Text = "Melted"
		TweenService:Create(label, TweenInfo.new(MELT_SECONDS * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end
end

local function freeze(state: WallState)
	state.Melted = false
	state.Part.CanCollide = true
	TweenService:Create(state.Part, TweenInfo.new(MELT_SECONDS, Enum.EasingStyle.Quad), {
		Transparency = FROZEN_TRANSPARENCY,
	}):Play()

	local label = findLabel(state.Part)
	if label then
		label.Text = state.SignText
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.3
	end
end

local function refresh()
	for _, state in walls do
		local qualifies = currentFire >= requiredFire(state.Part)
		if qualifies and not state.Melted then
			melt(state)
		elseif not qualifies and state.Melted then
			freeze(state)
		end
	end
end

local function addWall(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local label = findLabel(instance)
	table.insert(walls, {
		Part = instance,
		Melted = false,
		SignText = if label then label.Text else "",
	})
	refresh()
end

local function removeWall(instance: Instance)
	for index, state in walls do
		if state.Part == instance then
			table.remove(walls, index)
			return
		end
	end
end

function IceWalls.Init()
	for _, instance in CollectionService:GetTagged(TAG) do
		addWall(instance)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(addWall)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(removeWall)

	task.spawn(function()
		local leaderstats = localPlayer:WaitForChild("leaderstats", 30)
		local fire = if leaderstats then leaderstats:WaitForChild("Fire", 30) else nil
		if fire and fire:IsA("IntValue") then
			currentFire = fire.Value
			refresh()
			fire.Changed:Connect(function(value)
				currentFire = value
				refresh()
			end)
		end
	end)
end

return IceWalls
