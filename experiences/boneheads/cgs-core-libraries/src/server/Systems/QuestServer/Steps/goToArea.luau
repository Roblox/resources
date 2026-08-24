-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Parent.Types)
local getTaggedList = require(ReplicatedStorage.Core.Utility.getTaggedList)
local isPointInBox = require(ReplicatedStorage.Core.Libraries.Sensor.isPointInBox)

local function goToArea(areaTag: string, areaDisplayName: string?): Types.StepDefinition
	local areas = getTaggedList({ areaTag })

	local function start(player: Player, _taskCallback: (Types.StepTask) -> (), completeCallback: () -> ()): Types.Step
		local completed = false
		local connection: RBXScriptConnection?

		local function getTask(): Types.StepTask
			return {
				mode = "single",
				description = `Go to {areaDisplayName or areaTag}`,
				isComplete = completed,
			}
		end

		local function cleanup()
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end

		local function complete()
			completed = true

			completeCallback()
			cleanup()
		end

		local function checkCharacterInArea()
			local character = player.Character
			if not character then
				return
			end

			local cframe = character:GetPivot()

			for _, instance in areas do
				if not instance:IsA("BasePart") then
					continue
				end

				local areaCFrame = instance.CFrame
				local areaSize = instance.Size

				if isPointInBox(cframe.Position, areaCFrame, areaSize) then
					complete()
					break
				end
			end
		end

		connection = RunService.Heartbeat:Connect(checkCharacterInArea)

		return {
			getTask = getTask,
			cleanup = cleanup,
		}
	end

	return {
		name = `Go to {areaTag}`,
		start = start,
	}
end

return goToArea
