--!strict

--[[
	Links a group of tweens together, allowing them to be played, paused and canceled as one.

	Note TweenGroup does not support PlaybackState or Completed events.
--]]

local TweenGroup = {}
TweenGroup.__index = TweenGroup

function TweenGroup.new(...: Tween)
	local self = {
		_tweens = { ... },
	}
	setmetatable(self, TweenGroup)

	return self
end

function TweenGroup:play()
	for _, tween in ipairs(self._tweens) do
		tween:Play()
	end
end

function TweenGroup:pause()
	for _, tween in ipairs(self._tweens) do
		tween:Pause()
	end
end

function TweenGroup:cancel()
	for _, tween in ipairs(self._tweens) do
		tween:Cancel()
	end
end

return TweenGroup
