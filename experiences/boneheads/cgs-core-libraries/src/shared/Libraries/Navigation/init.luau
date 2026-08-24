-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(script.Constants)
local Debug = require(ReplicatedStorage.Core.Systems.Debug)
local Types = require(script.Types)

local getCharacterFromPart = require(ReplicatedStorage.Core.Utility.getCharacterFromPart)
local getXZDistance = require(ReplicatedStorage.Core.Libraries.Sensor.getXZDistance)
local tapInputAction = require(ReplicatedStorage.Core.Utility.tapInputAction)

local FORWARD_MOVE_VECTOR = Vector2.yAxis

local WAYPOINT_LABEL_ACTIONS: { [string]: { string } } = {
	[Constants.PATHFINDING_LABELS.JUMP] = { "jump" },
}

export type NavigationParams = Types.NavigationParams
export type NavigationStatus = Types.NavigationStatus
export type NavigationCompletionStatus = Types.NavigationCompletionStatus
export type NavigationAbort = Types.NavigationAbort
export type NavigationProcessedCallback = Types.NavigationProcessedCallback
export type NavigationCompletedCallback = Types.NavigationCompletedCallback
export type NavigationInputs = Types.NavigationInputs

local Navigation = {}

local function getClosestAlignedWaypointIndex(
	startingPosition: Vector3,
	pathWaypoints: { PathWaypoint },
	params: NavigationParams?
): number
	local skipParams = params and params.pathfindingSkipWaypointsParams
	local maxDistanceToPath = if skipParams and skipParams.maxDistanceToPath
		then skipParams.maxDistanceToPath
		else Constants.PATHFINDING_MAX_DISTANCE_TO_PATH
	local minAlignmentDot = if skipParams and skipParams.minDotProduct
		then skipParams.minDotProduct
		else Constants.PATHFINDING_PATH_ALIGNMENT_THRESHOLD

	for i = #pathWaypoints, 2, -1 do
		local frontPosition = pathWaypoints[i].Position
		local backPosition = pathWaypoints[i - 1].Position

		local backToFront = frontPosition - backPosition
		local backToCharacter = startingPosition - backPosition

		-- The waypoints are basically stacked, skip.
		if backToFront.Magnitude <= Constants.MOVEMENT_EPSILON then
			continue
		end

		-- The character is near-exactly at the back waypoint. Target the front waypoint.
		if backToCharacter.Magnitude <= Constants.MOVEMENT_EPSILON then
			return i
		end

		-- The heights are too far apart.
		if math.abs(frontPosition.Y - backPosition.Y) > Constants.MOVEMENT_HEIGHT_THRESHOLD then
			continue
		end

		-- Project starting position onto line formed by waypoints to check distance.
		local segmentDirection = backToFront.Unit
		local projection = backToCharacter:Dot(segmentDirection)
		local closestPoint = backPosition + segmentDirection * math.clamp(projection, 0, backToFront.Magnitude)
		local orthogonalDistance = ((startingPosition - closestPoint) * Vector3.new(1, 0, 1)).Magnitude

		-- Decline if too far away.
		if orthogonalDistance >= maxDistanceToPath then
			continue
		end

		-- Accept if in front of the back waypoint (i.e. you are between the waypoints).
		if segmentDirection:Dot(backToCharacter.Unit) > minAlignmentDot then
			return i
		end
	end

	return 1
end

local function isWithinDistance(instance: PVInstance, target: Vector3, stoppingDistance: number?): boolean
	local height = math.abs(instance:GetPivot().Y - target.Y)
	local xzDistance = getXZDistance(instance, target)
	local xzThreshold = math.max(stoppingDistance or 0, Constants.MOVEMENT_TARGET_THRESHOLD)
	return xzDistance <= xzThreshold and height <= Constants.MOVEMENT_HEIGHT_THRESHOLD
end

local function getFacingDirection(instance: PVInstance, target: Vector3): Vector3
	return (target - instance:GetPivot().Position).Unit
end

local function fireDirectionalInput<T>(inputAction: InputAction, value: T & (Vector2 | Vector3))
	if not value:FuzzyEq(inputAction:GetState() :: T, Constants.MOVEMENT_EPSILON) then
		inputAction:Fire(value)
	end
