--[[
	Loads an animation on an Animator based on the animationId
--]]

local function loadAnimationTrack(animator: Animator, animationId: string): AnimationTrack
	local animation = Instance.new("Animation")
	animation.Name = string.format("Animation_%s", animationId)
	animation.AnimationId = animationId
	animation.Parent = animator

	local animationTrack = animator:LoadAnimation(animation)
	return animationTrack
end

return loadAnimationTrack
