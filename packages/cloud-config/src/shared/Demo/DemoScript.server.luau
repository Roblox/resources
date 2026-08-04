--!strict

--[[
	This module uses DataStores and must have access to Studio APIs to be used.
	A guide on enabling access can be found here:
	https://create.roblox.com/docs/tutorials/scripting/intermediate-scripting/saving-data

	Setup a demo flag by running this code snippet in the command line:
	require(path.to.CloudConfig).setValueAsync("DemoFlag", "Demo value")
--]]

local CloudConfig = require(script.Parent.Parent.CloudConfig)
local DEMO_FLAG = "DemoFlag"

CloudConfig.getValueChangedSignal(DEMO_FLAG):Connect(function(value)
	print("Demo flag changed to:", value)
end)

while true do
	local demoFlagValue = CloudConfig.getValue(DEMO_FLAG)
	print("Demo flag has a value of:", demoFlagValue)
	task.wait(5)
end
