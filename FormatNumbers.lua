--[[
    FormatNumbers.lua
    Formatage des nombres (1.5M, 2.3B, etc.)
]]

local FormatNumbers = {}

local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}

function FormatNumbers:Format(number)
	if number < 1000 then
		return tostring(math.floor(number))
	end

	local exp = math.floor(math.log10(number) / 3)
	exp = math.min(exp, #suffixes - 1)

	local scaled = number / (10 ^ (exp * 3))
	local formatted = string.format("%.1f", scaled)

	if formatted:match("%.0$") then
		formatted = formatted:gsub("%.0", "")
	end

	return formatted .. suffixes[exp + 1]
end

function FormatNumbers:FormatTime(seconds)
	if seconds < 60 then
		return string.format("%ds", seconds)
	elseif seconds < 3600 then
		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%dm %ds", mins, secs)
	else
		local hours = math.floor(seconds / 3600)
		local mins = math.floor((seconds % 3600) / 60)
		return string.format("%dh %dm", hours, mins)
	end
end

return FormatNumbers
