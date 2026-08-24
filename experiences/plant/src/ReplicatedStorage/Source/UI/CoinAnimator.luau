--!strict

--[[
	Shows an animation whenever coins get added to player's data to make it obvious
	to the user they got coins.

	Once the projectile lands, the coin indicator plays a "catch" animation (momentarily resizes larger)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local PlayerDataClient = require(ReplicatedStorage.Source.PlayerData.Client)
local ProjectileIconQueue = require(script.Parent.ProjectileIconQueue)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local CATCH_SIZE_MULTIPLIER = 1.25 -- Coin indicator gets resized by this amount as a "Catch" animation
local CATCH_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
local TOTAL_DELTA_TWEEN_INFO = TweenInfo.new(4, Enum.EasingStyle.Quint)
local TOTAL_DELTA_OFFSET = UDim2.fromScale(0, -1)

local deltaPrefab: TextLabel = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "CoinDeltaPrefab")
local coinPrefab: Model = getInstance(ReplicatedStorage, "Instances", "Coin")
local addCoinsSound: Sound = getInstance(SoundService, "SoundEffects", "Coins")
local removeCoinsSound: Sound = getInstance(SoundService, "SoundEffects", "Purchase")

local CoinAnimator = {}
CoinAnimator.__index = CoinAnimator

export type ClassType = typeof(setmetatable(
	{} :: {
		_initialValueSet: boolean,
		_isUpdatePending: boolean,
		_isDestroyed: boolean,
		_oldCoinCount: number,
		_screenGui: ScreenGui,
		_coinIndicatorScreenGui: ScreenGui,
		_coinBackground: Frame,
		_projectileIconQueue: ProjectileIconQueue.ClassType,
		_connections: Connections.ClassType,
	},
	CoinAnimator
))

function CoinAnimator.new(coinIndicatorScreenGui: ScreenGui): ClassType
	local coinBackground: Frame = getInstance(coinIndicatorScreenGui, "Background")

	local self = {
		_initialValueSet = false,
		_isUpdatePending = false,
		_isDestroyed = false,
		_oldCoinCount = 0,
		_screenGui = coinIndicatorScreenGui,
		_coinIndicatorScreenGui = coinIndicatorScreenGui,
		_coinBackground = coinBackground,
		_projectileIconQueue = ProjectileIconQueue.new(coinIndicatorScreenGui, coinBackground),
		_connections = Connections.new(),
	}

	setmetatable(self, CoinAnimator)

	self:_update()
	self:_listenForDataChanges()
	self:_listenForIconCompleted()

	return self
end

function CoinAnimator._listenForDataChanges(self: ClassType)
	local dataUpdatedConnection = PlayerDataClient.updated:Connect(function(key: any)
		if key :: string ~= PlayerDataKey.Coins then
			return
		end

		self:_update()
	end)

	self._connections:add(dataUpdatedConnection)
end

function CoinAnimator._update(self: ClassType)
	task.spawn(function()
		-- The update waits until the coin indicator is visible. In order to avoid triggering unnecessary duplicate updates,
		-- we use this _isUpdatePending debounce flag. When the first update thread
		-- resumes, it calculates a total diff since the last update, so no later deltas are lost.
		if self._isUpdatePending then
			return
		end

		self._isUpdatePending = true
		self:_waitForVisibleAsync()
		self._isUpdatePending = false

		if self._isDestroyed then
			return
		end

		local coins: number = PlayerDataClient.get(PlayerDataKey.Coins)
		local amountTextLabel: TextLabel = getInstance(self._coinBackground, "AmountText")
		amountTextLabel.Text = tostring(coins)

		-- Get coin delta since last update
		local coinDelta = self:_getNextCoinDelta() -- Updates old data to diff next time

		if self._initialValueSet then
			-- Only animate the delta if it's not the initial data load
			self:_animateDelta(coinDelta)
		else
			self._initialValueSet = true
		end
	end)
end

function CoinAnimator._waitForVisibleAsync(self: ClassType)
	while not self._screenGui.Enabled do
		self._screenGui:GetPropertyChangedSignal("Enabled"):Wait()
	end
end

function CoinAnimator._listenForIconCompleted(self: ClassType)
	local coinIndicatorCatchTween = TweenService:Create(self._coinBackground, CATCH_TWEEN_INFO, {
		Size = UDim2.fromScale(
			self._coinBackground.Size.X.Scale * CATCH_SIZE_MULTIPLIER,
			self._coinBackground.Size.Y.Scale * CATCH_SIZE_MULTIPLIER
		),
	})

	local iconCompletedConnection = self._projectileIconQueue.iconCompleted:Connect(function()
		coinIndicatorCatchTween:Play()
	end)

	self._connections:add(iconCompletedConnection)
end

function CoinAnimator._animateDelta(self: ClassType, coinDelta: number)
	if coinDelta == 0 then
		return
	end

	local sound = coinDelta > 0 and addCoinsSound or removeCoinsSound
	sound:Play()

	self._projectileIconQueue:animateDeltas({ [coinPrefab] = coinDelta })

	local deltaElement = deltaPrefab:Clone()
	local prefix = coinDelta > 0 and "+" or "-"

	deltaElement.Text = prefix .. math.abs(coinDelta)
	local amountTextLabel: TextLabel = getInstance(self._coinBackground, "AmountText")
	deltaElement.Parent = amountTextLabel

	local tween = TweenService:Create(
		deltaElement,
		TOTAL_DELTA_TWEEN_INFO,
		{ Position = TOTAL_DELTA_OFFSET, TextTransparency = 1, TextStrokeTransparency = 1 }
	)

	task.spawn(function()
		tween:Play()
		tween.Completed:Wait()
		deltaElement:Destroy()
	end)
end

function CoinAnimator._getNextCoinDelta(self: ClassType)
	local newCount = PlayerDataClient.get(PlayerDataKey.Coins)
	local oldCount = self._oldCoinCount

	-- Update the cached count to compare against next time this function is called
	self._oldCoinCount = newCount

	return newCount - oldCount
end

function CoinAnimator.destroy(self: ClassType)
	self._projectileIconQueue:destroy()
	self._isDestroyed = true

	self._connections:disconnect()
end

return CoinAnimator
