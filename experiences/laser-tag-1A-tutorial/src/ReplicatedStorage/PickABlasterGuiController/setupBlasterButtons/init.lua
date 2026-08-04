--!nocheck
--[[
	Generates a button for each blaster in the LaserBlastersFolder
	Each blaster Configuration contains an IconId attribute used as the display icon on the associated button.

	The selected blaster is updated by setting the GuiAttribute.selectedIndex attribute on the GUI.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local setupSelectButton = require(script.setupSelectButton)
local setupNavButtons = require(script.setupNavButtons)
local updateSelectedIndex = require(script.updateSelectedIndex)
local GuiAttribute = require(ReplicatedStorage.GuiAttribute)

local laserBlastersFolder = ReplicatedStorage.Instances.LaserBlastersFolder
local blasterButtonPrefab = ReplicatedStorage.Instances.Guis.BlasterButtonPrefab

local function setupBlasterButtons(gui: ScreenGui)
	local frame = gui.Frame.SelectionFrame.Frame
	local blasterButtonContainer = frame.Container
	local blasterButtons = {}

	local function createBlasterButton(blasterConfiguration: Configuration)
		local index = blasterConfiguration:GetAttribute("iconLayoutOrder")

		local blasterButton = blasterButtonPrefab:Clone()
		-- Name the blaster button the same as the blaster, so we can read the name
		-- of the button later to get the associated blaster type
		blasterButton.Name = blasterConfiguration.Name
		blasterButton.ImageLabel.Image = blasterConfiguration:GetAttribute("iconId")
		blasterButton.LayoutOrder = index
		blasterButton.Parent = blasterButtonContainer

		blasterButton.Activated:Connect(function()
			gui:SetAttribute(GuiAttribute.selectedIndex, index)
		end)

		table.insert(blasterButtons, index, blasterButton)
	end

	for _, blaster in laserBlastersFolder:GetChildren() do
		createBlasterButton(blaster)
	end

	-- Setup other buttons that depend on the generated blasterButtons
	setupSelectButton(gui, blasterButtons)
	setupNavButtons(gui, blasterButtons)

	-- Change blaster buttons appearance when they are selected or deselected
	gui:GetAttributeChangedSignal(GuiAttribute.selectedIndex):Connect(function()
		local newIndex = gui:GetAttribute(GuiAttribute.selectedIndex)
		updateSelectedIndex(newIndex, blasterButtons)
	end)
end

return setupBlasterButtons
