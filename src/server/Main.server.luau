--!strict
-- Server entry point. Starts every service in dependency order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CashService = require(script.Parent.Services.CashService)
local PlotService = require(script.Parent.Services.PlotService)

print(`[{Config.GameName}] server starting`)

-- Cash first so leaderstats exist before a plot is assigned.
CashService.Init()
PlotService.Init()

print(`[{Config.GameName}] server ready`)
