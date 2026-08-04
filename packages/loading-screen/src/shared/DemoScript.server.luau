--[[
	The task.wait() calls below are placeholders for calling asynchronous functions
	that would load parts of your game.
--]]

local ContentProvider = game:GetService("ContentProvider")

local LoadingScreen = require(script.Parent.LoadingScreen)

local REQUIRED_ASSETS = {
	-- Instances or content strings that are important to display first
}

LoadingScreen.enableAsync()
LoadingScreen.updateDetailText("Preloading important assets...")
ContentProvider:PreloadAsync(REQUIRED_ASSETS)
LoadingScreen.updateDetailText("Initializing...")
task.wait(1.5)
LoadingScreen.updateDetailText("Loading user data...")
task.wait(3)
LoadingScreen.updateDetailText("Spawning character...")
task.wait(3)
LoadingScreen.updateDetailText("Finishing up...")
task.wait(0.5)
LoadingScreen.disableAsync()
