--!strict

--[[
	Calls the provided handler when any of the provided signals are fired.
	Returns an array of the connections made.

	Example usage:
		local handler = print

		local connections = connectAll(
			{signalA, signalB},
			handler
		)

		eventA:Fire("1 Hello,", "world!")
		eventB:Fire("2 foo", "bar")

		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

	Output:
		1 Hello, world!
		2 foo bar
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Source.Signal)

type Handler = (...any) -> ...any

local function connectAll(signals: { RBXScriptSignal | Signal.ClassType }, handler: Handler)
	local connections: { RBXScriptConnection | Signal.SignalConnection } = {}

	for _, signal in ipairs(signals) do
		local connection: RBXScriptConnection | Signal.SignalConnection = (signal :: any):Connect(handler)
		table.insert(connections, connection)
	end

	return connections
end

return connectAll
