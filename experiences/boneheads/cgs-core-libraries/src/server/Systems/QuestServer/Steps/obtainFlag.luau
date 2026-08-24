-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerFlags = require(ReplicatedStorage.Core.Libraries.PlayerFlags)
local Types = require(script.Parent.Parent.Types)

local function obtainFlag(flag: string, description: string?): Types.StepDefinition
	local function start(player: Player, _taskCallback: (Types.StepTask) -> (), completeCallback: () -> ()): Types.Step
		local connection: RBXScriptConnection?

		local function getTask(): Types.StepTask
			return {
				mode = "single",
				description = description or `Get flag: {flag}`,
				isComplete = PlayerFlags.hasFlag(player, flag),
			}
		end

		local function cleanup()
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end

		local function complete()
			completeCallback()
			cleanup()
		end

		if PlayerFlags.hasFlag(player, flag) then
			task.defer(complete)
		else
			connection = PlayerFlags.getFlagChangedSignal(player, flag, function()
				if PlayerFlags.hasFlag(player, flag) then
					complete()
				end
			end)
		end

		return {
			getTask = getTask,
			cleanup = cleanup,
		}
	end

	return {
		name = `Obtain Flag: {flag}`,
		start = start,
	}
end

return obtainFlag
