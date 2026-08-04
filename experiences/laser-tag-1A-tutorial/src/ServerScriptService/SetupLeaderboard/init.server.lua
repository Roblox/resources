--[[
	Entry point for setting up players leaderboards so they can get points
	when tagging out players.
--]]

local Players = game:GetService("Players")

local setupLeaderboard = require(script.setupLeaderboard)

local function onPlayerAdded(player: Player)
	-- Add Points leaderstats for this player on the leaderboard
	setupLeaderboard(player)
end

-- Call onPlayerAdded for any players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
-- Call onPlayerAdded for all future players
Players.PlayerAdded:Connect(onPlayerAdded)
