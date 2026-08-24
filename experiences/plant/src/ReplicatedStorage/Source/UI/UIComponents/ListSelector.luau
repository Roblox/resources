--!strict

--[[
	Component class for selecting an item from a list. Provides events and functions
	that can be used by other classes to add functionality to choosing an item and
	activating the sidebar button for it.

	This is used in several UI layer singletons to create similar guis
	where an item is selected from a list and some action is done for that item.
--]]

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local ListItem = require(script.Parent.Parent.UIComponents.ListItem)
local Sidebar = require(script.Parent.Parent.UIComponents.Sidebar)
local CloseButton = require(script.Parent.Parent.UIComponents.CloseButton)
local Signal = require(ReplicatedStorage.Source.Signal)
local InputCategorizer = require(ReplicatedStorage.Source.InputCategorizer)
local InputCategory = require(ReplicatedStorage.Source.SharedConstants.InputCategory)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local autoSizeCanvasHeight = require(ReplicatedStorage.Source.Utility.UI.autoSizeCanvasHeight)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local prefabInstance: ScreenGui = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "ListSelectorGuiPrefab")

export type ListSelectorProperties = {
	primaryColor: Color3,
	secondaryColor: Color3,
	title: string,
	titleIconImageId: number?,
	footerDescription: string,
	footerIconId: number?,
	itemIds: { string }, -- The order of this list is the order in which they appear
}

assert(not prefabInstance.ResetOnSpawn, "ListSelectorGuiPrefab.ResetOnSpawn should be false")

local ListSelector = {}
ListSelector.__index = ListSelector

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: ScreenGui,
		_sidebar: Sidebar.ClassType,
		_closeButton: CloseButton.ClassType,
		_listItemsById: { [string]: ListItem.ClassType },
		_selectedItemId: string?,
		_connections: Connections.ClassType,
		_selectedListItem: ListItem.ClassType?,
		_isVisible: boolean,
		_itemIds: { string },
		selectionChanged: Signal.ClassType,
		closed: Signal.ClassType,
	},
	ListSelector
))

function ListSelector.new(properties: ListSelectorProperties): ClassType
	local instance = prefabInstance:Clone()
	-- Name each instance for easier viewing in the Explorer, removing whitespace
	-- to maintain consistency with the prefab name
	instance.Name = instance.Name .. properties.title:gsub("%s", "")

	local self = {
		_instance = instance,
		_sidebar = Sidebar.new({
			primaryColor = properties.primaryColor,
			secondaryColor = properties.secondaryColor,
			footerDescription = properties.footerDescription,
		}),
		_closeButton = CloseButton.new(),
		_listItemsById = {},
		_selectedItemId = nil,
		_connections = Connections.new(),
		_selectedListItem = nil,
		_isVisible = false,
		_itemIds = properties.itemIds,
		selectionChanged = Signal.new(),
		closed = Signal.new(),
	}

	setmetatable(self, ListSelector)

	self:_setup(properties)

	return self
end

function ListSelector.setParent(self: ClassType, parent: Instance)
	self._instance.Parent = parent
end

function ListSelector._setup(self: ClassType, properties: ListSelectorProperties)
	local sidebarFrame: Frame = getInstance(self._instance, "ContainerFrame", "SidebarFrame")
	local closeButtonHolder: Frame = getInstance(self._instance, "ContainerFrame", "SidebarFrame", "CloseButtonHolder")
	self._sidebar:setParent(sidebarFrame)
	self._closeButton:setParent(closeButtonHolder)

	self:_setupCloseButton()
	self:_setupListItems(properties)
	self:_setTitle(properties.title, properties.titleIconImageId, properties.primaryColor)

	-- To enable/disable gamepad selection
	local inputTypeChangedConnection = InputCategorizer.changed:Connect(function()
		if not self._isVisible then
			return
		end
		self:_updateSelection()
	end)

	-- TODO: Figure out why having UIAspectRatioConstraint breaks AutomaticCanvasSize and remove this custom solution once fixed
	local itemScrollingFrame: ScrollingFrame =
		getInstance(self._instance, "ContainerFrame", "MainFrame", "ItemScrollingFrame")
	local canvasHeightConnection = autoSizeCanvasHeight(itemScrollingFrame)

	self._connections:add(inputTypeChangedConnection, canvasHeightConnection)

	self:hide()
