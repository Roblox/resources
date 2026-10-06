--!strict
-- Volumetric rain and mist. Storms arrive on a scaled game clock and form as
-- two grids of transparent parts: one in the air for the rain, one on the
-- ground for the mist. Rain fires down, mist fires up.
--
-- Configure in WeatherSystemConfig.
--
-- Server owned. GlobalWind and Terrain.Clouds replicate by themselves and the
-- rain parts reach clients through ordinary streaming, so no remotes are
-- involved and every player sees the same weather.
--
-- Call WeatherSystem.start() once from a server script. You can also force start
-- and force clear with WeatherSystem.startRain() and WeatherSystem.stopRain().

local RunService = game:GetService("RunService")

local WeatherSystemConfig = require(script.WeatherSystemConfig)
local WeatherClock = require(script.WeatherClock)
local RainField = require(script.RainField)
local MistField = require(script.MistField)
local SkyState = require(script.SkyState)

local WeatherSystem = {}

type Phase = "Clear" | "RampUp" | "Raining" | "RampDown"

local started = false
local phase: Phase = "Clear"
-- Hours spent in the current phase, not in the storm as a whole.
local phaseHours = 0
local stormDurationHours = 0
local publishedIntensity = -1
local connection: RBXScriptConnection? = nil

local function setPhase(next: Phase)
	phase = next
	phaseHours = 0
end

-- Sky intensity, rain coverage, rain emitter rate, and mist density for where
-- the storm is now.
--
-- Rain deliberately lags the sky and wind at both ends: nothing falls until the
-- clouds and wind are half way in, and the last cell is gone by the time they are
-- half way out.
--
-- Mist runs on rain's half of the transition, not the sky's, so the two arrive
-- together. Where rain opens at half and fills, mist opens at nothing and
-- climbs the whole way. Both reach full at the same time.
local function targets(): (number, number, number, number)
	local transition = math.max(WeatherSystemConfig.RAIN_TRANSITION_HOURS, 1e-6)

	if phase == "Clear" then
		return 0, 0, 0, 0
	elseif phase == "Raining" then
		return 1, 1, 1, 1
	elseif phase == "RampUp" then
		local progress = math.clamp(phaseHours / transition, 0, 1)
		if progress < 0.5 then
			return progress, 0, 0, 0
		end
		-- Second half opens at half coverage and half rate, then fills in.
		local fill = (progress - 0.5) / 0.5
		return progress, 0.5 + 0.5 * fill, 0.5 + 0.5 * fill, fill
	end

	local progress = math.clamp(phaseHours / transition, 0, 1)
	-- Rings peel off from the outside and the rate eases to half, both landing
	-- at nothing by the midpoint while the sky keeps clearing. Mist thins out
	-- across the same half, so it is gone when the last ring is.
	local fade = math.clamp(progress / 0.5, 0, 1)
	return 1 - progress, 1 - fade, 1 - 0.5 * fade, 1 - fade
end

local function publish(intensity: number)
	local rounded = math.floor(intensity * 100 + 0.5) / 100
	if rounded ~= publishedIntensity then
		publishedIntensity = rounded
		workspace:SetAttribute("RainIntensity", rounded)
	end
end

local function advancePhase(deltaHours: number)
	local transition = WeatherSystemConfig.RAIN_TRANSITION_HOURS

	if phase == "Clear" then
		if WeatherClock.shouldStartRain(deltaHours) then
			WeatherSystem.startRain()
		end
		return
	end

	phaseHours += deltaHours

	if phase == "RampUp" then
		if phaseHours >= transition then
			setPhase("Raining")
		end
	elseif phase == "Raining" then
		-- The rolled duration covers the whole storm, ramps included.
		if phaseHours >= math.max(stormDurationHours - transition * 2, 0) then
			setPhase("RampDown")
		end
	elseif phase == "RampDown" and phaseHours >= transition then
		setPhase("Clear")
		RainField.clear()
		WeatherClock.onRainEnded()
		SkyState.apply(0, 0, true)
	end
end

local function step(deltaSeconds: number)
	local deltaHours = WeatherClock.step(deltaSeconds)
	advancePhase(deltaHours)

	local sky, coverage, rate, mist = targets()
	-- Haze shares the mist's curve, so the air thickens with the fog at ground
	-- level rather than ahead of it with the clouds.
	SkyState.step(deltaSeconds, sky, mist)
	if phase ~= "Clear" then
		RainField.step(deltaSeconds, coverage, rate)
	end
	-- The sheet goes up the moment a storm exists, well before mist is due to
	-- be visible, because building it takes longer than the gap between the
	-- first non-zero density and full.
	MistField.step(phase ~= "Clear", mist)
	publish(sky)
end

-- Manually start a storm if one isn't already running.
function WeatherSystem.startRain()
	if phase ~= "Clear" then
		return
	end
	stormDurationHours = WeatherClock.rollStormDurationHours()
	SkyState.rollWindTarget()
	-- The storm picks where it lands and the mist follows it, so the two always
	-- cover the same ground.
	MistField.beginStorm(RainField.beginStorm())
	setPhase("RampUp")
end

-- Manually stop the storm.
function WeatherSystem.stopRain()
	if phase == "Clear" or phase == "RampDown" then
		return
	end
	setPhase("RampDown")
end

function WeatherSystem.isRaining(): boolean
	return phase ~= "Clear"
end

function WeatherSystem.getIntensity(): number
	local sky = targets()
	return sky
end

function WeatherSystem.start()
	if started then
		return
	end
	started = true

	WeatherClock.reset()
	SkyState.ensure()
	SkyState.rollWindTarget()
	SkyState.apply(0, 0, true)
	RainField.init()
	MistField.init()
	publish(0)

	if WeatherSystemConfig.DEBUG_START_RAINING_IMMEDIATELY then
		WeatherSystem.startRain()
	end

	connection = RunService.Heartbeat:Connect(step)
end

function WeatherSystem.stop()
	if not started then
		return
	end
	started = false

	if connection then
		connection:Disconnect()
		connection = nil
	end

	RainField.clear()
	MistField.clear()
	setPhase("Clear")
	SkyState.apply(0, 0, true)
	publish(0)
end

return WeatherSystem
