--!strict

--[[
	A mapping of ZoneIds to UILayers used for setting up zone connections to open corresponding shop UI
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)

local UILayerIdByZoneId: { [ZoneIdTag.EnumType]: UILayerId.EnumType } = {
	[ZoneIdTag.InShop] = UILayerId.SeedMarket,
	[ZoneIdTag.InGardenStore] = UILayerId.GardenStore,
}

return UILayerIdByZoneId
