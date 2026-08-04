--!strict

type GenericTable = { [any]: any }

local TableUtils = {}

TableUtils.NoValue = newproxy(true)

function TableUtils.deepCopy<T>(source: T): T
	local output = {}

	if typeof(source) == "table" then
		for key, value in pairs(source) do
			if typeof(value) == "table" then
				output[key] = TableUtils.deepCopy(value)
			else
				output[key] = value
			end
		end
	end

	return (output :: any) :: T
end

function TableUtils.filter<K, V>(source: { [K]: V }, filter: (value: V, key: K, dictionary: { [K]: V }) -> any)
	local output: { [K]: V } = {}

	for key, value in pairs(source) do
		if filter(value, key, source) then
			output[key] = value
		end
	end

	return output
end

function TableUtils.merge<T>(...: any): T
	local output = {}

	for index, input in { ... } do
		if type(input) ~= "table" then
			continue
		end

		for key, value in pairs(input) do
			if value == TableUtils.NoValue then
				output[key] = nil
			else
				output[key] = value
			end
		end
	end

	return (output :: any) :: T
end

function TableUtils.invertValuesToKeys<T>(source: { T }): { [T]: boolean }
	local output = {}

	for _, value in source do
		output[value] = true
	end

	return output
end

return TableUtils
