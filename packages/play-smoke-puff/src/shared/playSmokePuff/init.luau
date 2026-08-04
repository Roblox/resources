--!strict

--[[
	Plays a particle animation of a puff of smoke at the location, volume, and size of a given part.
--]]

local Workspace = game:GetService("Workspace")

local particlePrefab: ParticleEmitter = script.SmokePuff

local NUM_SMOKE_PARTICLES_PER_RADIUS_STUD = 2
local BASE_PARTICLE_SIZE_PER_RADIUS_STUD = 0.2
local END_PARTICLE_SIZE_MULTIPLIER = 2

local function playSmokePuff(parent: BasePart)
	-- Clone the parent so the particles stay in the same place as when this function is called,
	-- even if the parent gets moved
	local dummyParent = parent:Clone()
	dummyParent.Anchored = true
	dummyParent:ClearAllChildren()
	dummyParent.CanCollide = false
	dummyParent.CanQuery = false
	dummyParent.Transparency = 1

	local particles = particlePrefab:Clone()
	particles.Parent = dummyParent
	dummyParent.Parent = Workspace

	local radius = parent.Size.Magnitude / 2
	local numSmokeParticles = math.ceil(radius * NUM_SMOKE_PARTICLES_PER_RADIUS_STUD)
	local baseParticleSize = math.ceil(radius * BASE_PARTICLE_SIZE_PER_RADIUS_STUD)
	local particleSizeSequence = NumberSequence.new(baseParticleSize, baseParticleSize * END_PARTICLE_SIZE_MULTIPLIER)
	particles.Size = particleSizeSequence
	particles:Emit(numSmokeParticles)

	task.delay(particles.Lifetime.Max, function()
		dummyParent:Destroy()
	end)

	return particles
end

return playSmokePuff
