--!strict
-- Loads and saves player progress with DataStoreService: Fire, Wins and
-- upgrade levels. Saves on leave, on server shutdown and on a timer.
--
-- Safety rule: if a player's load fails, nothing is ever saved for them in
-- that session, so a DataStore outage cannot overwrite real progress with
-- defaults. In Studio, saving needs "Enable Studio Access to API Services"
-- under Game Settings > Security, and the place must be published.
--
-- This is a plain DataStore. Swapping in ProfileStore later for session
-- locking only changes this file; the rest of the game reads live stats.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StatService = require(script.Parent.StatService)
local UpgradeService = require(script.Parent.UpgradeService)

local DataService = {}

local STORE_NAME = "PlayerData_v1"
local DATA_VERSION = 1
local AUTOSAVE_SECONDS = 120
local LOAD_ATTEMPTS = 3
local SAVE_ATTEMPTS = 2
local RETRY_DELAY = 2

export type SaveData = {
	Version: number,
	Fire: number,
	Wins: number,
	Upgrades: { [string]: number },
}

type Profile = {
	Data: SaveData,
	Loaded: boolean, -- false means the load failed and this player must not be saved
}

local store = DataStoreService:GetDataStore(STORE_NAME)
local profiles: { [Player]: Profile } = {}

local function defaultData(): SaveData
	return { Version = DATA_VERSION, Fire = 0, Wins = 0, Upgrades = {} }
end

local function keyFor(player: Player): string
	return `Player_{player.UserId}`
end

-- Fills in anything missing from older or damaged saves.
local function sanitize(raw: any): SaveData
	local data = defaultData()
	if typeof(raw) ~= "table" then
		return data
	end
	if typeof(raw.Fire) == "number" then
		data.Fire = math.max(math.floor(raw.Fire), 0)
	end
	if typeof(raw.Wins) == "number" then
		data.Wins = math.max(math.floor(raw.Wins), 0)
	end
	if typeof(raw.Upgrades) == "table" then
		for id, level in raw.Upgrades do
			if typeof(id) == "string" and typeof(level) == "number" then
				data.Upgrades[id] = math.max(math.floor(level), 0)
			end
		end
	end
	return data
end

local function collect(player: Player): SaveData
	return {
		Version = DATA_VERSION,
		Fire = StatService.GetFire(player),
		Wins = StatService.GetWins(player),
		Upgrades = UpgradeService.GetLevels(player),
	}
end

local function apply(player: Player, data: SaveData)
	StatService.SetWins(player, data.Wins)
	UpgradeService.SetLevels(player, data.Upgrades)
	StatService.SetFire(player, data.Fire)
end

local function load(player: Player): Profile
	for attempt = 1, LOAD_ATTEMPTS do
		local ok, result = pcall(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			return { Data = sanitize(result), Loaded = true }
		end
		warn(`[DataService] Load attempt {attempt} failed for {player.Name}: {result}`)
		if attempt < LOAD_ATTEMPTS then
			task.wait(RETRY_DELAY)
		end
	end
	warn(`[DataService] Giving up loading {player.Name}; progress this session will NOT be saved`)
	return { Data = defaultData(), Loaded = false }
end

local function save(player: Player)
	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return
	end

	local data = collect(player)
	profile.Data = data

	for attempt = 1, SAVE_ATTEMPTS do
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function()
				return data
			end)
		end)
		if ok then
			return
		end
		warn(`[DataService] Save attempt {attempt} failed for {player.Name}: {err}`)
		if attempt < SAVE_ATTEMPTS then
			task.wait(RETRY_DELAY)
		end
	end
end

local function onPlayerAdded(player: Player)
	local profile = load(player)
	if not player.Parent then
		return -- left while loading
	end
	profiles[player] = profile
	apply(player, profile.Data)
	print(`[DataService] Loaded {player.Name}: {profile.Data.Fire} Fire, {profile.Data.Wins} wins`)
end

local function onPlayerRemoving(player: Player)
	save(player)
	profiles[player] = nil
end

local function saveAll()
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function()
			save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait(0.1)
	end
end

function DataService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		-- Studio stop: skip the wait so the editor is not held up.
		if RunService:IsStudio() then
			return
		end
		saveAll()
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in profiles do
				task.spawn(save, player)
			end
		end
	end)
end

return DataService
