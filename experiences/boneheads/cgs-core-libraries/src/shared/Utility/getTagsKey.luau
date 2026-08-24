-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local TAGS_SEPARATOR = "|"

local function getTagsKey(tags: { string }): string
	table.sort(tags)
	return table.concat(tags, TAGS_SEPARATOR)
end

return getTagsKey
