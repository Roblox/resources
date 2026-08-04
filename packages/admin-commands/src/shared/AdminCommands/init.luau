--!strict

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

assert(
	TextChatService.ChatVersion == Enum.ChatVersion.TextChatService,
	"TextChatService.ChatVersion must be set to 'TextChatService'"
)

local Commands = require(script.Commands)
local Admins = require(script.Admins)

local AdminCommands = {
	_initialized = false,
	_permissionCache = {},
}

function AdminCommands.getPermissionLevelAsync(player: Player): number
	if AdminCommands._permissionCache[player] then
		return AdminCommands._permissionCache[player]
	end

	local permissionLevel = 0
	if Admins.UserIds[player.UserId] then
		permissionLevel = Admins.UserIds[player.UserId]
	else
		permissionLevel = player:GetRankInGroup(Admins.GroupId)
	end

	AdminCommands._permissionCache[player] = permissionLevel
	return permissionLevel
end

function AdminCommands._initialize()
	assert(not AdminCommands._initialized, "Module already initialized")

	-- Listen to PlayerRemoving to make sure the permission cache is cleaned when a player leaves
	Players.PlayerRemoving:Connect(function(player)
		if AdminCommands._permissionCache[player] then
			AdminCommands._permissionCache[player] = nil
		end
	end)

	-- Create a new folder in TextChatService to store commands and keep things organized
	local commandsFolder = Instance.new("Folder")
	commandsFolder.Name = "AdminCommands"
	commandsFolder.Parent = TextChatService

	-- Create a new TextChatCommand for each command defined in the Commands module
	for _, commandInfo in Commands.List do
		local textChatCommand = Instance.new("TextChatCommand")
		textChatCommand.Name = commandInfo.PrimaryAlias
		-- Set the primary and secondary aliases with the prefix set in the Commands module
		textChatCommand.PrimaryAlias = Commands.Prefix .. commandInfo.PrimaryAlias
		if commandInfo.SecondaryAlias then
			textChatCommand.SecondaryAlias = Commands.Prefix .. commandInfo.SecondaryAlias
		end
		textChatCommand.Parent = commandsFolder

		textChatCommand.Triggered:Connect(function(textSource, message)
			-- Find the player object of the speaker
			local player = Players:GetPlayerByUserId(textSource.UserId)
			assert(player ~= nil, string.format("No player with UserId: %d", textSource.UserId))

			-- Make sure the player has permission to use this command
			local playerPermissionLevel = AdminCommands.getPermissionLevelAsync(player)
			if playerPermissionLevel >= commandInfo.PermissionLevel then
				-- Clean up whitespace in the message so that extra spaces do not cause empty strings in the split
				local cleanMessage = string.gsub(message, "%s+", " ")
				-- Split up the message into individual words
				local words = string.split(cleanMessage, " ")
				-- The first word is the command, select all words except the first to pass in as arguments
				local args = table.move(words, 2, #words, 1, {})

				-- Call the set command Function, passing in the player who triggered it and any additional words after the command
				commandInfo.Function(player, args)
			end
		end)
	end

	AdminCommands._initialized = true
end

AdminCommands._initialize()

return AdminCommands
