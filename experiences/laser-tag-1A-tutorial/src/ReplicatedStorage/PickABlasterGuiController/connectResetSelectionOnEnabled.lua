--[[
	Ensures that whenever the PickABlasterGui is shown to the user (enabled),
	the left most blaster is selected by default.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiAttribute = require(ReplicatedStorage.GuiAttribute)

local function connectResetSelectionOnEnabled(gui: ScreenGui)
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			-- Reset selected index
			gui:SetAttribute(GuiAttribute.selectedIndex, 1)
		end
	end)
end

return connectResetSelectionOnEnabled
