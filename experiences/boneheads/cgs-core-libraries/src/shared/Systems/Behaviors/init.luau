-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Types = require(script.Types)
local bindTagged = require(ReplicatedStorage.Core.Utility.bindTagged)
local shouldSimulate = require(script.shouldSimulate)

export type Behavior = Types.Behavior
export type BehaviorDefinition = Types.BehaviorDefinition

type BehaviorEntry = {
	behavior: Types.Behavior,
	definition: Types.BehaviorDefinition,
}

local BEHAVIOR_DEFINITION_TAG = "BehaviorDefinition"

local behaviors: { [Instance]: { BehaviorEntry } } = {}

local function step(stepType: Types.Step, delta: number)
	for instance, entries in behaviors do
		for _, entry in entries do
			if not entry.behavior.step then
				continue
			end
			if entry.definition.step ~= stepType then
				continue
			end
			if entry.definition.mode == "owner" and not shouldSimulate(instance) then
				continue
			end

			entry.behavior.step(delta)
		end
	end
end

local function bindBehavior(definition: Types.BehaviorDefinition)
	if definition.mode == "server" and not RunService:IsServer() then
		return
	end
	if definition.mode == "client" and not RunService:IsClient() then
		return
	end

	local function onInstanceAdded(instance: Instance)
		if not instance:IsDescendantOf(Workspace) then
			return
		end
		local entries = behaviors[instance]
		if not entries then
			entries = {}
			behaviors[instance] = entries
		end

		local entry: BehaviorEntry = {
			definition = definition,
			behavior = definition.create(instance),
		}

		-- Find the furthest forward index that we can insert at.
		-- The first entry that has an order higher than ours is where we want to insert,
		-- Since that entry will be shifted to the right.
		local insertIndex = 1
		for index, otherEntry in entries do
			if otherEntry.definition.order > entry.definition.order then
				insertIndex = index
				break
			end
		end

		table.insert(entries, insertIndex, entry)
	end

	local function onInstanceRemoved(instance: Instance)
		local entries = behaviors[instance]
		if not entries then
			return
		end

		for index, entry in entries do
			if entry.definition == definition then
				if entry.behavior.cleanup then
					entry.behavior.cleanup()
				end
				table.remove(entries, index)
				break
			end
		end

		if #entries == 0 then
			behaviors[instance] = nil
		end
	end

	bindTagged(definition.tag, { Workspace }, onInstanceAdded, onInstanceRemoved)
end

local function onBehaviorDefinitionAdded(behaviorModule: Instance)
	assert(behaviorModule:IsA("ModuleScript"), "Invalid behavior")
	local behaviorDefinition = require(behaviorModule) :: Types.BehaviorDefinition
	bindBehavior(behaviorDefinition)
end

local Behaviors = {}

function Behaviors.start()
	-- TODO: Switch this to server auth fixed step
	RunService.PreSimulation:Connect(function(delta: number)
		step("physics", delta)
	end)
	RunService.Heartbeat:Connect(function(delta: number)
		step("heartbeat", delta)
	end)
	if RunService:IsClient() then
		RunService.RenderStepped:Connect(function(delta: number)
			step("render", delta)
		end)
	end

	CollectionService:GetInstanceAddedSignal(BEHAVIOR_DEFINITION_TAG):Connect(onBehaviorDefinitionAdded)

	for _, behaviorModule in CollectionService:GetTagged(BEHAVIOR_DEFINITION_TAG) do
		onBehaviorDefinitionAdded(behaviorModule)
	end
end

function Behaviors.autoLoad(target: Instance)
	-- Auto load everything in the target folder
	for _, behaviorModule in target:GetChildren() do
		onBehaviorDefinitionAdded(behaviorModule)
	end
end

return Behaviors
