-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function validateNumber(number: number): boolean
	-- Make sure this is actually a number
	if typeof(number) ~= "number" then
		return false
	end

	-- Make sure the number is not NaN
	if number ~= number then
		return false
	end

	return true
end

return validateNumber
