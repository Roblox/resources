--!strict

--[[
	Create an animated BillboardGui "Call to action" on an instance
	An optional proximity prompt can also be specified
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CtaDataType = require(ReplicatedStorage.Source.Farm.CtaDataType)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local GUI_TWEEN_SIZE_SCALAR = 0.25
local PROMPT_DEBOUNCE_SECONDS = 1

local ctaGuiPrefab: BillboardGui = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "CtaGuiPrefab")
local ctaPromptPrefab: ProximityPrompt = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "CtaPromptPrefab")
local objectHighlightPrefab: Highlight = getInstance(ReplicatedStorage, "Instances", "ObjectHighlightPrefab")
local guiTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true, 0)

local CallToAction = {}
CallToAction.__index = CallToAction

export type ClassType = typeof(setmetatable(
	{} :: {
		_parent: Instance,
		_ctaData: CtaDataType.CtaData,
		_isDestroyed: boolean,
		_billboardGui: BillboardGui,
		_proximityPrompt: ProximityPrompt?,
		_objectHighlight: Highlight?,
		_connections: Connections.ClassType,
	},
	CallToAction
))

function CallToAction.new(parent: Instance, ctaData: CtaDataType.CtaData): ClassType
	assert(
		ctaData.iconData or ctaData.promptData,
		"Creating a CallToAction requires one or both of iconData and promptData to be specified"
	)

	local self = {
		_parent = parent,
		_ctaData = ctaData,
		_isDestroyed = false,
		_billboardGui = ctaGuiPrefab:Clone(),
		_proximityPrompt = nil,
		_objectHighlight = nil,
		_connections = Connections.new(),
	}

	setmetatable(self, CallToAction)

	if ctaData.iconData then
		self:_addGui()
	end

	if ctaData.promptData then
		self:_addPrompt()
	end

	return self
end

-- Adds an image that is always visible, regardless of whether the prompt is showing
function CallToAction._addGui(self: ClassType)
	assert(self._ctaData.iconData, "Cannot add gui to CallToAction without iconData")
	local imageLabel: ImageLabel = getInstance(self._billboardGui, "ImageLabel")
	imageLabel.Image = PlayerFacingString.ImageAsset.Prefix .. self._ctaData.iconData.imageId
	imageLabel.ImageColor3 = self._ctaData.iconData.imageColor3
	imageLabel.BackgroundColor3 = self._ctaData.iconData.backgroundColor3

	-- Animate gui
	local tween = TweenService:Create(
		self._billboardGui,
		guiTweenInfo,
		{ Size = self._billboardGui.Size + UDim2.fromScale(GUI_TWEEN_SIZE_SCALAR, GUI_TWEEN_SIZE_SCALAR) }
	)

	self._billboardGui.Parent = self._parent
	tween:Play()
end

function CallToAction._updatePromptText(self: ClassType, prompt: ProximityPrompt)
	local promptData = self._ctaData.promptData
	assert(promptData, "Cannot update prompt text for non-prompt CallToActions")

	prompt.ActionText = promptData.functions.getActionText(self._parent)
	prompt.ObjectText = promptData.functions.getObjectText(self._parent)
end

function CallToAction._addPrompt(self: ClassType)
	assert(self._ctaData.promptData, "Cannot add prompt to CallToAction without promptData")
	local prompt = ctaPromptPrefab:Clone()
	local highlight = objectHighlightPrefab:Clone()

	local shownConnection = prompt.PromptShown:Connect(function()
		self:_updatePromptText(prompt)
		highlight.Enabled = true
	end)

	local hiddenConnection = prompt.PromptHidden:Connect(function()
		highlight.Enabled = false
	end)

	local triggeredConnection = prompt.Triggered:Connect(function()
		self:_onPromptTriggered()
	end)

	self._connections:add(shownConnection, hiddenConnection, triggeredConnection)

	local properties = self._ctaData.promptData.properties
	if properties then
		prompt.GamepadKeyCode = properties.gamepadKeyCode or prompt.GamepadKeyCode
		prompt.KeyboardKeyCode = properties.keyboardKeyCode or prompt.KeyboardKeyCode
		prompt.UIOffset = properties.uiOffset or prompt.UIOffset
	end
	self:_updatePromptText(prompt)
	self._proximityPrompt = prompt
	prompt.Parent = self._parent

	self._objectHighlight = highlight
	highlight.Parent = self._parent
end

function CallToAction._onPromptTriggered(self: ClassType)
	local promptData = self._ctaData.promptData
	assert(promptData and self._proximityPrompt, "Cannot update prompt text for non-prompt CallToActions")

	self._proximityPrompt.Enabled = false

	task.delay(PROMPT_DEBOUNCE_SECONDS, function()
		if not self._isDestroyed then
			self._proximityPrompt.Enabled = true
		end
	end)

	promptData.functions.onTriggered(self._parent)
end

function CallToAction.destroy(self: ClassType)
	self._isDestroyed = true

	if self._proximityPrompt then
		self._proximityPrompt:Destroy()
	end

	if self._objectHighlight then
		self._objectHighlight:Destroy()
	end

	if self._billboardGui then
		self._billboardGui:Destroy()
	end

	self._connections:disconnect()
end

return CallToAction
