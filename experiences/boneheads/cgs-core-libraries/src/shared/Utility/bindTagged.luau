-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local CollectionService = game:GetService("CollectionService")

type Callback = (instance: Instance) -> ()

local function bindTagged(tag: string, environment: { Instance }, onAdded: Callback, onRemoved: Callback): () -> ()
	local inEnvironmentMap: { [Instance]: boolean } = {}
	local ancestryConnections: { [Instance]: RBXScriptConnection } = {}

	local function isInEnvironment(instance: Instance): boolean
		for _, environmentParent in environment do
			if instance:IsDescendantOf(environmentParent) then
				return true
			end
		end

		return false
	end

	local function onInstanceAdded(instance: Instance)
		local inEnvironment = isInEnvironment(instance)
		inEnvironmentMap[instance] = inEnvironment

		if not ancestryConnections[instance] then
			ancestryConnections[instance] = instance.AncestryChanged:Connect(function()
				local nowInEnvironment = isInEnvironment(instance)
				local wasInEnvironment = inEnvironmentMap[instance]
				if nowInEnvironment == wasInEnvironment then
					return
				end

				if nowInEnvironment then
					task.spawn(onAdded, instance)
				else
					task.spawn(onRemoved, instance)
				end
			end)
		end

		if inEnvironment then
			task.spawn(onAdded, instance)
		end
	end

	local function onInstanceRemoved(instance: Instance)
		if ancestryConnections[instance] then
			ancestryConnections[instance]:Disconnect()
			ancestryConnections[instance] = nil
		end

		local wasInEnvironment = inEnvironmentMap[instance]
		if wasInEnvironment then
			task.spawn(onRemoved, instance)
		end

		inEnvironmentMap[instance] = nil
	end

	local addedConnection = CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded)
	local removedConnection = CollectionService:GetInstanceRemovedSignal(tag):Connect(onInstanceRemoved)

	for _, instance in CollectionService:GetTagged(tag) do
		onInstanceAdded(instance)
	end

	return function()
		addedConnection:Disconnect()
		removedConnection:Disconnect()
	end
end

return bindTagged
