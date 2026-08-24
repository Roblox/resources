--!strict

--[[
	Returns when the initial snapshot of the game has finished replicating to the client.

	Used by the client side entry point script to determine when to hide the loading screen.
--]]

local function waitForGameLoadedAsync()
	if game:IsLoaded() then
		return
	end

	game.Loaded:Wait()
end

return waitForGameLoadedAsync
