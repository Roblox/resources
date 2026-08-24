--!strict
local updateIn = require(script.Parent.updateIn)

return function<Key, Value>(collection: { [Key]: Value }, key: Key, updater: (Value?) -> Value, notSetValue: any?)
	return updateIn(collection, { key }, updater, notSetValue)
end
