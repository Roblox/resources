--!strict

--[[
	CTA that shows up over an empty plant pot prompting opening of the seeds menu
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local ImageId = require(ReplicatedStorage.Source.SharedConstants.ImageId)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local PotTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PotTag)
local CtaDataType = require(ReplicatedStorage.Source.Farm.CtaDataType)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

local promptDataFunctions = require(script.promptDataFunctions)
local shouldEnable = require(script.shouldEnable)

local ctaData: CtaDataType.CtaData = {
	tag = PotTag.CanPlant,
	listenToPlayerDataValues = { PlayerDataKey.Inventory },
	listenToTags = {
		PotTag.CanPlant,
		CharacterTag.Holding,
	},
	listenToSignals = { UIHandler.areMenusVisibleChanged },
	iconData = {
		imageColor3 = ColorTheme.White,
		backgroundColor3 = ColorTheme.White,
		imageId = ImageId.PlantSeedIcon,
	},
	promptData = { functions = promptDataFunctions },
	shouldEnable = shouldEnable,
}

return ctaData
