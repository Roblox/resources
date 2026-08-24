-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Types = require(ReplicatedStorage.Core.Systems.Inventory.Types)
local makeDroppable = require(ReplicatedStorage.Core.ManagedContent.Inventory.BehaviorFactories.makeDroppable)
local validateInstance = require(ServerScriptService.Core.Validation.validateInstance)
local validateNumber = require(ServerScriptService.Core.Validation.validateNumber)
local validateString = require(ServerScriptService.Core.Validation.validateString)

local DROP_OFFSET = Vector3.new(0, 0, 5)
local DROP_ITEM_TAG = "DroppedItem"

local Droppable = makeDroppable({
	validate = function(actionName: string, context: Types.ItemBehaviorContext): boolean
		if not validateString(actionName) then
			return false
		end

		if not validateString(context.item.uid) then
			return false
		end

		local owner = context.owner
		local character = if owner:IsA("Player") then owner.Character else owner
		if not character or not validateInstance(character, "Model") then
			return false
		end

		if not character.PrimaryPart then
			return false
		end

		if not context.item.definition.droppedModel then
			return false
		end

		local count = if context.actionParams then context.actionParams.count else 1
		if not validateNumber(count) or count < 1 then
			return false
		end

		if context.item.count < count then
			return false
		end

		return true
	end,
	onDrop = function(context: Types.ItemBehaviorContext)
		local definition = context.item.definition
		local model = definition.droppedModel :: PVInstance
		local count = if context.actionParams then context.actionParams.count else 1

		context.inventory.removeItemByUid(context.item.uid, count)

		local owner = context.owner
		local character = if owner:IsA("Player") then owner.Character else owner
		local rootPart = character.PrimaryPart :: BasePart

		local droppedModel = model:Clone()
		droppedModel.Name = definition.name
		droppedModel:PivotTo(rootPart.CFrame * CFrame.new(DROP_OFFSET))
		droppedModel:SetAttribute("itemDefinitionId", definition.id)
		droppedModel:SetAttribute("count", count)
		droppedModel:AddTag(DROP_ITEM_TAG)
		droppedModel.Parent = Workspace
	end,
})

return Droppable
