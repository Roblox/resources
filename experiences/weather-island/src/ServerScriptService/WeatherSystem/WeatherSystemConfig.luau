--!strict

local WeatherSystemConfig = {

	-- Clock. Every duration below is in game hours. SECONDS_PER_GAME_HOUR is
	-- the only connection to real time, so dropping this number speeds up
	-- the whole schedule.
	SECONDS_PER_GAME_HOUR = 30, -- a full day runs 12 real minutes
	STARTING_CLOCK_TIME = 14, -- match to the TimeOfDay in the place file
	DRIVE_LIGHTING_CLOCK = true,

	-- Gaps, duration, and transitions
	MIN_TIME_BETWEEN_RAIN_HOURS = 12, -- set low for testing
	MAX_TIME_BETWEEN_RAIN_HOURS = 24 * 7, -- set low for testing
	MIN_RAIN_DURATION_HOURS = 4, -- set high for testing
	MAX_RAIN_DURATION_HOURS = 12, -- set high for testing
	-- Counted twice, once on the way in and once on the way out, so a storm is
	-- never shorter than 2x this value.
	RAIN_TRANSITION_HOURS = 2,

	-- Testing
	DEBUG_START_RAINING_IMMEDIATELY = true,

	-- Map and part size
	MAP_DIMENSIONS_X_STUDS = 2000,
	MAP_DIMENSIONS_Z_STUDS = 2000,
	MAP_CENTER_X_STUDS = 0,
	MAP_CENTER_Z_STUDS = 0,
	-- How much of the map to cover. This is per-axis, a square storm, so 50
	-- yields 25% of the map, 60 36% of the map, 80 64% of the map, and so on.
	RAIN_COVERAGE_PERCENTAGE = 40,
	RAIN_COVERAGE_Y_STUDS = 150, -- how high in the air to put the parts
	-- Square rain parts for simplicity. This is also the relative precision
	-- of roof detection since each part casts one ray downward.
	RAIN_PART_XZ_STUDS = 30,

	-- Particle properties
	-- Points each streak along its direction of travel, so it leans with the
	-- wind.
	RAIN_EMITTER_ORIENTATION = Enum.ParticleOrientation.VelocityParallel,
	-- Negative because of VelocityParallel above. Use a positive value if you
	-- switch to FacingCamera for some reason.
	RAIN_EMITTER_SQUASH = -3,
	RAIN_EMITTER_RESPECT_GLOBAL_WIND = true,
	RAIN_EMITTER_SIZE = 1,
	RAIN_EMITTER_LIGHT_EMISSION = 0.5,
	RAIN_EMITTER_LIGHT_INFLUENCE = 0.5,
	RAIN_EMITTER_COLOR = Color3.fromRGB(86, 86, 86),
	RAIN_EMITTER_SHAPE = Enum.ParticleEmitterShape.Disc,
	RAIN_EMITTER_SHAPE_IN_OUT = Enum.ParticleEmitterShapeInOut.Outward,
	RAIN_EMITTER_EMISSION_DIRECTION = Enum.NormalId.Bottom,
	RAIN_EMITTER_SPEED = 50,
	-- These attach to parts, so if you adjust RAIN_PART_XZ_STUDS, you need to
	-- adjust the rate here to keep the rain looking the same.
	RAIN_EMITTER_RATE = 80,
	RAIN_EMITTER_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds", -- default, gets squashed anyway
	RAIN_EMITTER_TRANSPARENCY = 0.35,
	RAIN_EMITTER_SPREAD_ANGLE = 4,
	RAIN_EMITTER_ZOFFSET = 0,
	-- Essential for making the rain lean in the wind. At 0, no drag, no lean.
	RAIN_EMITTER_DRAG = 3,
	-- Wind has no vertical component, so drag decays the fall too and it settles
	-- at ACCELERATION.Y / DRAG studs per second. Keep that product near the fall
	-- speed you want or the rain starts to look more like drifting mist.
	-- At drag 3 this terminal speed is 200, so the rain still falls hard while
	-- drifting about 38 studs over a 150 stud fall (at wind 50).
	RAIN_EMITTER_ACCELERATION = Vector3.new(0, -600, 0),
	-- How long a drop lives, which is what decides where it stops. Set it to land
	-- just under the ground. 1 is a bit long for 150 studs, but gives you a small
	-- margin of error.
	RAIN_EMITTER_LIFETIME_SECONDS = 1,

	-- Mist. Follows same transition time as rain, going from nothing to full
	-- in the second half of RAIN_TRANSITION_HOURS and back to nothing as the
	-- storm ends. Ignores wind and roofs.
	MIST_ENABLED = true,
	-- How much of the map to cover. Uses the same point of origin as the rain.
	MIST_COVERAGE_PERCENTAGE = 40,
	-- Align with the height of most of the terrain.
	MIST_COVERAGE_Y_STUDS = 15,
	-- Smaller parts mean thicker mist.
	MIST_PART_XZ_STUDS = 30,

	-- Mist particle properties
	MIST_EMITTER_TEXTURE = "rbxassetid://8464983433",
	MIST_EMITTER_RATE = 2,
	MIST_EMITTER_SPEED = 0.001,
	MIST_EMITTER_MIN_LIFETIME_SECONDS = 2,
	MIST_EMITTER_MAX_LIFETIME_SECONDS = 4,
	MIST_EMITTER_DRAG = 0,
	MIST_EMITTER_RESPECT_GLOBAL_WIND = false,
	MIST_EMITTER_ACCELERATION = Vector3.new(0, 0, 1),
	MIST_EMITTER_SPREAD_ANGLE = 0,
	MIST_EMITTER_SHAPE = Enum.ParticleEmitterShape.Box,
	MIST_EMITTER_SHAPE_STYLE = Enum.ParticleEmitterShapeStyle.Volume,
	MIST_EMITTER_SHAPE_IN_OUT = Enum.ParticleEmitterShapeInOut.Outward,
	MIST_EMITTER_EMISSION_DIRECTION = Enum.NormalId.Top,
	MIST_EMITTER_ORIENTATION = Enum.ParticleOrientation.FacingCamera,
	MIST_EMITTER_LIGHT_EMISSION = 0.8,
	MIST_EMITTER_LIGHT_INFLUENCE = 0.8,
	MIST_EMITTER_COLOR = Color3.fromRGB(255, 255, 255),
	MIST_EMITTER_ZOFFSET = 0,
	-- Random start angle and a slow tumble, so no two puffs match.
	MIST_EMITTER_MIN_ROTATION = 0,
	MIST_EMITTER_MAX_ROTATION = 360,
	MIST_EMITTER_MIN_ROT_SPEED = -10,
	MIST_EMITTER_MAX_ROT_SPEED = 20,
	-- Curves rather than single values so the mist swells.
	MIST_EMITTER_SIZE = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 4),
		NumberSequenceKeypoint.new(1, 8),
	}),
	-- Invisible at both ends so puffs appear and leave rather than popping.
	MIST_EMITTER_TRANSPARENCY = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.85),
		NumberSequenceKeypoint.new(0.75, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	}),

	-- Wind. During the transition, it goes from CLEAR to the storm value over
	-- the entire RAIN_TRANSITION_HOURS. So clouds gather and wind picks up
	-- first. Rain and mist start to ramp up midway through the transition.
	CLEAR_GLOBAL_WIND_X = 0,
	CLEAR_GLOBAL_WIND_Z = 0,
	MIN_GLOBAL_WIND_X = 10,
	MAX_GLOBAL_WIND_X = 50,
	MIN_GLOBAL_WIND_Z = 10,
	MAX_GLOBAL_WIND_Z = 50,
	-- Make wind speed negative or positive so that it doesn't always blow in
	-- the same general direction.
	RANDOMIZE_GLOBAL_WIND_SIGN = true,

	-- Clouds
	CLEAR_CLOUD_COVER = 0.6, -- anything below 0.5 is barely noticable
	CLEAR_CLOUD_DENSITY = 0.6,
	CLEAR_CLOUD_COLOR = Color3.fromRGB(135, 135, 135),
	RAIN_CLOUD_COVER = 0.8, -- anything above 0.9 is essentially soup
	RAIN_CLOUD_DENSITY = 0.9,
	RAIN_CLOUD_COLOR = Color3.fromRGB(68, 68, 68),

	-- Atmosphere. Haze runs on the mist curve rather than the cloud one, so the
	-- air thickens as the mist comes up and clears as it leaves.
	MIN_HAZE = 0,
	MAX_HAZE = 2.5,

	-- Roof detection. Works better with larger roofs. Small shelters or trees,
	-- less so.
	ROOF_DETECTION_ENABLED = true,
	-- How far above a roof to stop the rain. Raise it a bit particles still poke
	-- through.
	ROOF_CLEARANCE_STUDS = 5,
	-- How long to take doing a full check for roofs across the entire field.
	-- Presumably roofs don't move very often, so you don't need to do this
	-- check very often. Each rain part casts one ray, part count divided by
	-- this value gives the number of rays per second.
	ROOF_RECHECK_SECONDS = 15,

	-- Makes the rain cells solid and tints them by whether the ray found a
	-- roof so that you can see which parts are shortening their particle
	-- lifetime and which aren't.
	ROOF_DEBUG_VISUALIZE = false,
	ROOF_DEBUG_TRANSPARENCY = 0.55,
	ROOF_DEBUG_OPEN_COLOR = Color3.fromRGB(80, 200, 120),
	ROOF_DEBUG_SHELTERED_COLOR = Color3.fromRGB(220, 70, 70),
}

return WeatherSystemConfig
