--!strict

--[[
	Handles the client-side InFarm stage during the First Time User Experience,
	which disables all vendors and makes the wagon hidden until the player harvests
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local UIHighlight = require(ReplicatedStorage.Source.UI.UIComponents.UIHighlight)
local UILayerId = require(ReplicatedStorage.Source.SharedConstants.UILayerId)
local PotTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PotTag)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local setVendorEnabled = require(ReplicatedStorage.Source.Utility.Farm.setVendorEnabled)
local getWagonModelFromOwnerId = require(ReplicatedStorage.Source.Utility.Farm.getWagonModelFromOwnerId)
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local playSmokePuff = require(ReplicatedStorage.Source.Utility.playSmokePuff)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local WAGON_SPAWN_ANIMATION_OFFSET = Vector3.yAxis * 10
local TWEEN_INFO = TweenInfo.new(1.5, Enum.EasingStyle.Bounce)

local gardenSupplyVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "GardenSupply")
local marketVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Market")
local storeVendor: Model = getInstance(Workspace, "World", "MarketArea", "Vendors", "Store")
local localPlayer = Players.LocalPlayer :: Player

local InFarmFtueStage = {}
InFarmFtueStage._despawnedWagon = nil :: Model?
InFarmFtueStage._originalParent = nil :: Instance?
InFarmFtueStage._originalCFrame = nil :: CFrame?
InFarmFtueStage._tagRemovedConnection = nil :: RBXScriptConnection?
InFarmFtueStage._uiHighlight = nil :: UIHighlight.ClassType?

function InFarmFtueStage.setup()
	-- TODO: Polish CTAs
	InFarmFtueStage._highlightPlantButton()

	setVendorEnabled(gardenSupplyVendor, false)
	setVendorEnabled(marketVendor, false)
	setVendorEnabled(storeVendor, false)

	InFarmFtueStage._despawnWagon()

	task.spawn(function()
		InFarmFtueStage._waitForPlantHarvestAsync()
		InFarmFtueStage._respawnWagon()
	end)
end

function InFarmFtueStage._highlightPlantButton()
	local emptyPots = CollectionService:GetTagged(PotTag.CanPlant)
	local emptyPot = Freeze.List.find(emptyPots, function(anyEmptyPot: Instance)
		return getFarmOwnerIdFromInstance(anyEmptyPot) == localPlayer.UserId
	end)

	if not emptyPot then
		-- It's possible the player left during FTUE and is loading back in the middle of the stage,
		-- so it's possible there is no open pot to plant in. In that case, skip creating the highlight.
		return
	end

	local plantSeedUiLayer = UIHandler.getLayerClassInstanceById(UILayerId.PlantSeed)
	local sidebarActionButton =
		plantSeedUiLayer:getInventoryListSelector():getListSelector():getSidebar():getActionButton():getInstance()

	local uiHighlight = UIHighlight.new(sidebarActionButton)
	InFarmFtueStage._uiHighlight = uiHighlight

	local connection
	connection = CollectionService:GetInstanceRemovedSignal(PotTag.CanPlant):Connect(function(instance)
		-- This is required due to deferred events
		if not connection.Connected then
			return
		end
		if instance == emptyPot then
			connection:Disconnect()
			uiHighlight:destroy()
		end
	end)
	InFarmFtueStage._tagRemovedConnection = connection
end

function InFarmFtueStage._despawnWagon()
	local maybeWagonModel = getWagonModelFromOwnerId(localPlayer.UserId)
	if not maybeWagonModel then
		return
	end

	local wagonModel = maybeWagonModel :: Model

	-- Parent the wagon to nil to hide it, but keep a reference to it
	-- so we can spawn it back in later
	InFarmFtueStage._despawnedWagon = wagonModel
	InFarmFtueStage._originalParent = wagonModel.Parent
	InFarmFtueStage._originalCFrame = wagonModel:GetPivot()
	wagonModel.Parent = nil
end

function InFarmFtueStage._waitForPlantHarvestAsync()
	while not (localPlayer.Character and CollectionService:HasTag(localPlayer.Character, CharacterTag.Holding)) do
		CollectionService:GetInstanceAddedSignal(CharacterTag.Holding):Wait()
	end
end

function InFarmFtueStage._respawnWagon()
	local maybeWagonModel = InFarmFtueStage._despawnedWagon
	if not maybeWagonModel then
		warn("Missing wagonModel property when respawning wagon during InFarmFtueStage")
		return
	end

	local wagonModel = maybeWagonModel :: Model

	wagonModel:PivotTo(InFarmFtueStage._originalCFrame :: CFrame + WAGON_SPAWN_ANIMATION_OFFSET)
	wagonModel.Parent = InFarmFtueStage._originalParent
	playSmokePuff(wagonModel.PrimaryPart :: BasePart)
	TweenService:Create(wagonModel.PrimaryPart :: BasePart, TWEEN_INFO, { CFrame = InFarmFtueStage._originalCFrame })
		:Play()
	InFarmFtueStage._despawnedWagon = nil
	InFarmFtueStage._originalParent = nil
	InFarmFtueStage._originalCFrame = nil
end

function InFarmFtueStage.teardown()
	if InFarmFtueStage._despawnedWagon then
		-- This won't happen during the normal flow of FTUE, but is included for fulfilling the concept of tearing down
		-- things from setup if :waitForPlantHarvestAsync never resumed after yielding. (e.g. player resets their data during this stage)
		pcall(function()
			-- Pcalled because the wagon may have been destroyed, in which case we can't re-parent it.
			InFarmFtueStage._despawnedWagon.Parent = InFarmFtueStage._originalParent
		end)

		InFarmFtueStage._despawnedWagon = nil
		InFarmFtueStage._originalParent = nil
		InFarmFtueStage._originalCFrame = nil
	end

	if InFarmFtueStage._tagRemovedConnection then
		InFarmFtueStage._tagRemovedConnection:Disconnect()
		InFarmFtueStage._tagRemovedConnection = nil
	end

	if InFarmFtueStage._uiHighlight then
		InFarmFtueStage._uiHighlight:destroy()
		InFarmFtueStage._uiHighlight = nil
	end
end

return InFarmFtueStage
