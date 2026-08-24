-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Token = require(ReplicatedStorage.Core.Utility.Token)
local getClosestInstances = require(ReplicatedStorage.Core.Libraries.Sensor.getClosestInstances)
local getTaggedList = require(ReplicatedStorage.Core.Utility.getTaggedList)

local random = Random.new()

local NEXT_WAYPOINT_OBJECT_VALUE = "NextWaypoint"

export type AreaParam = {
	tags: { string },
	maxDistance: number?,
	selectClosest: boolean?,
	tokenAttribute: string?,
	filter: ((area: PVInstance) -> boolean)?,
}

type Context = {
	character: Model,

	-- TODO: revisit this double-setup once we have per-state context
	areaWaypoint: PVInstance?,
	areaTokenHolder: Instance?,
	areaTokenAttribute: string?,

	targetAreaWaypoint: PVInstance?,
	targetAreaTokenHolder: Instance?,
	targetAreaTokenAttribute: string?,
}

local POI = {}

local function findAvailableArea(position: Vector3, areaParam: AreaParam): PVInstance?
	local candidateDistances: { [PVInstance]: number } = {}
	local candidates: { PVInstance } = {}

	-- Gather available candidates and their distances
	for _, area in getTaggedList(areaParam.tags) :: { PVInstance } do
		assert(area:IsA("PVInstance"), "Area must be a PVInstance")

		if not area:IsDescendantOf(Workspace) then
			continue
		end

		local distance = (area:GetPivot().Position - position).Magnitude
		if areaParam.maxDistance and distance > areaParam.maxDistance then
			continue
		end

		candidateDistances[area] = distance
		table.insert(candidates, area)
	end

	-- Sort candidates by distance if selectClosest is true, otherwise randomize order
	if areaParam.selectClosest then
		table.sort(candidates, function(a, b)
			return candidateDistances[a] < candidateDistances[b]
		end)
	else
		random:Shuffle(candidates)
	end

	-- Final filtering for token availability and custom filter function
	for _, area in candidates do
		if areaParam.filter and not areaParam.filter(area) then
			continue
		end

		if areaParam.tokenAttribute and not Token.canTake(area, areaParam.tokenAttribute) then
			continue
		end

		return area
	end

	return nil
end

local function getAreaBoundingBox(instance: PVInstance): (CFrame, Vector3)
	if instance:IsA("BasePart") then
		return instance.CFrame, instance.Size
	elseif instance:IsA("Model") then
		return instance:GetBoundingBox()
	end

	return instance:GetPivot(), Vector3.zero
end

local function getClosestAreaWaypoint(position: Vector3, area: PVInstance): PVInstance
	local waypoints = area:QueryDescendants("PVInstance") :: { PVInstance }
	local closestWaypoints = getClosestInstances(waypoints, position, #waypoints)
	return closestWaypoints[1] or area
end

function POI.findArea(context: Context, areaParam: AreaParam): boolean
	local position = context.character:GetPivot().Position
	local area = findAvailableArea(position, areaParam)

	if area then
		context.targetAreaWaypoint = getClosestAreaWaypoint(position, area)
		context.targetAreaTokenHolder = area
		context.targetAreaTokenAttribute = areaParam.tokenAttribute

		return true
	end

	return false
end

function POI.findNextWaypoint(context: Context): boolean
	local currentWaypoint = context.areaWaypoint
	if currentWaypoint then
		local nextWaypointValue = currentWaypoint:FindFirstChild(NEXT_WAYPOINT_OBJECT_VALUE) :: ObjectValue?
		local nextWaypoint = nextWaypointValue and nextWaypointValue.Value

		if nextWaypoint then
			assert(nextWaypoint:IsA("PVInstance"), "Next waypoint must be a PVInstance")
			context.areaWaypoint = nextWaypoint

			return true
		end
	end

	return false
end

function POI.pickPointInArea(area: PVInstance): Vector3
	local cframe, size = getAreaBoundingBox(area)
	local offset = Vector3.new(random:NextNumber(), random:NextNumber(), random:NextNumber()) * size
	return cframe:PointToWorldSpace(-size * 0.5 + offset)
end

function POI.isPointInArea(point: Vector3, area: PVInstance): boolean
	local cframe, size = getAreaBoundingBox(area)
	local offset = cframe:PointToObjectSpace(point):Abs()
	return offset:Min(size * 0.5) == offset
end

function POI.takeArea(context: Context)
	-- Assume area was recently found, should still be available
	if context.targetAreaTokenHolder and context.targetAreaTokenAttribute then
		Token.take(context.targetAreaTokenHolder, context.targetAreaTokenAttribute)
	end

	context.areaWaypoint = context.targetAreaWaypoint
	context.areaTokenHolder = context.targetAreaTokenHolder
	context.areaTokenAttribute = context.targetAreaTokenAttribute

	context.targetAreaWaypoint = nil
	context.targetAreaTokenHolder = nil
	context.targetAreaTokenAttribute = nil
end

function POI.releaseArea(context: Context)
	if context.areaTokenHolder and context.areaTokenAttribute then
		Token.release(context.areaTokenHolder, context.areaTokenAttribute)
	end

	context.areaWaypoint = nil
	context.areaTokenHolder = nil
	context.areaTokenAttribute = nil
end

return POI
