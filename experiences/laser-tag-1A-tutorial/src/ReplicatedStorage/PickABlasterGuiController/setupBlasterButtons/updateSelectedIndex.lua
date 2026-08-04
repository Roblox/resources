--[[
	Updates the blaster buttons when the selected index has changed.

	Adjusts the Size and BackgroundTransparency of a button depending on whether it has
	become selected or unselected.

	Stores the previous index to apply the unselected properties
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local blasterButtonPrefab = ReplicatedStorage.Instances.Guis.BlasterButtonPrefab

local prevIndex = nil

-- Size and BackgroundTransparency values for a selected and unselected button
local ImageButtonProperties = {
	Selected = {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.1,
	},
	Unselected = {
		Size = blasterButtonPrefab.Size,
		BackgroundTransparency = blasterButtonPrefab.BackgroundTransparency,
	},
}

local function updateSelectedIndex(newIndex: number, blasterButtons: { ImageButton })
	local selectedProperties = ImageButtonProperties.Selected
	local selectedButton = blasterButtons[newIndex]
	selectedButton.Size = selectedProperties.Size
	selectedButton.BackgroundTransparency = selectedProperties.BackgroundTransparency

	local unselectedProperties = ImageButtonProperties.Unselected
	local deselectedButton = blasterButtons[prevIndex]
	if deselectedButton then
		deselectedButton.Size = unselectedProperties.Size
		deselectedButton.BackgroundTransparency = unselectedProperties.BackgroundTransparency
	end

	prevIndex = newIndex
end

return updateSelectedIndex
