-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

local function loadItemDefinitions(
	itemDefinitionsByIdMap: { [string]: Types.ItemDefinition },
	definitions: { [string]: Types.ItemDefinition }
)
	for id, definition in definitions do
		assert(definition.id == id, `Item definition key "{id}" does not match id "{definition.id}"`)
		assert(itemDefinitionsByIdMap[id] == nil, `Duplicate item definition id found: {id}`)
		itemDefinitionsByIdMap[id] = definition
	end
end

return loadItemDefinitions
