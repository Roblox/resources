--!strict

--[[
	Provides an interface for scripts to hide and show UI Layers.

	UI Layers are singleton classes (typically made up of UI Components). They are found in the
	ReplicatedStorage.UI.UILayers directory

	There are two types of UI Layer:

	- HeadsUpDisplay (HUD): HUD visibility can be toggled. When a Menu is visible, all HUD layers are hidden
	- Menu (Menu): Menu visibility can be toggled. Only one menu is visible at a time, with previously visible menus inserted into a queue
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Source.Signal)
local UILayerType = require(ReplicatedStorage.Source.SharedConstants.UILayerType)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)

export type LayerDataType = {
	isVisible: boolean, -- Current visibility status
	layerType: UILayerType.EnumType,
	layerClassInstance: any,
	visibilityChangedSignal: Signal.ClassType, -- Fired when a layer's visibility status is updated
}

local UIHandler = {}
UIHandler._menuQueue = {} :: { UILayerId.EnumType } -- A queue of menu layer ids, with the front of the queue storing the currently visible menu id
UIHandler._hudLayersEnabledByLayerId = {} :: { [UILayerId.EnumType]: boolean } -- A map of HUD layers that should be visible when no menus are present
UIHandler._layerDataById = {} :: { [UILayerId.EnumType]: LayerDataType } -- Data for each registered layer
UIHandler._lastAreMenusVisible = false :: boolean -- Tracks whether menus are visible, used to ensure changed signal only fires when it changes
UIHandler.areMenusVisibleChanged = Signal.new() :: Signal.ClassType -- Fires when changing from no menus visible to any menu being visible, and vice versa

function UIHandler.registerLayer(
	layerId: UILayerId.EnumType,
	layerType: UILayerType.EnumType,
	layerClassInstance: any
): Signal.ClassType
	assert(
		not UIHandler._layerDataById[layerId],
		string.format("LayerId %s has already been registered to UIHandler", layerId)
	)

	UIHandler._layerDataById[layerId] = {
		isVisible = false,
		layerType = layerType,
		layerClassInstance = layerClassInstance,
		visibilityChangedSignal = Signal.new(),
	} :: LayerDataType

	-- TODO: Add getVisibilityChangedSignal() and refactor code to use that
	return UIHandler._layerDataById[layerId].visibilityChangedSignal
end

function UIHandler._updateLayerVisibility(layerId: UILayerId.EnumType, isVisible: boolean)
	-- We do not want to update the layer if its visibility is unchanged
	if isVisible == UIHandler._layerDataById[layerId].isVisible then
		return
	end

	UIHandler._layerDataById[layerId].isVisible = isVisible
	local signal = UIHandler._layerDataById[layerId].visibilityChangedSignal

	-- Fire the signal returned by registerLayer so the given layer can hide itself
	signal:Fire(isVisible)
end

function UIHandler._updateAllLayers()
	local areMenusVisible = #UIHandler._menuQueue > 0

	for layerId: UILayerId.EnumType, layerData in UIHandler._layerDataById do
		local isLayerVisible = false

		if layerData.layerType == UILayerType.HeadsUpDisplay then
			-- HUD layers should be visible if the UIHandler.show() has been called for them
			-- AND no menus are currently visible
			isLayerVisible = if UIHandler._hudLayersEnabledByLayerId[layerId] and not areMenusVisible
				then true
				else false
		elseif layerData.layerType == UILayerType.Menu then
			-- Menus should be visible if they are at the front of the menu queue
			isLayerVisible = UIHandler._menuQueue[1] == layerId
		end

		UIHandler._updateLayerVisibility(layerId, isLayerVisible)
	end

	if areMenusVisible ~= UIHandler._lastAreMenusVisible then
		UIHandler._lastAreMenusVisible = areMenusVisible
		UIHandler.areMenusVisibleChanged:Fire(areMenusVisible)
	end
end

function UIHandler.areMenusVisible()
	return UIHandler._lastAreMenusVisible
end

function UIHandler._showMenu(layerId: UILayerId.EnumType)
	-- A single menu shouldn't feature in the queue twice, so we will remove the existing
	-- entry if there is one
	local layerIndexInQueue = table.find(UIHandler._menuQueue, layerId)
	if layerIndexInQueue then
		table.remove(UIHandler._menuQueue, layerIndexInQueue)
	end

	table.insert(UIHandler._menuQueue, 1, layerId)

	UIHandler._updateAllLayers()
end

function UIHandler._hideMenu(layerId: UILayerId.EnumType)
	-- We want hideMenu to remove a menu from the queue even if it is not at the front to avoid
	-- it being shown due to a menu ahead of it in the queue getting hidden and revealing this menu
	local layerIndexInQueue = table.find(UIHandler._menuQueue, layerId)
	if layerIndexInQueue then
		table.remove(UIHandler._menuQueue, layerIndexInQueue)
	end

	UIHandler._updateAllLayers()
end

function UIHandler._showHud(layerId: UILayerId.EnumType)
	UIHandler._hudLayersEnabledByLayerId[layerId] = true
	UIHandler._updateAllLayers()
end

function UIHandler._hideHud(layerId: UILayerId.EnumType)
	UIHandler._hudLayersEnabledByLayerId[layerId] = nil
	UIHandler._updateAllLayers()
end

function UIHandler.show(layerId: UILayerId.EnumType)
	local layerType = UIHandler._layerDataById[layerId].layerType

	if layerType == UILayerType.Menu then
		UIHandler._showMenu(layerId)
	elseif layerType == UILayerType.HeadsUpDisplay then
		UIHandler._showHud(layerId)
	else
		error(string.format("Layer %s has not been registered to UIHandler with a valid UILayerType", layerId))
	end
end

function UIHandler.hide(layerId: UILayerId.EnumType)
	local layerType = UIHandler._layerDataById[layerId].layerType

	if layerType == UILayerType.Menu then
		UIHandler._hideMenu(layerId)
	elseif layerType == UILayerType.HeadsUpDisplay then
		UIHandler._hideHud(layerId)
	else
		error(string.format("Layer %s has not been registered to UIHandler with a valid UILayerType", layerId))
	end
end

function UIHandler.isVisible(layerId: UILayerId.EnumType)
	assert(UIHandler._layerDataById[layerId], string.format("Layer %s has not been registered to UIHandler", layerId))
	return UIHandler._layerDataById[layerId].isVisible
end

function UIHandler.getLayerClassInstanceById(layerId: UILayerId.EnumType)
	assert(UIHandler._layerDataById[layerId], string.format("Layer %s has not been registered to UIHandler", layerId))
	return UIHandler._layerDataById[layerId].layerClassInstance
end

return UIHandler