end

function ListSelector._onItemSelected(self: ClassType, itemId: string?)
	if not itemId then
		self._sidebar:reset()
	end

	self._selectedItemId = itemId
	self.selectionChanged:Fire(itemId)
end

function ListSelector._setupListItems(self: ClassType, listSelectorProperties: ListSelectorProperties)
	for index, itemId in ipairs(listSelectorProperties.itemIds) do
		self:_createListItem(index, itemId)
	end
end

function ListSelector._createListItem(self: ClassType, listIndex: number, itemId: string)
	local itemScrollingFrame: ScrollingFrame =
		getInstance(self._instance, "ContainerFrame", "MainFrame", "ItemScrollingFrame")
	local listItem = ListItem.new(itemId, listIndex)
	listItem:setParent(itemScrollingFrame)

	self:_listenToListItemInput(listItem, itemId)
	self._listItemsById[itemId] = listItem
end

function ListSelector._listenToListItemInput(self: ClassType, listItem, itemId: string)
	-- Treat a ListItem selection as an activation so the item can be shown in the sidebar
	local listItemSelectedConnection = listItem:getButton().selected:Connect(function(isSelected: any)
		if not isSelected :: boolean then
			return
		end
		self:_onItemSelected(itemId)
	end)

	local listItemActivatedConnection = listItem:getButton().activated:Connect(function()
		self:_onItemSelected(itemId)
	end)

	local listItemEnabledConnection = listItem.enabledChanged:Connect(function()
		self:_updateSelection()
	end)

	self._connections:add(listItemSelectedConnection, listItemActivatedConnection, listItemEnabledConnection)
end

function ListSelector._setupSidebar(self: ClassType, properties: ListSelectorProperties)
	local sidebarFrame: Frame = getInstance(self._instance, "ContainerFrame", "SidebarFrame")
	self._sidebar:setParent(sidebarFrame)
end

function ListSelector._setupCloseButton(self: ClassType)
	local closeActivatedConnection = self._closeButton:getButton().activated:Connect(function()
		self.closed:Fire()
	end)

	self._connections:add(closeActivatedConnection)
end

function ListSelector._setTitle(self: ClassType, text: string, iconId: number?, color: Color3)
	local titleFrame: Frame = getInstance(self._instance, "ContainerFrame", "MainFrame", "TitleFrame")
	local titleIcon: ImageLabel = getInstance(titleFrame, "TitleIcon")
	local titleTextLabel: TextLabel = getInstance(titleFrame, "TitleTextLabel")
	titleTextLabel.Text = text
	titleTextLabel.TextColor3 = color
	titleIcon.Image = if iconId
		then PlayerFacingString.ImageAsset.Prefix .. tostring(iconId)
		else PlayerFacingString.ImageAsset.None
end

function ListSelector.getListItems(self: ClassType)
	return self._listItemsById
end

function ListSelector.setAllListItemsEnabled(self: ClassType, isEnabled: boolean)
	for _, listItem in pairs(self._listItemsById) do
		listItem:setEnabled(isEnabled)
	end
end

function ListSelector.setListItemEnabled(self: ClassType, itemId: string, isEnabled: boolean)
	self._listItemsById[itemId]:setEnabled(isEnabled)
end

function ListSelector.getSidebar(self: ClassType)
	return self._sidebar
end

function ListSelector.getCloseButton(self: ClassType)
	return self._closeButton
end

function ListSelector.show(self: ClassType)
	-- TODO: Animate
	self._isVisible = true
	self:setAllListItemsEnabled(true)
	self._closeButton:getButton():setEnabled(true)
	self._instance.Enabled = true
	self:_updateSelection()
