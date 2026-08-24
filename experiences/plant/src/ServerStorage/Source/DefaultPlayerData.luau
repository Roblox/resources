--!strict

--[[
	Default data that every new player starts with
--]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultFarmData = require(ServerStorage.Source.Farm.DefaultFarmData)
local FtueStage = require(ReplicatedStorage.Source.SharedConstants.FtueStage)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)

local DefaultPlayerData: { [string]: any } = {
	[PlayerDataKey.Coins] = 3, -- Just enough coins to complete FTUE
	[PlayerDataKey.FtueStage] = FtueStage.InFarm,
	[PlayerDataKey.Farm] = DefaultFarmData,
	[PlayerDataKey.Inventory] = {
		Seeds = {
			SeedCabbage = 1,
		},
		Tables = {},
		Pots = {},
	} :: {
		[string]: { -- [category]: countByItemId
			[string]: number, -- [itemId]: count
		},
	},
}

return DefaultPlayerData