end

function Navigation.directTo(
	instance: PVInstance,
	inputInstances: NavigationInputs,
	target: Vector3,
	onCompleted: NavigationCompletedCallback?,
	params: NavigationParams?,
	_focusTarget: CFrame?
): NavigationAbort
	local moveAction = inputInstances.move
	local lookAction = inputInstances.look

	local preSimulationConnection: RBXScriptConnection
	local navigating = true

	local function complete(status: NavigationCompletionStatus)
		if not navigating then
			return
		end

		navigating = false
		preSimulationConnection:Disconnect()
		moveAction:Fire(Vector2.zero)

		if onCompleted then
			onCompleted(status)
		end
	end

	local function abort()
		complete("Cancelled")
	end

	local function doWalk()
		-- If a focus target is provided, consider the target reached if either the focus target
		-- or the main target is reached. This allows moving between pathfinding waypoints while
		-- respecting the stopping distance on the final target.
		local focusTargetPosition = _focusTarget and _focusTarget.Position

		local stoppingDistance = params and params.stoppingDistance
		local reachedTarget = if focusTargetPosition
			then isWithinDistance(instance, focusTargetPosition, stoppingDistance) or isWithinDistance(instance, target)
			else isWithinDistance(instance, target, stoppingDistance)

		if reachedTarget then
			complete("Success")
			return
		end

		-- Apply auto-braking if enabled
		local moveVector = FORWARD_MOVE_VECTOR
		local brakingDistance = params and params.autoBrakingStrength or 0

		if brakingDistance > 0 then
			local distance = getXZDistance(instance, focusTargetPosition or target)

			if distance < brakingDistance then
				local speedScale = math.max(0.1, distance / brakingDistance)
				moveVector = FORWARD_MOVE_VECTOR * speedScale
			end
		end

		if params and params.moveSpeedFactor then
			moveVector *= params.moveSpeedFactor
		end

		fireDirectionalInput(moveAction, moveVector)
		fireDirectionalInput(lookAction, getFacingDirection(instance, target))
	end

	preSimulationConnection = RunService.PreSimulation:Connect(doWalk)
	return abort
end

function Navigation.computePathAsync(
	instance: PVInstance,
	target: Vector3,
	params: NavigationParams?
): (NavigationStatus, Path?)
	local path = PathfindingService:CreatePath(params and params.pathfindingAgentParams or {})
	local pathComputed, errorMessage = pcall(path.ComputeAsync, path, instance:GetPivot().Position, target)

	if not pathComputed then
		if errorMessage and Constants.PATHFINDING_SHOW_ERRORS then
			warn(`Path computation failed with error: {errorMessage}`)
		end

		return "Errored", nil
	elseif path.Status ~= Enum.PathStatus.Success and path.Status ~= Enum.PathStatus.ClosestNoPath then
		return "NoPath", nil
	end

	return "Success", path
end

