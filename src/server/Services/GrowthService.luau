--!strict
-- The player is the dragon. This dresses every character as one and scales the
-- whole character with the player's Fire. Scaling happens on the server so
-- every client sees the same size. Walk speed and jump grow with scale so a
-- big dragon still feels right to move.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonCostume = require(script.Parent.Parent.DragonCostume)
local StatService = require(script.Parent.StatService)

local GrowthService = {}

-- Ignore scale changes smaller than this to avoid needless rescaling per click.
local MIN_SCALE_STEP = 0.01

local function applyScale(character: Model, fire: number)
	local target = Config.DragonScale(fire)
	if math.abs(character:GetScale() - target) < MIN_SCALE_STEP then
		return
	end

	local ok, err = pcall(function()
		character:ScaleTo(target)
	end)
	if not ok then
		warn(`[GrowthService] ScaleTo failed for {character.Name}: {err}`)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.BaseWalkSpeed * target ^ 0.5
		if humanoid.UseJumpPower then
			humanoid.JumpPower = Config.BaseJumpPower * target ^ 0.5
		else
			humanoid.JumpHeight = Config.BaseJumpHeight * target
		end
	end
end

local function onCharacter(player: Player, character: Model)
	-- Wait for the rig so the costume has parts to weld to.
	local humanoid = character:WaitForChild("Humanoid", 10)
	local head = character:WaitForChild("Head", 10)
	if not humanoid or not head then
		return
	end

	DragonCostume.Dress(character)
	applyScale(character, StatService.GetFire(player))

	local connection = StatService.OnFireChanged(player, function(fire)
		if character.Parent then
			applyScale(character, fire)
		end
	end)

	player.CharacterRemoving:Once(function()
		if connection then
			connection:Disconnect()
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

function GrowthService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return GrowthService
