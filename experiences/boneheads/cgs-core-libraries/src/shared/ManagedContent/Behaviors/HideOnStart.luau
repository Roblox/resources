-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BehaviorTypes = require(ReplicatedStorage.Core.Systems.Behaviors.Types)
local Constants = require(ReplicatedStorage.Core.Constants)

local function hideInstance(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Transparency = 1
		instance.CanCollide = false
		instance.AudioCanCollide = false
	elseif instance:IsA("SurfaceGui") then
		instance.Enabled = false
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		instance.Transparency = 1
	end
end

local function create(instance: Instance): BehaviorTypes.Behavior
	hideInstance(instance)

	for _, descendant in instance:GetDescendants() do
		hideInstance(descendant)
	end

	return {}
end

local TriggerVolume: BehaviorTypes.BehaviorDefinition = {
	tag = Constants.TAGS.HIDE_ON_START,
	order = 0,
	mode = "server",
	step = "heartbeat",
	create = create,
}

return TriggerVolume
