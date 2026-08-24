-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local dampFactor = require(ReplicatedStorage.Core.Utility.dampFactor)

local camera = Workspace.CurrentCamera

local TAU = math.pi * 2
local MIN_SPEED = 10
local MAX_SPEED = 50

local xStride = 0
local yStride = 0
local zStride = 0
local shake = 0

local Shake = {}

function Shake.shake(amount: number)
	shake += amount
end

function Shake.step(delta: number)
	if shake <= 0.01 then
		return
	end

	shake = math.lerp(shake, 0, dampFactor(5, delta))

	local speed = math.clamp(math.map(shake, 0, 10, MIN_SPEED, MAX_SPEED), MIN_SPEED, MAX_SPEED)
	local scale = math.clamp(shake * 0.1, 0, 1)

	xStride = (xStride + delta * speed * 1.6) % TAU
	yStride = (yStride + delta * speed * 1.2) % TAU
	zStride = (zStride + delta * speed * 0.7) % TAU

	local x = math.sin(xStride) * scale
	local y = math.sin(yStride) * scale
	local z = math.sin(zStride) * scale

	camera.CFrame *= CFrame.new(x, y, z)
end

function Shake.enable() end

function Shake.disable() end

return Shake
