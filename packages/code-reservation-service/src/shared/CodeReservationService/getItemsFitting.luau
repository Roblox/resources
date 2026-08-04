--!strict

local HttpService = game:GetService("HttpService")

-- Returns a table of items that can fit into another table while staying under a maximum JSON encoded length.
-- Since MemoryStore has a maximum value length per key, this is used to make sure the final JSON encoded
-- table length is within the MemoryStore limits.
-- Note: items are expected to have uniform length
local function getItemsFitting<T>(container: { T }, items: { T }, maxLength: number): { T }
	local containerWithItems = table.clone(container)
	table.move(items, 1, #items, #containerWithItems + 1, containerWithItems)
	-- Get the minimum (container without items) and maximum (container with items) JSON encoded lengths
	local min = string.len(HttpService:JSONEncode(container))
	local max = string.len(HttpService:JSONEncode(containerWithItems))
	-- Calculate the length of each item after it has been JSON encoded
	local itemLength = math.ceil((max - min) / #items)

	-- If the container + items is under the maximum length, simply return all items
	if max <= maxLength then
		return items
	end

	-- Calculate the number of items that can fit into the container while staying under maxLength
	local size = min
	local amount = 0
	while size + itemLength <= maxLength do
		size += itemLength
		amount += 1
	end

	-- No items can fit, return an empty table
	if amount == 0 then
		return {}
	end

	-- Move the first <amount> entries from items into an empty table and return it
	return table.move(items, 1, amount, 1, {})
end

return getItemsFitting
