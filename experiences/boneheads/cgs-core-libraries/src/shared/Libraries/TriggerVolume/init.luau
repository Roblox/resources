-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BehaviorTypes = require(ReplicatedStorage.Core.Systems.Behaviors.Types)
local Constants = require(script.Constants)
local Types = require(script.Types)

local isInstanceInBox = require(ReplicatedStorage.Core.Libraries.Sensor.isInstanceInBox)

local TriggerVolumes: { [string]: Types.TriggerVolumeDefinition } = {}

local function create(volumePart: Instance): BehaviorTypes.Behavior
	assert(volumePart:IsA("BasePart"), "TriggerVolume should be a BasePart")

	local triggerVolumeDefinitionName =
		volumePart:GetAttribute(Constants.TRIGGER_VOLUME_DEFINITION_ATTRIBUTE) :: string?
	local triggerVolumeDefinition = triggerVolumeDefinitionName and TriggerVolumes[triggerVolumeDefinitionName]
	assert(triggerVolumeDefinition, `Missing trigger volume definition for {triggerVolumeDefinitionName or "nil"}`)

	volumePart.Transparency = 1
	volumePart.CanCollide = false
	volumePart.AudioCanCollide = false
	volumePart.CanTouch = true
	volumePart.CanQuery = false

	local triggerVolume = triggerVolumeDefinition.create(volumePart)
	local occupants: { [PVInstance]: boolean } = {}

	local function onEnter(occupant: PVInstance)
		occupants[occupant] = true
		if triggerVolume.onEnter then
			triggerVolume.onEnter(occupant)
		end
	end

	local function onExit(occupant: PVInstance)
		occupants[occupant] = nil
		if triggerVolume.onExit then
			triggerVolume.onExit(occupant)
		end
	end

	-- Touched events are not reliable with custom character (fires Touched
	-- started and ended while still in the volume). So do custom point in box
	-- check upon entering the volume.
	local touchConnection = volumePart.Touched:Connect(function(part: BasePart)
		local occupant: PVInstance? = part

		if triggerVolumeDefinition.filter then
			occupant = triggerVolumeDefinition.filter(part)
		end

		if occupant and not occupants[occupant] then
			onEnter(occupant)
		end
	end)

	local function step(delta: number)
		local cframe = volumePart.CFrame
		local size = volumePart.Size

		for occupant in occupants do
			if not occupant:IsDescendantOf(Workspace) or not isInstanceInBox(occupant :: Model, cframe, size) then
				onExit(occupant)
			end
		end

		if triggerVolume.step then
			triggerVolume.step(delta)
		end
	end

	local function cleanup()
		for occupant in occupants do
			onExit(occupant)
		end

		table.clear(occupants)
		touchConnection:Disconnect()

		if triggerVolume.cleanup then
			triggerVolume.cleanup()
		end
	end

	return {
		step = step,
		cleanup = cleanup,
	}
end

local function initialize()
	for _, definitionModule in CollectionService:GetTagged(Constants.TRIGGER_VOLUME_DEFINITION_TAG) do
		assert(definitionModule:IsA("ModuleScript"), "Trigger volume definitions should be ModuleScripts")
		local definition = require(definitionModule) :: Types.TriggerVolumeDefinition
		TriggerVolumes[definitionModule.Name] = definition
	end
end

local TriggerVolume: BehaviorTypes.BehaviorDefinition = {
	tag = Constants.TRIGGER_VOLUME_TAG,
	order = 0,
	mode = "server",
	step = "heartbeat",
	create = create,
}

initialize()

return TriggerVolume
