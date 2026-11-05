--!strict
-- Number formatting shared by the HUD and popups.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

-- 1234 -> "1.23K", 999 -> "999", 1500000 -> "1.5M"
function Format.Short(value: number): string
	value = math.floor(value)
	if value < 1000 then
		return tostring(value)
	end

	local tier = math.min(math.floor(math.log10(value) / 3), #SUFFIXES - 1)
	local scaled = value / 10 ^ (tier * 3)
	local text = string.format("%.2f", scaled)
	-- Trim trailing zeros and a dangling dot: "1.50" -> "1.5", "2.00" -> "2"
	text = text:gsub("0+$", ""):gsub("%.$", "")
	return text .. SUFFIXES[tier + 1]
end

return Format
