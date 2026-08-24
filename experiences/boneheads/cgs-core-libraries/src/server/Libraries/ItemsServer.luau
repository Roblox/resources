-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Core.Libraries.Items.Constants)
local Types = require(ReplicatedStorage.Core.Libraries.Items.Types)

local itemDefinitions: { [Types.ItemDefinitionName]: Types.ItemDefinition } = {}

local ItemsServer = {}

function ItemsServer.createItem(itemModel: Types.ItemModel, character: Model): Types.ItemController
	local definitionName = itemModel:GetAttribute(Constants.DEFINITION_ATTRIBUTE) :: string?
	assert(definitionName, `Item model {itemModel.Name} is missing definition attribute`)

	local itemDefinition = itemDefinitions[definitionName]
	assert(itemDefinition, `Item definition {definitionName} not found`)

	return itemDefinition.constructor(itemModel, character)
end

function ItemsServer.destroyItem(item: Types.ItemController)
	local itemModel = item.getModel()
	if itemModel.Parent then
		itemModel:Destroy()
	end

	item.cleanup()
end

function ItemsServer.autoLoad(target: Instance)
	for _, itemDefinitionModule in target:GetChildren() do
		local itemDefinition = require(itemDefinitionModule) :: Types.ItemDefinition
		itemDefinitions[itemDefinitionModule.Name] = itemDefinition
	end
end

return ItemsServer
