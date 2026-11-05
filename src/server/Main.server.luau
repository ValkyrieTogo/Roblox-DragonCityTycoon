--!strict
-- Server entry point. Loads and starts every service in dependency order.
-- Each step runs under xpcall so one broken service is reported in Output
-- and the rest of the game still comes up, instead of a silent empty map.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local services = script.Parent.Services

-- Order matters: stats first so leaderstats exist before anything reads them,
-- then data so a save is applied over them, then zones before clicks so the
-- map and multipliers exist when the first click lands.
local ORDER = {
	"StatService",
	"UpgradeService",
	"DataService",
	"ZoneService",
	"ClickService",
	"TrainingService",
	"GrowthService",
	"WinService",
	"NpcService",
}

local function report(name: string, phase: string, err: unknown)
	warn(`[Server] {name} failed to {phase}: {err}`)
	warn(debug.traceback())
end

print(`[{Config.GameName}] server starting`)

for _, name in ORDER do
	local module = services:FindFirstChild(name)
	if not module or not module:IsA("ModuleScript") then
		warn(`[Server] Missing service module {name}`)
		continue
	end

	local loaded, service = xpcall(require, function(err)
		report(name, "load", err)
	end, module)
	if not loaded or typeof(service) ~= "table" or typeof(service.Init) ~= "function" then
		continue
	end

	xpcall(service.Init, function(err)
		report(name, "start", err)
	end)
end

print(`[{Config.GameName}] server ready`)
