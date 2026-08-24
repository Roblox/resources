-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

local function getGraphPlayers(audioGraph: Types.AudioGraph): { AudioPlayer }
	local audioPlayers = audioGraph:QueryDescendants("AudioPlayer") :: { AudioPlayer }

	if audioGraph:IsA("AudioPlayer") then
		table.insert(audioPlayers, audioGraph)
	end

	return audioPlayers
end

return getGraphPlayers
