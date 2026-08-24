--!strict

--[[
	Wait in parallel for all RemoteEvents and RemoteFunctions defined in RemoteNames to
	replicate into the remoteFolder.

	Used to ensure all remotes exist before the client Network module finishes initializing.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.Dependencies.Freeze)
local RemoteEventName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteEventName)
local RemoteFunctionName = require(ReplicatedStorage.Source.Network.RemoteName.RemoteFunctionName)
local RemoteFolderName = require(ReplicatedStorage.Source.Network.RemoteFolderName)

local function waitForAllRemotesAsync(remoteFolder: Instance, timeoutSeconds: number)
	-- Using FindFirstChild to satisfy the type checker
	local remoteEventsFolder = remoteFolder:FindFirstChild(RemoteFolderName.RemoteEvents) :: Folder
	local remoteFunctionsFolder = remoteFolder:FindFirstChild(RemoteFolderName.RemoteFunctions) :: Folder

	local remoteEvents: { string } = Freeze.Dictionary.values(RemoteEventName)
	local remoteFunctions: { string } = Freeze.Dictionary.values(RemoteFunctionName)

	-- Validate that the remotes defined under RemoteNames exist in remote folders
	local success = true
	local function search(names: { string }, folder: Folder)
		for _, remoteName in ipairs(names) do
			local remote = folder:WaitForChild(remoteName, timeoutSeconds)
			if not remote then
				success = false
				break
			end
		end
	end

	search(remoteEvents, remoteEventsFolder)
	search(remoteFunctions, remoteFunctionsFolder)

	assert(success, "Network could not find all remotes. Did the client Network module initialize before the server?")
end

return waitForAllRemotesAsync
