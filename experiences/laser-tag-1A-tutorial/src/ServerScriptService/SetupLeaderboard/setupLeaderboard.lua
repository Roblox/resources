--[[
	Sets up leaderstats for the given player, which is a number statistic called
	'Points' that shows up on the leaderboard in the player list.
--]]

local function setupLeaderboard(player: Player)
	local leaderstats = Instance.new("Folder")

	-- 'leaderstats' is a reserved name Roblox recognizes for creating a leaderboard
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stat = Instance.new("IntValue")
	stat.Name = "Points"
	stat.Value = 0
	stat.Parent = leaderstats
end

return setupLeaderboard
