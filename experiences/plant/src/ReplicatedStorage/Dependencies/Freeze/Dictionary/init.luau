--!strict

--[=[
	@class Dictionary
	Handles dictionary-like operations.

	[`Dictionaries`](../api/Dictionary) are unordered tables with key-value pairs.
]=]

return {
	count = require(script.count),
	equals = require(script.equals),
	every = require(script.every),
	filter = require(script.filter),
	filterNot = require(script.filterNot),
	find = require(script.find),
	findKey = require(script.findKey),
	findPair = require(script.findPair),
	flatten = require(script.flatten),
	flip = require(script.flip),
	forEach = require(script.forEach),
	get = require(script.get),
	getIn = require(script.getIn),
	has = require(script.has),
	hasIn = require(script.hasIn),
	includes = require(script.includes),
	join = require(script.compat.join),
	joinAsString = require(script.joinAsString),
	keys = require(script.keys),
	map = require(script.map),
	max = require(script.max),
	merge = require(script.merge),
	mergeIn = require(script.mergeIn),
	min = require(script.min),
	remove = require(script:FindFirstChild("remove")),
	removeIn = require(script.removeIn),
	removeKey = require(script.compat.removeKey),
	removeKeys = require(script.compat.removeKeys),
	removeValue = require(script.removeValue),
	removeValues = require(script.compat.removeValues),
	set = require(script.set),
	setIn = require(script.setIn),
	some = require(script.some),
	toArray = require(script.compat.toArray),
	update = require(script.update),
	updateIn = require(script.updateIn),
	values = require(script.values),
}
