--!strict

local Loop = require(script.Loop)

local LeaderElection = {
	_loops = {} :: { [string]: any },
}

function LeaderElection.startLoop(id: string, interval: number, updateFunction: (number) -> ())
	assert(not LeaderElection._loops[id], string.format("Loop already registered with id: %s", id))

	local loop = Loop.new(id, interval, updateFunction) :: any
	LeaderElection._loops[id] = loop

	loop:start()
end

return LeaderElection
