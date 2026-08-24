--!strict

--[[
	Links a group of tweens together, allowing them to be played, paused and canceled as one.

	Note TweenGroup does not support PlaybackState or Completed events.
--]]

local TweenGroup = {}
TweenGroup.__index = TweenGroup

export type ClassType = typeof(setmetatable(
	{} :: {
		_tweens: { Tween },
	},
	TweenGroup
))

function TweenGroup.new(...: Tween): ClassType
	local self = {
		_tweens = { ... },
	}
	setmetatable(self, TweenGroup)

	return self
end

function TweenGroup.play(self: ClassType)
	for _, tween in ipairs(self._tweens) do
		tween:Play()
	end
end

function TweenGroup.pause(self: ClassType)
	for _, tween in ipairs(self._tweens) do
		tween:Pause()
	end
end

function TweenGroup.cancel(self: ClassType)
	for _, tween in ipairs(self._tweens) do
		tween:Cancel()
	end
end

return TweenGroup
