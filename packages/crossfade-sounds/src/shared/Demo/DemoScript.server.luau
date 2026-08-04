--[[
	Crossfading is an audio editing technique that creates a smooth transition between two audio clips.
	Demonstrates crossfading between two sounds indefinitely.
--]]

local crossfadeAsync = require(script.Parent.Parent.crossfadeAsync)

local FADE_TIME = 4
local VOLUME = 1

local sounds = script.Parent.Sounds
local rainSound = sounds.RainSound
local cricketSound = sounds.CricketSound

local function initializeSounds()
	-- Start with the rain sound playing
	rainSound.Volume = VOLUME
	cricketSound.Volume = 0

	rainSound:Play()
	cricketSound:Play()
end

initializeSounds()

while true do
	-- Wait some time, then crossfade to the cricket sound
	task.wait(5)
	crossfadeAsync(rainSound, cricketSound, FADE_TIME, VOLUME)

	-- Wait some time, then crossfade to the rain sound
	task.wait(5)
	crossfadeAsync(cricketSound, rainSound, FADE_TIME, VOLUME)
end
