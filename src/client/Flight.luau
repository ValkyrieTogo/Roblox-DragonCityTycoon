--!strict
-- Flying. Dragons do not jump: Space (or the jump button) takes off. In the
-- air the dragon goes where the camera looks: forward flies along the
-- camera's aim, up or down included, strafing stays level, Space adds a
-- climb, and hovering with no input sinks slowly. Touching the ground while
-- sinking lands. Walking off an edge starts a glide, so nobody falls off.
-- The character's physics belong to this client, so a LinearVelocity on the
-- root does the moving and the dragon is turned to face its travel. The
-- local attribute "Flying" on the player tells the HUD and the animator.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Flight = {}

local TURN_RATE = 6
local LAND_CLEARANCE = 0.6 -- studs of air under the feet that still counts as landed
local AUTO_GLIDE_DELAY = 0.35 -- seconds of free fall before a glide starts on its own
local MOBILE_CLIMB_SECONDS = 0.3 -- one jump-button tap climbs for this long

local localPlayer = Players.LocalPlayer

local flying = false
local spaceHeld = false
local climbUntil = 0
local fallingSince: number? = nil
local mover: LinearVelocity? = nil

local function character(): (Model?, BasePart?, Humanoid?)
	local model = localPlayer.Character
	if not model then
		return nil, nil, nil
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return model, if root and root:IsA("BasePart") then root else nil, humanoid
end

local function climbing(): boolean
	return spaceHeld or os.clock() < climbUntil
end

-- Distance from the root's centre down to the ground, or nil when there is
-- none within `reach`.
local function groundBelow(model: Model, root: BasePart, reach: number): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -reach, 0), params)
	return if hit then hit.Distance else nil
end

local function rootHeight(root: BasePart, humanoid: Humanoid): number
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return root.Size.Y / 2 + 2
	end
	return humanoid.HipHeight + root.Size.Y / 2
end

local function setFlying(value: boolean)
	flying = value
	localPlayer:SetAttribute("Flying", value)
end

local function land()
	if not flying then
		return
	end
	setFlying(false)
	if mover then
		mover:Destroy()
		mover = nil
	end
	local _, _, humanoid = character()
	if humanoid then
		humanoid.AutoRotate = true
	end
end

local function takeOff(boost: boolean)
	local model, root, humanoid = character()
	if flying or not model or not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	setFlying(true)
	humanoid.AutoRotate = false

	local existing = root:FindFirstChild("RootAttachment")
	local attachment: Attachment
	if existing and existing:IsA("Attachment") then
		attachment = existing
	else
		attachment = Instance.new("Attachment")
		attachment.Name = "RootAttachment"
		attachment.Parent = root
	end
	local created = Instance.new("LinearVelocity")
	created.Name = "FlightMover"
	created.Attachment0 = attachment
	created.RelativeTo = Enum.ActuatorRelativeTo.World
	created.MaxForce = math.huge
	created.VectorVelocity = Vector3.zero
	created.Parent = root
	mover = created

	if boost then
		climbUntil = os.clock() + 0.45
	end
end

local function update(dt: number)
	local model, root, humanoid = character()
	if not model or not root or not humanoid then
		return
	end
	if humanoid.Health <= 0 then
		land()
		return
	end

	local scale = model:GetScale()
	local height = rootHeight(root, humanoid)

	if not flying then
		-- Walking off an edge: glide after a moment of free fall.
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			local since = fallingSince or os.clock()
			fallingSince = since
			if os.clock() - since > AUTO_GLIDE_DELAY and not groundBelow(model, root, height + 3) then
				takeOff(false)
			end
		else
			fallingSince = nil
		end
		return
	end

	local current = mover
	if not current or current.Parent ~= root then
		land()
		return
	end

	local speedScale = math.sqrt(scale)
	local move = humanoid.MoveDirection -- camera-relative, flat, from the control script

	-- Split the input into forward and sideways relative to the camera, then
	-- send the forward part along the camera's true aim so pitch steers.
	local camera = Workspace.CurrentCamera
	local look = if camera then camera.CFrame.LookVector else root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	flat = if flat.Magnitude > 0.01 then flat.Unit else root.CFrame.LookVector
	local right = Vector3.new(-flat.Z, 0, flat.X)
	local forward = move:Dot(flat)
	local sideways = move:Dot(right)
	local velocity = (look * forward + right * sideways) * Config.FlySpeed * speedScale

	if climbing() then
		velocity += Vector3.new(0, Config.FlyClimbSpeed * speedScale, 0)
	elseif move.Magnitude < 0.05 then
		velocity += Vector3.new(0, -Config.FlySinkSpeed * speedScale, 0)
	end
	current.VectorVelocity = velocity

	local heading = Vector3.new(velocity.X, 0, velocity.Z)
	if heading.Magnitude > 0.5 then
		local goal = CFrame.lookAt(root.Position, root.Position + heading)
		root.CFrame = root.CFrame:Lerp(goal, math.min(dt * TURN_RATE, 1))
	end

	-- Landing: descending onto ground within reach of the feet.
	if velocity.Y < 0 then
		local distance = groundBelow(model, root, height + LAND_CLEARANCE)
		if distance then
			land()
		end
	end
end

function Flight.IsFlying(): boolean
	return flying
end

function Flight.Init()
	setFlying(false)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.Space then
			return
		end
		spaceHeld = true
		if not flying then
			takeOff(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			spaceHeld = false
		end
	end)
	-- The on-screen jump button and gamepads come through here.
	UserInputService.JumpRequest:Connect(function()
		if not flying then
			takeOff(true)
		elseif not spaceHeld then
			climbUntil = os.clock() + MOBILE_CLIMB_SECONDS
		end
	end)

	local function onCharacter(model: Model)
		flying = false
		mover = nil
		fallingSince = nil
		setFlying(false)
		local humanoid = model:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			-- Dragons fly instead of jumping.
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
	end
	localPlayer.CharacterAdded:Connect(onCharacter)
	if localPlayer.Character then
		onCharacter(localPlayer.Character)
	end

	RunService.Heartbeat:Connect(update)
end

return Flight
