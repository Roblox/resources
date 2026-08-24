-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

-- FactionService manages faction membership for characters efficiently. It tracks which faction(s) a character
-- belongs to via CollectionService tags, exposes memoized RaycastParams that exclude allies from
-- raycasts, and provides a list of enemy characters per faction.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getTaggedList = require(ReplicatedStorage.Core.Utility.getTaggedList)
local getTagsKey = require(ReplicatedStorage.Core.Utility.getTagsKey)

local FACTION_KEY_ATTRIBUTE = "_factionKey"
local TAGS_SEPARATOR = "|"

export type FactionKey = string
export type FactionRelations = { [FactionKey]: { FactionKey } }
export type FactionDefinitions = {
	FACTIONS: { FactionKey },
	FACTION_ALLIES: FactionRelations,
	FACTION_ENEMIES: FactionRelations,
}

local factionKeys: { FactionKey } = {}
local factionAllies: FactionRelations = {}
local factionEnemies: FactionRelations = {}

local factionEnemyCharacters: { [FactionKey]: { PVInstance } } = {}
local factionAllyCharacters: { [FactionKey]: { PVInstance } } = {}

local factionRaycastParams: { [FactionKey]: RaycastParams } = {}
local factionDependents: { [FactionKey]: { FactionKey } } = {}

local Factions = {}

local function updateFactionRaycastParams(factionKey: FactionKey)
	-- Get characters that belong to this faction (or combination of factions) to exclude them from raycasts
	-- Manually update RaycastParams.FilterDescendantsInstances to copy new instances changes to C++
	local factionTags = string.split(factionKey, TAGS_SEPARATOR)
	local factionCharacters: { any } = {}

	for _, factionTag in factionTags do
		local taggedList = getTaggedList({ factionTag }, true)
		table.insert(factionCharacters, taggedList)
	end

	local raycastParams = factionRaycastParams[factionKey]
	assert(raycastParams, `Missing RaycastParams for faction {factionKey}`)
	raycastParams.FilterDescendantsInstances = factionCharacters

	-- Update all other RaycastParams that exclude this faction as well
	if factionDependents[factionKey] then
		for _, dependentFaction in factionDependents[factionKey] do
			updateFactionRaycastParams(dependentFaction)
		end
	end
end

local function registerFaction(factionKey: FactionKey)
	if factionRaycastParams[factionKey] then
		return
	end

	-- Create ally exclusion RaycastParams
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	factionRaycastParams[factionKey] = raycastParams
	updateFactionRaycastParams(factionKey)

	-- Add self to dependencies of each individual base faction tag, so if any of these faction tags
	-- are updated we can update the RaycastParams for this faction combination as well
	local factionTags = string.split(factionKey, TAGS_SEPARATOR)

	for _, factionTag in factionTags do
		if factionTag == factionKey then
			continue
		end

		if not factionDependents[factionTag] then
			factionDependents[factionTag] = { factionKey }
		else
			table.insert(factionDependents[factionTag], factionKey)
		end
	end

	-- Get list of ally & enemy factions
	-- NOTE: This doesn't need to be updated in updateFactionRaycastParams because
	-- getTaggedList maintains an up-to-date list of instances for each tag combination
	local allyFactionTags = {}
	local enemyFactionTags = {}

	for _, factionTag in factionTags do
		if factionAllies[factionTag] then
			for _, allyFaction in factionAllies[factionTag] do
				table.insert(allyFactionTags, allyFaction)
			end
		end

		if factionEnemies[factionTag] then
			for _, enemyFaction in factionEnemies[factionTag] do
				table.insert(enemyFactionTags, enemyFaction)
			end
		end
	end

	factionAllyCharacters[factionKey] = (getTaggedList(allyFactionTags, true) :: any) :: { PVInstance }
	factionEnemyCharacters[factionKey] = (getTaggedList(enemyFactionTags, true) :: any) :: { PVInstance }
