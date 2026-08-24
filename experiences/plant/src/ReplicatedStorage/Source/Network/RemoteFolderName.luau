--!strict

--[[
	Specifies the names of the RemoteEvent and RemoteFunction folders used by createRemotesFolders
	and waitForAllRemotesAsync
--]]

export type EnumType = "RemoteEvents" | "RemoteFunctions"

local RemoteFolderName = {
	RemoteEvents = "RemoteEvents" :: "RemoteEvents",
	RemoteFunctions = "RemoteFunctions" :: "RemoteFunctions",
}

return RemoteFolderName
