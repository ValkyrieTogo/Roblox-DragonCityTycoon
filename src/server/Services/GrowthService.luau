--!strict
-- The player is the dragon. This dresses every character as one and scales the
-- whole character with the player's Fire. Scaling happens on the server so
-- every client sees the same size. Walk speed and jump grow with scale so a
-- big dragon still feels right to move.
--
-- Rescaling a live character causes a small physics hitch, so growth is
-- stepped (Config.DragonScaleStep) and rate limited (Config.DragonScaleInterval)
-- instead of happening on every click.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonCostume = require(script.Parent.Parent.DragonCostume)
local StatService = require(script.Parent.StatService)

local GrowthService = {}

type Growth = {
	Character: Model,
	LastApplied: number, -- os.clock() of the last rescale
	Pending: boolean, -- a delayed rescale is already scheduled
	TargetFire: number,
}

local growths: { [Player]: Growth } = {}

local function applyScale(character: Model, fire: number)
	local target = Config.DragonScale(fire)
	if math.abs(character:GetScale() - target) < Config.DragonScaleStep / 2 then
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

-- Applies now if the interval has passed, otherwise schedules one apply for
-- when it has. Many Fire changes in that window collapse into one rescale.
local function requestScale(player: Player, fire: number)
	local growth = growths[player]
	if not growth then
		return
	end
	growth.TargetFire = fire

	local now = os.clock()
	local wait = Config.DragonScaleInterval - (now - growth.LastApplied)
	if wait <= 0 then
		growth.LastApplied = now
		applyScale(growth.Character, fire)
		return
	end

	if growth.Pending then
		return
	end
	growth.Pending = true
	task.delay(wait, function()
		local current = growths[player]
		if current ~= growth then
			return -- character changed meanwhile
		end
		growth.Pending = false
		growth.LastApplied = os.clock()
		if growth.Character.Parent then
			applyScale(growth.Character, growth.TargetFire)
		end
	end)
end

local function onCharacter(player: Player, character: Model)
	-- Wait for the rig so the costume has parts to weld to.
	local humanoid = character:WaitForChild("Humanoid", 10)
	local head = character:WaitForChild("Head", 10)
	if not humanoid or not head then
		return
	end

	DragonCostume.Dress(character)

	growths[player] = {
		Character = character,
		LastApplied = 0,
		Pending = false,
		TargetFire = StatService.GetFire(player),
	}
	requestScale(player, StatService.GetFire(player))

	local connection = StatService.OnFireChanged(player, function(fire)
		requestScale(player, fire)
	end)

	player.CharacterRemoving:Once(function()
		if connection then
			connection:Disconnect()
		end
		if growths[player] and growths[player].Character == character then
			growths[player] = nil
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
	Players.PlayerRemoving:Connect(function(player)
		growths[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return GrowthService
