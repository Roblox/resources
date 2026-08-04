--!strict

local LightingPresets = require(script.Parent.Parent.LightingPresets)
local presets = script.Parent.Presets

local TWEEN_TIME = 3 -- Time to tween to each preset
local INTERVAL_TIME = 3 -- Time between each preset
local EASING_STYLE = Enum.EasingStyle.Quad
local EASING_DIRECTION = Enum.EasingDirection.InOut

-- Presets are stored as Configuration objects rather than Folders to create
-- the distinction of 'useful object' vs purely organizational
local PRESETS: { Configuration } = {
	presets.Dawn,
	presets.Midday,
	presets.Dusk,
	presets.Night,
}

local presetIndex = 1

local function initialize()
	-- Initialize lighting to the current presetIdnex
	LightingPresets.setLighting(PRESETS[presetIndex])

	task.spawn(function()
		-- Loop through the PRESETS list to create a day/night cycle
		while true do
			presetIndex += 1
			if presetIndex > #PRESETS then
				presetIndex = 1
			end

			LightingPresets.tweenLightingAsync(PRESETS[presetIndex], TWEEN_TIME, EASING_STYLE, EASING_DIRECTION)
			task.wait(INTERVAL_TIME)
		end
	end)
end

initialize()
