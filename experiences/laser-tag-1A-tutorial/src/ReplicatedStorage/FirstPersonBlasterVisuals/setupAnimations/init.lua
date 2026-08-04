--!nocheck
--[[
	Sets up the following animations to be used for the first person visuals
		- blastAnimation plays when the blaster is blasted
		- idleAnimation plays when the blaster is not blasting to keep the blaster idle

	characterHoldAnimation plays such that the character raises their arm with the blaster in hand.
	This is not seen by the local player because CameraMode.LockFirstPerson will make their character
	(and any children) locally invisible.
--]]

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local loadAnimationTrackToRig = require(script.loadAnimationTrackToRig)

local function setupAnimations(blasterConfig: Configuration, rigModel: Model): { AnimationTrack }
	local blastAnimationId = blasterConfig:GetAttribute("blastAnimationId")
	local idleAnimationId = blasterConfig:GetAttribute("idleAnimationId")
	local characterHoldAnimationId = blasterConfig:GetAttribute("characterHoldAnimationId")

	local blastAnimation = loadAnimationTrackToRig(rigModel, blastAnimationId)
	local idleAnimation = loadAnimationTrackToRig(rigModel, idleAnimationId)
	local characterHoldAnimation = loadAnimationTrackToRig(localPlayer.Character, characterHoldAnimationId)

	idleAnimation:Play()
	characterHoldAnimation:Play()

	return {
		blastAnimation = blastAnimation,
		idleAnimation = idleAnimation,
		characterHoldAnimation = characterHoldAnimation,
	}
end

return setupAnimations
