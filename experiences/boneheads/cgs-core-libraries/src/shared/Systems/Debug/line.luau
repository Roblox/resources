-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)

local line = {}

function line.create(): Types.DebugLine
	local newAdornment = Instance.new("CylinderHandleAdornment")
	newAdornment.Name = Constants.LINE.NAME
	newAdornment.Adornee = Workspace.Terrain
	newAdornment.Transparency = Constants.LINE.TRANSPARENCY
	newAdornment.Shading = Enum.AdornShading.XRay

	local lineObject: Types.DebugLine = {
		line = newAdornment,
		position1 = Vector3.zero,
		position2 = Vector3.zero,
	}

	line.update(lineObject, Vector3.zero, Vector3.zero, Constants.LINE.COLOR, Constants.LINE.WIDTH)

	newAdornment.Parent = Utils.getContainer()

	return lineObject
end

function line.update(
	lineObject: Types.DebugLine,
	position1: Vector3?,
	position2: Vector3?,
	color: Color3?,
	width: number?
)
	lineObject.position1 = position1 or lineObject.position1
	lineObject.position2 = position2 or lineObject.position2

	local newDirection = lineObject.position2 - lineObject.position1
	local newDistance = newDirection.Magnitude
	local newMidpoint = lineObject.position1 + newDirection / 2
	lineObject.line.CFrame = CFrame.new(newMidpoint, lineObject.position2)
	lineObject.line.Height = newDistance
	lineObject.line.Radius = width or lineObject.line.Radius
	lineObject.line.Color3 = color or lineObject.line.Color3
end

function line.destroy(lineObject: Types.DebugLine)
	lineObject.line:Destroy()
end

return line
