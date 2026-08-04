--!strict

--[[
	Calls the given callback for all existing players in the game, and any that join thereafter.

	Useful in situations where you want to run code for every player, even players who are already in the game.
--]]

local Players = game:GetService("Players")

local function safePlayerAdded(onPlayerAddedCallback: (Player) -> nil)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAddedCallback, player)
	end
	return Players.PlayerAdded:Connect(function(player: Player)
		onPlayerAddedCallback(player)
	end)
end

return safePlayerAdded
