--!strict
-- Server entry point. Starts every service in dependency order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local StatService = require(script.Parent.Services.StatService)
local ClickService = require(script.Parent.Services.ClickService)
local DragonService = require(script.Parent.Services.DragonService)

print(`[{Config.GameName}] server starting`)

-- Stats first so leaderstats exist before anything reads them.
StatService.Init()
ClickService.Init()
DragonService.Init()

print(`[{Config.GameName}] server ready`)
