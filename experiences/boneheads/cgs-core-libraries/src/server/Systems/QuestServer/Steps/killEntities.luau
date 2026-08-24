-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Damage = require(ServerScriptService.Core.Libraries.Damage)
local Types = require(script.Parent.Parent.Types)
local getTaggedList = require(ReplicatedStorage.Core.Utility.getTaggedList)

local function killEntities(tag: string, count: number, description: string?): Types.StepDefinition
	local function start(player: Player, taskCallback: (Types.StepTask) -> (), completeCallback: () -> ()): Types.Step
		local kills = 0
		local connections: { RBXScriptConnection } = {}

		local function getTask(): Types.StepTask
			return {
				mode = "counter",
				description = description or `Kill {count} {tag}s`,
				isComplete = kills >= count,
				progress = kills,
				maxProgress = count,
			}
		end

		local function cleanup()
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
		end

		local function bindEntity(entity: Instance)
			if not entity:IsA("Model") then
				return
			end

			table.insert(
				connections,
				Damage.onKilled(entity, function(attacker: Instance?)
					if attacker ~= player.Character then
						return
					end

					kills += 1
					taskCallback(getTask())

					if kills >= count then
						completeCallback()
						cleanup()
					end
				end)
			)
		end

		local tagged = getTaggedList({ tag })
		for _, entity in tagged do
			bindEntity(entity)
		end

		table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(bindEntity))

		return {
			getTask = getTask,
			cleanup = cleanup,
		}
	end

	return {
		name = `Kill {count} {tag}`,
		start = start,
	}
end

return killEntities
