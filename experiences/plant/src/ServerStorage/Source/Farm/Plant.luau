--!strict

--[[
	Class associated with a plant instance that provides serialization & deserialization.
	This also provides plant growth mechanics and reacts to networked plant events like
	harvesting and watering.
--]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CustomAnalytics = require(ServerStorage.Source.Analytics.CustomAnalytics)
local Signal = require(ReplicatedStorage.Source.Signal)
local Network = require(ReplicatedStorage.Source.Network)
local FarmConstants = require(ReplicatedStorage.Source.Farm.FarmConstants)
local ItemCategory = require(ReplicatedStorage.Source.SharedConstants.ItemCategory)
local Connections = require(ReplicatedStorage.Source.Connections)
local PlantTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.PlantTag)
local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local findFirstChildWithAttribute = require(ReplicatedStorage.Source.Utility.findFirstChildWithAttribute)
local getFarmOwnerIdFromInstance = require(ReplicatedStorage.Source.Utility.Farm.getFarmOwnerIdFromInstance)
local getAttribute = require(ReplicatedStorage.Source.Utility.getAttribute)
local weldDescendantsToPrimaryPart = require(ReplicatedStorage.Source.Utility.weldDescendantsToPrimaryPart)
local distanceFromCharacter = require(ReplicatedStorage.Source.Utility.distanceFromCharacter)
local moveModelByAttachment = require(ReplicatedStorage.Source.Utility.moveModelByAttachment)
local rigidlyAttach = require(ReplicatedStorage.Source.Utility.rigidlyAttach)
local getItemByIdInCategory = require(ReplicatedStorage.Source.Utility.Farm.getItemByIdInCategory)
local playWaterDropletsAsync = require(ServerStorage.Source.Utility.Particles.playWaterDropletsAsync)
local playSparklingStar = require(ServerStorage.Source.Utility.Particles.playSparklingStar)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local RemoteEvents = Network.RemoteEvents

local t = Network.t

export type PlantData = {
	id: string,
	currentStage: number,
	timeGrown: number,
}

local Plant = {}
Plant.__index = Plant

export type ClassType = typeof(setmetatable(
	{} :: {
		_id: string,
		_instance: Model,
		_startingTimeGrown: number,
		_stageModels: { Model },
		_connections: Connections.ClassType,
		changed: Signal.ClassType,
		harvested: Signal.ClassType,
	},
	Plant
))

function Plant.new(plantData: PlantData): ClassType
	local plantPrefab: Model = getItemByIdInCategory(plantData.id, ItemCategory.Plants)

	local self = {
		_id = plantData.id,
		_instance = plantPrefab:Clone(),
		_startingTimeGrown = 0,
		_stageModels = {} :: { Model },
		_connections = Connections.new(),
		changed = Signal.new(),
		harvested = Signal.new(),
	}

	setmetatable(self, Plant)
	self:_loadData(plantData)
	self:_listenForWatering()
	self:_listenForHarvest()

	return self
end

function Plant.getData(self: ClassType)
	local timeGrown: number

	if CollectionService:HasTag(self._instance, PlantTag.Growing) then
		local finishesGrowingAt: number = getAttribute(self._instance, Attribute.FinishesGrowingAt)

		-- Non-zero value indicates the plant is growing when loading the data back
		-- :GetServerTimeNow() allows the client timer to match the server's timer exactly regardless of network latency
		-- Provide a 1 second buffer to ensure that timeGrown is always saved as a nice integer > 0 when growing
		timeGrown = math.max(1, math.floor(finishesGrowingAt - Workspace:GetServerTimeNow()))
	else
		-- 0 indicates the plant is not growing when loading the data back
		timeGrown = 0
	end

	local currentStage: number = getAttribute(self._instance, Attribute.CurrentStage)
	local data: PlantData = {
		id = self._instance.Name,
		currentStage = currentStage,
		timeGrown = timeGrown,
	}

	return data
end

