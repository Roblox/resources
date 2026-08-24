-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PartyConstants = require(ReplicatedStorage.Core.Systems.Party.Constants)
local ServerTypes = require(script.Types)
local Signal = require(ReplicatedStorage.Core.Libraries.Signal)
local Types = require(ReplicatedStorage.Core.Systems.Party.Types)

local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)
local makeBaseParty = require(ReplicatedStorage.Core.Systems.Party.Utility.makeBaseParty)
local validateInstance = require(ServerScriptService.Core.Validation.validateInstance)
local validateString = require(ServerScriptService.Core.Validation.validateString)

local remotes = ReplicatedStorage.Core.Systems.Party.Remotes

export type Party = Types.Party
export type PartyCompact = Types.PartyCompact
export type PartyUpdate = Types.PartyUpdate
export type PartyRequest = Types.PartyRequest
export type ServerParty = ServerTypes.ServerParty
export type ServerPartyParams = ServerTypes.ServerPartyParams

local partyByIds: { [string]: ServerParty } = {}
local activePlayers: { [Player]: boolean } = {} -- Tracks players who is subscribed to party updates
local inviteExpirationDuration = PartyConstants.DEFAULT_INVITE_EXPIRATION_DURATION

local PartyServer = {
	partyAdded = Signal.create(),
	partyRemoved = Signal.create(),
}

local function makePartyCompact(party: ServerParty): PartyCompact
	local leaderId = if party.leader then party.leader.UserId else party.expectedLeaderId
	local memberIds: { number } = {}

	for _, member in party.getMembers() do
		table.insert(memberIds, member.UserId)
	end

	return {
		id = party.id,
		leaderId = leaderId,
		memberIds = memberIds,
		maxSize = party.maxSize,
	}
end

local function replicatePartyUpdate(player: Player, update: PartyUpdate)
	if not activePlayers[player] then
		return
	end

	remotes.PartyUpdate:FireClient(player, update)
end

local function replicatePartyJoined(player: Player, party: ServerParty)
	replicatePartyUpdate(player, {
		type = "joined",
		party = makePartyCompact(party),
	})
	replicatePartyUpdate(player, {
		type = "readyChanged",
		readyMembers = party.getReadyMembers(),
	})
end

