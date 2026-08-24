--!strict

--[[
	Default farm data that every new player starts with
--]]

local ServerStorage = game:GetService("ServerStorage")

local Farm = require(ServerStorage.Source.Farm.Farm)

local DefaultFarmData: Farm.FarmData = {
	tables = {
		spot1 = nil,
		spot2 = nil,
		spot3 = {
			id = "Table",
			pots = {
				spot1 = {
					id = "SmallPot",
					plant = nil,
				},
				spot2 = nil,
				spot3 = nil,
			},
		},
	},
	wagon = {
		id = "BasicWagon", -- TODO: Start with Rusty Wagon after purchasing wagons is implemented
		contents = {},
	},
	holdingPlantId = nil,
}

return DefaultFarmData
