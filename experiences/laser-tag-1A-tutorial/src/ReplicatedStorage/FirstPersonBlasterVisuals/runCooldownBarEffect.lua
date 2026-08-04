--!nocheck
--[[
	Visual effect for the player to understand when they can shoot again

	When a blast occurs, the bar will fill the container, then reduce to nothing over secondsBetweenBlasts
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)

local END_SIZE = UDim2.fromScale(0, 1)
local EASING_DIRECTION = Enum.EasingDirection.In
local EASING_STYLE = Enum.EasingStyle.Quad

local function runCooldownBarEffect(part: Part)
	local bar = part.SurfaceGui.Container.Bar

	-- Set bar size to 1 (bar filled)
	bar.Size = UDim2.fromScale(1, 1)

	-- Tween the size to 0 (bar empty) for the duration of secondsBetweenBlasts
	local secondsBetweenBlasts = getBlasterConfig():GetAttribute("secondsBetweenBlasts")
	local tweenInfo = TweenInfo.new(secondsBetweenBlasts, EASING_STYLE, EASING_DIRECTION)
	local propertyTable = {
		Size = END_SIZE,
	}
	local tween = TweenService:Create(bar, tweenInfo, propertyTable)
	tween:Play()
end

return runCooldownBarEffect
