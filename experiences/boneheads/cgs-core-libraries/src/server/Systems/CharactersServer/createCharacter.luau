-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Core.Constants)
local Health = require(ReplicatedStorage.Core.Libraries.Health)

local DEFAULT_HEALTH = 100

local function createCharacter(template: Model, input: InputContext): Model
	local character = template:Clone()

	local inputPointer = Instance.new("ObjectValue")
	inputPointer.Name = "Input"
	inputPointer.Value = input
	inputPointer.Parent = character

	local pathfindingModifier = Instance.new("PathfindingModifier")
	pathfindingModifier.PassThrough = true
	pathfindingModifier.Parent = character.PrimaryPart

	Health.assign(character, DEFAULT_HEALTH)

	character:AddTag(Constants.TAGS.CHARACTER)

	return character
end

return createCharacter
