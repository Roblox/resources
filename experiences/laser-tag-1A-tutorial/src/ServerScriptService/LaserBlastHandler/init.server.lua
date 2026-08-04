--[[
	Server script that handles incoming blast events from the Client, by doing the following:
		- Validates the blast data by doing sanity checks
		- Simulates the blast on the Server to get tagged players and laser destinations
		- Applies damage to tagged players
		- Replicates the laser blast data to all clients so they they can render the blasts locally
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlastData = require(ReplicatedStorage.Blaster.BlastData)
local blastServer = require(ReplicatedStorage.Blaster.blastServer)
local canPlayerBlast = require(ReplicatedStorage.Blaster.canPlayerBlast)
local getValidatedBlastData = require(script.getValidatedBlastData)

local processTaggedPlayers = require(script.processTaggedPlayers)
local replicateBlastEvent = ReplicatedStorage.Instances.ReplicateBlastEvent

local laserBlastedEvent = ReplicatedStorage.Instances.LaserBlastedEvent

local function onLaserBlastedEvent(playerBlasted: Player, blastData: BlastData.Type)
	-- Validate blastData
	local validatedBlastData = getValidatedBlastData(playerBlasted, blastData)
	if not validatedBlastData then
		-- Blast data was unable to be validated, so we cancel replicating and processing the blast
		return
	end

	-- Equipped blaster was validated to exist when validating blast data
	if not canPlayerBlast(playerBlasted) then
		-- The Server's blaster state is the source of truth, and it isn't ready to blast,
		-- so we cancel replicating and processing the blast
		return
	end

	-- Simulate the blast on the Server to keep blasterStateServer in sync with blasterStateClient
	blastServer(playerBlasted)

	-- Check tagged players' to adjust their health
	processTaggedPlayers(playerBlasted, blastData)

	-- Replicate the blast to all clients other than the player that blasted
	for _, replicateToPlayer in Players:GetPlayers() do
		if playerBlasted == replicateToPlayer then
			continue
		end
		replicateBlastEvent:FireClient(replicateToPlayer, playerBlasted, blastData)
	end
end

laserBlastedEvent.OnServerEvent:Connect(onLaserBlastedEvent)
