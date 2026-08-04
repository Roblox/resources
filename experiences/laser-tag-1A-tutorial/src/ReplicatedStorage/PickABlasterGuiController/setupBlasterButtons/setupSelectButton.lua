--!nocheck
--[[
	Creates a select button for the player to confirm their blaster selection.

	Fires blasterSelectedEvent to communicate to the Server that a blaster was picked (to be equipped).
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiAttribute = require(ReplicatedStorage.GuiAttribute)
local blasterSelectedEvent = ReplicatedStorage.Instances.BlasterSelectedEvent

local function setupSelectButton(gui: ScreenGui, blasterButtons: { ImageButton })
	gui.Frame.SelectButton.Activated:Connect(function()
		-- During button generation, we set the name of the button to correspond to its associated blaster type
		local blasterName = blasterButtons[gui:GetAttribute(GuiAttribute.selectedIndex)].Name
		blasterSelectedEvent:FireServer(blasterName)
	end)
end

return setupSelectButton
