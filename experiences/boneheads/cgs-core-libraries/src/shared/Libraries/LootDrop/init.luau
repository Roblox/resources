-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script.Types)
local deepEqual = require(ReplicatedStorage.Core.Utility.deepEqual)
local rollDroppable = require(script.Utility.rollDroppable)

export type Droppable = Types.Droppable
export type RolledDrop = Types.RolledDrop
export type CountRange = Types.CountRange

local moduleRandom = Random.new()

local LootDrop = {}

local function mergeDrops(drops: { RolledDrop }): { RolledDrop }
	local merged: { RolledDrop } = {}
	for _, drop in drops do
		local matched = false
		for _, existing in merged do
			if deepEqual(existing.data, drop.data) then
				existing.count += drop.count
				matched = true
				break
			end
		end
		if not matched then
			table.insert(merged, {
				data = drop.data,
				count = drop.count,
			})
		end
	end
	return merged
end

function LootDrop.range(min: number, max: number): CountRange
	assert(math.floor(min) == min, `CountRange min must be an integer, got {min}`)
	assert(math.floor(max) == max, `CountRange max must be an integer, got {max}`)
	assert(min <= max, `CountRange min ({min}) must be <= max ({max})`)

	return {
		min = min,
		max = max,
	}
end

function LootDrop.roll(droppable: Droppable, random: Random?): { RolledDrop }
	local randomToUse = random or moduleRandom
	local rolled = rollDroppable(droppable, randomToUse)
	return mergeDrops(rolled)
end

return LootDrop
