--[[
	Demonstrates how to show and hide different frames within a Gui.
	The example starts with a menu button visible to the player.
	When pressed, the menu button is hidden and a menu window appears.
	Clicking the 'X' at the top right corner of the menu will bring the user back to the original view.
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

-- The frames to toggle visibility for
local homeFrame = mainGui.HomeFrame
local menuFrame = mainGui.MenuFrame

-- The buttons to connect behavior to below
local openMenuButton = homeFrame.OpenMenuButton
local closeMenuButton = menuFrame.WindowFrame.CloseMenuButton

-- Hides the menuFrame and shows the homeFrame
local function showHomeFrame()
	menuFrame.Visible = false
	homeFrame.Visible = true
end

-- Hides the homeFrame and shows the menuFrame
local function showMenuFrame()
	homeFrame.Visible = false
	menuFrame.Visible = true
end

-- Connect the menu buttons to their appropriate actions
openMenuButton.Activated:Connect(showMenuFrame)
closeMenuButton.Activated:Connect(showHomeFrame)

-- Show the home frame initially
showHomeFrame()
