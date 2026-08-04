--!strict

--[[
	Demonstrates an admin command system using TextChatCommands.

	Command functions are stored in the Commands module and have an included permission level.
	Permission levels are determined from group rankings or a manual override set in the Admins module.
--]]

local Players = game:GetService("Players")
local AdminCommands = require(script.Parent.Parent.AdminCommands)

-- Print out the permission level of each player who joins
Players.PlayerAdded:Connect(function(player)
	local permissionLevel = AdminCommands.getPermissionLevelAsync(player)
	print(string.format("%s has a permission level of %d", player.Name, permissionLevel))
end)
