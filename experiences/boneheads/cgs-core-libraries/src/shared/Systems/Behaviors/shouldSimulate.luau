-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Core.Constants)

local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

local function isPlayerCharacter(model: Model): boolean
	local player = Players:GetPlayerFromCharacter(model)
	return player ~= nil and model:HasTag(Constants.TAGS.PLAYER)
end

-- Called for behaviors that are marked as 'sync'. Allows simulation to be synced to whoever is authoritative/predicting an object
local function shouldSimulate(instance: Instance): boolean
	-- TODO: Make this use prediction status
	-- For now we'll just assume player characters are the only thing that the client needs control over

	if instance:IsA("Model") then
		if isServer then
			return not isPlayerCharacter(instance)
		elseif isClient then
			return instance == Players.LocalPlayer.Character and isPlayerCharacter(instance)
		end
	end

	return isServer
end

return shouldSimulate
