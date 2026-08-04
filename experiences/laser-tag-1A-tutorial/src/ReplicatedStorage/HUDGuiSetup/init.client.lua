--[[
	Sets up the Heads Up Display (HUD), which includes:
		- Player profile icon/name
		- Objective banner
		- Crosshair
--]]

local Players = game:GetService("Players")

local setPlayerPortrait = require(script.setPlayerPortrait)
local setPlayerName = require(script.setPlayerName)
local setupTouchButtonAsync = require(script.setupTouchButtonAsync)
local disableMouseWhileGuiEnabled = require(script.disableMouseWhileGuiEnabled)
local setupHitmarker = require(script.setupHitmarker)

local localPlayer = Players.LocalPlayer
local gui = localPlayer.PlayerGui:WaitForChild("HUDGui")

setPlayerPortrait(gui)
setPlayerName(gui)
disableMouseWhileGuiEnabled(gui)
setupHitmarker(gui)
setupTouchButtonAsync(gui)
