--!strict

--[[
	Calculates a value based on a base value, offsets, and multipliers that can be added.
	Order of operation for multipliers vs offsets applied can be set.
	Can be linked to a property of an instance to keep that property's value up to date with this value.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local Signal = require(ReplicatedStorage.Source.Signal)
local OperationOrder = require(ReplicatedStorage.Source.SharedConstants.OperationOrder)

local ValueManager = {}
ValueManager.__index = ValueManager

export type ClassType = typeof(setmetatable(
	{} :: {
		_originalBaseValue: number,
		_baseValue: number,
		_lastValue: number,
		_operationOrder: OperationOrder.EnumType,
		_instance: Instance?,
		_property: string?,
		_multipliers: { [string]: number },
		_offsets: { [string]: number },
		changed: Signal.ClassType,
	},
	ValueManager
))

function ValueManager.new(baseValue: number, optionalOperationOrder: OperationOrder.EnumType?): ClassType
	if optionalOperationOrder then
		local operationOrder = optionalOperationOrder :: OperationOrder.EnumType
		assert(OperationOrder[operationOrder], string.format("Invalid operation order: %s", operationOrder))
	end

	local self = {
		_originalBaseValue = baseValue,
		_baseValue = baseValue,
		_lastValue = baseValue,
		_operationOrder = optionalOperationOrder or OperationOrder.OffsetThenMultiply,
		_instance = nil,
		_property = nil,
		_multipliers = {},
		_offsets = {},
		changed = Signal.new(),
	}

	setmetatable(self, ValueManager)

	return self
end

function ValueManager.getValue(self: ClassType)
	local multiplierValues = Freeze.Dictionary.values(self._multipliers)
	local offsetValues = Freeze.Dictionary.values(self._offsets)

	local totalMultiplier = Freeze.List.reduce(multiplierValues, function(a: number, b: number)
		return a * b
	end, 1)

	local totalOffset = Freeze.List.reduce(offsetValues, function(a: number, b: number)
		return a + b
	end, 0)

	local value: number

	if self._operationOrder == OperationOrder.OffsetThenMultiply then
		value = (self._baseValue + totalOffset) * totalMultiplier
	elseif self._operationOrder == OperationOrder.MultiplyThenOffset then
		value = (self._baseValue * totalMultiplier) + totalOffset
	end

	return value
end

function ValueManager.reset(self: ClassType)
	self._multipliers = {}
	self._offsets = {}
	self._baseValue = self._originalBaseValue
end

function ValueManager.setAttachedInstance(self: ClassType, instance: Instance, property: string)
	self._instance = instance
	self._property = property

	self:_onChanged()
end

function ValueManager.detachFromInstance(self: ClassType)
	self._instance = nil
	self._property = nil
end

function ValueManager.setMultiplier(self: ClassType, stringKey: string, multiplier: number)
	self._multipliers[stringKey] = multiplier
	self:_onChanged()
end

function ValueManager.removeMultiplier(self: ClassType, stringKey: string)
	self._multipliers[stringKey] = nil
	self:_onChanged()
end

function ValueManager.setOffset(self: ClassType, stringKey: string, offset: number)
	self._offsets[stringKey] = offset
	self:_onChanged()
end

function ValueManager.removeOffset(self: ClassType, stringKey: string)
	self._offsets[stringKey] = nil
	self:_onChanged()
end

function ValueManager.setBaseValue(self: ClassType, baseValue: number)
	self._baseValue = baseValue
	self:_onChanged()
end

function ValueManager.setOperationOrder(self: ClassType, operationOrder: OperationOrder.EnumType)
	assert(OperationOrder[operationOrder], string.format("Invalid operation order: %s", operationOrder))
	self._operationOrder = operationOrder
	self:_onChanged()
end

function ValueManager._onChanged(self: ClassType)
	local newValue = self:getValue()

	local instance = self._instance
	if instance then
		(instance :: any)[self._property] = newValue
	end

	if newValue ~= self._lastValue then
		self._lastValue = newValue
		self.changed:Fire(newValue)
	end
end

function ValueManager.destroy(self: ClassType)
	self.changed:DisconnectAll()
	self:detachFromInstance()
end

return ValueManager
