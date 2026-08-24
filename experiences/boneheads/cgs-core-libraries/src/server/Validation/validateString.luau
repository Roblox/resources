-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

-- Sort of arbitrary, but we really don't want clients sending us strings longer than this
local MAX_STRING_LENGTH = 1024

local function validateString(str: string): boolean
	if typeof(str) ~= "string" then
		return false
	end
	if #str > MAX_STRING_LENGTH then
		return false
	end

	return true
end

return validateString
