-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type RoundState = "InProgress" | "Intermission" | "Paused"
export type GameMode = string
export type Participant = Model

export type GameModeStopData = {
	winners: { Participant }?,
}

export type GameModeDefinition = {
	mode: GameMode,
	intermissionDuration: number?,
	roundDuration: number?,
	getParticipants: () -> { Participant },
	canStart: () -> boolean,
	shouldEnd: () -> boolean,
	onStart: () -> (),
	onStop: () -> GameModeStopData,
	onIntermissionStart: (() -> ())?,
	onIntermissionEnd: (() -> ())?,
}

export type TeamData = {
	teamConnections: { RBXScriptConnection },
	teamSpawnLocation: PVInstance?,
	teamMembers: { Participant },
	teamName: string,
}

return nil
