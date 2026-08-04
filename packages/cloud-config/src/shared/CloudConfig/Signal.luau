--!strict

type CallbackFunction = (...any) -> ...any

local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = {
		_callbacks = {},
		_waitingThreads = {},
	}

	setmetatable(self, Signal)

	return self
end

function Signal:Fire(...)
	for _, callback in self._callbacks do
		task.spawn(callback, ...)
	end

	for _, thread in self._waitingThreads do
		task.spawn(thread, ...)
	end
	table.clear(self._waitingThreads)
end

function Signal:Connect(callback: CallbackFunction)
	table.insert(self._callbacks, callback)

	local connection = {
		Connected = true,
		Disconnect = function(connectionSelf)
			connectionSelf.Connected = false
			local index = table.find(self._callbacks, callback)
			if index then
				table.remove(self._callbacks, index)
			end
		end,
	}

	return connection
end

function Signal:Once(callback: CallbackFunction)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)

	return connection
end

function Signal:Wait()
	local thread = coroutine.running()
	table.insert(self._waitingThreads, thread)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self._callbacks)
	for _, thread in self._waitingThreads do
		task.spawn(thread)
	end
	table.clear(self._callbacks)
end

return Signal
