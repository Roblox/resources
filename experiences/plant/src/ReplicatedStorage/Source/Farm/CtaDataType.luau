--!strict

--[[
	Type definitions for data passed into CallToAction class
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Source.Signal)
local TagEnumType = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.TagEnumType)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

export type PromptTriggeredCallback = (promptParent: Instance) -> nil

export type PromptData = {
	properties: {
		gamepadKeyCode: Enum.KeyCode?,
		keyboardKeyCode: Enum.KeyCode?,
		uiOffset: Vector2?,
	}?,
	functions: {
		getActionText: (promptParent: Instance) -> string,
		getObjectText: (promptParent: Instance) -> string,
		onTriggered: PromptTriggeredCallback,
	},
}
export type PromptIconData = {
	imageColor3: Color3,
	backgroundColor3: Color3,
	imageId: number,
}

export type CtaData = {
	tag: TagEnumType.EnumType,
	listenToPlayerDataValues: { PlayerDataKey.EnumType }?,
	listenToTags: { TagEnumType.EnumType }?,
	listenToSignals: { RBXScriptSignal | Signal.ClassType },
	iconData: PromptIconData?,
	promptData: PromptData?,
	shouldEnable: ((promptParent: Instance) -> boolean)?,
}

return nil
