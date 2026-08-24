-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedTypes = require(ReplicatedStorage.Core.Systems.Teleport.Types)

export type TeleportStatus = SharedTypes.TeleportStatus
export type TeleportStatusPayload = SharedTypes.TeleportStatusPayload
export type TeleportConfig = SharedTypes.TeleportConfig

export type TeleportServerAPI = {
	read teleportPlayer: (player: Player, placeId: number, teleportData: { [string]: any }?) -> (),
	read teleportPlayers: (players: { Player }, placeId: number, teleportData: { [string]: any }?) -> (),
	read cancelTeleport: (player: Player) -> (),
	read getStatus: (player: Player) -> TeleportStatus,
	read onStatusChanged: (
		callback: (player: Player, payload: TeleportStatusPayload) -> ()
	) -> { Disconnect: () -> () },
	read start: (config: TeleportConfig?) -> (),
}

return nil
