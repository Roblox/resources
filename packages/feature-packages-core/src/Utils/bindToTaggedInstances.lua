--!strict

--[[
	Utility for binding functions to instances with a given CollectionService tag.

    Binding will automatically call the onAddedCallback when the tag is added to an instance.
    
    Likewise, when the tag is removed from an instance, the onRemovedCallback will be called for the instance.
--]]

local CollectionService = game:GetService("CollectionService")

local function bindToTaggedInstances(
	tag: string,
	onAddedCallback: ((any) -> ())?,
	onRemovedCallback: ((any) -> ())?,
	includeReplicatedStorage: boolean?
)
	if onAddedCallback then
		local function filteredCallback(instance: Instance)
			if not includeReplicatedStorage and instance:FindFirstAncestorWhichIsA("ReplicatedStorage") then
				return
			end

			onAddedCallback(instance)
		end

		CollectionService:GetInstanceAddedSignal(tag):Connect(filteredCallback)

		for _, instance in CollectionService:GetTagged(tag) do
			task.spawn(filteredCallback, instance)
		end
	end

	if onRemovedCallback then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(onRemovedCallback)
	end
end

return bindToTaggedInstances
