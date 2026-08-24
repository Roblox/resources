-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Constants = require(ServerScriptService.Core.Systems.RoundServer.Constants)
local Types = require(ServerScriptService.Core.Systems.RoundServer.Types)
local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)

local DEFAULT_TEAM_SPAWN_ORIGIN = CFrame.new(0, 5, 0)
local TEAM_SPAWN_OFFSET_RANGE_XZ = 24
local GENERATED_SPAWN_ATTRIBUTE = "isGeneratedSpawn"

local random = Random.new()
local teamsData: { [string]: Types.TeamData } = {}

local TeamHandler = {}

local function generateRandomTeamSpawnOffset(): Vector3
	local offsetX = random:NextInteger(-TEAM_SPAWN_OFFSET_RANGE_XZ, TEAM_SPAWN_OFFSET_RANGE_XZ)
	local offsetZ = random:NextInteger(-TEAM_SPAWN_OFFSET_RANGE_XZ, TEAM_SPAWN_OFFSET_RANGE_XZ)
	return Vector3.new(offsetX, 0, offsetZ)
end

local function formatTeamName(teamName: string): string
	if teamName:match(Constants.TEAM_TAG_STRING_MATCH) then
		return teamName
	else
		return teamName .. Constants.TEAM_TAG_STRING_MATCH
	end
end

function TeamHandler.clearTeamData(team: string): ()
	local teamName = formatTeamName(team)
	local teamData = teamsData[teamName]
	assert(teamData, `Attempted to clear data for unregistered team {teamName}.`)

	disconnectAndClear(teamData.teamConnections)

	local teamMembers = TeamHandler.getTeamMembers(teamName)
	for i = #teamMembers, 1, -1 do
		local teamMember = teamMembers[i]
		TeamHandler.removeFromTeam(teamMember)
	end

	local spawnLocation = teamData.teamSpawnLocation
	if spawnLocation and spawnLocation:GetAttribute(GENERATED_SPAWN_ATTRIBUTE) then
		spawnLocation:Destroy()
	end

	teamData.teamSpawnLocation = nil
	teamsData[teamName] = nil
end

function TeamHandler.clearAllTeamsData(): ()
	for team in teamsData do
		TeamHandler.clearTeamData(team)
	end
end

function TeamHandler.setTeamSpawnLocation(team: string, spawnLocation: PVInstance): ()
	local teamName = formatTeamName(team)
	local teamData = teamsData[teamName]
	assert(teamData, `Attempted to set spawn location for unregistered team {teamName}.`)

	teamData.teamSpawnLocation = spawnLocation
end

function TeamHandler.getTeamSpawnLocation(team: string): PVInstance
	local teamName = formatTeamName(team)
	local teamData = teamsData[teamName]
	assert(teamData, `Attempted to get spawn location for unregistered team {teamName}.`)

	if teamData.teamSpawnLocation then
		return teamData.teamSpawnLocation
	end

	-- Generate new spawn location if one doesn't exist
	warn(`Spawn location not found for team {teamName}. Generating spawn location.`)
	local spawnLocation = Instance.new("Part")
	spawnLocation.Name = `{teamName}TeamSpawn`
	spawnLocation.Material = Enum.Material.Neon
	spawnLocation.CanCollide = false
	spawnLocation.Size = Vector3.one
	spawnLocation.Transparency = 0
	spawnLocation.Anchored = true
	spawnLocation:SetAttribute(GENERATED_SPAWN_ATTRIBUTE, true)
	spawnLocation:PivotTo(DEFAULT_TEAM_SPAWN_ORIGIN + generateRandomTeamSpawnOffset())
	spawnLocation.Parent = Workspace
	teamData.teamSpawnLocation = spawnLocation

	return spawnLocation
end

function TeamHandler.teleportToTeamSpawn(participant: Types.Participant): ()
	local team = participant:GetAttribute(Constants.TEAM_ATTRIBUTE) :: string?
	assert(team, `Attempted to teleport participant with no team attribute: {participant.Name}.`)

	local teamSpawn = TeamHandler.getTeamSpawnLocation(team)
	local participantHeight = participant:GetExtentsSize().Y
	local heightOffset = Vector3.yAxis * participantHeight / 2

	participant:PivotTo(teamSpawn:GetPivot() + heightOffset)
end

function TeamHandler.registerTeam(team: string): ()
	local teamName = formatTeamName(team)
	assert(not teamsData[teamName], `Attempted to register team with existing team name: {teamName}.`)

	local teamConnections = {}
	teamsData[teamName] = {
		teamConnections = teamConnections,
		teamSpawnLocation = nil,
		teamMembers = {},
		teamName = teamName,
	}

	table.insert(
		teamConnections,
		CollectionService:GetInstanceRemovedSignal(teamName):Connect(function(instance)
			assert(instance:IsA("Model"), `Team member must be a Model!`)
			TeamHandler.removeFromTeam(instance)
		end)
	)
	table.insert(
		teamConnections,
		CollectionService:GetInstanceAddedSignal(teamName):Connect(function(instance)
			assert(instance:IsA("Model"), `Team member must be a Model!`)
			TeamHandler.addToTeam(instance, teamName)
		end)
	)

	for _, instance in CollectionService:GetTagged(teamName) do
		assert(instance:IsA("Model"), `Team member must be a Model!`)
		TeamHandler.addToTeam(instance, teamName)
	end
end

function TeamHandler.getTeamData(team: string): Types.TeamData?
	local teamName = formatTeamName(team)
	return teamsData[teamName]
end

function TeamHandler.getTeamMembers(team: string): { Types.Participant }
	local teamName = formatTeamName(team)
	local teamData = teamsData[teamName]
	assert(teamData, `Attempted to get team members for unregistered team {teamName}.`)

	return teamData.teamMembers
end

function TeamHandler.getTeamMembersCount(team: string): number
	local teamName = formatTeamName(team)
	return #TeamHandler.getTeamMembers(teamName)
end

function TeamHandler.isParticipantInTeam(participant: Types.Participant, team: string): boolean
	local teamName = formatTeamName(team)
	local teamData = teamsData[teamName]
	assert(teamData, `Attempted to check if participant is in unregistered team {teamName}.`)
	return table.find(teamData.teamMembers, participant) ~= nil
end

function TeamHandler.addToTeam(participant: Types.Participant, team: string): ()
	local teamName = formatTeamName(team)
	local teamData = teamsData[teamName]
	assert(teamData, `Attempted to add participant to unregistered team {teamName}.`)

	if TeamHandler.isParticipantInTeam(participant, teamName) then
		return
	end

	table.insert(teamData.teamMembers, participant)
	participant:SetAttribute(Constants.TEAM_ATTRIBUTE, teamName)
	participant:AddTag(teamName)
end

function TeamHandler.removeFromTeam(participant: Types.Participant): ()
	local team = participant:GetAttribute(Constants.TEAM_ATTRIBUTE) :: string?
	assert(team, `Attempted to remove participant with no team attribute: {participant.Name}.`)

	local teamName = formatTeamName(team)
	local teamData = teamsData[teamName]
	assert(teamData, `Attempted to remove participant from unregistered team {teamName}.`)

	local teamMemberIndex = table.find(teamData.teamMembers, participant)
	if teamMemberIndex then
		table.remove(teamData.teamMembers, teamMemberIndex)
		participant:SetAttribute(Constants.TEAM_ATTRIBUTE, nil)
		participant:RemoveTag(teamName)
	end
end

function TeamHandler.getParticipantTeam(participant: Types.Participant): string?
	return participant:GetAttribute(Constants.TEAM_ATTRIBUTE) :: string?
end

return TeamHandler