end

local function updateCharacterFactionKey(character: PVInstance)
	local factionTags = {}

	for _, faction in factionKeys do
		if character:HasTag(faction) then
			table.insert(factionTags, faction)
		end
	end

	local previousFaction = character:GetAttribute(FACTION_KEY_ATTRIBUTE) :: FactionKey?
	local currentFaction = getTagsKey(factionTags)

	character:SetAttribute(FACTION_KEY_ATTRIBUTE, currentFaction)

	if factionRaycastParams[currentFaction] then
		updateFactionRaycastParams(currentFaction)
	else
		registerFaction(currentFaction)
	end

	if previousFaction and previousFaction ~= currentFaction then
		updateFactionRaycastParams(previousFaction)
	end
end

local function onCharacterFactionChanged(character: Instance)
	assert(character:IsA("PVInstance"), "Only PVInstances can have factions")
	updateCharacterFactionKey(character)
end

function Factions.getCharacterFactionKey(character: PVInstance): FactionKey
	return character:GetAttribute(FACTION_KEY_ATTRIBUTE) :: string? or ""
end

function Factions.getCharacterFactions(character: PVInstance): { string }
	local factionKey = Factions.getCharacterFactionKey(character)
	return string.split(factionKey, TAGS_SEPARATOR)
end

function Factions.bindCharacterFactionChanged(
	character: PVInstance,
	callback: (factionKey: FactionKey, factions: { string }) -> ()
): RBXScriptConnection
	local function onFactionChanged()
		callback(Factions.getCharacterFactionKey(character), Factions.getCharacterFactions(character))
	end

	onFactionChanged()
	return character:GetAttributeChangedSignal(FACTION_KEY_ATTRIBUTE):Connect(onFactionChanged)
end

function Factions.getFactionEnemies(factionKey: FactionKey): { PVInstance }
	return factionEnemyCharacters[factionKey] or {}
end

function Factions.getFactionAllies(factionKey: FactionKey): { PVInstance }
	return factionAllyCharacters[factionKey] or {}
end

function Factions.areCharactersEnemies(characterA: PVInstance, characterB: PVInstance): boolean
	local factionsB = Factions.getCharacterFactions(characterB)

	for _, factionTag in Factions.getCharacterFactions(characterA) do
		if not factionEnemies[factionTag] then
			continue
		end

		for _, enemyFaction in factionEnemies[factionTag] do
			if table.find(factionsB, enemyFaction) then
				return true
			end
		end
	end

	return false
end

function Factions.areCharactersAllies(characterA: PVInstance, characterB: PVInstance): boolean
	local factionsB = Factions.getCharacterFactions(characterB)

	for _, factionTag in Factions.getCharacterFactions(characterA) do
		if not factionAllies[factionTag] then
			continue
		end

		for _, allyFaction in factionAllies[factionTag] do
			if table.find(factionsB, allyFaction) then
				return true
			end
		end
	end

	return false
end

-- Memorize exclusion RaycastParams for each faction combination to avoid creating new ones for each NPC
function Factions.getFactionExclusionRaycastParams(factionKey: FactionKey): RaycastParams
	if not factionRaycastParams[factionKey] then
		registerFaction(factionKey)
	end

	return factionRaycastParams[factionKey]
end

function Factions.autoLoad(definitions: FactionDefinitions)
	factionKeys = definitions.FACTIONS
	factionAllies = definitions.FACTION_ALLIES
	factionEnemies = definitions.FACTION_ENEMIES

	for _, faction in factionKeys do
		CollectionService:GetInstanceAddedSignal(faction):Connect(onCharacterFactionChanged)
		CollectionService:GetInstanceRemovedSignal(faction):Connect(onCharacterFactionChanged)

		for _, instance in CollectionService:GetTagged(faction) do
			onCharacterFactionChanged(instance)
		end

		registerFaction(faction)
	end
end

return Factions
