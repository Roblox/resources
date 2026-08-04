--[[
	When the HUDGui is enabled, we only want to see the crosshair within the HUDGui, not the player's mouse.
	This hides the Roblox cursor when the HUDGui is enabled.
--]]

local UserInputService = game:GetService("UserInputService")

local function disableMouseWhileGuiEnabled(gui: ScreenGui)
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		UserInputService.MouseIconEnabled = not gui.Enabled
	end)
end

return disableMouseWhileGuiEnabled
