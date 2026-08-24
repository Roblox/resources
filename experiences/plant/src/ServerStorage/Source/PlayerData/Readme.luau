--[[
	Sample Player Data System

	*Background*

	Although Roblox provides low-level APIs to interface with DataStores via DataStoreService, the most
	common use case is for saving and loading player 'profile' data. That is, data associated with the
	player's progress, purchases, and play session data to allow persistence between individual sessions.

	For that reason, most games leverage some form of 'Player Data' system. There are some popular
	community authored modules in this space, including:

	- ProfileService https://madstudioroblox.github.io/ProfileService/
	- DataStore2 https://kampfkarren.github.io/Roblox/

	There are a number of problems systems like these usually attempt to solve, including:

	- In-Memory Data: DataStoreService requests make a web request from the Roblox game server to Roblox's Data Store
	  infrastructure. This takes time, and is subject to rate limits. By caching this data on the server, we can
	  limit our requests to only three situations:
		1. Initial load on join
		2. Final save on leave
		3. Periodic saves on an interval to mitigate data loss in case #2 doesn't happen, such as if the server crashes

	- Efficient Storage: Storing all player data in a single table means fewer DataStore requests are needed to
	  manage the same amount of data. It also helps ensure data consistency and makes rollbacks easier to reason about.

	- Replication: The client will often need access to the saved data, for example to display the player's score
	  in the UI.

	- Error Handling: If the DataStoreService request to load the player's data fails to load, most solutions will
	  implement a retrying mechanism and a fallback to 'default' data. Special care is needed to ensure fallback data
	  doesn't later overwrite 'real' data, and that DataStore retries are applied in the correct order.

	- Session Locking: If a single player's data is 'in-memory' in multiple servers, issues may occur where one server saves
	  out-of-date information over a new server. This can lead to data loss and item duplication loopholes.

	The Player Data System in this project is not intended as a drag and drop resource or a replacement for the community
	authored solutions listed above. Instead, it serves as reference code demonstrating how the various use cases above
	can be met in developers' own code.

	Comments have been left in-line in these files to try to call out some of the edge cases addressed, and high-level
	information can be found below.

	*Key Files*

	- PlayerData/Server.lua: The server-side entry point for the system, provides APIs to update, query and subscribe to changes to player data
	- PlayerData/Client.lua: The client-side entry point for the system, provides APIs to query player data and subscribe to changes
	- PlayerData/DefaultPlayerData.lua: The default player data object
	- PlayerData/SessionLockedDataStoreWrapper.lua: A wrapper class for DataStoreWrapper.lua that implements 'Session Locking' logic
	- PlayerData/DataStoreWrapper.lua: A wrapper class for the standard DataStoreService APIs that provides ordered retries with exponential back-off
	- PlayerData/ThreadQueue.lua > A dependency of DataStoreWrapper that allows lua callbacks to be queued for asynchronous execution

	*Overview*

	- Player data is represented as a dictionary of top level values.
	- Player data will be loaded when the player joins the game, and a fallback
	- Each value can be accessed by its valueName using the get / getValue functions on PlayerDataServer / PlayerDataClient (see below)
	- Values can be updated using PlayerDataServer, and the changes will replicate to PlayerDataClient

	*Usage*

	- The service is started with a default data object and the name of the DataStore to save to
		PlayerDataServer.start({coins = 0}, "playerData")

	- Before the first use for a given player, always ensure the data has loaded
	
		-- Server:
		if not PlayerDataServer.hasLoaded(player) then
			PlayerDataServer.waitForDataLoadAsync(player)
		end
		-- Client: 
		if not PlayerDataClient.hasLoaded() then
			PlayerDataClient.loaded:Wait()
		end

	- Values can be read, set or updated on the server

		local value = PlayerDataServer.getValue(player, "valueName)
		PlayerDataServer.setValue(player, "valueName", value)
		PlayerDataServer.updateValue(player, "valueName, function(oldValue)
			return oldValue + 1
		end)
		PlayerDataServer.removeValue(player, "valueName")

	- Values can be read on the client, but not set or updated

		PlayerDataClient.get("valueName")

	- Changes to values on both the client and the server can be subscribed to via events

		-- Server:
		PlayerDataServer.playerDataUpdated:Connect(function(player, valueName, value) end)
		-- Client:
		PlayerDataClient.updated:Connect(function(valueName, value) end)

		- Values can be set as private on the server when PlayerDataServer is started. For example:
		PlayerDataServer.start(defaultData, dataStoreName, {"purchaseHistory", "banHistory"})

	- Saving is done on an automatic loop, and when the player leaves, but can also be scheduled
	  and waited for manually

		PlayerDataServer.scheduleSave(player)
		PlayerDataServer.waitForNextDataSaveAsync(player)

	- Whether a player's data has loaded correctly (or is using a default fallback) can be queried
	  on the client and the server (useful for showing error messages)

		-- Server:
		local hasErrored = PlayerDataServer.hasErrored(player)
		-- Client:
		local hasErrored = PlayerDataClient.hasLoadingErrored(player)
		local loadErrorType = hasErrored and PlayerDataClient.getLoadError()

	- The client can query whether its last save was successful (useful for showing error messages)
		local hasSavingErrored = PlayerDataClient.hasSavingErrored(player)
		local saveErrorType = hasSavingErrored and PlayerDataClient.getSaveError()
		-- OR
		PlayerDataClient.saved:Connect(function(success, errorType) end)
--]]
