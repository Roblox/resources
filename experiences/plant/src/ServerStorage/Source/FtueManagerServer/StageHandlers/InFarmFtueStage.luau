--!strict

--[[
	Handles the InFarm stage during the First Time User Experience,
	which waits for the player to place a table and pot, water the seed,
	harvest the plant, and place it in the wagon
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FarmManagerServer = require(ServerStorage.Source.Farm.FarmManagerServer)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)

local InFarmFtueStage = {}

function InFarmFtueStage.handleAsync(player: Player): FtueStage.EnumType?
	local farm = FarmManagerServer.getFarmForPlayer(player)
	local wagonClass = farm:getWagon()
	assert(wagonClass, "WagonClass must be initialized before FTUE stage")
	local contentsManager = wagonClass:getContentsManager()

	farm:closeDoor()
	while contentsManager:isEmpty() do
		contentsManager.changed:Wait()
	end
	farm:openDoor()

	return FtueStage.SellingPlant
end

return InFarmFtueStage
