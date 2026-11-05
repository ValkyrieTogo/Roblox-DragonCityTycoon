--!strict
-- Plays the fire breath effect from a character's mouth. Client only: the
-- server never touches effects, it just changes numbers. The burst grows with
-- the character so a hatchling puffs a spark and a titan floods the screen.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)
local Mouth = require(ReplicatedStorage.Shared.Mouth)

local FireEffects = {}

local BASE_PARTICLES = 10
local BASE_SPEED = 22
local BASE_PEAK_SIZE = 1.6
local GLOW_SECONDS = 0.12
local POPUP_SECONDS = 0.8

local function sizeFor(scale: number): NumberSequence
	local peak = BASE_PEAK_SIZE * scale
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, peak * 0.4),
		NumberSequenceKeypoint.new(0.4, peak),
		NumberSequenceKeypoint.new(1, peak * 0.12),
	})
end

local function flashGlow(mouth: Attachment, scale: number)
	local glow = mouth:FindFirstChild("Glow")
	if not glow or not glow:IsA("PointLight") then
		return
	end
	glow.Range = 12 * scale
	glow.Enabled = true
	task.delay(GLOW_SECONDS, function()
		glow.Enabled = false
	end)
end

local function showPopup(mouth: Attachment, amount: number, scale: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = mouth
	billboard.Size = UDim2.fromOffset(120, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2 * scale, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 170, 40)
	label.TextStrokeTransparency = 0.3
	label.Text = `+{Format.Short(amount)}`
	label.Parent = billboard

	billboard.Parent = mouth

	TweenService:Create(billboard, TweenInfo.new(POPUP_SECONDS, Enum.EasingStyle.Quad), {
		StudsOffsetWorldSpace = Vector3.new(0, 5 * scale, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(POPUP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(billboard, POPUP_SECONDS)
end

-- One breath from this character, worth `amount` Fire.
function FireEffects.Burst(character: Model, amount: number)
	local mouth = Mouth.Find(character)
	if not mouth then
		return
	end

	local scale = character:GetScale()

	local flame = mouth:FindFirstChild("Flame")
	if flame and flame:IsA("ParticleEmitter") then
		flame.Size = sizeFor(scale)
		flame.Speed = NumberRange.new(BASE_SPEED * scale * 0.8, BASE_SPEED * scale * 1.2)
		flame:Emit(math.floor(BASE_PARTICLES * scale))
	end

	flashGlow(mouth, scale)
	showPopup(mouth, amount, scale)
end

return FireEffects
