--!strict

--[[
	Signal works as a replacement for BindableEvents to create custom events and replicates the behavior of RBXScriptSignal.
	Unlike BindableEvents, objects are passed by reference in Signals rather than being serialized
--]]

local Signal = require(script.Parent.Parent.Signal)

local demoSignal = Signal.new()

local connection = demoSignal:Connect(function(...)
	print("Connect", ...)
end)

demoSignal:Once(function(...)
	print("Once", ...)
end)

for i = 1, 3 do
	demoSignal:Fire(i)
end

--> Connect 1
--> Once 1  << Note that demoSignal:Once() disconnects after the first time it is fired
--> Connect 2
--> Connect 3

connection:Disconnect()

-- Schedule demoSignal to be fired 3 seconds in the future
task.delay(3, function()
	demoSignal:Fire("Some value")
end)

-- :Wait() for demoSignal to be fired, blocking the current thread
local now = os.clock()
local value = demoSignal:Wait()
print("Wait", os.clock() - now, value)

--> Wait 3.014... Some value
