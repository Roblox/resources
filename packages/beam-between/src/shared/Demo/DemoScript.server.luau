--[[
	Given two attachments and a beam prefab, this class continuously orients duplicates of the attachments to face each other so that the beam remains straight.
	Also provides an API to enable/disable the beam and its orientation updates.
--]]

local BeamBetween = require(script.Parent.Parent.BeamBetween)

local Instances = script.Parent.Instances
local beam = Instances.Beam
local swingingPart1 = Instances:WaitForChild("SwingingPart1")
local swingingPart2 = Instances:WaitForChild("SwingingPart2")
local attachment0 = swingingPart1.Part.BeamAttachment
local attachment1 = swingingPart2.Part.BeamAttachment

-- Create an instance of BeamBetween
local beamBetween = BeamBetween.new(attachment0, attachment1, beam)

-- Toggle enabling the beam in a loop
while true do
	beamBetween.setEnabled(beamBetween, true)
	task.wait(3)
	beamBetween.setEnabled(beamBetween, false)
	task.wait(3)
end
