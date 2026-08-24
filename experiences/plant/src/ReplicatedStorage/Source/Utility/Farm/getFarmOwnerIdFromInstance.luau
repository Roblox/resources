--!strict

--[[
	Finds the top-level farm model from any descendant and
	returns the OwnerId attribute value of that farm.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FarmConstants = require(ReplicatedStorage.Source.Farm.FarmConstants)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)

function getFarmOwnerIdFromInstance(instance: Instance)
	local farm = instance

	while farm and farm.Parent ~= FarmConstants.FarmContainer do
		farm = farm:FindFirstAncestor("Farm")
	end

	assert(farm, "The given instance does not belong to a farm")

	return getAttribute(farm, Attribute.OwnerId) :: number
end

return getFarmOwnerIdFromInstance
