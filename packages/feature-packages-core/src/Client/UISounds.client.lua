--!strict

--[[
	Connects sounds to tagged GUIObjects.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConstants = require(ReplicatedStorage.FeaturePackagesCore.Configs.SharedConstants)
local bindToTaggedInstances = require(ReplicatedStorage.FeaturePackagesCore.Utils.bindToTaggedInstances)
local playSound = require(ReplicatedStorage.FeaturePackagesCore.Utils.playSound)

local function onButtonAdded(button: Instance)
	assert(button:IsA("GuiButton"), `Invalid tagged UIButton: {button:GetFullName()}`)

	button.Activated:Connect(function()
		task.spawn(playSound, SharedConstants.Sounds.Ids.BUTTON_ACTIVATED)
	end)

	button.MouseEnter:Connect(function()
		task.spawn(playSound, SharedConstants.Sounds.Ids.BUTTON_HOVER, SharedConstants.Sounds.VOLUME / 2)
	end)

	button.SelectionGained:Connect(function()
		task.spawn(playSound, SharedConstants.Sounds.Ids.BUTTON_HOVER, SharedConstants.Sounds.VOLUME / 2)
	end)
end

local function initialize()
	bindToTaggedInstances(SharedConstants.Tags.UI.UIBUTTON_TAG, onButtonAdded)
end

initialize()
