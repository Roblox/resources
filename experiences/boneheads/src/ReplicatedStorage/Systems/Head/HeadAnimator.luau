local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)
local VoiceEffects = require(ReplicatedStorage.Systems.Voice.VoiceEffects)
local VoiceIntensity = require(ReplicatedStorage.Systems.Voice.VoiceIntensity)

local getCharacterTextAnchor = require(ReplicatedStorage.Utility.getCharacterTextAnchor)
local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local HeadAnimator = {}
local started = false

-- Flap relative to each joint's authored C0 (its rest pose in the model), not a hardcoded offset.
local restC0ByJoint: { [Motor6D]: CFrame } = {}

type HeadRestPose = {
	localCenter: Vector3,
	headWidth: number,
}

-- Character-text placement is anchored to the head's rest-pose bounding box, measured once in
-- the host part's local space. The host is the cranium joint's Part0, so it never moves with the
-- flap — reconstructing from it each frame keeps the label from bobbing with the animation.
local restPoseByHead: { [Model]: HeadRestPose } = {}

local function getOrCreateVoiceEffectParticleEmitter(inJawPart: BasePart): ParticleEmitter
	local particleEmitter = inJawPart:FindFirstChild(Constants.VOICE_EFFECT_PARTICLE_EMITTER_NAME, true)
	if not (particleEmitter and particleEmitter:IsA("ParticleEmitter")) then
		local jawAttachment = Instance.new("Attachment")
		jawAttachment.Name = "JawAttachment"
		jawAttachment.Parent = inJawPart

		local newParticleEmitter = Instance.new("ParticleEmitter")
		newParticleEmitter.Name = Constants.VOICE_EFFECT_PARTICLE_EMITTER_NAME
		newParticleEmitter.LightInfluence = 0
		newParticleEmitter.Size = Constants.VOICE_EFFECT_PARTICLE_EMITTER_SIZE_SEQUENCE

		newParticleEmitter.Speed = Constants.VOICE_EFFECT_PARTICLE_EMITTER_SPEED
		newParticleEmitter.SpreadAngle = Constants.VOICE_EFFECT_PARTICLE_EMITTER_SPREAD_ANGLE
		newParticleEmitter.Rate = 0
		newParticleEmitter.EmissionDirection = Enum.NormalId.Front
		newParticleEmitter.Lifetime = Constants.VOICE_EFFECT_PARTICLE_EMITTER_LIFETIME
		newParticleEmitter.Enabled = false
		newParticleEmitter.Parent = jawAttachment

		particleEmitter = newParticleEmitter
	end

	return particleEmitter :: ParticleEmitter
end

local function animateVoiceEffects(inOwnerUserId: unknown, inVoiceIntensity: number, inJawPart: BasePart)
	if typeof(inOwnerUserId) ~= "number" then
		return
	end

	local particleEmitter = getOrCreateVoiceEffectParticleEmitter(inJawPart)
	if not particleEmitter then
		return
	end

	local presetTextureId = VoiceEffects.getCurrentPresetTextureId(inOwnerUserId)
	if presetTextureId == nil or inVoiceIntensity <= 0 then
		particleEmitter.Enabled = false
		return
	end

	particleEmitter.Rate = math.lerp(
		Constants.VOICE_EFFECT_PARTICLE_EMITTER_MIN_RATE,
		Constants.VOICE_EFFECT_PARTICLE_EMITTER_MAX_RATE,
		inVoiceIntensity
	)
	particleEmitter.Texture = presetTextureId
	particleEmitter.Enabled = true
end

local function animateCranium(head: Model)
	local craniumJoint = head:FindFirstChild(Constants.CRANIUM_JOINT, true)
	if not (craniumJoint and craniumJoint:IsA("Motor6D")) then
		return
	end

	local restC0 = restC0ByJoint[craniumJoint]
	if not restC0 then
		restC0 = craniumJoint.C0
		restC0ByJoint[craniumJoint] = restC0
	end

	local ownerUserId = head:GetAttribute(Constants.HEAD_OWNER_ATTRIBUTE)
	local intensity = if typeof(ownerUserId) == "number" then VoiceIntensity.getIntensity(ownerUserId) else 0
	craniumJoint.C0 = restC0 * CFrame.Angles(intensity * Constants.MAX_CRANIUM_ANGLE, 0, 0)

	local jawPart = craniumJoint.Part0
	if jawPart then
		animateVoiceEffects(ownerUserId, intensity, jawPart)
	end
end

local function alignCharacterText(head: Model)
	local host = getHostPart(head)
	if not host then
		return
	end

	local characterTextAnchor = getCharacterTextAnchor(host)
	if not characterTextAnchor then
		return
	end

	local restPose = restPoseByHead[head]
	if not restPose then
		local boundingCFrame, boundingSize = head:GetBoundingBox()
		restPose = {
			localCenter = host.CFrame:Inverse() * boundingCFrame.Position,
			headWidth = math.max(boundingSize.X, boundingSize.Y, boundingSize.Z),
		}
		restPoseByHead[head] = restPose
	end

	local worldCenter = host.CFrame * restPose.localCenter
	characterTextAnchor.WorldPosition = worldCenter
		+ Vector3.new(0, restPose.headWidth + Constants.CHARACTER_TEXT_VERTICAL_OFFSET, 0)
end

local function animate()
	for joint in restC0ByJoint do
		if not joint.Parent then
			restC0ByJoint[joint] = nil
		end
	end

	for head in restPoseByHead do
		if not head.Parent then
			restPoseByHead[head] = nil
		end
	end

	for _, head in CollectionService:GetTagged(Constants.HEAD_TAG) do
		animateCranium(head)
		alignCharacterText(head)
	end
end

function HeadAnimator.start()
	if started then
		return
	end
	started = true

	RunService:BindToRenderStep("HeadAnimator", Enum.RenderPriority.Last.Value + 1, animate)
end

return HeadAnimator