local function makeServerParty(params: ServerPartyParams): ServerParty
	local party = makeBaseParty(params.id, params.leader, params.maxSize) :: ServerParty
	local baseCleanup = party.cleanup

	local id = params.id
	local maxSize = params.maxSize

	party.expectedLeaderId = params.expectedLeaderId or -1
	party.expectedMemberIds = params.expectedMemberIds

	local members = party.members
	local readyMembers = party.readyMembers

	local pendingInvites: { Player } = {}
	local pendingInviteExpirations: { [Player]: thread } = {}
	local connections: { RBXScriptConnection } = {}

	local hasFiredAssembled = false
	party.assembled = Signal.create()

	local function broadcastToMembers(update: PartyUpdate)
		for _, member in members do
			replicatePartyUpdate(member, update)
		end
	end

	local function replicateMembersChanged()
		broadcastToMembers({
			type = "membersChanged",
			members = members,
		})
	end

	local function replicateLeaderChanged()
		local leader = party.leader
		assert(leader, `Cannot replicate leaderChanged: party {id} has no leader`)
		broadcastToMembers({
			type = "leaderChanged",
			leader = leader,
		})
	end

	local function replicateReadyChanged()
		broadcastToMembers({
			type = "readyChanged",
			readyMembers = readyMembers,
		})
	end

	-- For cross experience teleporting, to know if all party members have arrived
	function party.isAssembled(): boolean
		return #party.expectedMemberIds == 0
	end

	function party.hasPendingInvite(player: Player): boolean
		return table.find(pendingInvites, player) ~= nil
	end

	function party.addMember(player: Player)
		if #members >= maxSize then
			return
		end

		if table.find(members, player) then
			return
		end

		player:SetAttribute(PartyConstants.PARTY_ID_ATTRIBUTE, id)
		table.insert(members, player)

		local pendingIndex = table.find(pendingInvites, player)
		if pendingIndex then
			table.remove(pendingInvites, pendingIndex)
		end

		local inviteTimer = pendingInviteExpirations[player]
		if inviteTimer then
			task.cancel(inviteTimer)
			pendingInviteExpirations[player] = nil
		end

		local expectedIndex = table.find(party.expectedMemberIds, player.UserId)
		if expectedIndex then
			table.remove(party.expectedMemberIds, expectedIndex)
		end

		local claimedLeader = false
		if not party.leader and (party.expectedLeaderId == -1 or party.expectedLeaderId == player.UserId) then
			party.leader = player
			party.expectedLeaderId = -1
			claimedLeader = true
		end

		replicatePartyJoined(player, party)

		for _, member in members do
			if member ~= player then
				replicatePartyUpdate(member, {
					type = "membersChanged",
					members = members,
				})
			end
		end

		if claimedLeader and #members > 1 then
			replicateLeaderChanged()
		end

		if not hasFiredAssembled and #party.expectedMemberIds == 0 then
			hasFiredAssembled = true
			party.assembled:Fire()
		end
	end

	function party.removeMember(player: Player)
		local index = table.find(members, player)
		if not index then
			return
		end

		table.remove(members, index)
		player:SetAttribute(PartyConstants.PARTY_ID_ATTRIBUTE, nil)

		local expectedIndex = table.find(party.expectedMemberIds, player.UserId)
		if expectedIndex then
			table.remove(party.expectedMemberIds, expectedIndex)
		end

		local readyIndex = table.find(readyMembers, player)
		if readyIndex then
			table.remove(readyMembers, readyIndex)
			replicateReadyChanged()
		end

		if party.leader == player then
			party.leader = members[1]
			if party.leader then
				replicateLeaderChanged()
			end
		end

		replicatePartyUpdate(player, { type = "left" })
		replicateMembersChanged()
	end

	function party.setLeader(player: Player)
		if not table.find(members, player) then
			return
		end

		if party.leader == player then
			return
		end

		party.leader = player
		replicateLeaderChanged()
	end

	function party.setMemberReady(player: Player, ready: boolean)
		local index = table.find(readyMembers, player)
		if ready and not index then
			table.insert(readyMembers, player)
			replicateReadyChanged()
		elseif not ready and index then
			table.remove(readyMembers, index)
			replicateReadyChanged()
		end
	end

	function party.addPendingInvite(player: Player)
		if table.find(members, player) then
			return
		end

		local existingTimer = pendingInviteExpirations[player]
		if existingTimer then
			task.cancel(existingTimer)
			pendingInviteExpirations[player] = nil
		end

		if not table.find(pendingInvites, player) then
			table.insert(pendingInvites, player)
		end

		pendingInviteExpirations[player] = task.delay(inviteExpirationDuration, function()
			pendingInviteExpirations[player] = nil
			party.removePendingInvite(player)
			replicatePartyUpdate(player, {
				type = "inviteExpired",
				partyId = id,
			})
		end)
	end

	function party.removePendingInvite(player: Player)
		local index = table.find(pendingInvites, player)
		if index then
			table.remove(pendingInvites, index)
		end

		local timer = pendingInviteExpirations[player]
		if timer then
			task.cancel(timer)
			pendingInviteExpirations[player] = nil
		end
	end

	function party.cleanup()
		for _, member in members do
			replicatePartyUpdate(member, { type = "left" })
			member:SetAttribute(PartyConstants.PARTY_ID_ATTRIBUTE, nil)
		end

		table.clear(pendingInvites)

		for _, timer in pendingInviteExpirations do
			task.cancel(timer)
		end
		table.clear(pendingInviteExpirations)

		table.clear(party.expectedMemberIds)
		party.expectedLeaderId = -1

		disconnectAndClear(connections)
		party.assembled:DisconnectAll()

		baseCleanup()
	end

	return party
end

function PartyServer.createParty(leader: Player, maxSize: number?): ServerParty
	assert(not PartyServer.hasParty(leader), `Player {leader.Name} is already in a party`)

	local party = makeServerParty({
		id = HttpService:GenerateGUID(false),
		maxSize = maxSize or PartyConstants.DEFAULT_MAX_PARTY_SIZE,
		leader = leader,
		expectedLeaderId = nil,
		expectedMemberIds = {},
	})

	partyByIds[party.id] = party
	PartyServer.partyAdded:Fire(party)

	party.addMember(leader)

	return party
end

function PartyServer.removeParty(party: ServerParty)
	if partyByIds[party.id] then
		partyByIds[party.id] = nil
	end

	party.cleanup()
	PartyServer.partyRemoved:Fire(party)
end

function PartyServer.getPartyFromId(partyId: string): ServerParty?
	return partyByIds[partyId]
end

function PartyServer.getPlayerParty(player: Player): ServerParty?
	local partyId = player:GetAttribute(PartyConstants.PARTY_ID_ATTRIBUTE) :: string?
	return partyId and partyByIds[partyId]
end

function PartyServer.getParties(): { ServerParty }
	local result: { ServerParty } = {}

	for _, party in partyByIds do
		table.insert(result, party)
	end

	return result
end

function PartyServer.hasParty(player: Player): boolean
	return PartyServer.getPlayerParty(player) ~= nil
end

