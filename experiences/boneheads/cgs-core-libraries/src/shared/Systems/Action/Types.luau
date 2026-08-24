-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type RemoteType = "Reliable" | "Unreliable"

export type ActionName = string
export type Execute<T> = (params: T) -> ()
export type Validate<T> = (player: Player, params: T) -> boolean
export type Action<T> = {
	execute: Execute<T>?,
	validate: Validate<T>?,
	replicates: RemoteType?,
}

export type ActionDefinition = {
	client: string?,
	server: string?,
	validate: string,
	replicateToServer: RemoteType?,
	replicateToClient: RemoteType?,
}

return nil
