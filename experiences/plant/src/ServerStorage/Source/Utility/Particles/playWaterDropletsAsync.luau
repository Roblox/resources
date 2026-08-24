--!strict

--[[
	Plays a watering particle animation over a given parent part. Yields until the particles stop spawning.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local WATER_TIME = 1.25 -- length of time the watering animation plays

local particlePrefab: ParticleEmitter = getInstance(ReplicatedStorage, "Instances", "Particles", "WaterDroplets")

local function playWaterDropletsAsync(parent: BasePart)
	local particles = particlePrefab:Clone()
	particles.Parent = parent

	-- We want the particles to start at the top of the plant and stop at the bottom of the plant.
	-- To achieve this, we need to set lifetime based on the height we want the particle to fall.
	-- We need to solve for this lifetime value.

	-- The initial height is equal to the height of the part, h = height.
	-- When the particle reaches the bottom of the plant, y is 0, so the fall height Δy = h - 0 = h:
	local height = parent.Size.Y

	-- We know initial velocity, v = speed:
	local speed = particles.Speed.Max

	-- We know acceleration, a = acceleration:
	local acceleration = math.abs(particles.Acceleration.Y)

	-- And we know the equation describing the change in height of a projectile in vertical motion at any time t:
	-- h = vt + 0.5at^2

	-- Solve for t (a quadratic), which is the lifetime required to achieve a given height:
	-- t = [v + √(v² + 2ah)] / a

	-- Plug in our numbers:
	local lifetime = (speed + math.sqrt(speed ^ 2 + 2 * acceleration * height)) / acceleration

	particles.Lifetime = NumberRange.new(lifetime)
	task.wait(WATER_TIME)

	particles.Enabled = false
	task.delay(lifetime, function()
		particles:Destroy()
	end)

	return particles
end

return playWaterDropletsAsync
