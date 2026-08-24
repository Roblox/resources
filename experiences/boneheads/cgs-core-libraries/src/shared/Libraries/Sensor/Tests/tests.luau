-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Sensor = ReplicatedStorage.Core.Libraries.Sensor
local getClosestInstance = require(ReplicatedStorage.Core.Libraries.Sensor.getClosestInstance)
local getClosestInstances = require(Sensor.getClosestInstances)
local getClosestVisibleInstances = require(Sensor.getClosestVisibleInstances)
local getInstancesInArc = require(Sensor.getInstancesInArc)
local getInstancesInRadius = require(Sensor.getInstancesInRadius)
local hasLineOfSight = require(Sensor.hasLineOfSight)
local spheresOverlap = require(Sensor.spheresOverlap)

local testingObjects: { PVInstance }
local testOrigin = Vector3.new(30, 5, 30)

-- TODO Replace these tests with a proper testing framework that compares test results to expected values.

local visualBox

local function setupBlocks()
	local positions = {
		Vector3.new(0, 0, 0),
		Vector3.new(12, 0, 0),
		Vector3.new(12, 0, 10),
		Vector3.new(0, 0, 10),
	}
	local colors = {
		{ name = "Red", color = Color3.fromRGB(255, 0, 0) },
		{ name = "Green", color = Color3.fromRGB(0, 255, 0) },
		{ name = "Blue", color = Color3.fromRGB(0, 0, 255) },
		{ name = "Orange", color = Color3.fromRGB(255, 165, 0) },
	}

	for i, position in positions do
		local block = Instance.new("Part")
		block.Shape = Enum.PartType.Block
		block.Size = Vector3.new(1, 1, 2)
		block.Position = position + testOrigin
		block.Anchored = true
		block.Color = colors[i].color
		block.Name = colors[i].name
		block:AddTag("SensorTesting")
		block.Parent = Workspace

		local directionIndicator = Instance.new("Part")
		directionIndicator.Shape = Enum.PartType.Cylinder
		directionIndicator.Size = Vector3.new(1, 0.5, 0.5)
		directionIndicator.Position = position + testOrigin + Vector3.new(0, -0.5, -1)
		directionIndicator.Anchored = true
		directionIndicator.Color = colors[i].color
		directionIndicator.Name = colors[i].name
		directionIndicator.Rotation = Vector3.new(0, 90, 0)
		directionIndicator.CanQuery = false
		directionIndicator.Parent = Workspace
	end

	visualBox = Instance.new("Part")
	visualBox.Shape = Enum.PartType.Block
	visualBox.Size = Vector3.new(5, 2, 14)
	visualBox.Position = Vector3.new(0, 0, 7.6) + testOrigin
	visualBox.Anchored = true
	visualBox.Material = Enum.Material.Plastic
	visualBox.Color = Color3.fromRGB(255, 255, 255)
	visualBox.Transparency = 0.5
	visualBox.CanQuery = false
	visualBox.CanCollide = false
	visualBox.Parent = Workspace

	local wall = Instance.new("Part")
	wall.Shape = Enum.PartType.Block
	wall.Size = Vector3.new(1, 3, 15)
	wall.Position = Vector3.new(5, 0, 5) + testOrigin
	wall.Anchored = true
	wall.Parent = Workspace

	return
end

local function testGetClosestInstance()
	for _, part in testingObjects do
		local toCheck = table.clone(testingObjects)
		table.remove(toCheck, table.find(toCheck, part))
		local closest = getClosestInstance(toCheck, part:GetPivot().Position)
		print("Closest to", part.Name, "is", closest and closest.Name or "nil")
	end
end

local function testGetClosestInstances()
	for _, part in testingObjects do
		local toCheck = table.clone(testingObjects)
		table.remove(toCheck, table.find(toCheck, part))
		local closest = getClosestInstances(toCheck, part:GetPivot().Position, 2)
		print(
			"Closest to",
			part.Name,
			"are",
			closest[1] and closest[1].Name or "nil",
			"and",
			closest[2] and closest[2].Name or "nil"
		)
	end
end

