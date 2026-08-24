-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ServerScriptService = game:GetService("ServerScriptService")

local QuestServer = require(ServerScriptService.Core.Systems.QuestServer)
local Types = require(script.Parent.Parent.Types)

local function awaitSignal(signalName: string, description: string?): Types.StepDefinition
	local function start(player: Player, _taskCallback: (Types.StepTask) -> (), completeCallback: () -> ()): Types.Step
		local disconnect: (() -> ())?

		local function getTask(): Types.StepTask
			return {
				mode = "single",
				description = description or signalName,
				isComplete = false,
			}
		end

		local function cleanup()
			if disconnect then
				disconnect()
				disconnect = nil
			end
		end

		local function complete()
			completeCallback()
			cleanup()
		end

		disconnect = QuestServer.onSignal(function(firedPlayer: Player, firedSignal: string)
			if firedPlayer == player and firedSignal == signalName then
				complete()
			end
		end)

		return {
			getTask = getTask,
			cleanup = cleanup,
		}
	end

	return {
		name = `Await: {signalName}`,
		start = start,
	}
end

return awaitSignal
