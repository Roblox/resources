--!strict
local Freeze = script.Parent.Parent
local None = require(Freeze.None)

local isDataStructure = require(script.Parent.Parent.utils.isDataStructure)

local slice = require(script.Parent.slice)
local get = require(script.Parent.get)
local remove = require(script.Parent:FindFirstChild("remove"))
local set = require(script.Parent.set)

local function toString(path)
	return table.concat(path, ", ")
end

local function updateInDeeply<Key, Value>(
	existing: any,
	keyPath: { any },
	i: number,
	updater: (Value, Key?) -> Value,
	notSetValue: Value?
)
	local wasNotSet = existing == None
	if i == #keyPath + 1 then
		local existingValue = if wasNotSet then notSetValue else existing
		local newValue = updater(existingValue)
		return if newValue == existingValue then existing else newValue
	end

	if not wasNotSet and not isDataStructure(existing) then
		error(
			"Cannot update within non-data-structure value in path ["
				.. toString(slice(keyPath, 1, i - 1))
				.. "]: "
				.. tostring(existing)
		)
	end

	local key = keyPath[i]
	local nextExisting = if wasNotSet then None else get(existing, key, None)
	local nextUpdated = updateInDeeply(nextExisting, keyPath, i + 1, updater, notSetValue)

	return if nextUpdated == nextExisting
		then existing
		elseif nextUpdated == None then remove(existing, key)
		else set(if wasNotSet then {} else existing, key, nextUpdated)
end

return function<Key, Value>(
	collection: { [Key]: Value },
	keyPath: { Key },
	updater: (Value) -> Value,
	notSetValue: Value?
): { [Key]: Value }
	local updatedValue = updateInDeeply(collection, keyPath, 1, updater, notSetValue)

	return if updatedValue == None then notSetValue else updatedValue
end
