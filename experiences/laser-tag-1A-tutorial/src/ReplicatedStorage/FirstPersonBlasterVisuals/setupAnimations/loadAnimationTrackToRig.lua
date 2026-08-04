--[[
	Loads the given animation ID into the Animator of the given rig,
	returning the AnimationTrack result.

	Used for playing the character holding animation and playing the laser blaster
	idle and blast animations.
--]]

local function loadAnimationTrackToRig(rig: Model, animationId: string): AnimationTrack
	-- Recursively search for the Animator as a descendant of the rig
	local animator = rig:FindFirstChildWhichIsA("Animator", true)
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local animationTrack = animator:LoadAnimation(animation)

	return animationTrack
end

return loadAnimationTrackToRig
