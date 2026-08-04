local PlayerDataClient = require(script.Parent.Parent.PlayerData.Client)

PlayerDataClient.start()

if not PlayerDataClient.hasLoaded() then
	PlayerDataClient.loaded:Wait()
end

-- If the player's data has failed to load, it's important the user knows so they are not surprised
-- when they are playing with default data
local loadError = PlayerDataClient.getLoadError()
if loadError then
	print(string.format("%s error loading data, progress will not save", loadError))
end

local function onCoinsUpdated(coins: number)
	print(string.format("I have %d coins", coins))
end

-- By listening to the PlayerData on the client, we can update the UI
local coins = PlayerDataClient.get("coins")
onCoinsUpdated(coins)
PlayerDataClient.updated:Connect(function(key, value)
	if key == "coins" then
		onCoinsUpdated(value)
	end
end)

-- If data has failed to save, it's important to inform the user so they know that recent progress may
-- be lost if they leave the game
PlayerDataClient.saved:Connect(function(success, saveError)
	if not success then
		print(string.format("%s error saving data, recent progress may not have saved", saveError))
	end
end)
