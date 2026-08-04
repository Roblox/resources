--[[
	Sets up the PickABlaster GUI, responsible for prompting the player to pick
	a blaster from a list upon spawning.

	Players can select a blaster by clicking buttons with the corresponding blaster directly,
	or moving between blasters with left and right navigation buttons.

	Once their choice is selected, players press the 'Select' button to confirm their choice and
	equip the blaster.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiAttribute = require(ReplicatedStorage.GuiAttribute)
local setupBlasterButtons = require(script.setupBlasterButtons)
local connectResetSelectionOnEnabled = require(script.connectResetSelectionOnEnabled)

local localPlayer = Players.LocalPlayer
local gui = localPlayer.PlayerGui:WaitForChild("PickABlasterGui")

setupBlasterButtons(gui)
connectResetSelectionOnEnabled(gui)
-- Have the left most blaster selected by default
gui:SetAttribute(GuiAttribute.selectedIndex, 1)