function Plant._isMaxStage(self: ClassType)
	local currentStage: number = getAttribute(self._instance, Attribute.CurrentStage)
	local maxStage: number = getAttribute(self._stageModels[#self._stageModels], Attribute.StageNumber)

	return currentStage >= maxStage
end

function Plant._advanceStage(self: ClassType)
	CollectionService:RemoveTag(self._instance, PlantTag.Growing)

	local currentStage: number = getAttribute(self._instance, Attribute.CurrentStage)
	self._instance:SetAttribute(Attribute.CurrentStage, currentStage + 1)
	self._instance:SetAttribute(Attribute.FinishesGrowingAt, 0)

	if self:_isMaxStage() then
		CollectionService:AddTag(self._instance, PlantTag.CanHarvest)
	else
		CollectionService:AddTag(self._instance, PlantTag.NeedsWater)
	end
end

-- wateredByPlayer is nil if this function is called during data loading,
-- but it is not nil if the watering is initiated by the player
function Plant._onWatered(self: ClassType, wateredByPlayer: Player?)
	if not CollectionService:HasTag(self._instance, PlantTag.NeedsWater) then
		warn("Attempt to water a plant that can't be watered")
		return
	end

	if self:_isMaxStage() then
		warn("Attempt to water a plant that is already max stage")
		return
	end

	local currentStage: number = getAttribute(self._instance, Attribute.CurrentStage)

	local stagesModel: Model = getInstance(self._instance, "Stages")
	local stageModel = findFirstChildWithAttribute(stagesModel, Attribute.StageNumber, currentStage) :: Model
	assert(stageModel and stageModel.PrimaryPart, "StageModel does not exist")

	local growTime: number = getAttribute(stageModel, Attribute.GrowTime)
	local timeLeft = growTime - self._startingTimeGrown

	CollectionService:RemoveTag(self._instance, PlantTag.NeedsWater)

	-- Only show the watering animation & log analytics if the plant is watered by the player
	-- i.e. avoid doing these during data loading / initialization
	if wateredByPlayer then
		playWaterDropletsAsync(stageModel.PrimaryPart)
		CustomAnalytics.logPlantWatered(wateredByPlayer, self._id)
	end

	local finishesGrowingAt = Workspace:GetServerTimeNow() + timeLeft

	-- startingTimeGrown is a timer offset so that a timer can be paused when leaving and resume at the same point after loading data
	-- After resuming in-progress timers from initial load, all timers after that will start at the beginning so this offset is reset to 0
	self._startingTimeGrown = 0
	self._instance:SetAttribute(Attribute.FinishesGrowingAt, finishesGrowingAt)
	CollectionService:AddTag(self._instance, PlantTag.Growing)

	task.delay(timeLeft, self._advanceStage, self)
end

function Plant._onHarvested(self: ClassType, harvestedByPlayer: Player)
	if not CollectionService:HasTag(self._instance, PlantTag.CanHarvest) then
		warn("Attempt to harvest a plant that can't be harvested")
		return
	end

	if not self:_isMaxStage() then
		warn("Attempt to harvest a plant that isn't fully grown")
		return
	end

	CollectionService:RemoveTag(self._instance, PlantTag.CanHarvest)

	CustomAnalytics.logPlantHarvested(harvestedByPlayer, self._id)

	-- The pot this is planted in listens, destroys this plant, and creates a HarvestedPlant for the player to hold
	self.harvested:Fire()
end

function Plant._onStageChanged(self: ClassType)
	local currentStage: number = getAttribute(self._instance, Attribute.CurrentStage)

	for _, stageModel in ipairs(self._stageModels) do
		local stageNumber: number = getAttribute(stageModel, Attribute.StageNumber)

		if currentStage == stageNumber then
			if self:_isMaxStage() then
				playSparklingStar(stageModel.PrimaryPart :: BasePart)
			end

			stageModel.Parent = getInstance(self._instance, "Stages")
		else
			stageModel.Parent = nil
		end
	end
end

function Plant._loadData(self: ClassType, plantData: PlantData)
	self._startingTimeGrown = plantData.timeGrown
	getInstance(self._instance, "Harvested"):Destroy()
	self._stageModels = self:_getSortedStageModels()

	-- Set up welds and constraints
	for _, stageModel in ipairs(self._stageModels) do
		weldDescendantsToPrimaryPart(stageModel)

		local instancePrimaryPart = self._instance.PrimaryPart :: BasePart
		local stageModelPrimaryPart = stageModel.PrimaryPart :: BasePart
		rigidlyAttach(
			getInstance(instancePrimaryPart, "PlantAttachment"),
			getInstance(stageModelPrimaryPart, "PlantAttachment")
		)
	end

	-- Load stage model from data
	self._instance:SetAttribute(Attribute.CurrentStage, plantData.currentStage)
	self:_onStageChanged()
	self:_listenForStageChanged()

	-- Update CollectionService state tag
	if self:_isMaxStage() then
		CollectionService:AddTag(self._instance, PlantTag.CanHarvest)
	else
		CollectionService:AddTag(self._instance, PlantTag.NeedsWater)

		if plantData.timeGrown > 0 then
			self:_onWatered(nil)
		end
	end
end

function Plant._getSortedStageModels(self: ClassType)
	local stagesFolder: Folder = getInstance(self._instance, "Stages")
	local stageModels = stagesFolder:GetChildren()

	-- Sort by lowest stage first
	table.sort(stageModels, function(a: Instance, b: Instance)
		local stageANumber: number = getAttribute(a, Attribute.StageNumber)
		local stageBNumber: number = getAttribute(b, Attribute.StageNumber)

		return stageANumber < stageBNumber
	end)

	-- Casting to any because the type checker refuses to case { Instance } to { Model }
	return (stageModels :: any) :: { Model }
end

function Plant._canPlayerInteract(self: ClassType, player: Player, plantModel: Model)
	if plantModel ~= self._instance then
		return false
	end

	local ownerId = getFarmOwnerIdFromInstance(plantModel)

	if ownerId ~= player.UserId then
		warn(
			string.format(
				"Attempt by %s (%d) to interact with plant %s owned by someone else: %s",
				player.Name,
				player.UserId,
				plantModel:GetFullName(),
				tostring(ownerId)
			)
		)
		return false
	end

	local instancePrimaryPart = self._instance.PrimaryPart :: BasePart
	local distanceFromPlantMaybe = distanceFromCharacter(player, instancePrimaryPart.Position)

	-- distanceFromCharacter returns nil if no character or primary part exists
	if distanceFromPlantMaybe == nil then
		warn(
			string.format(
				"Attempt by %s (%d) to interact with a plant without having a character with a PrimaryPart",
				player.Name,
				player.UserId
			)
		)
		return false
	end
	local distanceFromPlant = distanceFromPlantMaybe :: number

	if distanceFromPlant > FarmConstants.MaxInteractionDistance then
		warn(
			string.format(
				"Attempt by %s (%d) to interact with plant %s that is too far away (%d > %d)",
				player.Name,
				player.UserId,
				plantModel:GetFullName(),
				distanceFromPlant,
				FarmConstants.MaxInteractionDistance
			)
		)
		return false
	end

	return true
end

function Plant._listenForStageChanged(self: ClassType)
	local connection = self._instance:GetAttributeChangedSignal(Attribute.CurrentStage):Connect(function()
		self:_onStageChanged()
		self.changed:Fire()
	end)
	self._connections:add(connection)
end

function Plant._listenForWatering(self: ClassType)
	local connection = Network.connectEvent(RemoteEvents.PlantWatered, function(player: Player, plantModel: Model)
		if not self:_canPlayerInteract(player, plantModel) then
			return
		end

		self:_onWatered(player)
	end, t.tuple(t.instanceOf("Player"), t.instanceOf("Model")))
	self._connections:add(connection)
end

function Plant._listenForHarvest(self: ClassType)
	local connection = Network.connectEvent(RemoteEvents.PlantHarvested, function(player: Player, plantModel: Model)
		if not self:_canPlayerInteract(player, plantModel) then
			return
		end

		self:_onHarvested(player)
	end, t.tuple(t.instanceOf("Player"), t.instanceOf("Model")))
	self._connections:add(connection)
end

function Plant.movePrimaryAttachmentTo(self: ClassType, targetCFrame: CFrame)
	local plantAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "PlantAttachment")
	moveModelByAttachment(self._instance, plantAttachment, targetCFrame)
end

function Plant.attachTo(self: ClassType, targetAttachment: Attachment)
	local plantAttachment: Attachment = getInstance(self._instance.PrimaryPart :: BasePart, "PlantAttachment")
	rigidlyAttach(targetAttachment, plantAttachment)
end

function Plant.getInstance(self: ClassType)
	return self._instance
end

function Plant.getId(self: ClassType)
	return self._id
end

function Plant.destroy(self: ClassType)
	-- Destroying the instance cleans up attribute changed connection too
	self._instance:Destroy()
	self.changed:DisconnectAll()
	self.harvested:DisconnectAll()

	self._connections:disconnect()
end

return Plant
