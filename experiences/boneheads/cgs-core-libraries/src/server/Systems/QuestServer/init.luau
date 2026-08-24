-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestUpdateTypes = require(ReplicatedStorage.Core.Systems.Quest.Types)
local Signal = require(ReplicatedStorage.Core.Libraries.Signal)
local Types = require(script.Types)

local remotes = ReplicatedStorage.Core.Systems.Quest.Remotes

export type Quest = Types.Quest
export type QuestDefinition = Types.QuestDefinition
export type StepDefinition = Types.StepDefinition
export type StepTask = Types.StepTask
export type Step = Types.Step

local questDefinitions: { [string]: Types.QuestDefinition } = {}

local activeQuests: { [Player]: { Types.Quest } } = {}
local activePlayers: { [Player]: boolean } = {} -- Used to track which players are ready to receive quest updates (event listener connected on client), to avoid dropping event invocation errors.

local questSignal = Signal.create()

local QuestServer = {}

local function replicateQuestState(player: Player, quest: Types.Quest)
	if not activePlayers[player] then
		return
	end

	local progress, maxProgress = quest.getProgress()
	local name = quest.definition.name

	if quest.isCompleted then
		local questUpdate: QuestUpdateTypes.QuestUpdate = {
			type = "complete",
			id = quest.id,
			name = name,
			maxProgress = maxProgress,
			description = "Completed!",
		}

		remotes.ReplicateQuestState:FireClient(player, questUpdate)
	else
		local description = quest.getStepDescription()
		local questUpdate: QuestUpdateTypes.QuestUpdate = {
			type = "update",
			id = quest.id,
			name = name,
			progress = progress,
			maxProgress = maxProgress,
			description = description,
		}

		remotes.ReplicateQuestState:FireClient(player, questUpdate)
	end
end

local function removeActiveQuest(player: Player, quest: Types.Quest)
	local playerQuests = activeQuests[player]
	if not playerQuests then
		return
	end

	local index = table.find(playerQuests, quest)
	if not index then
		return
	end

	table.remove(playerQuests, index)
	quest.cleanup()
end

function QuestServer.requestQuest(player: Player, questName: string): Types.Quest?
	local questDefinition = questDefinitions[questName]
	assert(questDefinition, `No quest definition found for "{questName}"`)

	if questDefinition.unique == true and QuestServer.hasActiveQuestByDefinition(player, questDefinition) then
		return nil
	end

	return QuestServer.startQuest(player, questDefinition)
end

