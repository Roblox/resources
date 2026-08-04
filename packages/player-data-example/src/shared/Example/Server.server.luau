local Players = game:GetService("Players")

local PlayerDataServer = require(script.Parent.Parent.PlayerData.Server)

local defaultPlayerData = {
	coins = 0,
}
PlayerDataServer.start(defaultPlayerData, "PlayerData")

Players.PlayerAdded:Connect(function(player: Player)
	PlayerDataServer.waitForDataLoadAsync(player)

	-- To demonstrate the player data system, we'll increment coins by 1 every second
	while player:IsDescendantOf(Players) do
		PlayerDataServer.updateValue(player, "coins", function(oldValue)
			return oldValue + 1
		end)

		task.wait(1)
	end
end)
