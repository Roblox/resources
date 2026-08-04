--!strict

--[[
	Connects various UI animations to tagged GUIObjects.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConstants = require(ReplicatedStorage.FeaturePackagesCore.Configs.SharedConstants)
local UITween = require(ReplicatedStorage.FeaturePackagesCore.Modules.UITween)
local bindToTaggedInstances = require(ReplicatedStorage.FeaturePackagesCore.Utils.bindToTaggedInstances)

-- Animation constants
local ROTATION_DURATION = 15
local ROTATION_VALUE = 360
local HOVER_DURATION = 0.3
local SCALE_DURATION = 2
local SCALE_FACTOR = 0.9
local SHEEN_DURATION = 2
local LOADING_DURATION = 4

local function onUILoadingStrokeObjectAdded(object: UIGradient)
	UITween.rotation(object, ROTATION_VALUE, LOADING_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
end

local function onUIGlowObjectAdded(object: ImageLabel)
	UITween.rotation(object, ROTATION_VALUE, ROTATION_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
	UITween.size(
		object,
		UDim2.new(
			object.Size.Width.Scale * SCALE_FACTOR,
			object.Size.Width.Offset * SCALE_FACTOR,
			object.Size.Height.Scale * SCALE_FACTOR,
			object.Size.Height.Offset * SCALE_FACTOR
		),
		SCALE_DURATION,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut,
		-1,
		true
	)
end

local function onUISheenObjectAdded(object: UIGradient)
	local delay = math.random(1, 100) / 25
	UITween.offset(
		object,
		Vector2.new(-1, 0),
		SHEEN_DURATION,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		false,
		delay
	)
end

local function onUIHoverObjectAdded(object: GuiObject)
	local goalPropertiesByIsHovering: { [boolean]: { [string]: any } } = {}

	if object:IsA("TextButton") or object:IsA("TextLabel") then
		goalPropertiesByIsHovering[true] = {
			TextTransparency = 0,
			BackgroundTransparency = 0.8,
		}
		goalPropertiesByIsHovering[false] = {
			TextTransparency = object.TextTransparency,
			BackgroundTransparency = object.BackgroundTransparency,
		}
	else
		goalPropertiesByIsHovering[true] = {
			Size = UDim2.new(
				object.Size.X.Scale / SCALE_FACTOR,
				object.Size.X.Offset / SCALE_FACTOR,
				object.Size.Y.Scale / SCALE_FACTOR,
				object.Size.X.Offset / SCALE_FACTOR
			),
		}
		goalPropertiesByIsHovering[false] = {
			Size = object.Size,
		}
	end

	local function onHover(isHovering: boolean)
		UITween.play(object, goalPropertiesByIsHovering[isHovering], HOVER_DURATION)
	end

	object.MouseEnter:Connect(function()
		onHover(true)
	end)

	object.MouseLeave:Connect(function()
		onHover(false)
	end)
end

local function initialize()
	bindToTaggedInstances(SharedConstants.Tags.UI.UIGLOW_TAG, onUIGlowObjectAdded)
	bindToTaggedInstances(SharedConstants.Tags.UI.UISHEEN_TAG, onUISheenObjectAdded)
	bindToTaggedInstances(SharedConstants.Tags.UI.UILOADING_STROKE_TAG, onUILoadingStrokeObjectAdded)
	bindToTaggedInstances(SharedConstants.Tags.UI.UIHOVER_TAG, onUIHoverObjectAdded)
end

initialize()
