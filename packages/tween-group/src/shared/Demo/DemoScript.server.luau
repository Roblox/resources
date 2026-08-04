--[[
	Links a group of tweens together, allowing them to be played, paused and cancelled as one.
	Note: TweenGroup does not support PlaybackState or Completed events.
--]]

local TweenService = game:GetService("TweenService")
local TweenGroup = require(script.Parent.Parent.TweenGroup)

local part = script.Parent.Part

-- Create a TweenGroup containing multiple tweens
local tweenGroup = TweenGroup.new(
	TweenService:Create(part, TweenInfo.new(5, Enum.EasingStyle.Linear), {
		Color = Color3.new(1, 0, 0),
	}),
	TweenService:Create(part, TweenInfo.new(12, Enum.EasingStyle.Quad), {
		Size = Vector3.new(10, 10, 10),
	}),
	TweenService:Create(part, TweenInfo.new(14, Enum.EasingStyle.Sine), {
		Transparency = 1,
	}),
	TweenService:Create(part, TweenInfo.new(9, Enum.EasingStyle.Bounce), {
		Position = part.Position + (Vector3.yAxis * 15),
	})
)

-- Play all the tweens at once
tweenGroup:play()
