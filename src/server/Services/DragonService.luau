--!strict
-- Gives every character a dragon welded beside it and scales the dragon with
-- the player's Fire. Scaling happens on the server so every client sees the
-- same size.
--
-- Studio setup (optional, a placeholder is generated when missing):
--   ServerStorage.Dragon   the dragon model, see DevDragon for required children

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DevDragon = require(script.Parent.Parent.DevDragon)
local StatService = require(script.Parent.StatService)

local DragonService = {}

-- Where the dragon floats relative to the character root, before scaling.
local DRAGON_OFFSET = CFrame.new(3.2, 2.5, 0.5)
-- Ignore scale changes smaller than this to avoid needless rescaling per click.
local MIN_SCALE_STEP = 0.01

local template: Model

local function getTemplate(): Model
	local existing = ServerStorage:FindFirstChild("Dragon")
	if existing and existing:IsA("Model") then
		return existing
	end

	warn("[DragonService] No Dragon model in ServerStorage, using the code-built placeholder")
	local built = DevDragon.Build()
	built.Parent = ServerStorage
	return built
end

local function applyScale(dragon: Model, fire: number)
	local target = Config.DragonScale(fire)
	if math.abs(dragon:GetScale() - target) < MIN_SCALE_STEP then
		return
	end
	dragon:ScaleTo(target)
end

local function attachDragon(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") then
		return
	end

	local dragon = template:Clone()
	local body = dragon.PrimaryPart
	if not body then
		warn("[DragonService] Dragon template has no PrimaryPart")
		dragon:Destroy()
		return
	end

	-- A Weld (not a WeldConstraint) so ScaleTo also scales the offset from the
	-- player, pushing a bigger dragon further out instead of into the character.
	local weld = Instance.new("Weld")
	weld.Name = "RootWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.C0 = DRAGON_OFFSET
	weld.Parent = body

	dragon:PivotTo(root.CFrame * DRAGON_OFFSET)
	dragon.Parent = character

	applyScale(dragon, StatService.GetFire(player))

	local connection = StatService.OnFireChanged(player, function(fire)
		if dragon.Parent then
			applyScale(dragon, fire)
		end
	end)

	dragon.Destroying:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		attachDragon(player, character)
	end)
	if player.Character then
		attachDragon(player, player.Character)
	end
end

function DragonService.Init()
	template = getTemplate()

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return DragonService
