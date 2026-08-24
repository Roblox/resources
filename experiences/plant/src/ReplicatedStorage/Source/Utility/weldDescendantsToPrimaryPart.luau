--!strict

--[[
	Iterates over a model's descendants, welding all the BaseParts
	to the model's PrimaryPart. Useful for welding models together at runtime.
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DoNotWeldTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.DoNotWeldTag)

local weldParts = require(ReplicatedStorage.Source.Utility.weldParts)

local function weldDescendantsToPrimaryPart(model: Model)
	assert(model.PrimaryPart, string.format("Cannot weld model missing primary part: %s", model:GetFullName()))
	local primaryPart = model.PrimaryPart

	for _, child in ipairs(model:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end

		-- Avoid welding the primary part to itself
		if child == primaryPart then
			continue
		end

		-- Developer can add a DoNotWeld tag to avoid an object being welded.
		-- One case a developer may use this is if the part already attached by another constraint
		if CollectionService:HasTag(child, DoNotWeldTag) then
			continue
		end

		weldParts(child, primaryPart)
		child.Anchored = false
	end
end

return weldDescendantsToPrimaryPart
