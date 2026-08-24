-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Core.Constants)
local createCharacter = require(script.Parent.createCharacter)
local getSpawnPosition = require(script.Parent.getSpawnPosition)

local function loadPlayerCharacter(player: Player, template: Model): Model
	local inputContext = player:FindFirstChild("CharacterInput")
	assert(inputContext and inputContext:IsA("InputContext"), "Missing InputContext")

	local existingCharacter = player.Character
	if existingCharacter then
		existingCharacter:Destroy()
	end

	local spawnPosition = getSpawnPosition(player)
	local character = createCharacter(template, inputContext)
	local _, size = character:GetBoundingBox()

	character:AddTag(Constants.TAGS.PLAYER)
	character:PivotTo(CFrame.new(spawnPosition + Vector3.new(0, size.Y * 0.5, 0)))

	character.Name = player.Name
	character.Parent = Workspace
	player.Character = character

	return character
end

return loadPlayerCharacter