end

function ListSelector.hide(self: ClassType)
	-- TODO: Animate
	self._isVisible = false
	-- Prevent buttons from getting pressed via KeyCode bindings while hidden
	self:setAllListItemsEnabled(false)
	self._sidebar:getActionButton():setEnabled(false)
	self._closeButton:getButton():setEnabled(false)
	self._instance.Enabled = false
	self:_updateSelection()
end

-- A list item can be selected if it is visible (i.e. not hidden) and its button instance is also visible (i.e. not disabled)
-- Note this does not account for the layer being visible, that should be checked separately if you care about that.
function ListSelector._canSelectItemId(self: ClassType, itemId: string)
	local selectedListItem = self._listItemsById[itemId]
	assert(selectedListItem, string.format("No list item created for itemId %s", itemId))

	local listItemInstance = selectedListItem:getInstance()
	local buttonInstance = selectedListItem:getButton():getInstance()

	if not (listItemInstance.Visible and buttonInstance.Visible) then
		return false
	end

	return true
end

function ListSelector._updateSelection(self: ClassType)
	local selectedId = self._selectedItemId
	if self._isVisible then
		if selectedId and self:_canSelectItemId(selectedId) then
			-- Previous selection is still valid, re-select it
			self:_selectListItemWithId(selectedId)
		else
			-- Previous selection is now invalid; select the first list item
			-- This can happen if a list item is no longer selectable, such as if a player plants their
			-- last seed of a type, that previously selected list item is now no longer available
			self:_selectFirstVisibleListItem()
		end
	else
		-- Avoid clearing SelectedObject if some other gui has stolen selection
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self._instance) then
			GuiService.SelectedObject = nil
		end
	end
end

function ListSelector._selectListItemWithId(self: ClassType, itemId: string)
	if InputCategorizer.getLast() == InputCategory.Gamepad then
		-- Setting SelectedObject fires the .selected event, which will in turn end up calling
		-- the _onItemSelected method and sync this class's current selection with the gamepad selection
		GuiService.SelectedObject = self._listItemsById[itemId]:getButton():getInstance()
	else
		GuiService.SelectedObject = nil
		self:_onItemSelected(itemId)
	end
end

function ListSelector._selectFirstVisibleListItem(self: ClassType)
	-- This assumes that the order of _itemProperties matches the sort order of LayoutOrder,
	-- which is always the case here since we generated the list items from the same list
	-- and set their LayoutOrder to the index in this list during setup.
	-- If it wasn't, this could select an item that is visually not first in the list.
	local firstVisibleItemId = Freeze.List.find(self._itemIds, function(itemId: string)
		return self:_canSelectItemId(itemId)
	end, nil)

	if not firstVisibleItemId then
		-- No visible list items, clear selection
		self:_onItemSelected(nil)
		return
	end

	if InputCategorizer.getLast() == InputCategory.Gamepad then
		local listItemInstance = self._listItemsById[firstVisibleItemId]:getInstance()

		-- Setting the SelectedObject property triggers the .selected event, which will
		-- in turn call the _onItemSelected method and sync this class's current selection
		-- with the gamepad selection
		GuiService.SelectedObject = getInstance(listItemInstance, "ButtonPrefab")
	else
		GuiService.SelectedObject = nil
		self:_onItemSelected(firstVisibleItemId)
	end
end

function ListSelector.getInstance(self: ClassType)
	return self._instance
end

function ListSelector.getSelectedId(self: ClassType): string?
	return self._selectedItemId
end

function ListSelector.isVisible(self: ClassType)
	return self._isVisible
end

function ListSelector.destroy(self: ClassType)
	self._instance:Destroy()
	self._sidebar:destroy()
	self._closeButton:destroy()
	self.selectionChanged:DisconnectAll()
	self.closed:DisconnectAll()

	for _, listItem in pairs(self._listItemsById) do
		listItem:destroy()
	end

	self._connections:disconnect()
end

return ListSelector
