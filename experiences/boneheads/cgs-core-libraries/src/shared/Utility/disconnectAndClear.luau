-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function disconnectAndClear(connections: { RBXScriptConnection })
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return disconnectAndClear
