--!strict

--[[
	A single place to keep track of walk and jump multipliers to avoid conflicts across
	multiple scripts when changing these values
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ValueManager = require(ReplicatedStorage.Source.ValueManager)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)

local localPlayer = Players.LocalPlayer :: Player

local LocalWalkJumpManager = {
	_jumpValueManager = ValueManager.new(StarterPlayer.CharacterJumpHeight),
	_walkValueManager = ValueManager.new(StarterPlayer.CharacterWalkSpeed),
}

function LocalWalkJumpManager._onCharacterAdded(character: Model)
	task.spawn(function()
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid

		LocalWalkJumpManager._walkValueManager:setAttachedInstance(humanoid, "WalkSpeed")
		LocalWalkJumpManager._jumpValueManager:setAttachedInstance(humanoid, "JumpHeight")
	end)
end

function LocalWalkJumpManager.getWalkValueManager()
	return LocalWalkJumpManager._walkValueManager
end

function LocalWalkJumpManager.getJumpValueManager()
	return LocalWalkJumpManager._jumpValueManager
end

function LocalWalkJumpManager.setup()
	local characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer)

	if characterLoadedWrapper:isLoaded() then
		LocalWalkJumpManager._onCharacterAdded(localPlayer.Character :: Model)
	end

	characterLoadedWrapper.loaded:Connect(function(character: any)
		LocalWalkJumpManager._onCharacterAdded(character :: Model)
	end)
end

return LocalWalkJumpManager
