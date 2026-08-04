--!strict

--[[
	Given two attachments and a beam prefab, this class continuously orients duplicates of the attachments
	to face each other so that the beam remains straight.

	Also provides an API to enable/disable the beam and its orientation updates.
--]]

local RunService = game:GetService("RunService")

local BeamBetween = {}
BeamBetween.__index = BeamBetween

function BeamBetween.new(attachment0: Attachment, attachment1: Attachment, beamPrefab: Beam): any
	local self = {
		-- Duplicate the given attachments to avoid modifying the originals
		_attachment0 = attachment0:Clone(),
		_attachment1 = attachment1:Clone(),
		_beam = beamPrefab:Clone(),
		_isEnabled = false,
		_heartbeatConnection = nil,
	}
	setmetatable(self, BeamBetween)

	self:_setup(attachment0, attachment1)

	return self
end

function BeamBetween:_setup(originalAttachment0: Attachment, originalAttachment1: Attachment)
	-- Set up the new attachments
	self._attachment0.Name = "BeamBetween_" .. originalAttachment0.Name
	self._attachment0.Parent = originalAttachment0.Parent

	self._attachment1.Name = "BeamBetween_" .. originalAttachment1.Name
	self._attachment1.Parent = originalAttachment1.Parent

	-- Set up the new beam
	self._beam.Attachment0 = self._attachment0
	self._beam.Attachment1 = self._attachment1
	self._beam.Parent = self._attachment0
end

function BeamBetween:_enable()
	self._beam.Enabled = true
	self._isEnabled = true

	self._heartbeatConnection = RunService.Heartbeat:Connect(function()
		self:_update()
	end)
end

function BeamBetween:_disable()
	self._beam.Enabled = false
	self._isEnabled = false

	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
	end
end

function BeamBetween:setEnabled(isEnabled: boolean)
	if isEnabled == self._isEnabled then
		return
	end

	if isEnabled then
		self:_enable()
	else
		self:_disable()
	end
end

function BeamBetween:_update()
	self._attachment0.WorldCFrame = CFrame.new(self._attachment0.WorldPosition, self._attachment1.WorldPosition)
		* CFrame.Angles(0, 0, math.pi / 2)
	self._attachment1.WorldCFrame = CFrame.new(self._attachment1.WorldPosition, self._attachment0.WorldPosition)
		* CFrame.Angles(0, 0, -math.pi / 2)
end

function BeamBetween:destroy()
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
	end

	self._beam:Destroy()
	self._attachment0:Destroy()
	self._attachment1:Destroy()
end

return BeamBetween
