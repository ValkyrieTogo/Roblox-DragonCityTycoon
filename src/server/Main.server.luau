--!strict
-- Server entry point. Starts every service in dependency order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StatService = require(script.Parent.Services.StatService)
local ZoneService = require(script.Parent.Services.ZoneService)
local ClickService = require(script.Parent.Services.ClickService)
local DragonService = require(script.Parent.Services.DragonService)

print(`[{Config.GameName}] server starting`)

-- Stats first so leaderstats exist before anything reads them.
-- Zones before clicks so the map and multipliers exist when the first click lands.
StatService.Init()
ZoneService.Init()
ClickService.Init()
DragonService.Init()

print(`[{Config.GameName}] server ready`)