local function testHasLineOfSight()
	for _, part in testingObjects do
		local toCheck = table.clone(testingObjects)
		table.remove(toCheck, table.find(toCheck, part))
		for _, other in toCheck do
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = { part }
			local los = hasLineOfSight(part:GetPivot().Position, other, raycastParams)
			print("Line of sight between", part.Name, "and", other.Name, "is", los)
		end
	end
end

local function testGetClosestVisibleInstances()
	for _, part in testingObjects do
		local toCheck = table.clone(testingObjects)
		table.remove(toCheck, table.find(toCheck, part))
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { part }
		local closestVisible = getClosestVisibleInstances(toCheck, part:GetPivot(), 100, math.pi / 2, 1, raycastParams)
		print("Closest visible to", part.Name, "is", closestVisible[1] and closestVisible[1].Name or "nil")
	end
end

local function testGetInstancesInArc()
	for _, part in testingObjects do
		local toCheck = table.clone(testingObjects)
		table.remove(toCheck, table.find(toCheck, part))
		local inArc = getInstancesInArc(toCheck, part:GetPivot(), 100, math.pi * 0.8)
		print("Instances in arc of", part.Name, "are", #inArc)
	end
end
local function testGetInstancesInRadius()
	for _, part in testingObjects do
		local toCheck = table.clone(testingObjects)
		table.remove(toCheck, table.find(toCheck, part))
		local inRadius = getInstancesInRadius(toCheck, part:GetPivot().Position, 10)
		print("Instances in radius of", part.Name, "are", #inRadius)
	end
end

local function testSpheresOverlap()
	local result1 = spheresOverlap(Vector3.new(0, 0, 0), 5, Vector3.new(8, 0, 0), 5)
	print("Overlapping spheres (distance 8, radii 5+5):", result1, result1 == true and "✓" or "✗")

	local result2 = spheresOverlap(Vector3.new(0, 0, 0), 5, Vector3.new(15, 0, 0), 5)
	print("Non-overlapping spheres (distance 15, radii 5+5):", result2, result2 == false and "✓" or "✗")

	local result3 = spheresOverlap(Vector3.new(0, 0, 0), 5, Vector3.new(10, 0, 0), 5)
	print("Touching spheres (distance 10, radii 5+5):", result3, result3 == false and "✓" or "✗")

	local result4 = spheresOverlap(Vector3.new(5, 5, 5), 10, Vector3.new(5, 5, 5), 5)
	print("Concentric spheres (same center):", result4, result4 == true and "✓" or "✗")

	local result5 = spheresOverlap(Vector3.new(0, 0, 0), 10, Vector3.new(3, 4, 0), 2)
	print("One sphere inside another (distance 5, radii 10+2):", result5, result5 == true and "✓" or "✗")
end

local function tests()
	print("=== Running All Sensor Tests ===")

	setupBlocks()
	testingObjects = CollectionService:GetTagged("SensorTesting") :: { PVInstance }

	print("\n--- Testing spheresOverlap ---")
	testSpheresOverlap()

	print("\n--- Testing getClosestInstances ---")
	testGetClosestInstances()

	print("\n--- Testing getClosestInstance ---")
	testGetClosestInstance()

	print("\n--- Testing hasLineOfSight ---")
	print("> Should show true for pairs without wall in between, false for pairs with wall")
	testHasLineOfSight()

	print("\n--- Testing getClosestVisibleInstances ---")
	print("> Should show only for the two parts aimed at the back of another part")
	testGetClosestVisibleInstances()

	print("\n--- Testing getInstancesInArc ---")
	print("> Should show 2 for the ones in back and 0 for the ones in front")
	testGetInstancesInArc()

	print("\n--- Testing getInstancesInRadius ---")
	print("> Should show 1 for each")
	testGetInstancesInRadius()

	print("\n=== All Tests Complete ===")
end

return {
	tests = tests,
	testGetClosestInstances = testGetClosestInstances,
	testGetClosestInstance = testGetClosestInstance,
	testHasLineOfSight = testHasLineOfSight,
	testGetClosestVisibleInstances = testGetClosestVisibleInstances,
	testGetInstancesInArc = testGetInstancesInArc,
	testGetInstancesInRadius = testGetInstancesInRadius,
	testSpheresOverlap = testSpheresOverlap,
}
