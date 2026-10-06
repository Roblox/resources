--!strict
-- Wind, clouds, and atmospheric haze.
--
-- All of these replicate on their own, so the server only has to interpolate
-- between the configured endpoints and Roblox handles the rest. Inexpensive
-- compared to the rain and mist.
--
-- Wind and clouds start with the storm. Haze comes in with the mist.
--
-- ensure() creates a Clouds and Atmosphere instance if they don't already exist.

local WeatherSystemConfig = require(script.Parent.WeatherSystemConfig)

local SkyState = {}

-- Wind, clouds, and haze all replicate, so write them at a fixed rate rather
-- than every frame.
local WRITE_HZ = 15

local clouds: Clouds? = nil
local atmosphere: Atmosphere? = nil
local windTarget = Vector3.zero
local writeCountdown = 0
local appliedIntensity = -1
local appliedHaze = -1

local function lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

local function clearWind(): Vector3
	return Vector3.new(WeatherSystemConfig.CLEAR_GLOBAL_WIND_X, 0, WeatherSystemConfig.CLEAR_GLOBAL_WIND_Z)
end

function SkyState.ensure()
	local terrain = workspace.Terrain
	local existingClouds = terrain:FindFirstChildOfClass("Clouds")
	if existingClouds then
		clouds = existingClouds
	else
		local created = Instance.new("Clouds")
		created.Parent = terrain
		clouds = created
	end

	local lighting = game:GetService("Lighting")
	local existingAir = lighting:FindFirstChildOfClass("Atmosphere")
	if existingAir then
		atmosphere = existingAir
	else
		local created = Instance.new("Atmosphere")
		created.Parent = lighting
		atmosphere = created
	end
end

-- Pick the wind this storm blows. The configured ranges are both positive, so
-- RANDOMIZE_GLOBAL_WIND_SIGN keeps the wind from always coming from the same corner.
function SkyState.rollWindTarget()
	local function axis(minSpeed: number, maxSpeed: number): number
		local speed = minSpeed + math.random() * (maxSpeed - minSpeed)
		if WeatherSystemConfig.RANDOMIZE_GLOBAL_WIND_SIGN and math.random() < 0.5 then
			return -speed
		end
		return speed
	end

	windTarget = Vector3.new(
		axis(WeatherSystemConfig.MIN_GLOBAL_WIND_X, WeatherSystemConfig.MAX_GLOBAL_WIND_X),
		0,
		axis(WeatherSystemConfig.MIN_GLOBAL_WIND_Z, WeatherSystemConfig.MAX_GLOBAL_WIND_Z)
	)
end

function SkyState.getWindTarget(): Vector3
	return windTarget
end

-- Write the sky at this storm intensity and this much haze.
function SkyState.apply(intensity: number, hazeAlpha: number, force: boolean?)
	local settled = math.abs(intensity - appliedIntensity) < 1e-4 and math.abs(hazeAlpha - appliedHaze) < 1e-4
	if not force and settled then
		return
	end
	appliedIntensity = intensity
	appliedHaze = hazeAlpha

	workspace.GlobalWind = clearWind():Lerp(windTarget, intensity)

	local instance = clouds
	if instance then
		instance.Cover = lerp(WeatherSystemConfig.CLEAR_CLOUD_COVER, WeatherSystemConfig.RAIN_CLOUD_COVER, intensity)
		instance.Density =
			lerp(WeatherSystemConfig.CLEAR_CLOUD_DENSITY, WeatherSystemConfig.RAIN_CLOUD_DENSITY, intensity)
		instance.Color = WeatherSystemConfig.CLEAR_CLOUD_COLOR:Lerp(WeatherSystemConfig.RAIN_CLOUD_COLOR, intensity)
	end

	local air = atmosphere
	if air then
		air.Haze = lerp(WeatherSystemConfig.MIN_HAZE, WeatherSystemConfig.MAX_HAZE, hazeAlpha)
	end
end

function SkyState.step(deltaSeconds: number, intensity: number, hazeAlpha: number)
	writeCountdown -= deltaSeconds
	if writeCountdown > 0 then
		return
	end
	writeCountdown = 1 / WRITE_HZ
	SkyState.apply(intensity, hazeAlpha)
end

return SkyState
