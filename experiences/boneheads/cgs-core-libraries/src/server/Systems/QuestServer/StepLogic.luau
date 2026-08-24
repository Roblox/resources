-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

local StepLogic = {}

function StepLogic.AND(...: Types.StepDefinition): Types.StepDefinition
	local stepDefinitions = { ... }

	local function start(player: Player, taskCallback: (Types.StepTask) -> (), completeCallback: () -> ()): Types.Step
		local subSteps: { Types.Step } = {}
		local completed = false

		local function getTask(): Types.StepTask
			local subTasks = {}
			local allComplete = true

			for i, subStep in subSteps do
				local subTask = subStep.getTask()
				subTasks[i] = subTask

				if not subTask.isComplete then
					allComplete = false
				end
			end

			return {
				mode = "group",
				isComplete = allComplete,
				subTasks = subTasks,
			}
		end

		local function onSubTaskUpdated()
			if completed then
				return
			end

			local groupTask = getTask()
			if groupTask.isComplete then
				completed = true
				completeCallback()
			else
				taskCallback(groupTask)
			end
		end

		local function cleanup()
			for _, subStep in subSteps do
				subStep.cleanup()
			end
		end

		for _, definition in stepDefinitions do
			local subStep = definition.start(player, onSubTaskUpdated, onSubTaskUpdated)
			table.insert(subSteps, subStep)
		end

		return {
			getTask = getTask,
			cleanup = cleanup,
		}
	end

	local names = {}
	for _, definition in stepDefinitions do
		table.insert(names, definition.name)
	end

	return {
		name = `AND: {table.concat(names, " + ")}`,
		start = start,
	}
end

function StepLogic.OR(...: Types.StepDefinition): Types.StepDefinition
	local stepDefinitions = { ... }

	local function start(player: Player, taskCallback: (Types.StepTask) -> (), completeCallback: () -> ()): Types.Step
		local subSteps: { Types.Step } = {}
		local completed = false

		local function getTask(): Types.StepTask
			local subTasks = {}
			local anyComplete = false

			for i, subStep in subSteps do
				local subTask = subStep.getTask()
				subTasks[i] = subTask

				if subTask.isComplete then
					anyComplete = true
				end
			end

			return {
				mode = "group",
				isComplete = anyComplete,
				subTasks = subTasks,
			}
		end

		local function onSubTaskUpdated()
			if completed then
				return
			end

			local groupTask = getTask()
			if groupTask.isComplete then
				completed = true
				completeCallback()
			else
				taskCallback(groupTask)
			end
		end

		for _, definition in stepDefinitions do
			local subStep = definition.start(player, onSubTaskUpdated, onSubTaskUpdated)
			table.insert(subSteps, subStep)
		end

		local function cleanup()
			for _, subStep in subSteps do
				subStep.cleanup()
			end
		end

		return {
			getTask = getTask,
			cleanup = cleanup,
		}
	end

	local names = {}
	for _, definition in stepDefinitions do
		table.insert(names, definition.name)
	end

	return {
		name = `OR: {table.concat(names, " | ")}`,
		start = start,
	}
end

return StepLogic
