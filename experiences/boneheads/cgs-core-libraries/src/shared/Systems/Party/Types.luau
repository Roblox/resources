-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type PartyCompact = {
	id: string,
	leaderId: number,
	memberIds: { number },
	maxSize: number,
}

export type PartyInvite = {
	partyId: string,
	fromPlayer: Player,
}

export type PartyRequest =
	{ type: "subscribe" }
	| { type: "invite", target: Player }
	| { type: "decline", partyId: string }
	| { type: "join", partyId: string }
	| { type: "leave" }
	| { type: "kick", target: Player }
	| { type: "setReady", ready: boolean }

export type PartyUpdate =
	{ type: "joined", party: PartyCompact }
	| { type: "left" }
	| { type: "membersChanged", members: { Player } }
	| { type: "leaderChanged", leader: Player }
	| { type: "inviteReceived", partyId: string, fromPlayer: Player }
	| { type: "inviteExpired", partyId: string }
	| { type: "readyChanged", readyMembers: { Player } }

export type Party = {
	id: string,
	leader: Player?,
	maxSize: number,
	members: { Player },
	readyMembers: { Player },

	getSize: () -> number,
	getMembers: () -> { Player },
	getReadyMembers: () -> { Player },
	isReady: () -> boolean,

	cleanup: () -> (),
}

export type ClientParty = Party & {
	invite: (player: Player) -> (),
	kick: (player: Player) -> (),
	leave: () -> (),
	setReady: (ready: boolean) -> (),
}

return nil
