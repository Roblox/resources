--!nocheck
--[[
	Sets up a touch button for blasting if the local player is on a device that supports touch.

	Toggles the visibility of the button based on their last input type.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local function setupTouchButtonAsync(gui: ScreenGui)
	local blastButton = gui.BlastButton

	-- Determine if the player is on a device that supports touch with UserInputService.TouchEnabled.
	-- If true, add a button for firing the blaster.
	if UserInputService.TouchEnabled then
		-- Wait for Roblox core scripts to add the TouchGui
		local touchGui = localPlayer.PlayerGui:WaitForChild("TouchGui")

		-- Base the size and position of our blast button off of the jump button, which can be different on different devices
		local jumpButton = touchGui:WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
		local halfJumpSize = UDim2.fromOffset(jumpButton.AbsoluteSize.X / 2, jumpButton.AbsoluteSize.Y / 2)

		blastButton.Size = halfJumpSize
		blastButton.Position = jumpButton.Position + UDim2.fromOffset(halfJumpSize.X.Offset, -halfJumpSize.Y.Offset)
	end

	-- Only show the touch button when user is using touch input
	local function updateTouchVisibility()
		local lastInputType = UserInputService:GetLastInputType()
		local isTouchInput = lastInputType == Enum.UserInputType.Touch
		blastButton.Visible = isTouchInput
	end
	UserInputService.LastInputTypeChanged:Connect(updateTouchVisibility)
	updateTouchVisibility()
end

return setupTouchButtonAsync
