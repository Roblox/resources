-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)
local line = require(script.Parent.line)

local lines = {}

function lines.create(): { Types.DebugLine }
	return {}
end

function lines.update(linesTable: { Types.DebugLine }, pointsTable: { Vector3 }, color: Color3?, width: number?)
	local targetLineCount = #pointsTable - 1
	local currentLineCount = #linesTable

	for i = currentLineCount, targetLineCount + 1, -1 do
		line.destroy(linesTable[i])
		table.remove(linesTable, i)
	end
	for _ = currentLineCount + 1, targetLineCount do
		table.insert(linesTable, line.create())
	end

	for i = 1, targetLineCount do
		line.update(linesTable[i], pointsTable[i], pointsTable[i + 1], color, width)
	end
end

function lines.destroy(linesTable: { Types.DebugLine })
	for _, debugLine in linesTable do
		line.destroy(debugLine)
	end
	table.clear(linesTable)
end

return lines
