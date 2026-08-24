-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

type Callback<T...> = (T...) -> ()

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: Callback<T...>) -> () -> (),
	Once: (self: Signal<T...>, callback: Callback<T...>) -> () -> (),
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

local Signal = {}

function Signal.create<T...>(): Signal<T...>
	local callbacks: { Callback<T...> } = {}
	local onceCallbacks: { Callback<T...> } = {}

	local signal = {} :: Signal<T...>

	local function register(callback: Callback<T...>, tbl: { Callback<T...> }): () -> ()
		table.insert(tbl, callback)
		return function()
			local index = table.find(tbl, callback)
			if index then
				table.remove(tbl, index)
			end
		end
	end

	function signal:Connect(callback: Callback<T...>): () -> ()
		return register(callback, callbacks)
	end

	function signal:Once(callback: Callback<T...>): () -> ()
		return register(callback, onceCallbacks)
	end

	function signal:Wait(): T...
		local running = coroutine.running()

		self:Once(function(...)
			coroutine.resume(running, ...)
		end)

		return coroutine.yield()
	end

	function signal:Fire(...: T...)
		for _, callback in callbacks do
			task.spawn(callback, ...)
		end

		for _, callback in onceCallbacks do
			task.spawn(callback, ...)
		end
		table.clear(onceCallbacks)
	end

	function signal:DisconnectAll()
		table.clear(callbacks)
		table.clear(onceCallbacks)
	end

	return signal
end

return Signal
