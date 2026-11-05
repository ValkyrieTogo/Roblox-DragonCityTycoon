--!strict
-- NPC dragons. Every part tagged "NpcSpawn" gets a dragon built from the R6
-- rig and dressed with the DragonCostume, standing where the spawn faces.
-- Attributes on the spawn: Role ("Trainer" or "Villager"), ZoneIndex and
-- Seat (which villager). Trainers stand still, turn toward nearby players
-- and breathe fire at their dummies now and then. Villagers are small
-- hatchlings that wander around their spawn. All NPCs cycle through their
-- lines in a speech bubble; a Talk prompt skips to the next line.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local DragonCostume = require(script.Parent.Parent.DragonCostume)
local Rig = require(script.Parent.Parent.Npc.Rig)

local NpcService = {}

local TAG = "NpcSpawn"
local TURN_RATE = 4
local WANDER_RADIUS = 22
local VILLAGER_SCALE = 0.75
local BREATH_SECONDS = 0.5

type Npc = {
	Model: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Role: string,
	Home: CFrame,
	Lines: { string },
	LineIndex: number,
	Bubble: TextLabel,
	Walk: AnimationTrack?,
	NextLine: number,
	NextMove: number,
	NextBreath: number,
}

local npcs: { [BasePart]: Npc } = {}
local rng = Random.new(Config.MapSeed + 1)
local folder: Folder? = nil

local PALETTES: { Rig.Palette } = {
	{ Skin = Color3.fromRGB(190, 60, 50), Shirt = Color3.fromRGB(70, 40, 40), Pants = Color3.fromRGB(50, 30, 30) },
	{ Skin = Color3.fromRGB(80, 140, 90), Shirt = Color3.fromRGB(40, 70, 50), Pants = Color3.fromRGB(35, 50, 40) },
	{ Skin = Color3.fromRGB(70, 110, 190), Shirt = Color3.fromRGB(40, 50, 90), Pants = Color3.fromRGB(30, 35, 60) },
	{ Skin = Color3.fromRGB(220, 170, 60), Shirt = Color3.fromRGB(110, 80, 30), Pants = Color3.fromRGB(70, 50, 25) },
	{ Skin = Color3.fromRGB(150, 80, 180), Shirt = Color3.fromRGB(70, 40, 90), Pants = Color3.fromRGB(45, 30, 60) },
}

local function numberAttribute(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function speechFor(role: string, zoneIndex: number, seat: number): Config.NpcSpeech
	if role == "Trainer" then
		local zone = Config.Zones[zoneIndex]
		local speech = if zone then Config.Trainers[zone.Name] else nil
		if speech then
			return speech
		end
		return { Name = "Trainer", Lines = { "Breathe on the dummies to train." } }
	end
	local count = #Config.Villagers
	return Config.Villagers[((seat - 1) % count) + 1]
end

local function makeBubble(head: BasePart, name: string): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Speech"
	billboard.Size = UDim2.fromOffset(260, 90)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.MaxDistance = 70
	billboard.LightInfluence = 0

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextSize = 20
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 90)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Text = name
	nameLabel.Parent = billboard

	local bubble = Instance.new("TextLabel")
	bubble.Name = "Line"
	bubble.Size = UDim2.new(1, 0, 0, 56)
	bubble.Position = UDim2.fromOffset(0, 28)
	bubble.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	bubble.BackgroundTransparency = 0.25
	bubble.Font = Enum.Font.GothamMedium
	bubble.TextSize = 16
	bubble.TextWrapped = true
	bubble.TextColor3 = Color3.new(1, 1, 1)
	bubble.Text = ""
	bubble.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bubble
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = bubble

	billboard.Parent = head
	return bubble
end

