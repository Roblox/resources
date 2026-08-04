--[[
	Handles setting up all blaster pickups and the logic for a player picking them up using
	ProximityPrompts.
--]]

local ProximityPromptService = game:GetService("ProximityPromptService")

local setupPickups = require(script.setupPickups)
local onPromptTriggeredAsync = require(script.onPromptTriggeredAsync)

ProximityPromptService.PromptTriggered:Connect(onPromptTriggeredAsync)
setupPickups()
