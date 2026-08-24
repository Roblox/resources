--!strict

--[[
	CTA that shows up over a table placement indicator when a table can be placed in it
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)
local ImageId = require(ReplicatedStorage.Source.SharedConstants.ImageId)
local PlacementTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlacementTag)
local CtaDataType = require(ReplicatedStorage.Source.Farm.CtaDataType)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local promptDataFunctions = require(script.promptDataFunctions)
local shouldEnable = require(script.shouldEnable)

local ctaData: CtaDataType.CtaData = {
	tag = PlacementTag.CanPlaceTable,
	listenToPlayerDataValues = { PlayerDataKey.Inventory },
	listenToTags = nil,
	listenToSignals = { UIHandler.areMenusVisibleChanged },
	iconData = {
		imageColor3 = ColorTheme.White,
		backgroundColor3 = ColorTheme.White,
		imageId = ImageId.PlaceTableIcon,
	},
	promptData = { functions = promptDataFunctions },
	shouldEnable = shouldEnable,
}

return ctaData
