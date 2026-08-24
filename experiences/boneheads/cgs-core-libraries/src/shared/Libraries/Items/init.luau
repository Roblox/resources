-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

if RunService:IsServer() then
	local ItemsServer = require(ServerScriptService.Core.Libraries.ItemsServer)
	return ItemsServer
else
	local ItemsClient = require(script.ItemsClient)
	return ItemsClient
end
