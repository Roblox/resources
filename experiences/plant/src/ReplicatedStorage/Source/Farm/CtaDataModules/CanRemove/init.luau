--!strict

--[[
	CTA that shows up over an empty plant pot prompting removal of the pot
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local PotTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PotTag)
local CtaDataType = require(ReplicatedStorage.Source.Farm.CtaDataType)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

local promptDataFunctions = require(script.promptDataFunctions)
local shouldEnable = require(script.shouldEnable)

local ctaData: CtaDataType.CtaData = {
	tag = PotTag.CanRemove,
	listenToPlayerDataValues = { PlayerDataKey.Inventory },
	listenToTags = {
		PotTag.CanRemove,
		CharacterTag.Holding,
	},
	listenToSignals = { UIHandler.areMenusVisibleChanged },
	promptData = {
		properties = {
			gamepadKeyCode = Enum.KeyCode.ButtonB,
			keyboardKeyCode = Enum.KeyCode.Backspace,
			uiOffset = Vector2.new(0, -150),
		},
		functions = promptDataFunctions,
	},
	shouldEnable = shouldEnable,
}

return ctaData
