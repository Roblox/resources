--!strict

--[[
	This demo prints out the number of moderation actions taken on a user and how long they have spent cumulatively banned.
--]]

local Players = game:GetService("Players")

local ModerationSystem = require(script.Parent.Parent.ModerationSystem)
local ModerationAction = require(script.Parent.Parent.ModerationSystem.ModerationAction)

local function onPlayerAddedAsync(player: Player)
	local success, history = ModerationSystem.getUserModerationHistoryAsync(player.UserId)

	if not success then
		warn(string.format("Failed to get moderation history for %s", player.Name))
		return
	end
	if not history then
		print(string.format("%s has no moderation history", player.Name))
		return
	end

	local banCount = 0
	local unbanCount = 0
	local timeBanned = 0

	for _, moderationStatus in history :: { any } do
		if moderationStatus.action == ModerationAction.Ban then
			banCount += 1
			timeBanned += moderationStatus.duration :: number
		elseif moderationStatus.action == ModerationAction.Unban then
			unbanCount += 1
		end
	end

	print(
		string.format(
			"%s has a history of %d moderation actions\n%d bans\n%d unbans\n%ds spent banned",
			player.Name,
			#history :: { any },
			banCount,
			unbanCount,
			timeBanned
		)
	)
end

Players.PlayerAdded:Connect(onPlayerAddedAsync)

for _, player in Players:GetPlayers() do
	onPlayerAddedAsync(player)
end
