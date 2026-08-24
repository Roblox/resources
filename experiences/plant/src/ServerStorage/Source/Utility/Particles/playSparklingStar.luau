--!strict

--[[
	Plays a sparkling star animation over a given parent part's center. Remains
	until destroyed externally.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local particlePrefab: ParticleEmitter = getInstance(ReplicatedStorage, "Instances", "Particles", "SparklingStar")

local function playSparklingStar(parent: BasePart)
	local centerAttachment = Instance.new("Attachment")
	centerAttachment.Name = "particleAttachment"

	local particles = particlePrefab:Clone()
	particles.Parent = centerAttachment
	centerAttachment.Parent = parent

	return particles
end

return playSparklingStar
