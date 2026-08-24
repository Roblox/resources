-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartyConstants = require(script.Constants)
local Signal = require(ReplicatedStorage.Core.Libraries.Signal)
local Types = require(script.Types)

local makeBaseParty = require(script.Utility.makeBaseParty)

local remotes = script.Remotes
local localPlayer = Players.LocalPlayer

export type Party = Types.Party
export type ClientParty = Types.ClientParty
export type PartyCompact = Types.PartyCompact
export type PartyUpdate = Types.PartyUpdate
export type PartyInvite = Types.PartyInvite

local localParty: ClientParty?

local invitesByPartyId: { [string]: PartyInvite } = {}

local partyChangedSignal: Signal.Signal<ClientParty?> = Signal.create()
local inviteReceivedSignal: Signal.Signal<PartyInvite> = Signal.create()
local inviteExpiredSignal: Signal.Signal<PartyInvite> = Signal.create()

local Party = {}

local function leaveClientParty()
	if not localParty then
		return
	end

	localParty.cleanup()
	localParty = nil
	partyChangedSignal:Fire(nil)
end

local function makeClientParty(compact: PartyCompact): ClientParty
	local leader = Players:GetPlayerByUserId(compact.leaderId)
	local party = makeBaseParty(compact.id, leader, compact.maxSize) :: ClientParty
	local partyBaseCleanup = party.cleanup

	for _, userId in compact.memberIds do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			table.insert(party.members, member)
		end
	end

	function party.invite(player: Player)
		remotes.PartyRequest:FireServer({ type = "invite", target = player })
	end

	function party.kick(player: Player)
		if party.leader ~= localPlayer then
			return
		end

		remotes.PartyRequest:FireServer({ type = "kick", target = player })
	end

	function party.leave()
		remotes.PartyRequest:FireServer({ type = "leave" })
		leaveClientParty()
	end

	function party.setReady(ready: boolean)
		remotes.PartyRequest:FireServer({ type = "setReady", ready = ready })
	end

	function party.cleanup()
		partyBaseCleanup()
	end

	return party
end

local function onPartyUpdate(update: PartyUpdate)
	if update.type == "joined" then
		if localParty then
			localParty.cleanup()
		end

		localParty = makeClientParty(update.party)
		partyChangedSignal:Fire(localParty)
	elseif update.type == "left" then
		if localParty then
			localParty.cleanup()
			localParty = nil
			partyChangedSignal:Fire(nil)
		end
	elseif update.type == "membersChanged" then
		if localParty then
			localParty.members = update.members
			partyChangedSignal:Fire(localParty)
		end
	elseif update.type == "leaderChanged" then
		if localParty then
			localParty.leader = update.leader
			partyChangedSignal:Fire(localParty)
		end
	elseif update.type == "readyChanged" then
		if localParty then
			localParty.readyMembers = update.readyMembers
			partyChangedSignal:Fire(localParty)
		end
	elseif update.type == "inviteReceived" then
		local invite: PartyInvite = {
			partyId = update.partyId,
			fromPlayer = update.fromPlayer,
		}

		invitesByPartyId[update.partyId] = invite
		inviteReceivedSignal:Fire(invite)
	elseif update.type == "inviteExpired" then
		local invite = invitesByPartyId[update.partyId]
		if invite then
			invitesByPartyId[update.partyId] = nil
			inviteExpiredSignal:Fire(invite)
		end
	end
end

function Party.getParty(): ClientParty?
	return localParty
end

function Party.joinParty(partyId: string)
	remotes.PartyRequest:FireServer({ type = "join", partyId = partyId })
end

function Party.leaveParty()
	if not localParty then
		return
	end

	localParty.leave()
end

function Party.invitePlayer(player: Player)
	if not localParty then
		return
	end

	localParty.invite(player)
end

function Party.declineInvite(partyId: string)
	invitesByPartyId[partyId] = nil
	remotes.PartyRequest:FireServer({ type = "decline", partyId = partyId })
end

function Party.kickPlayer(player: Player)
	if not localParty then
		return
	end

	if localParty.leader ~= localPlayer then
		return
	end

	localParty.kick(player)
end

function Party.setReady(ready: boolean)
	if not localParty then
		return
	end

	localParty.setReady(ready)
end

function Party.hasParty(player: Player): boolean
	return player:GetAttribute(PartyConstants.PARTY_ID_ATTRIBUTE) ~= nil
end

function Party.isPartyMember(playerA: Player, playerB: Player): boolean
	local partyIdA = playerA:GetAttribute(PartyConstants.PARTY_ID_ATTRIBUTE)
	local partyIdB = playerB:GetAttribute(PartyConstants.PARTY_ID_ATTRIBUTE)
	return partyIdA ~= nil and partyIdA == partyIdB
end

function Party.getPartyChangedSignal(): Signal.Signal<ClientParty?>
	return partyChangedSignal
end

function Party.getInviteReceivedSignal(): Signal.Signal<PartyInvite>
	return inviteReceivedSignal
end

function Party.getInviteExpiredSignal(): Signal.Signal<PartyInvite>
	return inviteExpiredSignal
end

function Party.start()
	remotes.PartyUpdate.OnClientEvent:Connect(onPartyUpdate)
	remotes.PartyRequest:FireServer({ type = "subscribe" })
end

return Party
