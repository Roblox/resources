--!strict

--[[
	Shows an animation whenever new items get added to inventory to make it obvious
	to the user they have new items available.

	Once the projectile lands, the inventory icon plays a "catch" animation (momentarily resizes larger)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local ProjectileIconQueue = require(script.Parent.ProjectileIconQueue)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local getCategoryForItemId = require(ReplicatedStorage.Source.Utility.Farm.getCategoryForItemId)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local CATCH_SIZE_MULTIPLIER = 1.25 -- Inventory button gets resized by this amount as a "Catch" animation
local CATCH_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)

local InventoryAnimator = {}
InventoryAnimator.__index = InventoryAnimator

export type ClassType = typeof(setmetatable(
	{} :: {
		_firstUpdate: boolean,
		_isAnimationPending: boolean,
		_isDestroyed: boolean,
		_oldItemCountByItemId: {},
		_screenGui: ScreenGui,
		_inventoryButton: ImageLabel,
		_projectileIconQueue: ProjectileIconQueue.ClassType,
		_connections: Connections.ClassType,
	},
	InventoryAnimator
))

function InventoryAnimator.new(inventoryButtonScreenGui: ScreenGui): ClassType
	local inventoryButton: ImageLabel = getInstance(inventoryButtonScreenGui, "IconFrame", "Icon")

	local self = {
		_firstUpdate = true,
		_isAnimationPending = false,
		_isDestroyed = false,
		_oldItemCountByItemId = {},
		_screenGui = inventoryButtonScreenGui,
		_inventoryButton = inventoryButton,
		_projectileIconQueue = ProjectileIconQueue.new(inventoryButtonScreenGui, inventoryButton),
		_connections = Connections.new(),
	}

	setmetatable(self, InventoryAnimator)

	self:_listenForDataChanges()
	self:_listenForIconCompleted()

	return self
end

function InventoryAnimator._listenForDataChanges(self: ClassType)
	local dataUpdatedConnection = PlayerDataClient.updated:Connect(function(key: any)
		if key :: string ~= PlayerDataKey.Inventory then
			return
		end

		-- The animation waits to play until the inventory button is visible. In order to avoid triggering any duplicate animations
		-- while the first animation thread is waiting, we use this _isAnimationPending debounce flag. When the first animation thread
		-- resumes, it calculates a total diff since the last animation played, so no later deltas are lost.
		if self._isAnimationPending then
			return
		end

		self._isAnimationPending = true
		self:_waitForVisibleAsync()

		if self._isDestroyed then
			return
		end

		self:_animateDeltas()
		self._isAnimationPending = false
	end)

	self._connections:add(dataUpdatedConnection)
end

function InventoryAnimator._waitForVisibleAsync(self: ClassType)
	while not self._screenGui.Enabled do
		self._screenGui:GetPropertyChangedSignal("Enabled"):Wait()
	end
end

function InventoryAnimator._listenForIconCompleted(self: ClassType)
	local inventoryCatchTween = TweenService:Create(self._inventoryButton, CATCH_TWEEN_INFO, {
		Size = UDim2.fromScale(
			self._inventoryButton.Size.X.Scale * CATCH_SIZE_MULTIPLIER,
			self._inventoryButton.Size.Y.Scale * CATCH_SIZE_MULTIPLIER
		),
	})

	local iconCompletedConnection = self._projectileIconQueue.iconCompleted:Connect(function()
		inventoryCatchTween:Play()
	end)

	self._connections:add(iconCompletedConnection)
end

function InventoryAnimator._animateDeltas(self: ClassType)
	-- Get deltas for each inventory item since last animation
	local inventoryDeltasByItemId = self:_getInventoryDeltasByItemId() -- Updates old data to diff next time
	local inventoryDeltasByItemPrefab = {}

	-- Convert ItemId keys to ItemPrefab
	for itemId, delta in pairs(inventoryDeltasByItemId) do
		local category: ItemCategory.EnumType = getCategoryForItemId(itemId)
		local itemPrefab = getItemByIdInCategory(itemId, category)
		inventoryDeltasByItemPrefab[itemPrefab] = delta
	end

	-- Only animate the deltas if it's not the initial data load
	if self._firstUpdate then
		self._firstUpdate = false
	else
		self._projectileIconQueue:animateDeltas(inventoryDeltasByItemPrefab)
	end
end

function InventoryAnimator._getInventoryDeltasByItemId(self: ClassType)
	local inventory = PlayerDataClient.get(PlayerDataKey.Inventory)
	local itemCountByItemId = Freeze.Dictionary.flatten(inventory)

	-- Calculate deltas for all items in the old list
	local oldInventoryDeltasByItemId = Freeze.Dictionary.map(
		self._oldItemCountByItemId,
		function(oldCount: number, itemId: string)
			local newCount = itemCountByItemId[itemId] or 0
			return newCount - oldCount, itemId
		end
	)

	-- Replace all values in the new list with the deltas. Any remaining items are newly added, so they remain positive.
	local inventoryDeltasByItemId = Freeze.Dictionary.merge(itemCountByItemId, oldInventoryDeltasByItemId)

	-- Update the cached list to compare against next time this function is called
	self._oldItemCountByItemId = itemCountByItemId

	return inventoryDeltasByItemId
end

function InventoryAnimator.destroy(self: ClassType)
	self._projectileIconQueue:destroy()
	self._isDestroyed = true

	self._connections:disconnect()
end

return InventoryAnimator
