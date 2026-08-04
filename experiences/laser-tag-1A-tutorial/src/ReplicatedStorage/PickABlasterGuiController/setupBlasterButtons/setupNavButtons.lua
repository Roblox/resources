--!nocheck
--[[
	Listens for activations of the left and right navigation buttons,
	decrementing or incrementing the currently selected index accordingly
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiAttribute = require(ReplicatedStorage.GuiAttribute)

local function setupNavButtons(gui: ScreenGui, blasterButtons: { ImageButton })
	local frame = gui.Frame.SelectionFrame.Frame
	local navigationButtonLeft = frame.NavigationButtonLeft
	local navigationButtonRight = frame.NavigationButtonRight

	navigationButtonLeft.Activated:Connect(function()
		local currentIndex = gui:GetAttribute(GuiAttribute.selectedIndex)
		local newIndex = math.clamp(currentIndex - 1, 1, #blasterButtons)
		gui:SetAttribute(GuiAttribute.selectedIndex, newIndex)
	end)

	navigationButtonRight.Activated:Connect(function()
		local currentIndex = gui:GetAttribute(GuiAttribute.selectedIndex)
		local newIndex = math.clamp(currentIndex + 1, 1, #blasterButtons)
		gui:SetAttribute(GuiAttribute.selectedIndex, newIndex)
	end)
end

return setupNavButtons