function Navigation.pathTo(
	instance: PVInstance,
	inputInstances: NavigationInputs,
	path: Path,
	onCompleted: NavigationCompletedCallback?,
	params: NavigationParams?
): NavigationAbort
	local waypoints = path:GetWaypoints()
	local waypointIndex = 1

	local finalWaypoint: PathWaypoint
	local pathBlockedConnection: RBXScriptConnection
	local abortDirectMovement: NavigationAbort = function() end

	local navigating = true

	local stuckTask: thread?

	local character = getCharacterFromPart(instance)
	local characterHeight = if character
		then character:GetExtentsSize().Y
		elseif
			params
			and params.pathfindingAgentParams
			and params.pathfindingAgentParams.AgentHeight
		then params.pathfindingAgentParams.AgentHeight :: number
		else 0

	local function complete(status: NavigationCompletionStatus, details: any?)
		if not navigating then
			return
		end

		navigating = false
		pathBlockedConnection:Disconnect()
		abortDirectMovement()

		if stuckTask then
			task.cancel(stuckTask)
			stuckTask = nil
		end

		if onCompleted then
			onCompleted(status, details)
		end
	end

	local function abort()
		complete("Cancelled")
	end

	local function toWaypoint(index: number)
		if index > #waypoints then
			complete("Success")
			return
		end

		local waypoint = waypoints[index]
		local position = waypoint.Position

		local function onWaypointReached(status: NavigationCompletionStatus)
			if not navigating then
				return
			end

			if status == "Cancelled" then
				return
			end

			toWaypoint(index + 1)
		end

		if waypoint.Action == Enum.PathWaypointAction.Walk then
			waypointIndex = index

			-- Send finalWaypoint as _focusTarget to allow auto-braking to work properly on the final approach
			local focusCFrame = CFrame.lookAlong(finalWaypoint.Position, instance:GetPivot().LookVector)
			abortDirectMovement =
				Navigation.directTo(instance, inputInstances, position, onWaypointReached, params, focusCFrame)
		else -- Trigger input actions based on pathfinding waypoints
			local waypointLabel = waypoint.Label
			local waypointAction = waypoint.Action

			if waypointAction == Enum.PathWaypointAction.Jump then
				waypointLabel = Constants.PATHFINDING_LABELS.JUMP
			end

			-- Face towards the next waypoint when performing a custom action to help with actions
			local nextWaypoint = waypoints[index + 1]
			if nextWaypoint then
				local faceDirection = getFacingDirection(instance, nextWaypoint.Position)
				fireDirectionalInput(inputInstances.look, faceDirection)
			end

			-- Play any input actions associated with this waypoint label (e.g. vault, zipline, etc.)
			local inputActions = WAYPOINT_LABEL_ACTIONS[waypointLabel]
			if inputActions then
				for _, inputActionName in inputActions do
					local inputAction = (inputInstances :: { [string]: InputAction })[inputActionName]
					assert(inputAction, `Input instance {inputActionName} not found for waypoint label {waypointLabel}`)
					tapInputAction(inputAction)
				end
			end

			toWaypoint(index + 1)
		end
	end

	-- Teleport to next waypoint if stuck too long
	local stuckTimeout = params and params.pathfindingTeleportWaypointAfter
	if stuckTimeout and stuckTimeout > 0 then
		local lastPosition = instance:GetPivot().Position
		local function teleportToWaypoint()
			abortDirectMovement()

			-- Teleport to the next waypoint
			local currentWaypointPosition = waypoints[waypointIndex].Position
			local lookCFrame =
				CFrame.lookAlong(currentWaypointPosition, currentWaypointPosition - instance:GetPivot().Position) -- Look towards the waypoint when teleporting

			local nextWaypoint = waypoints[waypointIndex + 1]
			if nextWaypoint then
				lookCFrame = CFrame.lookAlong(nextWaypoint.Position, nextWaypoint.Position - currentWaypointPosition) -- Look towards the next waypoint if it exists to help with smoother transitions after teleport
			end

			lookCFrame += Vector3.yAxis * characterHeight / 2
			instance:PivotTo(lookCFrame)

			toWaypoint(waypointIndex + 1)
		end

		stuckTask = task.spawn(function()
			while navigating do
				task.wait(stuckTimeout)

				if not navigating then
					stuckTask = nil
					break
				end

				local distance = (instance:GetPivot().Position - lastPosition).Magnitude
				lastPosition = instance:GetPivot().Position

				if distance < Constants.PATHFINDING_TELEPORT_STUCK_MIN_MOVEMENT then
					-- Defer onto a separate thread so stuckTask can yield and be cancellable by the
					-- time teleportToWaypoint reaches complete() -> task.cancel(stuckTask).
					task.defer(teleportToWaypoint)
				end
			end
		end)
	end

	-- Listen to path blocked event
	pathBlockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
		if blockedWaypointIndex < waypointIndex or blockedWaypointIndex > #waypoints then
			return
		end

		if Constants.PATHFINDING_SHOW_ERRORS then
			warn(`Path blocked at waypoint index {blockedWaypointIndex}`)
		end

		local blockedWaypoint = waypoints[blockedWaypointIndex]
		complete("Blocked", blockedWaypoint.Position)
	end)

	-- Allow early completion by removing waypoints from end of path
	if params and params.pathfindingEarlyCompleteWaypoints then
		for _ = 1, params.pathfindingEarlyCompleteWaypoints do
			if #waypoints == 1 then
				break
			end

			table.remove(waypoints)
		end
	end

	finalWaypoint = waypoints[#waypoints]

	-- Remove early waypoints in case instance passes them by the time path is computed
	for i = #waypoints, 1, -1 do
		if isWithinDistance(instance, waypoints[i].Position) then
			for _ = 1, i do
				table.remove(waypoints, 1)
			end
			break
		end
	end

	-- Start at the best waypoint using distance and dot product score if param is provided
	if params and params.pathfindingSkipWaypointsParams then
		waypointIndex = getClosestAlignedWaypointIndex(instance:GetPivot().Position, waypoints, params)
	end

	toWaypoint(waypointIndex)

	return abort
end

function Navigation.moveToAsync(
	instance: PVInstance,
	inputInstances: NavigationInputs,
	target: Vector3,
	onCompleted: NavigationCompletedCallback?,
	params: NavigationParams?
): (NavigationStatus, Types.NavigationAbort)
	local debugLinesId = `{Debug.getTogglePrefix("PATHFINDING")}{Debug.getId(instance)}`

	if params and params.pathfindingEnabled then
		local abortSpeculativeMove = if params.pathfindingSpeculativeMoveWhileComputing
			then Navigation.directTo(instance, inputInstances, target, nil, params)
			else function() end

		local pathStatus, path = Navigation.computePathAsync(instance, target, params)
		abortSpeculativeMove()

		if not path then
			return pathStatus, function() end
		end

		local abortPath: NavigationAbort = function() end
		local navigating = true
		local retriesRemaining = params.pathfindingRetriesOnBlocked or 0

		local function drawDebugPath(currentPath: Path)
			if not Debug.getToggle("PATHFINDING") then
				return
			end

			local waypoints = currentPath:GetWaypoints()
			local points = {}
			for _, waypoint in waypoints do
				table.insert(points, waypoint.Position)
			end

			Debug.lines(debugLinesId, points, Color3.fromRGB(0, 200, 255), 0.1)
		end

		drawDebugPath(path)

		local function complete(status: NavigationCompletionStatus, details: any?)
			if not navigating then
				return
			end

			-- Attempt to retry pathfinding if blocked and retries remain
			if status == "Blocked" and retriesRemaining > 0 then
				retriesRemaining -= 1
				local retryPathStatus: NavigationStatus, retryPath: Path? =
					Navigation.computePathAsync(instance, target, params)

				if retryPath then
					drawDebugPath(retryPath)
					abortPath = Navigation.pathTo(instance, inputInstances, retryPath, complete, params)
					return
				end

				pathStatus = retryPathStatus
			end

			navigating = false
			Debug.destroy(debugLinesId)

			if onCompleted then
				onCompleted(status, details)
			end
		end

		local function abort()
			Debug.destroy(debugLinesId)
			abortPath()
		end

		abortPath = Navigation.pathTo(instance, inputInstances, path, complete, params)
		return "Success", abort
	else
		local abort = Navigation.directTo(instance, inputInstances, target, onCompleted, params)
		return "Success", abort
	end
end

function Navigation.moveTo(
	instance: PVInstance,
	inputInstances: NavigationInputs,
	target: Vector3,
	onProcessed: NavigationProcessedCallback?,
	onCompleted: NavigationCompletedCallback?,
	params: NavigationParams?
): NavigationAbort
	local navigating = true
	local abortPath: NavigationAbort = function() end

	local function complete(status: NavigationCompletionStatus, details: any?)
		if not navigating then
			return
		end

		navigating = false
		if onCompleted then
			onCompleted(status, details)
		end
	end

	local function abort()
		if not navigating then
			return
		end

		complete("Cancelled")
		abortPath()
	end

	task.spawn(function()
		local processedStatus, processedAbort =
			Navigation.moveToAsync(instance, inputInstances, target, complete, params)
		abortPath = processedAbort

		if onProcessed then
			onProcessed(processedStatus)
		end

		if not navigating then
			abortPath()
		end
	end)

	return abort
end

return Navigation
