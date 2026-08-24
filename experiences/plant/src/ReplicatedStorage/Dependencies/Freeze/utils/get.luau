--!strict
--local isImmutable = require(script.Parent.isImmutable)
--local has = require(script.Parent.has)

return function<Key, Value>(collection: { [Key]: Value }, key: Key, notSetValue: Value?)
	return if collection[key] == nil then notSetValue else collection[key]
	--[[
	return if isImmutable(collection)
		then collection:get(key, notSetValue)
		elseif not has(collection, key) then notSetValue
		elseif typeof(collection.get) == "function" then collection:get(key, notSetValue)
		else collection[key]
        ]]
end
