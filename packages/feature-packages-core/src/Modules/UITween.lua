--!strict

--[[
	UITween provides utilities for tweening GuiObjects via short-hand methods.
--]]

local TweenService = game:GetService("TweenService")
local UITween = {}

function UITween.play(
	object: GuiObject | UIGradient,
	properties: { [string]: any },
	time: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	reverse: boolean?,
	delay: number?
): Tween
	local tweenInfo = TweenInfo.new(
		time,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out,
		repeatCount or 0,
		reverse == true,
		delay or 0
	)
	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()

	return tween
end

function UITween.rotation(
	object: GuiObject | UIGradient,
	rotation: number,
	time: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	reverse: boolean?,
	delay: number?
): Tween
	return UITween.play(object, { Rotation = rotation }, time, style, direction, repeatCount, reverse, delay)
end

function UITween.size(
	object: GuiObject | UIGradient,
	size: UDim2,
	time: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	reverse: boolean?,
	delay: number?
): Tween
	return UITween.play(object, { Size = size }, time, style, direction, repeatCount, reverse, delay)
end

function UITween.offset(
	object: UIGradient,
	offset: Vector2,
	time: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	reverse: boolean?,
	delay: number?
): Tween
	object.Offset = offset
	return UITween.play(object, { Offset = -offset }, time, style, direction, repeatCount, reverse, delay)
end

function UITween.position(
	object: GuiObject,
	position: UDim2,
	time: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	reverse: boolean?,
	delay: number?
): Tween
	return UITween.play(object, { Position = position }, time, style, direction, repeatCount, reverse, delay)
end

function UITween.transparency(
	object: GuiObject | UIGradient,
	transparency: number,
	time: number,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	repeatCount: number?,
	reverse: boolean?,
	delay: number?
): Tween?
	local transparencyProperty = if object:IsA("CanvasGroup")
		then "GroupTransparency"
		elseif object:IsA("ImageLabel") then "ImageTransparency"
		else "BackgroundTransparency"

	return UITween.play(
		object,
		{ [transparencyProperty] = transparency },
		time,
		style,
		direction,
		repeatCount,
		reverse,
		delay
	)
end

return UITween
