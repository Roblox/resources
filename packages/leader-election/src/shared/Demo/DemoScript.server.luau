--!strict

--[[
	Demonstrates using the LeaderElection module to have a single MessagingService message
	broadcast to all servers once per 30 seconds. The server in charge prints out when it publishes a
	message and other servers print out when they receive it.
--]]

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")

local LeaderElection = require(script.Parent.Parent.LeaderElection)

local TOPIC = "LeaderDemoTopic"

local function Update(deltaTime)
	local data = {
		server = game.JobId,
		deltaTime = deltaTime,
	}

	print(string.format("Sending update from self '%s' with deltaTime: %d", data.server, data.deltaTime))

	MessagingService:PublishAsync(TOPIC, HttpService:JSONEncode(data))
end

local success, result = pcall(function()
	MessagingService:SubscribeAsync(TOPIC, function(message)
		local data = HttpService:JSONDecode(message.Data)

		print(string.format("Got message from leader '%s' with deltaTime: %d", data.server, data.deltaTime))
	end)
end)

if not success then
	warn(string.format("Failed to subscribe to messaging topic because: %s", result))
end

LeaderElection.startLoop("Demo", 30, Update)
