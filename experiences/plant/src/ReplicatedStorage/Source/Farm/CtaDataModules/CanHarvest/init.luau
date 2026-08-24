--!strict

--[[
	CTA that shows up over a plant when it's ready to be harvested
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local ImageId = require(ReplicatedStorage.Source.SharedConstants.ImageId)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local WagonTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.WagonTag)
local PlantTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlantTag)
local CtaDataType = require(ReplicatedStorage.Source.Farm.CtaDataType)

local promptDataFunctions = require(script.promptDataFunctions)
local shouldEnable = require(script.shouldEnable)

local ctaData: CtaDataType.CtaData = {
	tag = PlantTag.CanHarvest,
	listenToPlayerDataValues = nil,
	listenToTags = { CharacterTag.Holding, WagonTag.WagonFull },
	listenToSignals = { UIHandler.areMenusVisibleChanged },
	iconData = {
		imageColor3 = ColorTheme.White,
		backgroundColor3 = ColorTheme.Orange,
		imageId = ImageId.HarvestIcon,
	},
	promptData = { functions = promptDataFunctions },
	shouldEnable = shouldEnable,
}

return ctaData
