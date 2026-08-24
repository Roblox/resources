--!strict

--[[
	Attaches a class's constructor and destructor to the lifetime of an object
	tagged with the specified CollectionService tag.

	This allows you to create classes that define behaviors for an object built out of
	different components by simply tagging an instance with different CollectionService tags.
--]]

-- TODO: Generalize into ClassEventWrapper (which takes raw signals), and ClassTagWrapper for CollectionService tags

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Signal = require(ReplicatedStorage.Source.Signal)
local Connections = require(ReplicatedStorage.Source.Connections)
local TagEnumType = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.TagEnumType)

local ComponentCreator = {}
ComponentCreator.__index = ComponentCreator

type Callback = (instance: Instance) -> nil

type WrapperClass = any -- TODO: Is there a way to specify a generic WrapperClass with .new and :destroy functions?

export type ClassType = typeof(setmetatable(
	{} :: {
		tag: TagEnumType.EnumType,
		wrapperClass: WrapperClass,
		_connections: Connections.ClassType,
		_wrappersByInstance: { [Instance]: WrapperClass },
		_wrapperParameters: { n: number, [number]: any },
		objectAdded: Signal.ClassType,
	},
	ComponentCreator
))

function ComponentCreator.new(
	collectionServiceTag: TagEnumType.EnumType,
	wrapperClass: WrapperClass,
	...: any?
): ClassType
	local self = {
		tag = collectionServiceTag,
		wrapperClass = wrapperClass,
		_connections = Connections.new(),
		_wrappersByInstance = {},
		_wrapperParameters = table.pack(...),
		objectAdded = Signal.new(),
	}

	setmetatable(self, ComponentCreator)

	return self
end

function ComponentCreator.listen(self: ClassType)
	-- Wrap existing instances
	local instances = CollectionService:GetTagged(self.tag)

	for _, instance in ipairs(instances) do
		self:_wrapInstance(instance)
	end

	-- Wrap newly added instances
	local addedConnection = CollectionService:GetInstanceAddedSignal(self.tag):Connect(function(instance: Instance)
		self:_wrapInstance(instance)
		self.objectAdded:Fire(self._wrappersByInstance[instance])
	end)

	-- Unwrap removing instances
	local removedConnection = CollectionService:GetInstanceRemovedSignal(self.tag):Connect(function(instance: Instance)
		self:_unwrapInstance(instance)
	end)

	self._connections:add(addedConnection, removedConnection)
end

function ComponentCreator.getComponentFromInstance(self: ClassType, instance: Instance)
	-- Returns the instance of the wrapper class associated with the Roblox instance argument
	return self._wrappersByInstance[instance]
end

function ComponentCreator._wrapInstance(self: ClassType, instance: Instance)
	self._wrappersByInstance[instance] = self.wrapperClass.new(instance, table.unpack(self._wrapperParameters))
end

function ComponentCreator._unwrapInstance(self: ClassType, instance: Instance)
	local wrapperClass = self._wrappersByInstance[instance]
	self._wrappersByInstance[instance] = nil

	if wrapperClass.destroy then
		wrapperClass:destroy()
	end
end

function ComponentCreator.destroy(self: ClassType)
	self._connections:disconnect()

	for _, wrapperClass in pairs(self._wrappersByInstance) do
		wrapperClass:destroy()
	end

	self.objectAdded:DisconnectAll()
end

return ComponentCreator
