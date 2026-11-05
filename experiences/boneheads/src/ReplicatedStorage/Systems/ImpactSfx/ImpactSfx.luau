local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioClient = require(ReplicatedStorage.Systems.Audio.AudioClient)
local Collision = require(ReplicatedStorage.Systems.Collision.Collision)
local Constants = require(script.Parent.Constants)

local IMPACT_SOUND_ATTRIBUTE = Constants.IMPACT_SOUND_ATTRIBUTE
local DEFAULT_IMPACT_SOUND = Constants.DEFAULT_IMPACT_SOUND
local MIN_IMPACT_SPEED = Constants.MIN_IMPACT_SPEED
local MAX_IMPACT_SPEED = Constants.MAX_IMPACT_SPEED
local MIN_IMPACT_VOLUME = Constants.MIN_IMPACT_VOLUME
local MAX_IMPACT_VOLUME = Constants.MAX_IMPACT_VOLUME
local IMPACT_COOLDOWN_SECONDS = Constants.IMPACT_COOLDOWN_SECONDS

local lastImpactAt: { [Instance]: number } = {}

local function getImpactVolume(speed: number): number
	local speedRange = MAX_IMPACT_SPEED - MIN_IMPACT_SPEED
	if speedRange <= 0 then
		return MAX_IMPACT_VOLUME
	end

	local alpha = math.clamp((speed - MIN_IMPACT_SPEED) / speedRange, 0, 1)
	return MIN_IMPACT_VOLUME + (MAX_IMPACT_VOLUME - MIN_IMPACT_VOLUME) * alpha
end

local function resolveImpactSound(item: Instance): string?
	local soundName = item:GetAttribute(IMPACT_SOUND_ATTRIBUTE) :: string?
	if soundName == nil then
		soundName = DEFAULT_IMPACT_SOUND
	end

	if soundName == "" then
		return nil
	end

	return soundName
end

local function onImpact(impact: Collision.Impact)
	local item = impact.item
	if impact.speed < MIN_IMPACT_SPEED then
		return
	end

	local now = os.clock()
	if now - (lastImpactAt[item] or 0) < IMPACT_COOLDOWN_SECONDS then
		return
	end

	local soundName = resolveImpactSound(item)
	if not soundName then
		return
	end

	if not AudioClient.hasDefinition(soundName) then
		warn(`[ImpactSfx] unknown impactSound "{soundName}" on {item:GetFullName()}`)
		return
	end

	lastImpactAt[item] = now
	task.delay(IMPACT_COOLDOWN_SECONDS, function()
		if lastImpactAt[item] == now then
			lastImpactAt[item] = nil
		end
	end)

	AudioClient.playOnInstance(soundName, impact.host, { volume = getImpactVolume(impact.speed) })
end

local ImpactSfx = {}

local started = false

function ImpactSfx.start()
	if started then
		return
	end
	started = true

	Collision.onImpact(onImpact)
end

return ImpactSfx
