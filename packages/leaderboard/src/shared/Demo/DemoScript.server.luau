local Players = game:GetService("Players")

local Leaderboard = require(script.Parent.Parent.Leaderboard)

local testValue = 0
while true do
	for _, player in pairs(Players:GetPlayers()) do
		-- Update all player's Leadboards with a "Points" stat of value testValue
		Leaderboard.setStat(player, "Points", testValue)
	end
	task.wait(1)
	testValue = testValue + 1
end
