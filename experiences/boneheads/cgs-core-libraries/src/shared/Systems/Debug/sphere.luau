-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local Utils = require(script.Parent.Utils)

local sphere = {}

function sphere.create(): SphereHandleAdornment
	local newAdornment = Instance.new("SphereHandleAdornment")
	newAdornment.Name = Constants.SPHERE.NAME
	newAdornment.Adornee = Workspace.Terrain
	newAdornment.Transparency = Constants.SPHERE.TRANSPARENCY

	sphere.update(newAdornment, Vector3.zero, Constants.SPHERE.RADIUS, Constants.SPHERE.COLOR)

	newAdornment.Parent = Utils.getContainer()

	return newAdornment
end

function sphere.update(sphereObject: SphereHandleAdornment, position: Vector3?, radius: number?, color: Color3?)
	sphereObject.CFrame = (position and CFrame.new(position)) or sphereObject.CFrame
	sphereObject.Radius = radius or sphereObject.Radius
	sphereObject.Color3 = color or sphereObject.Color3
end

function sphere.destroy(sphereObject: SphereHandleAdornment)
	sphereObject:Destroy()
end

return sphere
