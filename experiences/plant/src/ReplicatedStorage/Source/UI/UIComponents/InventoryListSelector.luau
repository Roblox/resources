--!strict

--[[
	A wrapper for ListSelector that acts as a base class for 'Inventory' List Selector UI layers, including:
	 - UIInventory
	 - UIPlacePot
	 - UIPlantSeed

	The following functionality is appended to ListSelector:
	 - Updating the ListItem and Sidebar to show the number of items owned
	 - Hiding ListItems for which the player owns none of this item
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ListSelector = require(ReplicatedStorage.Source.UI.UIComponents.ListSelector)
local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local Signal = require(ReplicatedStorage.Source.Signal)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local getItemAmountInInventory = require(ReplicatedStorage.Source.Utility.PlayerData.getItemAmountInInventory)

export type ListSelectorProperties = ListSelector.ListSelectorProperties

local InventoryListSelector = {}
InventoryListSelector.__index = InventoryListSelector

export type ClassType = typeof(setmetatable(
	{} :: {
		_listSelector: ListSelector.ClassType,
		_connections: Connections.ClassType,
		updated: Signal.ClassType,
	},
	InventoryListSelector
))

function InventoryListSelector.new(listSelectorProperties: ListSelector.ListSelectorProperties): ClassType
	local self = {
		_listSelector = ListSelector.new(listSelectorProperties),
		_connections = Connections.new(),
		updated = Signal.new(),
	}
	setmetatable(self, InventoryListSelector)

	self:_setup()
	return self
end

function InventoryListSelector._setup(self: ClassType)
	self:_update()

	local dataConnection = PlayerDataClient.updated:Connect(function(valueName: any)
		if valueName :: string ~= PlayerDataKey.Inventory then
			return
		end
		self:_update()
	end)

	local selectionConnection = self._listSelector.selectionChanged:Connect(function()
		self:_update()
	end)

	self._connections:add(dataConnection, selectionConnection)
end

function InventoryListSelector._update(self: ClassType)
	-- Avoid updating UI and making connections for invisible UI, as it will get called again whenever it's made visible
	if not self._listSelector:isVisible() then
		return
	end

	self:_updateListItems()
	self:_updateSidebar()
	self.updated:Fire()
end

function InventoryListSelector._updateListItems(self: ClassType)
	for itemId, listItem in pairs(self._listSelector:getListItems()) do
		local amount = getItemAmountInInventory(itemId)

		local amountText = tostring(amount)
		local isVisible = amount > 0

		listItem:setAmountText(amountText)
		listItem:setVisible(isVisible)
	end
end

function InventoryListSelector._updateSidebar(self: ClassType)
	local listSelector = self._listSelector
	local sidebar = listSelector:getSidebar()
	local selectedItemIdMaybe = listSelector:getSelectedId()

	if not selectedItemIdMaybe then
		sidebar:reset()
		return
	end
	local selectedItemId = selectedItemIdMaybe :: string

	local amount = getItemAmountInInventory(selectedItemId)
	local footerText = tostring(amount)
	sidebar:setFooterText(footerText)

	sidebar:setInfo(selectedItemId)
end

function InventoryListSelector.getListSelector(self: ClassType)
	return self._listSelector
end

function InventoryListSelector.destroy(self: ClassType)
	self._listSelector:destroy()
	self.updated:DisconnectAll()
	self._connections:disconnect()
end

return InventoryListSelector
