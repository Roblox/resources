-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type TeleportStatus = "idle" | "queued" | "teleporting" | "retrying" | "succeeded" | "failed"

export type TeleportStatusPayload = {
	read status: TeleportStatus,
	read placeId: number,
	read destinationName: string?,
	read attemptNumber: number,
	read maxRetries: number,
	read errorMessage: string?,
	read timestamp: number,
}

export type StudioTestConfig = {
	read simulateFailure: boolean,
	read failureCount: number,
}

export type TeleportConfig = {
	read maxRetries: number,
	read initialBackoffSeconds: number,
	read maxBackoffSeconds: number,
	read backoffMultiplier: number,
	read studioTestConfig: StudioTestConfig?,
}

export type TeleportClientAPI = {
	read getStatus: () -> TeleportStatus,
	read getLatestPayload: () -> TeleportStatusPayload?,
	read onStatusChanged: (callback: (payload: TeleportStatusPayload) -> ()) -> { Disconnect: () -> () },
	read start: () -> (),
}

return nil
