-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)
local getTagsKey = require(ReplicatedStorage.Core.Utility.getTagsKey)

local LIST_LIFETIME = 60

local listRegistry: {
	[string]: { list: { Instance }, connections: { RBXScriptConnection }, lastAccessed: number },
} =
	{}

local function removeTaggedList(key: string)
	local entry = listRegistry[key]
	if not entry then
		return
	end

	disconnectAndClear(entry.connections)
	table.clear(entry)
	listRegistry[key] = nil
end

local function getTaggedList(tags: { string }, persistent: boolean?): { Instance }
	local key = getTagsKey(tags)
	local entry = listRegistry[key]

	if entry then
		entry.lastAccessed = os.clock()
		return entry.list
	end

	local list: { Instance } = {}
	local connections: { RBXScriptConnection } = {}

	entry = { list = list, connections = connections, lastAccessed = os.clock() }
	listRegistry[key] = entry

	for _, tag in tags do
		if tag == "" then
			continue
		end

		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
				table.insert(list, instance)
			end)
		)

		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
				local index = table.find(list, instance)
				if index then
					table.remove(list, index)
				end
			end)
		)

		for _, instance in CollectionService:GetTagged(tag) do
			table.insert(list, instance)
		end
	end

	if not persistent then
		task.delay(LIST_LIFETIME, function()
			while listRegistry[key] do
				local remainingDuration = LIST_LIFETIME - (os.clock() - listRegistry[key].lastAccessed)
				if remainingDuration <= 0 then
					removeTaggedList(key)
					return
				end

				task.wait(remainingDuration)
			end
		end)
	end

	return list
end

return getTaggedList
