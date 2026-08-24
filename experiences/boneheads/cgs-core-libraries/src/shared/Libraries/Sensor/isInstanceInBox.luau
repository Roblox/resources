-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local isPointInBox = require(script.Parent.isPointInBox)

local CORNERS = {
	Vector3.new(1, 1, 1),
	Vector3.new(1, 1, -1),
	Vector3.new(1, -1, 1),
	Vector3.new(1, -1, -1),
	Vector3.new(-1, 1, 1),
	Vector3.new(-1, 1, -1),
	Vector3.new(-1, -1, 1),
	Vector3.new(-1, -1, -1),
}

local function hasPointInBox(points: { Vector3 }, origin: CFrame, size: Vector3): boolean
	if #points == 0 or size.X < 0 or size.Y < 0 or size.Z < 0 then
		return false
	end

	for _, point in points do
		if isPointInBox(point, origin, size) then
			return true
		end
	end

	return false
end

local function isInstanceInBox(instance: BasePart | Model, center: CFrame, size: Vector3): boolean
	if size.X < 0 or size.Y < 0 or size.Z < 0 then
		return false
	end

	local instanceSize: Vector3
	local instanceCFrame: CFrame

	if instance:IsA("Model") then
		instanceCFrame, instanceSize = instance:GetBoundingBox()
	else
		instanceSize = instance.Size
		instanceCFrame = instance.CFrame
	end

	local halfInstanceSize = instanceSize / 2
	local testPoints = {}

	for _, corner in CORNERS do
		table.insert(testPoints, instanceCFrame * (corner * halfInstanceSize))
	end

	table.insert(testPoints, instanceCFrame.Position)

	return hasPointInBox(testPoints, center, size)
end

return isInstanceInBox
