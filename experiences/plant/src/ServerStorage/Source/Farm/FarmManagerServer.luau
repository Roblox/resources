--!strict

--[[
	Handles creating farms for new players and cleaning them up when the player leaves
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local PlayerDataServer = require(ServerStorage.Source.PlayerData.Server)
local FarmConstants = require(ReplicatedStorage.Source.Farm.FarmConstants)
local Farm = require(ServerStorage.Source.Farm.Farm)
local CharacterTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.CharacterTag)
local ZoneHandler = require(ServerStorage.Source.ZoneHandler)
local ComponentCreator = require(ReplicatedStorage.Source.ComponentCreator)
local PlayerDataKey = require(ReplicatedStorage.Source.SharedConstants.PlayerDataKey)
local Connections = require(ReplicatedStorage.Source.Connections)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local farmAttachmentsContainer: MeshPart = getInstance(Workspace, "World", "Environment", "Terrain", "Terrain01")

local FarmManagerServer = {}
FarmManagerServer._farmByUserId = {} :: { [number]: Farm.ClassType }
FarmManagerServer._farmByIndex = {} :: { [number]: Farm.ClassType }
FarmManagerServer._connectionsByPlayer = {} :: { [Player]: Connections.ClassType }

function FarmManagerServer.start()
	ComponentCreator.new(CharacterTag.Character, ZoneHandler):listen()
end

function FarmManagerServer._getEmptyPosition()
	for farmIndex = 1, Players.MaxPlayers do
		local indexIsAvailable = (FarmManagerServer._farmByIndex[farmIndex] :: Farm.ClassType?) == nil
		if indexIsAvailable then
			return farmIndex
		end
	end

	error("Unable to find an empty farm position. Is the index not getting cleared properly?")
end

function FarmManagerServer._getFarmAttachmentAt(index: number)
	local attachmentName = "FarmAttachment" .. index
	local attachment = farmAttachmentsContainer:FindFirstChild(attachmentName)
	assert(attachment, string.format("No attachment `%s` found. Is MaxPlayerCount > #attachments?", attachmentName))

	return attachment :: Attachment
end

function FarmManagerServer.addFarmForPlayer(player: Player)
	local farmData = PlayerDataServer.getValue(player, PlayerDataKey.Farm)
	local connections = Connections.new()
	FarmManagerServer._connectionsByPlayer[player] = connections

	-- Set up farm
	local index = FarmManagerServer._getEmptyPosition()
	local farm = Farm.new(player)
	local attachment = FarmManagerServer._getFarmAttachmentAt(index)
	local farmCFrame = attachment.WorldCFrame

	FarmManagerServer._farmByUserId[player.UserId] = farm
	FarmManagerServer._farmByIndex[index] = farm

	local farmChangedConnection = farm.changed:Connect(function()
		PlayerDataServer.setValue(player, PlayerDataKey.Farm, farm:getData())
	end)
	connections:add(farmChangedConnection)

	farm:movePrimaryAttachmentTo(farmCFrame)
	farm:getInstance().Parent = FarmConstants.FarmContainer
	farm:openDoor()
	farm:loadData(farmData)

	local characterLoadedWrapper = PlayerObjectsContainer.getCharacterLoadedWrapper(player)
	local characterLoadedConnection = characterLoadedWrapper.loaded:Connect(function(character: any)
		FarmManagerServer._onCharacterAdded(character :: Model)
	end)
	connections:add(characterLoadedConnection)
end

function FarmManagerServer.getFarmForPlayer(player: Player)
	return FarmManagerServer._farmByUserId[player.UserId]
end

function FarmManagerServer._onCharacterAdded(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	local farm = FarmManagerServer._farmByUserId[player.UserId]
	local insidePlayerSpawn: BasePart = getInstance(farm:getInstance(), "InsidePlayerSpawn")

	-- Without deferring, this PivotTo gets overridden and the character spawns at the map's center
	-- Can stop deferring once this is live: https://devforum.roblox.com/t/avatar-loading-event-ordering-improvements/269607
	task.defer(function()
		character:PivotTo(insidePlayerSpawn.CFrame)
	end)
end

function FarmManagerServer.removeFarmForPlayer(player: Player)
	local farm = FarmManagerServer._farmByUserId[player.UserId]

	if not farm then
		-- Player left before their data loaded, so no farm was created
		return
	end

	FarmManagerServer._connectionsByPlayer[player]:disconnect()

	if PlayerDataServer.hasLoaded(player) then
		PlayerDataServer.setValue(player, PlayerDataKey.Farm, farm:getData())
	end

	local index: number = Freeze.Dictionary.flip(FarmManagerServer._farmByIndex)[farm]
	FarmManagerServer._farmByUserId[player.UserId] = nil
	FarmManagerServer._farmByIndex[index] = nil
	farm:destroy()
end

return FarmManagerServer
