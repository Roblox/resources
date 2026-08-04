--[[
	ThreadQueue can be used to queue functions so that they don't all run at once.
	In this example, 10 functions are added to a queue at the same time, and then executed in order with a 1s delay between them
--]]

local ThreadQueue = require(script.Parent.Parent.ThreadQueue)

local timeBetween = 1
local maxQueueLength = nil -- No max length is set, the queue can be infinitely long
local enableConcurrency = false

local myQueue = ThreadQueue.new(timeBetween, maxQueueLength, enableConcurrency)

-- Submit all functions to the queue at once
for i = 1, 10 do
	task.spawn(function()
		print("Submitting function #", i)
		myQueue:submitAsync(function()
			print("This is function #", i)
		end)
	end)
end

--> This is function # 1
-- (1s delay)
--> This is function # 2
-- (1s delay)
-- ...
--> This is function # 10
