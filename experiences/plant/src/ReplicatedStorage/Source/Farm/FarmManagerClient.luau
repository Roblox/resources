--!strict

--[[
	Creates client-side components that listen for their associated tags
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local PlantTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlantTag)
local AnimationTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.AnimationTag)
local ComponentCreator = require(ReplicatedStorage.Source.ComponentCreator)
local PullingWagon = require(ReplicatedStorage.Source.Farm.Components.PullingWagon)
local PlantStageTimer = require(ReplicatedStorage.Source.Farm.Components.PlantStageTimer)
local Holding = require(ReplicatedStorage.Source.Farm.Components.Holding)
local AnimatedShopSymbol = require(ReplicatedStorage.Source.Farm.Components.AnimatedShopSymbol)
local AnimatedRoosterNPC = require(ReplicatedStorage.Source.Farm.Components.AnimatedRoosterNPC)
local LocalCta = require(ReplicatedStorage.Source.Farm.Components.LocalCta)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local CtaDataModulesFolder: Folder = getInstance(ReplicatedStorage, "Source", "Farm", "CtaDataModules")

local FarmManagerClient = {}

function FarmManagerClient.start()
	ComponentCreator.new(CharacterTag.PullingWagon, PullingWagon):listen()
	ComponentCreator.new(PlantTag.Growing, PlantStageTimer):listen()
	ComponentCreator.new(CharacterTag.Holding, Holding):listen()
	ComponentCreator.new(AnimationTag.AnimatedShopSymbol, AnimatedShopSymbol):listen()
	ComponentCreator.new(AnimationTag.AnimatedRoosterNPC, AnimatedRoosterNPC):listen()

	for _, ctaDataModule in ipairs(CtaDataModulesFolder:GetChildren()) do
		assert(
			ctaDataModule:IsA("ModuleScript"),
			string.format(
				"Only ModuleScripts should be inside %s. Found: %s",
				CtaDataModulesFolder:GetFullName(),
				ctaDataModule.ClassName
			)
		)

		-- The typechecker does not recognize dynamic paths for require so we are casting to any
		local ctaData = (require :: any)(ctaDataModule)
		ComponentCreator.new(ctaData.tag, LocalCta, ctaData):listen()
	end

	-- TODO: Create a progress bar/wagon full cta
end

return FarmManagerClient
