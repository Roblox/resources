-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local LootDrop = require(script.Parent)
local Types = require(script.Parent.Types)

local Examples = {}

local ROLLS_PER_EXAMPLE = 10

local SLIME_DROP_TABLE: Types.DropTable = {
	rollCount = 1,
	weight = 1,
	entries = {
		{ data = { name = "Empty" }, count = 1, weight = 1, type = "Drop" },
		{ data = { name = "Slime" }, count = LootDrop.range(1, 4), weight = 1, type = "Drop" },
	},
	type = "DropTable",
}

local BOSS_DROP_TABLE: Types.DropTable = {
	rollCount = 1,
	weight = 1,
	entries = {
		{
			weight = 9,
			rollCount = 1,
			entries = {
				{ data = { name = "EpicSword" }, count = 1, weight = 1, type = "Drop" },
				{ data = { name = "EpicShield" }, count = 1, weight = 1, type = "Drop" },
				{ data = { name = "EpicStaff" }, count = 1, weight = 1, type = "Drop" },
			},
			type = "DropTable",
		},
		{
			weight = 1,
			rollCount = 1,
			entries = {
				{ data = { name = "LegendarySword" }, count = 1, weight = 1, type = "Drop" },
				{ data = { name = "LegendaryCrown" }, count = 1, weight = 1, type = "Drop" },
			},
			type = "DropTable",
		},
	},
	type = "DropTable",
}

local TWO_UNIQUE_WEAPONS_DROP_TABLE: Types.DropTable = {
	rollCount = 2,
	weight = 1,
	forceUnique = true,
	entries = {
		{ data = { name = "Sword" }, count = 1, weight = 1, type = "Drop" },
		{ data = { name = "Axe" }, count = 1, weight = 1, type = "Drop" },
		{ data = { name = "Bow" }, count = 1, weight = 1, type = "Drop" },
		{ data = { name = "Mace" }, count = 1, weight = 1, type = "Drop" },
		{ data = { name = "Dagger" }, count = 1, weight = 1, type = "Drop" },
	},
	type = "DropTable",
}

local WEIGHTED_UNIQUE_LOOT_DROP_TABLE: Types.DropTable = {
	rollCount = 3,
	weight = 1,
	forceUnique = true,
	entries = {
		{ data = { name = "CommonPotion" }, count = 1, weight = 4, type = "Drop" },
		{ data = { name = "RarePotion" }, count = 1, weight = 2, type = "Drop" },
		{ data = { name = "EpicPotion" }, count = 1, weight = 1, type = "Drop" },
		{ data = { name = "LegendaryPotion" }, count = 1, weight = 1, type = "Drop" },
		{ data = { name = "ArcaneShard" }, count = 1, weight = 2, type = "Drop" },
		{ data = { name = "VoidCrystal" }, count = 1, weight = 1, type = "Drop" },
	},
	type = "DropTable",
}

local function formatDrops(drops: { Types.RolledDrop }): string
	if #drops == 0 then
		return "(nothing)"
	end
	local parts: { string } = {}
	for _, drop in drops do
		local data = drop.data :: { name: string }
		table.insert(parts, `{data.name} x{drop.count}`)
	end
	return table.concat(parts, ", ")
end

local function demonstrate(label: string, dropTable: Types.DropTable)
	print(`=== {label} ===`)
	for i = 1, ROLLS_PER_EXAMPLE do
		local drops = LootDrop.roll(dropTable)
		print(`  Roll {i}: {formatDrops(drops)}`)
	end
end

function Examples.run()
	demonstrate("Example 1 - Slime drops 1-4, 50% of the time", SLIME_DROP_TABLE)
	demonstrate("Example 2 - Boss: epic weapon 90%, legendary 10%", BOSS_DROP_TABLE)
	demonstrate("Example 3 - Enemy drops two distinct weapons", TWO_UNIQUE_WEAPONS_DROP_TABLE)
	demonstrate("Example 4 - Three unique items from weighted pool", WEIGHTED_UNIQUE_LOOT_DROP_TABLE)
end

return Examples
