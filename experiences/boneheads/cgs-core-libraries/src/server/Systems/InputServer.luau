-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local managedContent = ReplicatedStorage:FindFirstChild("ManagedContent")
assert(managedContent, "Missing ReplicatedStorage.ManagedContent folder")
local playerInput = managedContent:FindFirstChild("PlayerInput")
assert(playerInput, "Missing PlayerInput managed content")

local InputServer = {}

local function onPlayerAdded(player: Player)
	for _, inputContextTemplate in playerInput:GetChildren() do
		assert(inputContextTemplate:IsA("InputContext"), "Invalid PlayerInput context found")
		local inputContext = inputContextTemplate:Clone()
		inputContext.Parent = player
	end
end

function InputServer.start()
	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return InputServer
