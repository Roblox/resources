--!strict

--[[
	Creates an attachment that trails on the ground at some max distance
	behind a player's character.

	This attachment can be used to position something that follows a character.
	The attachment stops updating when the character dies, at which point this
	class should be	destroyed by its creator.
--]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerObjectsContainer = require(ServerStorage.Source.PlayerObjectsContainer)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
local Connections = require(ReplicatedStorage.Source.Connections)

export type FollowingAttachmentProperties = {
	maxFollowDistance: number, -- Max distance the attachment will follow the character at
	verticalRayOffset: number, -- Distance above HumanoidRootPart to begin raycasting downward in studs
	downVectorDistance: number, -- Distance to cast downward in studs
	raycastParams: RaycastParams, -- RaycastParams to use during the downward raycasts
}

local FollowingAttachment = {}
FollowingAttachment.__index = FollowingAttachment

export type ClassType = typeof(setmetatable(
	{} :: {
		_character: Model,
		_characterLoadedWrapper: CharacterLoadedWrapper.ClassType,
		_positionAttachment: Attachment,
		_connections: Connections.ClassType,
		_heartbeatConnection: RBXScriptConnection?,
	},
	FollowingAttachment
))

function FollowingAttachment.new(character: Model, properties: FollowingAttachmentProperties): ClassType
	local player = Players:GetPlayerFromCharacter(character)
	assert(player, string.format("Invalid character passed to FollowingAttachment: %s", character:GetFullName()))

	local self = {
		_character = character,
		_characterLoadedWrapper = PlayerObjectsContainer.getCharacterLoadedWrapper(player),
		_positionAttachment = Instance.new("Attachment"),
		_connections = Connections.new(),
	}

	setmetatable(self, FollowingAttachment)
	self:_setup(properties)

	return self
end

function FollowingAttachment._setup(self: ClassType, properties: FollowingAttachmentProperties)
	assert(self._characterLoadedWrapper:isLoaded(), "FollowingAttachment created before character was loaded")
	self:_createAttachment(properties.maxFollowDistance)
	self:_startUpdatingAttachment(self._character, properties)
	self:_listenForDeath()
end

function FollowingAttachment._createAttachment(self: ClassType, maxFollowDistance: number)
	local character = self._character :: Model
	local primaryPart = character.PrimaryPart :: BasePart
	local characterCFrame: CFrame = primaryPart.CFrame

	local beginningOffsetCFrame = CFrame.new(0, 0, maxFollowDistance)
	local beginningPosition = (characterCFrame * beginningOffsetCFrame).Position

	local positionAttachment = self._positionAttachment
	positionAttachment.Name = "FollowingAttachment_" .. self._character.Name
	positionAttachment.WorldPosition = beginningPosition
	positionAttachment.Parent = Workspace.Terrain
end

function FollowingAttachment.getAttachment(self: ClassType)
	return self._positionAttachment
end

function FollowingAttachment._listenForDeath(self: ClassType)
	local connection = self._characterLoadedWrapper.died:Connect(function()
		self:_stopUpdatingAttachment()
	end)
	self._connections:add(connection)
end

function FollowingAttachment._stopUpdatingAttachment(self: ClassType)
	local heartbeatConnection = self._heartbeatConnection
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		self._connections:remove(heartbeatConnection)
	end
end

function FollowingAttachment._startUpdatingAttachment(
	self: ClassType,
	character: Model,
	properties: FollowingAttachmentProperties
)
	local verticalRayOffsetVector = Vector3.yAxis * properties.verticalRayOffset
	local downVector = Vector3.yAxis * -properties.downVectorDistance
	local attachment = self._positionAttachment

	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		-- A new character may have been loaded since last heartbeat, so calling :isLoaded() isn't enough.
		-- We have to pass it our current reference to ensure it's still the currently loaded character.
		-- This should get disconnected by the CharacterLoadedWrapper.died connection, but this could
		-- still run for a frame or two after it dies due to deferred events. Doesn't hurt to call
		-- _stopUpdatingAttachment() more than once.
		if not self._characterLoadedWrapper:isLoaded(character) then
			self:_stopUpdatingAttachment()
			return
		end

		local primaryPart = character.PrimaryPart :: BasePart
		local primaryPartPosition = primaryPart.Position

		local footRayResult =
			Workspace:Raycast(primaryPartPosition + verticalRayOffsetVector, downVector, properties.raycastParams)

		local characterPosition = if footRayResult then footRayResult.Position else primaryPartPosition

		local vectorToCharacter: Vector3 = characterPosition - attachment.WorldPosition
		local distanceToCharacter = vectorToCharacter.Magnitude
		local distanceBeyondMaximum = distanceToCharacter - properties.maxFollowDistance

		if distanceBeyondMaximum > 0 then
			local newPosition = attachment.WorldPosition + vectorToCharacter.Unit * distanceBeyondMaximum
			local normal: Vector3

			local raycastResult =
				Workspace:Raycast(newPosition + verticalRayOffsetVector, downVector, properties.raycastParams)

			if raycastResult then
				newPosition = raycastResult.Position
				normal = raycastResult.Normal
			end

			attachment.WorldCFrame = CFrame.lookAt(newPosition, characterPosition, normal or Vector3.yAxis)
		end
	end)

	self._heartbeatConnection = heartbeatConnection
	self._connections:add(heartbeatConnection)
end

function FollowingAttachment.destroy(self: ClassType)
	self._connections:disconnect()
	self._positionAttachment:Destroy()
end

return FollowingAttachment
