--[[
	Processes the behavior for a tagged players within each RayResult.
	The amount of damage to deal depends on the blaster used by the player that blasted.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)
local BlastData = require(ReplicatedStorage.Blaster.BlastData)

local onPlayerTagged = require(script.onPlayerTagged)

local function processTaggedPlayers(playerBlasted: Player, blastData: BlastData.Type)
	for _, rayResult in blastData.rayResults do
		if not rayResult.taggedPlayer then
			continue
		end

		local blasterConfig = getBlasterConfig(playerBlasted)
		local damagePerHit = blasterConfig:GetAttribute("damagePerHit")
		onPlayerTagged(playerBlasted, rayResult.taggedPlayer, damagePerHit)
	end
end

return processTaggedPlayers
