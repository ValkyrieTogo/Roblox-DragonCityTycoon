--!strict
-- Shared game configuration. Readable from both server and client.
-- Tuning numbers live here so the game can be balanced without touching logic.

local Config = {}

Config.GameName = "Dragon City Tycoon"

-- Economy
Config.StartingCash = 100

-- Plots
Config.PlotCount = 8
Config.PlotSize = 48 -- studs, square footprint of one plot
Config.PlotSpacing = 16 -- studs of gap between neighbouring plots
Config.PlotsPerRow = 4

return Config
