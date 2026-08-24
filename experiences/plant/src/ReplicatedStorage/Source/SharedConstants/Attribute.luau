--!strict

--[[
	A source of truth list of all attributes used by scripts. Allows
	scripts to reference attributes by name without typo-prone strings
	that won't be caught until runtime.
--]]

export type EnumType =
	"CurrentStage"
	| "StageNumber"
	| "OwnerId"
	| "FinishesGrowingAt"
	| "GrowTime"
	| "Holding"
	| "OriginalCollisionGroup"
	| "ZoneId"
	| "MaxPlantSize"
	| "PlantSize"
	| "HarvestValue"
	| "DescriptionLong"
	| "DescriptionShort"
	| "DisplayName"
	| "PurchaseCost"
	| "DeveloperProductId"
	| "CoinBundleSize"
	| "DoorOpenAngle"
	| "DoorCloseAngle"
	| "PlantId"
	| "PickupAttachmentName"

local Attribute = {
	CurrentStage = "CurrentStage" :: "CurrentStage",
	StageNumber = "StageNumber" :: "StageNumber",
	OwnerId = "OwnerId" :: "OwnerId",
	FinishesGrowingAt = "FinishesGrowingAt" :: "FinishesGrowingAt",
	GrowTime = "GrowTime" :: "GrowTime",
	Holding = "Holding" :: "Holding",
	OriginalCollisionGroup = "OriginalCollisionGroup" :: "OriginalCollisionGroup",
	ZoneId = "ZoneId" :: "ZoneId",
	MaxPlantSize = "MaxPlantSize" :: "MaxPlantSize",
	PlantSize = "PlantSize" :: "PlantSize",
	HarvestValue = "HarvestValue" :: "HarvestValue",
	DescriptionLong = "DescriptionLong" :: "DescriptionLong",
	DescriptionShort = "DescriptionShort" :: "DescriptionShort",
	DisplayName = "DisplayName" :: "DisplayName",
	PurchaseCost = "PurchaseCost" :: "PurchaseCost",
	DeveloperProductId = "DeveloperProductId" :: "DeveloperProductId",
	CoinBundleSize = "CoinBundleSize" :: "CoinBundleSize",
	DoorOpenAngle = "DoorOpenAngle" :: "DoorOpenAngle",
	DoorCloseAngle = "DoorCloseAngle" :: "DoorCloseAngle",
	PlantId = "PlantId" :: "PlantId",
	PickupAttachmentName = "PickupAttachmentName" :: "PickupAttachmentName",
}

return Attribute
