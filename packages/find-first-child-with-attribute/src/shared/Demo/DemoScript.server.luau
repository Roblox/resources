--[[
	Searches children of an instance, returning the first child containing an attribute matching the given name and value.
	The DemoScript removes flavors from an ice cream cone in the correct order using findFirstChildWithAttribute
--]]

local findFirstChildWithAttribute = require(script.Parent.Parent.findFirstChildWithAttribute)

local iceCreamCone = script.Parent.IceCreamCone
local ATTRIBUTE_NAME = "Order"

-- Wait some time before removing flavors
task.wait(5)

for attributeValue = 1, 3 do
	-- Get the flavor based on the "Order" attribute and value
	local flavor = findFirstChildWithAttribute(iceCreamCone, ATTRIBUTE_NAME, attributeValue)

	-- Transition the flavor's transparency to 1 over time
	task.wait(0.5)
	flavor.Transparency = 0.5
	task.wait(0.5)
	flavor.Transparency = 1
end
