-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Constants = require(script.Parent.Constants)
local random = Random.new()

local function selectRandomInstance<T>(instances: { T & Instance }): T?
	local numInstances = #instances

	if numInstances == 0 then
		return nil
	elseif numInstances == 1 then
		return instances[1]
	else
		-- Avoid selecting the same instance twice in a row
		local lastSelectedInstance: Instance?
		local selectedInstance: Instance

		for _, instance in instances do
			if instance:GetAttribute(Constants.LAST_SELECTED_ATTRIBUTE) then
				lastSelectedInstance = instance
				break
			end
		end

		if lastSelectedInstance then
			while not selectedInstance or selectedInstance == lastSelectedInstance do
				selectedInstance = instances[random:NextInteger(1, numInstances)]
			end

			lastSelectedInstance:SetAttribute(Constants.LAST_SELECTED_ATTRIBUTE, nil)
		else
			selectedInstance = instances[random:NextInteger(1, numInstances)]
		end

		selectedInstance:SetAttribute(Constants.LAST_SELECTED_ATTRIBUTE, true)
		return selectedInstance
	end
end

return selectRandomInstance
