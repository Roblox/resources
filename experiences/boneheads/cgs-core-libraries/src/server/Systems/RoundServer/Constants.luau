-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")
local Types = require(script.Parent.Types)

local DEFAULT_GAME_MODE_ATTRIBUTE = "gameMode"
local DEFAULT_GAME_MODE = Workspace:GetAttribute(DEFAULT_GAME_MODE_ATTRIBUTE) or "TeamDeathmatch"

return {
	DEFAULT_GAME_MODE = DEFAULT_GAME_MODE :: Types.GameMode,
	DEFAULT_ROUND_STATE = "Intermission" :: Types.RoundState,
	DEFAULT_INTERMISSION_DURATION = 30,
	DEFAULT_ROUND_DURATION = 2 * 60,

	ROUND_START_TIMESTAMP_ATTRIBUTE = "_roundStartTimestamp",
	ROUND_END_TIMESTAMP_ATTRIBUTE = "_roundEndTimestamp",
	INTERMISSION_END_TIMESTAMP_ATTRIBUTE = "_intermissionEndTimestamp",
	ROUND_STATE_ATTRIBUTE = "_roundState",
	ROUND_WINNER_USER_IDS_ATTRIBUTE = "_roundWinnerUserIds",
	IN_ROUND_ATTRIBUTE = "_inRound",

	TEAM_TAG_STRING_MATCH = "Team",
	TEAM_ATTRIBUTE = "_team",
}
