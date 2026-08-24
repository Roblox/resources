--!strict

--[[
	Updates the height of a ScrollingFrame canvas to match the
	AbsoluteContentSize of a UIListLayout whenever it changes.

	This shouldn't be necessary if AutomaticCanvasSize worked
	properly, but it doesn't seem to in all cases, especially
	if a UIAspectRatio exists in a list item in the scrolling frame.
--]]

local function autoSizeCanvasHeight(scrollingFrame: ScrollingFrame)
	local listLayout = scrollingFrame:FindFirstChildOfClass("UIListLayout")
	assert(
		listLayout,
		string.format("Unable to find a UIListLayout inside scrollingFrame %s", scrollingFrame:GetFullName())
	)

	local connection = listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingFrame.CanvasSize = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
	end)

	scrollingFrame.CanvasSize = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)

	return connection
end

return autoSizeCanvasHeight
