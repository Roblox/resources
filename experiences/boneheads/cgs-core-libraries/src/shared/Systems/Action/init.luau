-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(script.Types)

local Remotes = script.Remotes

local isServer = RunService:IsServer()

local actions: { [Types.ActionName]: Types.Action<any> } = {}

local Action = {}

local function getActionFromName(actionName: Types.ActionName): Types.Action<any>
	local action: Types.Action<any> = actions[actionName]
	assert(action, `No action found for name: {actionName}`)
	return action
end

local function executeAction<T>(action: Types.Action<T>, params: T)
	if action.execute then
		action.execute(params)
	end
end

local function replicateTrigger(
	actionName: Types.ActionName,
	params: any,
	replicates: Types.RemoteType?,
	originatingPlayer: Player?
)
	if not replicates then
		return
	end

	if isServer then
		for _, player in Players:GetPlayers() do
			if player == originatingPlayer then
				continue
			end

			if replicates == "Reliable" then
				Remotes.TriggerActionReliable:FireClient(player, actionName, params)
			elseif replicates == "Unreliable" then
				Remotes.TriggerActionUnreliable:FireClient(player, actionName, params)
			end
		end
	else
		if replicates == "Reliable" then
			Remotes.TriggerActionReliable:FireServer(actionName, params)
		elseif replicates == "Unreliable" then
			Remotes.TriggerActionUnreliable:FireServer(actionName, params)
		end
	end
end

local function onTriggerAction<T>(player: Player?, actionName: Types.ActionName, params: T)
	local action: Types.Action<T> = getActionFromName(actionName)

	if isServer then
		assert(player ~= nil, "Player cannot be nil in onTriggerAction on the server")
		assert(action.validate ~= nil, "Action validate function cannot be nil on the server")

		if not action.validate(player, params) then
			warn(`Player {player.Name} failed validation for action {actionName}`)
			return
		end
	end

	executeAction(action, params)

	if isServer then
		replicateTrigger(actionName, params, action.replicates, player)
	end
end

function Action.trigger<T>(actionName: Types.ActionName, params: T)
	local action: Types.Action<T> = getActionFromName(actionName)

	executeAction(action, params)

	replicateTrigger(actionName, params, action.replicates)
end

local function validateActionDefinition(actionName: Types.ActionName, definition: Types.ActionDefinition)
	assert(actions[actionName] == nil, `Duplicate action name: {actionName}`)
	assert(
		definition.client ~= nil or definition.server ~= nil,
		`Action definition for {actionName} must have a client or server function`
	)
	assert(
		definition.replicateToServer ~= nil or definition.replicateToClient ~= nil,
		`Action definition for {actionName} must have server or client replication defined`
	)
	assert(
		not definition.replicateToClient or definition.client,
		`Action definition for {actionName} cannot replicate to client without a client function`
	)
	assert(
		not (definition.replicateToServer and not (definition.server or definition.replicateToClient)),
		`Action definition for {actionName} cannot replicate to server without a server function or client replication`
	)
	assert(definition.validate, `Action definition for {actionName} is missing a validate function`)
end

function Action.autoLoad(target: Instance)
	local actionDefinitions: { [Types.ActionName]: Types.ActionDefinition } = {}

	for _, module in target:QueryDescendants("ModuleScript") :: { ModuleScript } do
		local actionName = module.Name
		local definition: Types.ActionDefinition = require(module) :: any

		actionDefinitions[actionName] = definition
	end

	for actionName, definition in actionDefinitions do
		if isServer then
			validateActionDefinition(actionName, definition)
		end

		local action: Types.Action<any> = {
			execute = if isServer and definition.server
				then require(definition.server) :: any
				elseif not isServer and definition.client then require(definition.client) :: any
				else nil,
			validate = if isServer then require(definition.validate) :: any else nil,
			replicates = if isServer then definition.replicateToClient else definition.replicateToServer,
		}
		actions[actionName] = action
	end
end

function Action.start()
	if isServer then
		Remotes.TriggerActionReliable.OnServerEvent:Connect(onTriggerAction)
		Remotes.TriggerActionUnreliable.OnServerEvent:Connect(onTriggerAction)
	else
		Remotes.TriggerActionReliable.OnClientEvent:Connect(function(actionName: Types.ActionName, params: any)
			onTriggerAction(nil, actionName, params)
		end)
		Remotes.TriggerActionUnreliable.OnClientEvent:Connect(function(actionName: Types.ActionName, params: any)
			onTriggerAction(nil, actionName, params)
		end)
	end
end

return Action
