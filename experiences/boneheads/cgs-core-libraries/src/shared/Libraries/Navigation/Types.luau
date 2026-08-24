-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type NavigationStatus = "Success" | "NoPath" | "Errored"
export type NavigationCompletionStatus = "Success" | "Blocked" | "Cancelled"

export type NavigationAbort = () -> ()
export type NavigationProcessedCallback = (status: NavigationStatus) -> ()
export type NavigationCompletedCallback = (status: NavigationCompletionStatus, details: any?) -> ()

export type NavigationInputs = {
	move: InputAction,
	look: InputAction,
	jump: InputAction,
}

export type NavigationParams = {
	stoppingDistance: number?,
	autoBrakingStrength: number?,

	moveSpeedFactor: number?,
	pathfindingEnabled: boolean?,
	pathfindingSpeculativeMoveWhileComputing: boolean?,
	pathfindingAgentParams: any?,
	pathfindingRetriesOnBlocked: number?,
	pathfindingEarlyCompleteWaypoints: number?,
	pathfindingTeleportWaypointAfter: number?,
	pathfindingSkipWaypointsParams: {
		maxDistanceToPath: number?,
		minDotProduct: number?,
	}?,
}

return nil
