--!strict

--[[
	Listens for input type changes and disables the mouse cursor during
	gamepad input, and enables it during non-gamepad input.

	This disables the dot on-screen while using a gamepad.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InputCategorizer = require(ReplicatedStorage.Source.InputCategorizer)
local InputCategory = require(ReplicatedStorage.Source.SharedConstants.InputCategory)

local GamepadMouseDisabler = {}

local function updateCursorEnabled()
	local shouldEnable = InputCategorizer.getLast() ~= InputCategory.Gamepad
	UserInputService.MouseIconEnabled = shouldEnable
end

function GamepadMouseDisabler.start()
	InputCategorizer.changed:Connect(updateCursorEnabled)
	updateCursorEnabled()
end

return GamepadMouseDisabler
