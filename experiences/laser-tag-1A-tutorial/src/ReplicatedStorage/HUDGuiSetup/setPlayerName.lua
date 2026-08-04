--!nocheck
--[[
	Sets the player's name for the HUD Gui.
--]]

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local function setPlayerName(gui: ScreenGui)
	gui.PlayerDisplay.PlayerNameTextLabel.Text = localPlayer.DisplayName
end

return setPlayerName
