--!strict

--[[
	Handles client-side behaviors and effects while pulling a wagon
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalWalkJumpManager = require(ReplicatedStorage.Source.LocalWalkJumpManager)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)

local localPlayer = Players.LocalPlayer :: Player

local PullingWagon = {}
PullingWagon.__index = PullingWagon

export type ClassType = typeof(setmetatable({} :: {}, PullingWagon))

function PullingWagon.new(characterModel: Model): ClassType
	local self = {}

	setmetatable(self, PullingWagon)

	-- Only create behaviors and effects for local character
	if characterModel == localPlayer.Character then
		self:_onPullingStarted()
	end

	return self
end

function PullingWagon._onPullingStarted(self: ClassType)
	-- Disable jumping
	LocalWalkJumpManager.getJumpValueManager():setMultiplier(PlayerFacingString.ValueManager.PullingWagon, 0)
end

function PullingWagon.destroy(self: ClassType)
	-- Re-enable jumping
	LocalWalkJumpManager.getJumpValueManager():removeMultiplier(PlayerFacingString.ValueManager.PullingWagon)
end

return PullingWagon
