--[[
	Creates a guiding beam from the bottom of the local character to a destination attachment.
	Useful for guiding players towards objectives in order to progress.
--]]

local Players = game:GetService("Players")

local CharacterPath = require(script.Parent.Parent.CharacterPath)
local instances = script.Parent.Instances
local building = instances:WaitForChild("Building")
local revolvingDoor = building.PrimaryPart
local pathAttachment = revolvingDoor.PathAttachment

-- Create a path connecting from the character to the pathAttachment on the door
local characterPath = CharacterPath.new(pathAttachment)

-- Destroy the path when the player reaches the door
local doorReachedConnection
doorReachedConnection = revolvingDoor.Touched:Connect(function(otherPart)
	local character = otherPart.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		doorReachedConnection:Disconnect()
		characterPath:destroy()
	end
end)
