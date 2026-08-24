--!strict

--[[
	Creates folders for RemoteFunctions and RemoteEvents used by
	Network. These folders are then populated with new RemoteEvents
	and RemoteFunctions for each name specified in the RemoteNames constants module.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)
local RemoteFunctionName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteFunctionName)
local RemoteFolderName = require(ReplicatedStorage.Source.Network.RemoteFolderName)
local createInstanceTree = require(ReplicatedStorage.Source.Utility.createInstanceTree)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

type PropertiesTable = { [string]: any }

local function createRemotes(remoteFolder: Folder)
	local remoteEventsFolder: Folder = getInstance(remoteFolder, RemoteFolderName.RemoteEvents)

	for eventName in pairs(RemoteEventName) do
		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = remoteEventsFolder
	end

	local remoteFunctionsFolder: Folder = getInstance(remoteFolder, RemoteFolderName.RemoteFunctions)

	for functionName in pairs(RemoteFunctionName) do
		local remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = functionName
		remoteFunction.Parent = remoteFunctionsFolder
	end
end

local function createRemotesFolders(rootFolderName: string): Folder
	local folder = createInstanceTree({
		className = "Folder",
		properties = {
			Name = rootFolderName,
		},
		children = {
			{
				className = "Folder",
				properties = {
					Name = RemoteFolderName.RemoteFunctions,
				} :: PropertiesTable,
			},
			{
				className = "Folder",
				properties = {
					Name = RemoteFolderName.RemoteEvents,
				} :: PropertiesTable,
			},
		},
	})

	createRemotes(folder)

	return folder
end

return createRemotesFolders
