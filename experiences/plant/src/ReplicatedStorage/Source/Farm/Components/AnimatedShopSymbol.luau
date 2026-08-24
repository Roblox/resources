--!strict

--[[
	Handles client-side floating animations for floating shop symbols
--]]

local TweenService = game:GetService("TweenService")

local ANIMATION_TIME = 3
local OFFSET = CFrame.new(0, 2, 0)
local TWEEN_INFO = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local AnimatedShopSymbol = {}
AnimatedShopSymbol.__index = AnimatedShopSymbol

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: BasePart,
		_originalCFrame: CFrame,
		_loopedAnimationTween: Tween?,
	},
	AnimatedShopSymbol
))

function AnimatedShopSymbol.new(symbol: BasePart): ClassType
	local self = {
		_instance = symbol,
		_originalCFrame = symbol.CFrame,
		_loopedAnimationTween = nil,
	}
	setmetatable(self, AnimatedShopSymbol)

	self:_startAnimation()

	return self
end

function AnimatedShopSymbol._startAnimation(self: ClassType)
	local tween = TweenService:Create(self._instance, TWEEN_INFO, {
		CFrame = self._originalCFrame * OFFSET * CFrame.Angles(0, math.rad(180), 0),
	})
	tween:Play()
	self._loopedAnimationTween = tween
end

function AnimatedShopSymbol.destroy(self: ClassType)
	local tween = self._loopedAnimationTween :: Tween
	tween:Cancel()

	self._instance.CFrame = self._originalCFrame
end

return AnimatedShopSymbol
