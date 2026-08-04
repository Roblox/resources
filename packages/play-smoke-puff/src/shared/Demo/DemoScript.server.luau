--[[
	Plays a particle animation of a puff of smoke at the location, volume, and size of a given part.
--]]

local playSmokePuff = require(script.Parent.Parent.playSmokePuff)

local smokePuffParts = script.Parent.SmokePuffParts

while true do
	for _, part in pairs(smokePuffParts:GetChildren()) do
		playSmokePuff(part)
		task.wait(1)
	end
end
