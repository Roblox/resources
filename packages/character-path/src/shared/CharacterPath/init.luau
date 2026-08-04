--!strict

--[[
	Creates a guiding beam from the bottom of the local character to a destination attachment
--]]

local Players = game:GetService("Players")

local BeamBetween = require(script.BeamBetween)
local CharacterLoadedWrapper = require(script.CharacterLoadedWrapper)

local characterBeamPrefab: Beam = script.CharacterBeamPrefab
local localPlayer = Players.LocalPlayer :: Player

local function getHumanoidRootPartOffset(humanoid: Humanoid)
	local rootPart = humanoid.RootPart
	assert(rootPart, "Humanoid has no RootPart set")

	return (rootPart.Size.Y * 0.5) + humanoid.HipHeight
end

local CharacterPath = {}
CharacterPath.__index = CharacterPath

function CharacterPath.new(targetAttachment: Attachment)
	local self = {
		_characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer),
		_beamBetween = nil,
		_connections = {},
	}
	setmetatable(self, CharacterPath)

	self:_setup(targetAttachment)

	return self
end

function CharacterPath:_setup(targetAttachment: Attachment)
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
	table.insert(self._connections, characterLoadedConnection)
	table.insert(self._connections, characterDiedConnection)
end

function CharacterPath:_makeBeamFromCharacterToAttachment(targetAttachment: Attachment)
	local character = localPlayer.Character :: Model
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	local rootPartOffset = getHumanoidRootPartOffset(humanoid)

	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, -rootPartOffset, 0)
	attachment0.Parent = character.PrimaryPart

	local beamBetween = BeamBetween.new(attachment0, targetAttachment, characterBeamPrefab) :: any
	beamBetween:setEnabled(true)
	self._beamBetween = beamBetween
end

function CharacterPath:destroy()
	for _, connection in pairs(self._connections) do
		connection:Disconnect()
	end

	if self._beamBetween then
		self._beamBetween:destroy()
	end

	self._characterLoadedWrapper:destroy()
end

return CharacterPath
