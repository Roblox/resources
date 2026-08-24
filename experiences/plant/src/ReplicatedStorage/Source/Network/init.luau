--!strict

--[[
	Provides functions to handle networking calls by remote name,
	handling all the creation of remote instances itself.
	Enforces argument type checking on all remote signal receivers.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RemoteEventName = require(script.RemoteName.RemoteEventName)
local RemoteFunctionName = require(script.RemoteName.RemoteFunctionName)
local createRemotesFolders = require(ReplicatedStorage.Source.Utility.Network.createRemotesFolders)
local waitForAllRemotesAsync = require(ReplicatedStorage.Source.Utility.Network.waitForAllRemotesAsync)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)
local t = require(ReplicatedStorage.Dependencies.t)

local REMOTE_REPLICATION_TIMEOUT_SECONDS = 2
local REMOTE_FOLDER_PARENT = ReplicatedStorage
local REMOTE_FOLDER_NAME = "Remotes"

type TypeValidator = (...any) -> (boolean, string?)

local Network = {}
Network.t = t
Network.RemoteEvents = RemoteEventName
Network.RemoteFunctions = RemoteFunctionName
Network._started = false
Network._remoteFolder = nil :: Folder?

function Network.startServer()
	assert(RunService:IsServer(), "Network.startServer can only be called on the server")
	assert(not Network._started, "Network.startServer has already been called")
	Network._started = true

	local remoteFolder = createRemotesFolders(REMOTE_FOLDER_NAME)

	remoteFolder.Parent = REMOTE_FOLDER_PARENT
	Network._remoteFolder = remoteFolder
end

function Network.startClientAsync()
	assert(RunService:IsClient(), "Network.startClientAsync can only be called on the client")
	assert(not Network._started, "Network.startClientAsync has already been called")
	Network._started = true

	local remoteFolder =
		REMOTE_FOLDER_PARENT:WaitForChild(REMOTE_FOLDER_NAME, REMOTE_REPLICATION_TIMEOUT_SECONDS) :: Folder

	assert(
		remoteFolder,
		string.format(
			"Missing remoteFolder folder %s. Did the client Network module initialize before the server?",
			REMOTE_FOLDER_NAME
		)
	)

	waitForAllRemotesAsync(remoteFolder, REMOTE_REPLICATION_TIMEOUT_SECONDS)

	Network._remoteFolder = remoteFolder
end

function Network.connectEvent(
	eventName: RemoteEventName.EnumType,
	callback: (...any) -> nil,
	typeValidator: TypeValidator
)
	local remoteEvent = Network._getRemoteEvent(eventName)

	if RunService:IsServer() then
		return remoteEvent.OnServerEvent:Connect(t.wrap(callback, typeValidator))
	else
		return remoteEvent.OnClientEvent:Connect(t.wrap(callback, typeValidator))
	end
end

function Network.bindFunction(
	functionName: RemoteFunctionName.EnumType,
	callback: (...any) -> ...any,
	typeValidator: TypeValidator
)
	local remoteFunction = Network._getRemoteFunction(functionName)

	if RunService:IsServer() then
		remoteFunction.OnServerInvoke = t.wrap(callback, typeValidator)
	else
		remoteFunction.OnClientInvoke = t.wrap(callback, typeValidator)
	end
end

function Network.fireServer(eventName: RemoteEventName.EnumType, ...: any)
	assert(RunService:IsClient(), "Network.fireServer can only be called on the client")

	local remoteEvent = Network._getRemoteEvent(eventName)
	remoteEvent:FireServer(...)
end

function Network.fireClient(eventName: RemoteEventName.EnumType, player: Player, ...: any)
	assert(RunService:IsServer(), "Network.fireClient can only be called on the server")

	local remoteEvent = Network._getRemoteEvent(eventName)
	remoteEvent:FireClient(player, ...)
end

function Network.fireAllClients(eventName: RemoteEventName.EnumType, ...: any)
	assert(RunService:IsServer(), "Network.fireAllClients can only be called on the server")

	local remoteEvent = Network._getRemoteEvent(eventName)
	remoteEvent:FireAllClients(...)
end

function Network.fireAllClientsExcept(eventName: RemoteEventName.EnumType, excludePlayer: Player, ...: any)
	assert(RunService:IsServer(), "Network.fireAllClientsExcept can only be called on the server")

	local remoteEvent = Network._getRemoteEvent(eventName)

	for _, player in ipairs(Players:GetPlayers()) do
		if player == excludePlayer then
			continue
		end

		remoteEvent:FireClient(player, ...)
	end
end

function Network.invokeServerAsync(functionName: RemoteFunctionName.EnumType, ...: any): (boolean, ...any)
	assert(RunService:IsClient(), "Network.invokeServerAsync can only be called on the client")

	local remoteFunction = Network._getRemoteFunction(functionName)

	return pcall(remoteFunction.InvokeServer, remoteFunction, ...)
end

function Network.invokeClientAsync(
	functionName: RemoteFunctionName.EnumType,
	player: Player,
	...: any
): (boolean, ...any)
	assert(RunService:IsServer(), "Network.invokeClientAsync can only be called on the server")

	local remoteFunction = Network._getRemoteFunction(functionName)

	return pcall(remoteFunction.InvokeClient, remoteFunction, player, ...)
end

function Network._getRemoteEvent(eventName: RemoteEventName.EnumType)
	assert(Network._remoteFolder, "Network setup not complete")

	local remoteEvent: RemoteEvent = getInstance(Network._remoteFolder, "RemoteEvents", eventName)

	return remoteEvent
end

function Network._getRemoteFunction(functionName: RemoteFunctionName.EnumType)
	assert(Network._remoteFolder, "Network setup not complete")

	local remoteFunction: RemoteFunction = getInstance(Network._remoteFolder, "RemoteFunctions", functionName)

	return remoteFunction
end

return Network
