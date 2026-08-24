--!strict

--[[
	Specifies the names of all RemoteEvents. One RemoteEvent object gets generated for each name
	in this list, and these names are used as enums when interacting with Network to tell it
	which remote event to fire without typing out typo-prone string literals.
--]]

export type EnumType =
	"PlayerDataLoaded"
	| "PlayerDataUpdated"
	| "PlayerDataSaved"
	| "PlantWatered"
	| "PlantHarvested"
	| "PlantPlaced"
	| "RequestPlaceObject"
	| "RequestRemoveObject"
	| "RequestPullWagon"
	| "RequestPlantSeed"
	| "ResetData"

local RemoteEventName = {
	PlayerDataLoaded = "PlayerDataLoaded" :: "PlayerDataLoaded",
	PlayerDataUpdated = "PlayerDataUpdated" :: "PlayerDataUpdated",
	PlayerDataSaved = "PlayerDataSaved" :: "PlayerDataSaved",
	PlantWatered = "PlantWatered" :: "PlantWatered",
	PlantHarvested = "PlantHarvested" :: "PlantHarvested",
	PlantPlaced = "PlantPlaced" :: "PlantPlaced",
	RequestPlaceObject = "RequestPlaceObject" :: "RequestPlaceObject",
	RequestRemoveObject = "RequestRemoveObject" :: "RequestRemoveObject",
	RequestPullWagon = "RequestPullWagon" :: "RequestPullWagon",
	RequestPlantSeed = "RequestPlantSeed" :: "RequestPlantSeed",
	ResetData = "ResetData" :: "ResetData",
}

return RemoteEventName