function PartyServer.isPartyMember(playerA: Player, playerB: Player): boolean
	local partyA = PartyServer.getPlayerParty(playerA)
	local partyB = PartyServer.getPlayerParty(playerB)
	return partyA ~= nil and partyA == partyB
end

function PartyServer.joinParty(player: Player, partyId: string)
	local party = PartyServer.getPartyFromId(partyId)
	local playerParty = PartyServer.getPlayerParty(player)

	assert(party, `Party {partyId} not found`)
	assert(not playerParty or playerParty == party, `Player {player.Name} is in a different party`)

	if playerParty == party then
		return
	end

	if party.getSize() >= party.maxSize then
		return
	end

	party.addMember(player)
end

function PartyServer.leaveParty(player: Player)
	local party = PartyServer.getPlayerParty(player)
	if party then
		party.removeMember(player)
	end
end

function PartyServer.invitePlayer(inviter: Player, target: Player)
	if inviter == target then
		return
	end

	if PartyServer.hasParty(target) then
		return
	end

	local party = PartyServer.getPlayerParty(inviter)
	assert(party, `Inviter player {inviter.Name} is not in a party`)

	party.addPendingInvite(target)
	replicatePartyUpdate(target, {
		type = "inviteReceived",
		partyId = party.id,
		fromPlayer = inviter,
	})
end

function PartyServer.declineInvite(player: Player, partyId: string)
	local party = PartyServer.getPartyFromId(partyId)
	if party then
		party.removePendingInvite(player)
	end
end

function PartyServer.kickPlayer(leader: Player, target: Player)
	if leader == target then
		return
	end

	local party = PartyServer.getPlayerParty(leader)
	assert(party, `Player {leader.Name} is not in a party`)

	if party.leader ~= leader then
		return
	end

	if not PartyServer.isPartyMember(leader, target) then
		return
	end

	party.removeMember(target)
end

function PartyServer.setInviteExpirationDuration(duration: number)
	inviteExpirationDuration = math.max(1, duration)
end

function PartyServer.serializeParty(party: ServerParty): PartyCompact
	return makePartyCompact(party)
end

function PartyServer.deserializeParty(partyCompact: PartyCompact): ServerParty
	assert(not PartyServer.getPartyFromId(partyCompact.id), `Party {partyCompact.id} already exists on this server`)

	local party = makeServerParty({
		id = partyCompact.id,
		maxSize = partyCompact.maxSize,
		leader = nil,

		expectedLeaderId = partyCompact.leaderId,
		expectedMemberIds = partyCompact.memberIds,
	})

	partyByIds[party.id] = party
	PartyServer.partyAdded:Fire(party)

	return party
end

local function onPartyRequest(player: Player, request: PartyRequest)
	if request.type == "subscribe" then
		activePlayers[player] = true
		local party = PartyServer.getPlayerParty(player)
		if party then
			replicatePartyJoined(player, party)
		end
	elseif request.type == "invite" then
		if not validateInstance(request.target, "Player") then
			return
		end

		if not PartyServer.hasParty(player) then
			return
		end

		-- TODO: Add permission modes for whether any member can invite, or only the leader can invite
		PartyServer.invitePlayer(player, request.target)
	elseif request.type == "decline" then
		if not validateString(request.partyId) then
			return
		end

		PartyServer.declineInvite(player, request.partyId)
	elseif request.type == "join" then
		if not validateString(request.partyId) then
			return
		end

		if PartyServer.hasParty(player) then
			return
		end

		local party = PartyServer.getPartyFromId(request.partyId)
		if party and party.hasPendingInvite(player) then
			PartyServer.joinParty(player, request.partyId)
		end
	elseif request.type == "leave" then
		if not PartyServer.hasParty(player) then
			return
		end

		PartyServer.leaveParty(player)
	elseif request.type == "kick" then
		if not validateInstance(request.target, "Player") then
			return
		end

		if not PartyServer.hasParty(player) then
			return
		end

		PartyServer.kickPlayer(player, request.target)
	elseif request.type == "setReady" then
		if typeof(request.ready) ~= "boolean" then
			return
		end

		local party = PartyServer.getPlayerParty(player)
		if not party then
			return
		end

		party.setMemberReady(player, request.ready)
	end
end

local function onPlayerRemoving(player: Player)
	activePlayers[player] = nil

	local party = PartyServer.getPlayerParty(player)
	if party then
		party.removeMember(player)
	end

	for _, existingParty in partyByIds do
		if existingParty.hasPendingInvite(player) then
			existingParty.removePendingInvite(player)
		end
	end
end

function PartyServer.start()
	remotes.PartyRequest.OnServerEvent:Connect(onPartyRequest)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return PartyServer
