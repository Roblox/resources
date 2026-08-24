--!strict

--[[
	Creates a BillboardGui timer on a plant showing the growth time progress based on
	its current stage and growing time attributes
--]]

local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local waitForChildWithAttributeAsync = require(ReplicatedStorage.Source.Utility.waitForChildWithAttributeAsync)
local setInterval = require(ReplicatedStorage.Source.Utility.setInterval)
local formatTime = require(ReplicatedStorage.Source.Utility.formatTime)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local timerPrefab: BillboardGui =
	getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "PlantStageTimerBillboardGui")

local PlantStageTimer = {}
PlantStageTimer.__index = PlantStageTimer

export type ClassType = typeof(setmetatable(
	{} :: {
		_plantModel: Model,
		_destroyed: boolean,
		_stageModel: Model?,
		_timerInstance: Instance?,
		_clearInterval: (() -> nil)?,
		_tween: Tween?,
	},
	PlantStageTimer
))

function PlantStageTimer.new(plantModel: Model): ClassType
	local self = {
		_plantModel = plantModel,
		_destroyed = false,
		_stageModel = nil,
		_timerInstance = nil,
		_clearInterval = nil,
		_tween = nil,
	}

	setmetatable(self, PlantStageTimer)

	task.spawn(function()
		self:_waitForReplicationAsync()

		if self._destroyed then
			return
		end

		self:_createTimer()
		self:_startProgressBar()
	end)

	return self
end

function PlantStageTimer._waitForReplicationAsync(self: ClassType)
	if not self._plantModel.PrimaryPart then
		self._plantModel:GetPropertyChangedSignal("PrimaryPart"):Wait()
	end
	local stages = self._plantModel:WaitForChild("Stages") :: Folder

	local currentStage: number = getAttribute(self._plantModel, Attribute.CurrentStage)
	self._stageModel = waitForChildWithAttributeAsync(stages, Attribute.StageNumber, currentStage) :: Model
end

function PlantStageTimer._createTimer(self: ClassType)
	local timerInstance = timerPrefab:Clone() :: BillboardGui

	local primaryPart = self._plantModel.PrimaryPart :: BasePart
	timerInstance.Parent = primaryPart

	self._timerInstance = timerInstance
end

function PlantStageTimer._startProgressBar(self: ClassType)
	assert(self._stageModel, "Cannot start progress bar until replication has completed")

	local totalSeconds: number = getAttribute(self._stageModel, Attribute.GrowTime)
	local finishesGrowingAt: number = getAttribute(self._plantModel, Attribute.FinishesGrowingAt)

	-- :GetServerTimeNow() allows the client timer to match the server's timer exactly regardless of network latency
	local secondsLeft = math.ceil(math.clamp(finishesGrowingAt - Workspace:GetServerTimeNow(), 0, totalSeconds))
	local currentProgressScale = (totalSeconds - secondsLeft) / totalSeconds

	self:_renderProgressBar(currentProgressScale, secondsLeft)
	self:_startCountdownText(finishesGrowingAt, totalSeconds)
end

function PlantStageTimer._renderProgressBar(self: ClassType, currentProgressScale, secondsLeft)
	assert(self._timerInstance, "Cannot render progress bar until the timer has been created")

	local progressBar: Frame = getInstance(self._timerInstance, "Background", "ProgressBar")
	progressBar.Size = UDim2.fromScale(currentProgressScale, 1)

	self._tween = TweenService:Create(
		progressBar,
		TweenInfo.new(secondsLeft, Enum.EasingStyle.Linear),
		{ Size = UDim2.fromScale(1, 1) }
	)
end

function PlantStageTimer._startCountdownText(self: ClassType, finishesGrowingAt: number, totalSeconds: number)
	assert(self._timerInstance, "Cannot start countdown text until the timer has been created")
	assert(self._tween, "Cannot start countdown text until the progress bar has been rendered") --TODO: Can we simplify this chain of functions?

	local countdownLabel: TextLabel = getInstance(self._timerInstance, "CountdownLabel")

	local function updateCountdown()
		-- :GetServerTimeNow() allows the client timer to match the server's timer exactly regardless of network latency
		local secondsLeft = math.ceil(math.clamp(finishesGrowingAt - Workspace:GetServerTimeNow(), 0, totalSeconds))

		countdownLabel.Text = formatTime(secondsLeft)
	end

	updateCountdown()

	self._clearInterval = setInterval(updateCountdown, 1)
	self._tween:Play()
end

function PlantStageTimer.destroy(self: ClassType)
	self._destroyed = true

	if self._clearInterval then
		self._clearInterval()
		self._clearInterval = nil
	end

	if self._tween then
		self._tween:Destroy()
		self._tween = nil
	end

	if self._timerInstance then
		self._timerInstance:Destroy()
		self._timerInstance = nil
	end
end

return PlantStageTimer
