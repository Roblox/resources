--!strict

--[[
	Connects timers to tagged GUIObjects. Timers are used to display countdowns in the UI.

	There are three types of timers:
		1. Round Progress Bars: A circular perimeter is progressively filled based on the percentage of remaining time.
		2. Progress Bars: A linear bar is progressively filled based on the percentage of remaining time
		3. Text: A TextLabel is updated to the timer's remaining time in numbers and abbreviations for units of time.
		
	When Text timer expires, it will be assigned an FeaturePackagesTimerExpired=true attribute so that client code knows the timer has ran out and can
		perform any necessary cleanup.

	Timers rely on attributes to be set on the GUIObjects
	Attributes:
		- Start: The Unix timestamp when the timer started.
		- End: The Unix timestamp when the timer ends.
--]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SharedConstants = require(ReplicatedStorage.FeaturePackagesCore.Configs.SharedConstants)
local TranslationStrings = require(ReplicatedStorage.FeaturePackagesCore.Configs.TranslationStrings)
local Attributes = require(ReplicatedStorage.FeaturePackagesCore.Configs.Attributes)
local formatTime = require(ReplicatedStorage.FeaturePackagesCore.Utils.formatTime)
local getAttribute = require(ReplicatedStorage.FeaturePackagesCore.Utils.getAttribute)
local getInstance = require(ReplicatedStorage.FeaturePackagesCore.Utils.getInstance)
local UITween = require(ReplicatedStorage.FeaturePackagesCore.Modules.UITween)

local UPDATE_INTERVAL_SECONDS = 1 -- The interval at which all timers are updated

local lastUpdate = 0

-- Used to return the percentage of time elapsed if the object has start and end attributes
local function getPercentTimeElapsed(timer: GuiObject): number?
	local startUtc: number = getAttribute(timer, Attributes.FeaturePackagesStart)
	local endUtc: number = getAttribute(timer, Attributes.FeaturePackagesEnd)

	local now = Workspace:GetServerTimeNow()
	local timeRemaining = os.difftime(endUtc, now)
	local percentTimeElapsed = 1 - timeRemaining / (endUtc - startUtc)
	return math.clamp(percentTimeElapsed, 0, 1)
end

local function updateRoundProgressBars()
	for _, roundProgressBar in CollectionService:GetTagged(SharedConstants.Tags.Timer.ROUND_PROGRESS_BAR) do
		assert(roundProgressBar:IsA("GuiObject"), "Round Progress Bars must be gui objects")

		local percentTimeElapsed = getPercentTimeElapsed(roundProgressBar)
		if not percentTimeElapsed then
			continue
		end

		local value = percentTimeElapsed * 360

		local rightMask: GuiObject = getInstance(roundProgressBar, "Right", "Mask")
		local leftMask: GuiObject = getInstance(roundProgressBar, "Left", "Mask")
		local rightMaskRotation = math.clamp(value - 180, -180, 0)
		local leftMaskRotation = leftMask.Rotation
		local leftMaskVisible = false

		if value > 180 then
			leftMaskRotation = math.clamp(value - 360, -180, 0)
			leftMaskVisible = true
		end

		rightMask.Rotation = rightMaskRotation
		leftMask.Visible = leftMaskVisible
		leftMask.Rotation = leftMaskRotation

		local isCompleted = percentTimeElapsed >= 1
		if isCompleted then
			CollectionService:RemoveTag(roundProgressBar, SharedConstants.Tags.Timer.ROUND_PROGRESS_BAR)
		end
	end
end

local function updateProgressBars()
	for _, progressBar in CollectionService:GetTagged(SharedConstants.Tags.Timer.PROGRESS_BAR) do
		assert(progressBar:IsA("GuiObject"), "Progress bars must be gui objects")

		local percentTimeElapsed = getPercentTimeElapsed(progressBar)
		if not percentTimeElapsed then
			continue
		end

		assert(
			progressBar.Parent and progressBar.Parent:IsA("GuiObject"),
			"Progress bars must be children of a gui object"
		)
		local parent: GuiObject = progressBar.Parent
		local minScaleX = parent.AbsoluteSize.Y / parent.AbsoluteSize.X

		local newSize = UDim2.fromScale(math.max(minScaleX, percentTimeElapsed), 1)
		UITween.size(progressBar, newSize, UPDATE_INTERVAL_SECONDS)

		local isCompleted = percentTimeElapsed >= 1
		if isCompleted then
			CollectionService:RemoveTag(progressBar, SharedConstants.Tags.Timer.PROGRESS_BAR)
		end
	end
end

local function updateClocks()
	for _, timerLabel in CollectionService:GetTagged(SharedConstants.Tags.Timer.TEXT) do
		assert(timerLabel:IsA("TextLabel"), "Progress bars must be text labels")

		local endUtc: number = getAttribute(timerLabel, Attributes.FeaturePackagesEnd)
		local now = Workspace:GetServerTimeNow()
		local timeRemaining = os.difftime(endUtc, now)

		if timeRemaining <= 0 then
			timerLabel.Text = TranslationStrings.OFFER_EXPIRED
			CollectionService:RemoveTag(timerLabel, SharedConstants.Tags.Timer.TEXT)
			timerLabel:SetAttribute(Attributes.FeaturePackagesTimerExpired, true)
			continue
		end

		local includesSuffix: boolean = getAttribute(timerLabel, Attributes.FeaturePackagesIncludeSuffix)
		local selectMaxUnits = 0
		local success, result = pcall(getAttribute, timerLabel, Attributes.FeaturePackagesMaxUnits)
		if success then
			selectMaxUnits = result
		end
		local suffix = if includesSuffix then TranslationStrings.LEFT else nil
		local includesPadding = if includesSuffix then true else false
		local maxUnits = if includesSuffix then 3 else 2
		if type(selectMaxUnits) == "number" and selectMaxUnits > 1 then
			maxUnits = selectMaxUnits
		end
		local formattedTime = formatTime(timeRemaining, maxUnits, includesPadding, suffix)
		timerLabel.Text = formattedTime
	end
end

local function onHeartbeat()
	local elapsed = os.clock() - lastUpdate
	if elapsed < UPDATE_INTERVAL_SECONDS then
		return
	end
	lastUpdate = os.clock()

	updateClocks()
	updateProgressBars()
	updateRoundProgressBars()
end

local function initialize()
	RunService.Heartbeat:Connect(onHeartbeat)
end

initialize()
