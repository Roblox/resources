--[[
	Takes a table of connections and then disconnects them when prompted.

	A more lightweight version of the common Maid pattern in Roblox:

	https://github.com/Quenty/NevermoreEngine/blob/version2/Modules/Shared/Events/Maid.lua
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Source.Signal)

type EitherConnection = RBXScriptConnection & Signal.SignalConnection

local Connections = {}
Connections.__index = Connections

export type ClassType = typeof(setmetatable(
	{} :: {
		_connections: { EitherConnection },
	},
	Connections
))

function Connections.new(): ClassType
	local self = {
		_connections = {},
	}
	setmetatable(self, Connections)

	return self
end

function Connections.add(self: ClassType, ...: EitherConnection)
	for _, connection in { ... } do
		assert(not table.find(self._connections, connection), "This connection has already been added")
		table.insert(self._connections, connection)
	end
end

function Connections.remove(self: ClassType, connection: EitherConnection)
	local index = table.find(self._connections, connection)
	if index then
		table.remove(self._connections, index)
	end
end

function Connections.disconnect(self: ClassType)
	for _, connection in self._connections do
		connection:Disconnect()
	end

	self._connections = {}
end

return Connections
