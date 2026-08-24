-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Core.Systems.Teleport.Constants)
local Types = require(ReplicatedStorage.Core.Systems.Teleport.Types)

local Remotes = ReplicatedStorage.Core.Systems.Teleport.Remotes

local started = false
local latestPayload: Types.TeleportStatusPayload? = nil
local callbacks: { (payload: Types.TeleportStatusPayload) -> () } = {}

local TeleportClient = {}

function TeleportClient.getStatus(): Types.TeleportStatus
	if latestPayload then
		return latestPayload.status
	end
	return Constants.STATUS_IDLE
end

function TeleportClient.getLatestPayload(): Types.TeleportStatusPayload?
	return latestPayload
end

function TeleportClient.onStatusChanged(
	callback: (payload: Types.TeleportStatusPayload) -> ()
): { Disconnect: () -> () }
	table.insert(callbacks, callback)

	return {
		Disconnect = function()
			local index = table.find(callbacks, callback)
			if index then
				table.remove(callbacks, index)
			end
		end,
	}
end

function TeleportClient.start()
	assert(not started, "TeleportClient.start() has already been called")
	started = true

	Remotes.TeleportStatusUpdate.OnClientEvent:Connect(function(payload: Types.TeleportStatusPayload)
		latestPayload = payload

		for _, callback in callbacks do
			task.spawn(callback, payload)
		end
	end)
end

return TeleportClient
