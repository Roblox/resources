--!strict

--[[
	CTA that shows up over a plant when it's ready to be watered
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local ImageId = require(ReplicatedStorage.Source.SharedConstants.ImageId)
local PlantTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlantTag)
local CtaDataType = require(ReplicatedStorage.Source.Farm.CtaDataType)

local promptDataFunctions = require(script.promptDataFunctions)
local shouldEnable = require(script.shouldEnable)

local ctaData: CtaDataType.CtaData = {
	tag = PlantTag.NeedsWater,
	listenToPlayerDataValues = nil,
	listenToTags = {
		CharacterTag.Holding,
	},
	listenToSignals = { UIHandler.areMenusVisibleChanged },
	iconData = {
		imageColor3 = ColorTheme.White,
		backgroundColor3 = ColorTheme.Blue,
		imageId = ImageId.WaterIcon,
	},
	promptData = { functions = promptDataFunctions },
	shouldEnable = shouldEnable,
}

return ctaData
