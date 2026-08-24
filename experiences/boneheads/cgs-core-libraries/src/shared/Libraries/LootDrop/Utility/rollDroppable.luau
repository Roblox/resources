-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Parent.Types)

local Helpers = {}

function Helpers.sampleCount(count: Types.Count, random: Random): number
	if type(count) == "number" then
		return count
	end

	return random:NextInteger(count.min, count.max)
end

function Helpers.selectWeighted(entries: { Types.Droppable }, random: Random): Types.Droppable
	assert(#entries > 0, "Cannot select from an empty entries list")

	local totalWeight = 0
	for _, entry in entries do
		totalWeight += entry.weight
	end
	assert(totalWeight > 0, "Total entry weight must be positive")

	local target = random:NextNumber() * totalWeight
	local accumulated = 0
	for _, entry in entries do
		accumulated += entry.weight
		if target < accumulated then
			return entry
		end
	end

	return entries[#entries]
end

function Helpers.rollWithCount(entries: { Types.Droppable }, count: number, random: Random): { Types.RolledDrop }
	assert(#entries > 0, "ROLL_COUNT requires at least one entry")

	local results: { Types.RolledDrop } = {}
	for _ = 1, count do
		local entry = Helpers.selectWeighted(entries, random)
		for _, rolled in Helpers.rollDroppable(entry, random) do
			table.insert(results, rolled)
		end
	end
	return results
end

-- When in unique roll mode, if count is greater than the number of entries,
--  every entry must be rolled at least one time before any entry can be rolled a second time, and so on.
function Helpers.rollUnique(entries: { Types.Droppable }, count: number, random: Random): { Types.RolledDrop }
	assert(#entries > 0, "forceUnique requires at least one entry")

	-- Track how many times each entry has been rolled.
	local timesRolled: { [Types.Droppable]: number } = {}
	for _, entry in entries do
		timesRolled[entry] = 0
	end

	local results: { Types.RolledDrop } = {}
	for _ = 1, count do
		-- Find the minimum number of times any entry has been rolled.
		local minRolledCount = math.huge
		for _, entryCount in timesRolled do
			if entryCount < minRolledCount then
				minRolledCount = entryCount
			end
		end

		-- Entries that have been rolled the minimum number of times are eligible.
		local eligible: { Types.Droppable } = {}
		for _, entry in entries do
			if timesRolled[entry] == minRolledCount then
				table.insert(eligible, entry)
			end
		end

		-- Weighted select from eligible entries, and increment its counter.
		local selected = Helpers.selectWeighted(eligible, random)
		timesRolled[selected] += 1
		for _, rolled in Helpers.rollDroppable(selected, random) do
			table.insert(results, rolled)
		end
	end
	return results
end

function Helpers.rollDroppable(entry: Types.Droppable, random: Random): { Types.RolledDrop }
	if entry.type ~= "DropTable" then
		return {
			{
				data = entry.data,
				count = Helpers.sampleCount(entry.count, random),
			},
		}
	end

	local count = Helpers.sampleCount(entry.rollCount, random)
	if entry.forceUnique then
		return Helpers.rollUnique(entry.entries, count, random)
	end
	return Helpers.rollWithCount(entry.entries, count, random)
end

return Helpers.rollDroppable
