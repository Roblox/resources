--[[
	Renders a visual ray for players to see between an origin and destination. This render
	should only happen on the Client.

	Attachments are created at the origin and destination for different particle effects
	and to connect a beam between them. Since attachments must have a BasePart parent,
	we use Terrain (inherits from BasePart) as a convenient container centered at origin.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local vfxFolder = ReplicatedStorage.Instances.LaserVFX

local ORIGIN_PARTICLE_LIFETIME = 0.25
local DESTINATION_PARTICLE_LIFETIME = 0.35

local function drawLaserRay(origin: Vector3, destination: CFrame)
	if not RunService:IsClient() then
		warn("drawLaserRay should only occur on the Client")
		return
	end

	local originAttachment = Instance.new("Attachment")
	originAttachment.CFrame = CFrame.lookAt(origin, destination.Position)
	originAttachment.Parent = Workspace.Terrain

	local destinationAttachment = Instance.new("Attachment")
	destinationAttachment.CFrame = destination
	destinationAttachment.Parent = Workspace.Terrain

	-- Create the beams
	local beamFolder = vfxFolder.Beams
	for _, beamPrefab in beamFolder:GetChildren() do
		local beam = beamPrefab:Clone()
		beam.Attachment0 = originAttachment
		beam.Attachment1 = destinationAttachment
		beam.Parent = originAttachment
	end

	-- Add origin particles
	local originParticlesFolder = vfxFolder.OriginParticles
	for _, particlePrefab in originParticlesFolder:GetChildren() do
		local particle = particlePrefab:Clone()
		particle.Parent = originAttachment
		particle:Emit(3)
	end

	-- Add destination particles
	local destinationParticlesFolder = vfxFolder.DestinationParticles
	for _, particlePrefab in destinationParticlesFolder:GetChildren() do
		local particle = particlePrefab:Clone()
		particle.Parent = destinationAttachment
		particle:Emit(3)
	end

	-- Destroying the attachments also destroy their children (beams and particles)
	task.delay(ORIGIN_PARTICLE_LIFETIME, originAttachment.Destroy, originAttachment)
	task.delay(DESTINATION_PARTICLE_LIFETIME, destinationAttachment.Destroy, destinationAttachment)
end

return drawLaserRay
