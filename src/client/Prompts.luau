--!strict
-- Reacts to ProximityPrompts the map places. A prompt with a string
-- attribute Notice shows that text as a toast; one with Action "ToggleShop"
-- opens or closes the upgrade panel. Both are purely local, so the server
-- never hears about them.

local ProximityPromptService = game:GetService("ProximityPromptService")

local Hud = require(script.Parent.Hud)
local Shop = require(script.Parent.Shop)

local Prompts = {}

function Prompts.Init()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		local notice = prompt:GetAttribute("Notice")
		if typeof(notice) == "string" then
			Hud.Toast(notice)
		end
		if prompt:GetAttribute("Action") == "ToggleShop" then
			Shop.Toggle()
		end
	end)
end

return Prompts