function QuestServer.startQuest(player: Player, questDefinition: Types.QuestDefinition): Types.Quest
	local quest: Types.Quest
	local progressionCallbacks: { (number, number, Types.StepTask) -> () } = {}

	local step: Types.Step
	local stepTask: Types.StepTask
	local stepIndex = 0

	local id = HttpService:GenerateGUID(false)

	local function describeTask(taskDetail: Types.StepTask): string
		if taskDetail.mode == "single" then
			return taskDetail.description or ""
		elseif taskDetail.mode == "counter" then
			return `{taskDetail.description or ""} ({taskDetail.progress}/{taskDetail.maxProgress})`
		elseif taskDetail.mode == "group" then
			local descriptions = {}

			for _, subTask in taskDetail.subTasks do
				table.insert(descriptions, describeTask(subTask))
			end

			return table.concat(descriptions, ", ")
		end

		return ""
	end

	local function getStepDescription(): string
		return describeTask(stepTask)
	end

	local function getProgress(): (number, number)
		local maxProgress = #questDefinition.steps

		if quest.isCompleted then
			return maxProgress, maxProgress
		else
			return stepIndex - 1, maxProgress
		end
	end

	local function updateStepTask(nextTask: Types.StepTask)
		stepTask = nextTask

		local maxSteps = #questDefinition.steps
		for _, callback in progressionCallbacks do
			callback(stepIndex, maxSteps, stepTask)
		end
	end

	local function onProgressed(callback: (stepIndex: number, maxSteps: number, task: Types.StepTask) -> ())
		table.insert(progressionCallbacks, callback)
	end

	local function replicateToClient()
		replicateQuestState(player, quest)
	end

	local function setStep(index: number)
		if step then
			step.cleanup()
		end

		local stepDefinition = questDefinition.steps[index]
		assert(stepDefinition, `Step index {index} out of range for quest "{questDefinition.name}"`)

		local nextStep = stepDefinition.start(player, updateStepTask, function()
			if quest.isCompleted or stepIndex <= 0 then
				return
			end

			step.cleanup()

			local nextIndex = stepIndex + 1
			if nextIndex > #questDefinition.steps then
				quest.isCompleted = true

				local maxSteps = #questDefinition.steps
				for _, callback in progressionCallbacks do
					callback(stepIndex, maxSteps, stepTask)
				end

				questDefinition.onCompleted(player)
				removeActiveQuest(player, quest)
			else
				setStep(nextIndex)
			end
		end)

		stepIndex = index
		step = nextStep

		updateStepTask(nextStep.getTask())
	end

	local function cleanup()
		step.cleanup()
		stepIndex = -1

		table.clear(progressionCallbacks)
	end

	quest = {
		id = id,
		definition = questDefinition,
		isCompleted = false,

		getProgress = getProgress,
		getStepDescription = getStepDescription,
		onProgressed = onProgressed,

		cleanup = cleanup,
	} :: Types.Quest

	if not activeQuests[player] then
		activeQuests[player] = {}
	end

	local playerQuests = activeQuests[player]
	table.insert(playerQuests, quest)

	-- TODO: Save to datastore

	onProgressed(replicateToClient)
	setStep(1)

	return quest
end

function QuestServer.cancelQuest(player: Player, quest: Types.Quest)
	removeActiveQuest(player, quest)

	if activePlayers[player] then
		local questUpdate: QuestUpdateTypes.QuestUpdate = {
			type = "cancel",
			id = quest.id,
		}

		remotes.ReplicateQuestState:FireClient(player, questUpdate)
	end

	-- TODO: Save to datastore
end

function QuestServer.hasActiveQuest(player: Player, questId: string): boolean
	local playerQuests = activeQuests[player]
	if not playerQuests then
		return false
	end

	for _, quest in playerQuests do
		if quest.id == questId then
			return true
		end
	end

	return false
end

function QuestServer.hasActiveQuestByDefinition(player: Player, questDefinition: Types.QuestDefinition): boolean
	local playerQuests = activeQuests[player]
	if not playerQuests then
		return false
	end

	for _, quest in playerQuests do
		if quest.definition == questDefinition then
			return true
		end
	end

	return false
end

function QuestServer.getActiveQuests(player: Player): { Types.Quest }
	return activeQuests[player] or {}
end

local function onRequestQuestState(player: Player)
	if not activePlayers[player] then
		activePlayers[player] = true
	end

	for _, quest in QuestServer.getActiveQuests(player) do
		replicateQuestState(player, quest)
	end
end

local function onPlayerAdded(player: Player)
	for _, quest in QuestServer.getActiveQuests(player) do
		replicateQuestState(player, quest)
	end
end

local function onPlayerRemoving(player: Player)
	local playerQuests = QuestServer.getActiveQuests(player)
	for i = #playerQuests, 1, -1 do
		removeActiveQuest(player, playerQuests[i])
	end

	activeQuests[player] = nil
	activePlayers[player] = nil
end

function QuestServer.fireSignal(player: Player, signalName: string)
	questSignal:Fire(player, signalName)
end

function QuestServer.onSignal(callback: (player: Player, signalName: string) -> ()): () -> ()
	return questSignal:Connect(callback)
end

function QuestServer.autoLoad(target: Instance)
	for _, module in target:GetChildren() do
		local questDefinition: Types.QuestDefinition = require(module) :: any
		questDefinitions[module.Name] = questDefinition
	end
end

function QuestServer.start()
	remotes.RequestQuestState.OnServerEvent:Connect(onRequestQuestState)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return QuestServer
