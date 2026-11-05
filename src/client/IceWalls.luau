--!strict
-- Melts ice walls for the local player once their Fire meets the wall's
-- requirement. The character's physics run on the client, so collision is
-- turned off here, locally only. This is cosmetic: the server grants the
-- zone multiplier by its own Fire check, so walking through early gains nothing.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local IceWalls = {}

local TAG = "IceWall"
local MELT_SECONDS = 1.2

local localPlayer = Players.LocalPlayer

local walls: { BasePart } = {}
local melted: { [BasePart]: boolean } = {}
local currentFire = 0

local function requiredFire(wall: BasePart): number
	local value = wall:GetAttribute("RequiredFire")
	return if typeof(value) == "number" then value else math.huge
end

local function melt(wall: BasePart)
	melted[wall] = true
	wall.CanCollide = false
	TweenService:Create(wall, TweenInfo.new(MELT_SECONDS, Enum.EasingStyle.Quad), {
		Transparency = 0.92,
	}):Play()

	local label = wall:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = "Melted"
		TweenService:Create(label, TweenInfo.new(MELT_SECONDS * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end
end

local function refresh()
	for _, wall in walls do
		if not melted[wall] and currentFire >= requiredFire(wall) then
			melt(wall)
		end
	end
end

local function addWall(instance: Instance)
	if instance:IsA("BasePart") then
		table.insert(walls, instance)
		refresh()
	end
end

local function removeWall(instance: Instance)
	local index = table.find(walls, instance :: any)
	if index then
		table.remove(walls, index)
	end
	melted[instance :: any] = nil
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
