--[[
	DataStoreWrapper attempts to address common pitfalls in the creation of data saving systems.
	All requests are placed in a queue and completed in order, to prevent data from being overwritten
	if multiple requests are made at the same time.
--]]

local DataStoreWrapper = require(script.Parent.Parent.DataStoreWrapper)

local name = "DemoDataStore"
local retryMaxAttempts = 3
local retryPauseConstant = 2
local retryPauseExponentBase = 2

local key = "DemoKey"

-- Create a new DataStoreWrapper for accessing DataStore
local myDataStoreWrapper = DataStoreWrapper.new(name, retryMaxAttempts, retryPauseConstant, retryPauseExponentBase)

print("Setting key...")
-- DataStoreWrapper returns whether the attempt was successful and the result of the operation or an error message
local setSuccess, setResult = myDataStoreWrapper:setAsync(key, "Some value")
if setSuccess then
	print("Set success!")
else
	print(string.format("Set failed because: %s", setResult))
end

print("Getting key...")
local getSuccess, getResult = myDataStoreWrapper:getAsync(key)
if getSuccess then
	print(string.format("Get success! Value is: %s", getResult))
else
	print(string.format("Get failed because: %s", getResult))
end
