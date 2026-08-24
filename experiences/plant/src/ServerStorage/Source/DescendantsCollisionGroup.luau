--!strict

--[[
	Sets all BaseParts in an instance to a given CollisionGroup
	Watches for new BaseParts to be added as a descendant
	Resets the CollisionGroup if the descendant is removed
	Automatically destroys itself if the instance is destroyed
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Attribute = require(ReplicatedStorage.Source.SharedConstants.Attribute)
local CollisionGroup = require(ServerStorage.Source.CollisionGroup)

local DescendantsCollisionGroup = {}
DescendantsCollisionGroup.__index = DescendantsCollisionGroup

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Instance,
		_collisionGroup: CollisionGroup.EnumType,
		_descendantAddedConnection: RBXScriptConnection?,
		_descendantRemovingConnection: RBXScriptConnection?,
	},
	DescendantsCollisionGroup
))

function DescendantsCollisionGroup.new(instance: Instance, collisionGroup: CollisionGroup.EnumType): ClassType
	local self = {
		_instance = instance,
		_collisionGroup = collisionGroup,
		_descendantAddedConnection = nil,
		_descendantRemovingConnection = nil,
	}

	setmetatable(self, DescendantsCollisionGroup)

	self:_setupDescendants()

	return self
end

function DescendantsCollisionGroup._setCollisionGroup(self: ClassType, part: BasePart)
	if not part:IsA("BasePart") then
		return
	end

	assert(
		part:GetAttribute(Attribute.OriginalCollisionGroup) == nil,
		string.format("%s already has another DescendantsCollisionGroup acting on it", part:GetFullName())
	)

	part:SetAttribute(Attribute.OriginalCollisionGroup, part.CollisionGroup)
	part.CollisionGroup = self._collisionGroup
end

function DescendantsCollisionGroup._restoreCollisionGroup(self: ClassType, part: BasePart)
	part.CollisionGroup = part:GetAttribute(Attribute.OriginalCollisionGroup)
	part:SetAttribute(Attribute.OriginalCollisionGroup, nil)
end

function DescendantsCollisionGroup._setupDescendants(self: ClassType)
	for _, part in ipairs(self._instance:GetDescendants()) do
		if part:IsA("BasePart") then
			self:_setCollisionGroup(part)
		end
	end

	self._descendantAddedConnection = self._instance.DescendantAdded:Connect(function(part: Instance)
		if part:IsA("BasePart") then
			self:_setCollisionGroup(part)
		end
	end)

	self._descendantRemovingConnection = self._instance.DescendantRemoving:Connect(function(part: Instance)
		if part:IsA("BasePart") then
			self:_restoreCollisionGroup(part)
		end
	end)
end

function DescendantsCollisionGroup.destroy(self: ClassType)
	local descendantAddedConnection = self._descendantAddedConnection :: RBXScriptConnection
	descendantAddedConnection:Disconnect()
	local descendantRemovingConnection = self._descendantRemovingConnection :: RBXScriptConnection
	descendantRemovingConnection:Disconnect()
end

return DescendantsCollisionGroup
