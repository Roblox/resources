--!strict

--[[
	Creates a guiding beam from the bottom of the local character to a destination attachment
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BeamBetween = require(ReplicatedStorage.Source.BeamBetween)
local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
local Connections = require(ReplicatedStorage.Source.Connections)
local getHumanoidRootPartOffset = require(ReplicatedStorage.Source.Utility.getHumanoidRootPartOffset)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local characterBeamPrefab: Beam = getInstance(ReplicatedStorage, "Instances", "CharacterBeamPrefab")
local localPlayer = Players.LocalPlayer :: Player

local CharacterPath = {}
CharacterPath.__index = CharacterPath

export type ClassType = typeof(setmetatable(
	{} :: {
		_characterLoadedWrapper: CharacterLoadedWrapper.ClassType,
		_beamBetween: BeamBetween.ClassType?,
		_connections: Connections.ClassType,
	},
	CharacterPath
))

function CharacterPath.new(targetAttachment: Attachment): ClassType
	local self = {
		_characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer),
		_beamBetween = nil,
		_connections = Connections.new(),
	}
	setmetatable(self, CharacterPath)

	self:_setup(targetAttachment)

	return self
end

function CharacterPath._setup(self: ClassType, targetAttachment: Attachment)
	if self._characterLoadedWrapper:isLoaded() then
		self:_makeBeamFromCharacterToAttachment(targetAttachment)
	end
	local characterLoadedConnection = self._characterLoadedWrapper.loaded:Connect(function()
		self:_makeBeamFromCharacterToAttachment(targetAttachment)
	end)

	local characterDiedConnection = self._characterLoadedWrapper.died:Connect(function()
		if self._beamBetween then
			self._beamBetween:destroy()
		end
	end)
	self._connections:add(characterLoadedConnection, characterDiedConnection)
end

function CharacterPath._makeBeamFromCharacterToAttachment(self: ClassType, targetAttachment: Attachment)
	local character = localPlayer.Character :: Model
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	local rootPartOffset = getHumanoidRootPartOffset(humanoid)

	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, -rootPartOffset, 0)
	attachment0.Parent = character.PrimaryPart

	local beamBetween = BeamBetween.new(attachment0, targetAttachment, characterBeamPrefab)
	beamBetween:setEnabled(true)
	self._beamBetween = beamBetween
end

function CharacterPath.destroy(self: ClassType)
	self._connections:disconnect()

	if self._beamBetween then
		self._beamBetween:destroy()
	end

	self._characterLoadedWrapper:destroy()
end

return CharacterPath
