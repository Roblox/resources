--!nocheck
--[[
	Defines a hitmarker effect that plays when a player is tagged. The effect quickly shows and hides the hitmarker
	using a tween on the image's transparency.

	Listens for playerTaggedBindableEvent which fires within renderBlast if a player is tagged.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local playerTaggedBindableEvent = ReplicatedStorage.Instances.PlayerTaggedBindableEvent

-- How long the hitmarker should be visible for after a blast connects with a target player
local HITMARKER_FLASH_TIME = 0.4
local HITMARKER_TWEEN_INFO =
	TweenInfo.new(HITMARKER_FLASH_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, true)

local function setupHitmarker(gui: ScreenGui)
	local propertyTable = {
		ImageTransparency = 0,
	}
	local tweenHitmarker = TweenService:Create(gui.Crosshair.Hitmarker, HITMARKER_TWEEN_INFO, propertyTable)

	local function onPlayerTaggedEvent()
		tweenHitmarker:Cancel()
		-- The hitmarker will remain at the transparency value at the time of canceling. Reset it to be invisible.
		gui.Crosshair.Hitmarker.ImageTransparency = 1
		tweenHitmarker:Play()
	end
	playerTaggedBindableEvent.Event:Connect(onPlayerTaggedEvent)
end

return setupHitmarker
