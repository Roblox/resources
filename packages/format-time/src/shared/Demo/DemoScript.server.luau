--[[
	Formats a number of seconds into a pretty string of Hours, Minutes, and Seconds.
	If all hours are 0, they are omitted. If all hours and all minutes are 0, they are both omitted.
	Leading 0's from hours are removed. If hours are omitted, leading 0's from minutes are removed.
	If hours and minutes are omitted, leading 0's from seconds are removed.

	The DemoScript uses formatTime to display a timer that rapidly increases on a Part.
--]]

local formatTime = require(script.Parent.Parent.formatTime)

local timerDisplay = script.Parent.TimerDisplay
local timerTextLabel = timerDisplay.SurfaceGui.TextLabel
local timerTimeSec = 0

-- Update the TextLabel's text using formatTime
-- 86400 = 24 hours (max supported time)
while timerTimeSec < 86400 do
	timerTextLabel.Text = formatTime(timerTimeSec)
	task.wait()
	timerTimeSec = timerTimeSec + 1
end
