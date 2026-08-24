-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

type ConstantsShape = {
	DEFAULT_MAX_RETRIES: number,
	DEFAULT_INITIAL_BACKOFF_SECONDS: number,
	DEFAULT_MAX_BACKOFF_SECONDS: number,
	DEFAULT_BACKOFF_MULTIPLIER: number,
	STUDIO_TELEPORT_DELAY_SECONDS: number,

	STATUS_IDLE: "idle",
	STATUS_QUEUED: "queued",
	STATUS_TELEPORTING: "teleporting",
	STATUS_RETRYING: "retrying",
	STATUS_SUCCEEDED: "succeeded",
	STATUS_FAILED: "failed",
}

local Constants: ConstantsShape = {
	DEFAULT_MAX_RETRIES = 5,
	DEFAULT_INITIAL_BACKOFF_SECONDS = 1,
	DEFAULT_MAX_BACKOFF_SECONDS = 30,
	DEFAULT_BACKOFF_MULTIPLIER = 2,
	-- Simulates the real-world delay when TeleportService spins up a server
	STUDIO_TELEPORT_DELAY_SECONDS = 3.5,

	STATUS_IDLE = "idle",
	STATUS_QUEUED = "queued",
	STATUS_TELEPORTING = "teleporting",
	STATUS_RETRYING = "retrying",
	STATUS_SUCCEEDED = "succeeded",
	STATUS_FAILED = "failed",
}

return Constants
