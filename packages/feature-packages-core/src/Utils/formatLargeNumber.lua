--!strict

--[[
	Utility for formatting large numbers, into a human-readable string with K, M, B, etc.
--]]

local symbols = { "K", "M", "B", "T", "Q" }

local function formatNumber(v: number): string
	local symbol = ""
	local shiftedValue = v

	for index in symbols do
		if shiftedValue < 1000 then
			break
		end
		symbol = symbols[index]
		shiftedValue = shiftedValue / 1000
	end

	if shiftedValue < 10 then
		shiftedValue = math.floor(shiftedValue * 10) / 10
	else
		shiftedValue = math.floor(shiftedValue)
	end

	return `{shiftedValue}{symbol}`
end

return formatNumber