local function sayNext(npc: Npc)
	npc.LineIndex = (npc.LineIndex % #npc.Lines) + 1
	npc.Bubble.Text = npc.Lines[npc.LineIndex]
	npc.NextLine = os.clock() + Config.NpcLineSeconds
end

local function flameOf(model: Model): ParticleEmitter?
	local head = model:FindFirstChild("Head")
	local mouth = if head then head:FindFirstChild("Mouth") else nil
	local flame = if mouth then mouth:FindFirstChild("Flame") else nil
	return if flame and flame:IsA("ParticleEmitter") then flame else nil
end

local function breathe(npc: Npc)
	local flame = flameOf(npc.Model)
	if not flame then
		return
	end
	-- Rate replicates, Emit does not, so pulse the rate for a moment.
	flame.Rate = 60
	task.delay(BREATH_SECONDS, function()
		flame.Rate = 0
	end)
end

local function nearestPlayerPosition(from: Vector3, within: number): Vector3?
	local best: Vector3? = nil
	local bestDistance = within
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			local distance = (root.Position - from).Magnitude
			if distance < bestDistance then
				best = root.Position
				bestDistance = distance
			end
		end
	end
	return best
end

local function spawnNpc(spawn: Instance)
	if not spawn:IsA("BasePart") or npcs[spawn] then
		return
	end
	local role = tostring(spawn:GetAttribute("Role") or "Villager")
	local zoneIndex = numberAttribute(spawn, "ZoneIndex", 1)
	local seat = numberAttribute(spawn, "Seat", 1)
	local speech = speechFor(role, zoneIndex, seat)

	local paletteIndex = if role == "Trainer" then ((zoneIndex - 1) % #PALETTES) + 1 else ((seat + 1) % #PALETTES) + 1
	local model = Rig.Create(speech.Name, PALETTES[paletteIndex])
	local root = model.PrimaryPart :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local head = model:FindFirstChild("Head") :: BasePart

	-- The spawn's CFrame is at ground + 1 looking where the NPC should face.
	local look = spawn.CFrame.LookVector
	local feet = spawn.Position - Vector3.new(0, 1, 0)
	local home = CFrame.lookAt(feet, feet + Vector3.new(look.X, 0, look.Z))
	model:PivotTo(home * CFrame.new(0, 3, 0))
	humanoid.WalkSpeed = Config.NpcWalkSpeed
	humanoid.DisplayName = speech.Name

	if role == "Trainer" then
		root.Anchored = true
	end

	model.Parent = folder
	DragonCostume.Dress(model)
	if role ~= "Trainer" then
		model:ScaleTo(VILLAGER_SCALE)
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
	end
	local _, walk = Rig.Animate(model)

	local npc: Npc = {
		Model = model,
		Root = root,
		Humanoid = humanoid,
		Role = role,
		Home = home,
		Lines = speech.Lines,
		LineIndex = 0,
		Bubble = makeBubble(head, speech.Name),
		Walk = walk,
		NextLine = 0,
		NextMove = os.clock() + rng:NextNumber(1, 4),
		NextBreath = os.clock() + rng:NextNumber(2, Config.NpcBreathSeconds),
	}
	npcs[spawn] = npc
	sayNext(npc)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = speech.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function()
		sayNext(npc)
	end)

	if walk then
		humanoid.Running:Connect(function(speed)
			if speed > 0.5 then
				if not walk.IsPlaying then
					walk:Play()
				end
			elseif walk.IsPlaying then
				walk:Stop()
			end
		end)
	end
end

local function despawn(spawn: Instance)
	local npc = if spawn:IsA("BasePart") then npcs[spawn] else nil
	if npc then
		npc.Model:Destroy()
		npcs[spawn :: BasePart] = nil
	end
end

local function updateTrainer(npc: Npc, dt: number, now: number)
	local position = npc.Root.Position
	local playerPosition = nearestPlayerPosition(position, Config.NpcTurnRadius)
	local goal: CFrame
	if playerPosition then
		goal = CFrame.lookAt(position, Vector3.new(playerPosition.X, position.Y, playerPosition.Z))
	else
		goal = CFrame.lookAt(position, position + npc.Home.LookVector)
	end
	npc.Root.CFrame = npc.Root.CFrame:Lerp(goal, math.min(dt * TURN_RATE, 1))

	if now >= npc.NextBreath and not playerPosition then
		breathe(npc)
		npc.NextBreath = now + Config.NpcBreathSeconds + rng:NextNumber(0, 3)
	end
end

local function updateVillager(npc: Npc, now: number)
	if now < npc.NextMove then
		return
	end
	local angle = rng:NextNumber(0, math.pi * 2)
	local distance = rng:NextNumber(6, WANDER_RADIUS)
	local goal = npc.Home.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
	npc.Humanoid:MoveTo(goal)
	npc.NextMove = now + rng:NextNumber(4, 9)
end

local function update(dt: number)
	local now = os.clock()
	for _, npc in npcs do
		if now >= npc.NextLine then
			sayNext(npc)
		end
		if npc.Role == "Trainer" then
			updateTrainer(npc, dt, now)
		else
			updateVillager(npc, now)
		end
	end
end

function NpcService.Init()
	local existing = Workspace:FindFirstChild("Npcs")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		local created = Instance.new("Folder")
		created.Name = "Npcs"
		created.Parent = Workspace
		folder = created
	end

	for _, spawn in CollectionService:GetTagged(TAG) do
		spawnNpc(spawn)
	end
	-- The map dresses itself in the background, so spawns keep arriving.
	CollectionService:GetInstanceAddedSignal(TAG):Connect(spawnNpc)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(despawn)

	RunService.Heartbeat:Connect(update)
end

return NpcService
