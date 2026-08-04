--[[
	Receives events from the Server with validated blaster data to replicate the visuals of the blast
	for all other Clients.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local drawLaserRay = require(ReplicatedStorage.LaserRay.drawLaserRay)
local getBlasterTipAttachment = require(ReplicatedStorage.Blaster.getBlasterTipAttachment)
local BlastData = require(ReplicatedStorage.Blaster.BlastData)

local replicateBlastEvent = ReplicatedStorage.Instances.ReplicateBlastEvent

local function onReplicateBlastEvent(playerBlasted: Player, blastData: BlastData.Type)
	-- The origin of the blast is set to the tip of the playerBlasted's blaster
	local tipAttachment = getBlasterTipAttachment(playerBlasted)
	if not tipAttachment then
		warn(`Cannot replicate lasers, unable to find blaster tip attachment for {playerBlasted.Name}`)
		return
	end
	local visualOrigin = tipAttachment.WorldPosition

	-- Draw the lasers
	for _, rayResult in blastData.rayResults do
		drawLaserRay(visualOrigin, rayResult.destination)
	end
end

replicateBlastEvent.OnClientEvent:Connect(onReplicateBlastEvent)
