--[[
	Creates an attachment that trails on the ground at some max distance
	behind a player's character.

	This attachment can be used to position something that follows a character.
	The attachment stops updating when the character dies, at which point this
	class should be	destroyed by its creator.
--]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

export type FollowingAttachmentProperties = {
	maxFollowDistance: number, -- Max distance the attachment will follow the character at
	verticalRayOffset: number, -- Distance above HumanoidRootPart to begin raycasting downward in studs
	downVectorDistance: number, -- Distance to cast downward in studs
	raycastParams: RaycastParams, -- RaycastParams to use during the downward raycasts
}

local FollowingAttachment = {}
FollowingAttachment.__index = FollowingAttachment

local function isCharacterLoaded(player: Player): boolean
	return player and player.Character and player.Character:IsDescendantOf(Workspace)
end

function FollowingAttachment.new(player: Player, properties: FollowingAttachmentProperties)
	local self = {
		_player = player,
		_positionAttachment = Instance.new("Attachment"),
	}

	setmetatable(self, FollowingAttachment)
	self:_setup(properties)

	return self
end

function FollowingAttachment:_setup(properties: FollowingAttachmentProperties)
	self:_createAttachment(properties.maxFollowDistance)
	self:_startUpdatingAttachment(self._player.Character, properties)
end

function FollowingAttachment:_createAttachment(maxFollowDistance: number)
	local character = self._player.Character
	local primaryPart = character.PrimaryPart
	local characterCFrame = primaryPart.CFrame

	local beginningOffsetCFrame = CFrame.new(0, 0, maxFollowDistance)
	local beginningPosition = (characterCFrame * beginningOffsetCFrame).Position

	local positionAttachment = self._positionAttachment
	positionAttachment.Name = "FollowingAttachment_" .. character.Name
	positionAttachment.WorldPosition = beginningPosition
	positionAttachment.Parent = Workspace.Terrain
end

function FollowingAttachment:getAttachment(): Attachment
	return self._positionAttachment
end

function FollowingAttachment:stopUpdatingAttachment()
	local heartbeatConnection = self._heartbeatConnection
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
	end
end

function FollowingAttachment:_startUpdatingAttachment(character: Model, properties: FollowingAttachmentProperties)
	local verticalRayOffsetVector = Vector3.yAxis * properties.verticalRayOffset
	local downVector = Vector3.yAxis * -properties.downVectorDistance
	local attachment = self._positionAttachment

	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		-- Check if a character is not longer loaded. This could still run for a frame or two after
		-- it dies due to deferred events. Doesn't hurt to call stopUpdatingAttachment() more than once.
		if not isCharacterLoaded(self._player) then
			self:stopUpdatingAttachment()
			return
		end

		local primaryPart = character.PrimaryPart
		if primaryPart then
			local primaryPartPosition = primaryPart.Position

			local footRayResult =
				Workspace:Raycast(primaryPartPosition + verticalRayOffsetVector, downVector, properties.raycastParams)

			local characterPosition = if footRayResult then footRayResult.Position else primaryPartPosition

			local vectorToCharacter: Vector3 = characterPosition - attachment.WorldPosition
			local distanceToCharacter = vectorToCharacter.Magnitude
			local distanceBeyondMaximum = distanceToCharacter - properties.maxFollowDistance

			if distanceBeyondMaximum > 0 then
				local newPosition = attachment.WorldPosition + vectorToCharacter.Unit * distanceBeyondMaximum
				local normal

				local raycastResult =
					Workspace:Raycast(newPosition + verticalRayOffsetVector, downVector, properties.raycastParams)

				if raycastResult then
					newPosition = raycastResult.Position
					normal = raycastResult.Normal
				end

				attachment.WorldCFrame = CFrame.lookAt(newPosition, characterPosition, normal or Vector3.yAxis)
			end
		end
	end)

	self._heartbeatConnection = heartbeatConnection
end

function FollowingAttachment:destroy()
	self:stopUpdatingAttachment()

	self._positionAttachment:Destroy()
end

return FollowingAttachment
