--[[
	Runs all visuals for the local player's blast, including
		- First person blaster animation
		- Drawing each laser ray from the blaster to the destination
		- Flaring the HUD hitmarker
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlastData = require(ReplicatedStorage.Blaster.BlastData)
local drawLaserRay = require(ReplicatedStorage.LaserRay.drawLaserRay)

local playerTaggedBindableEvent = ReplicatedStorage.Instances.PlayerTaggedBindableEvent

local function runBlastVisuals(tipAttachment: Attachment, blastData: BlastData.Type, blastAnimation: AnimationTrack)
	-- Play first-person blast animation
	blastAnimation:Play(0)

	-- Capture visual origin
	local visualOrigin = tipAttachment.WorldPosition
	local didTagPlayer = false

	-- Draw each laser ray
	for _, rayResult in blastData.rayResults do
		drawLaserRay(visualOrigin, rayResult.destination)
		if rayResult.taggedPlayer then
			didTagPlayer = true
		end
	end

	-- Flare the HUD hitmarker
	if didTagPlayer then
		playerTaggedBindableEvent:Fire()
	end
end

return runBlastVisuals
