-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function getListFromString(content: string): { string }
	local result = {}

	for entry in string.gmatch(content, "[^,]+") do
		local trimmed = string.match(entry, "^%s*(.-)%s*$")
		if trimmed and trimmed ~= "" then
			table.insert(result, trimmed)
		end
	end

	return result
end

return getListFromString
