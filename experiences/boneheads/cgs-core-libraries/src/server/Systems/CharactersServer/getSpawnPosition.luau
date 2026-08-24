-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local DEFAULT_LOCATION = Vector3.new(0, 100, 0)

local random = Random.new()

local function getSpawnPosition(player: Player): Vector3
	local spawnLocations = Workspace:QueryDescendants("SpawnLocation") :: { SpawnLocation }
	local validSpawnLocations: { SpawnLocation } = {}

	for _, spawnLocation in spawnLocations do
		if not spawnLocation.Enabled then
			continue
		end

		if (player.Neutral and spawnLocation.Neutral) or player.TeamColor == spawnLocation.TeamColor then
			table.insert(validSpawnLocations, spawnLocation)
		end
	end

	if #validSpawnLocations == 0 then
		return DEFAULT_LOCATION
	end

	local spawnLocation = validSpawnLocations[random:NextInteger(1, #validSpawnLocations)]
	return spawnLocation.Position
end

return getSpawnPosition
