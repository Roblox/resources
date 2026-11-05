local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Systems.Audio.Constants)
local Types = require(ReplicatedStorage.Systems.Audio.Types)

local AudioRemotes = ReplicatedStorage.Systems.Audio.Remotes
local playSoundEvent = AudioRemotes.PlaySound
local stopSoundEvent = AudioRemotes.StopSound

local definitions: { [string]: Types.SoundDefinition } = {}
local nextSoundId = 0

local function generateSoundId(): string
	nextSoundId += 1
	return tostring(nextSoundId)
end

local function getDefinition(soundName: string): Types.SoundDefinition
	local definition = definitions[soundName]
	assert(definition, `no sound definition registered for "{soundName}"`)
	return definition
end

local function firePlaySound(
	soundId: string,
	soundName: string,
	mode: string,
	target: any,
	options: Types.PlayOptions?,
	excludePlayer: Player?
)
	if excludePlayer then
		for _, player in Players:GetPlayers() do
			if player ~= excludePlayer then
				playSoundEvent:FireClient(player, soundId, soundName, mode, target, options)
			end
		end
	else
		playSoundEvent:FireAllClients(soundId, soundName, mode, target, options)
	end
end

local function createHandle(soundId: string): Types.SoundHandle
	local function stop()
		stopSoundEvent:FireAllClients(soundId)
	end

	return { stop = stop }
end

local AudioServer = {}

function AudioServer.loadDefinitions(folder: Instance)
	for _, child in folder:GetChildren() do
		if not child:IsA("ModuleScript") then
			continue
		end

		local group = require(child) :: { Types.SoundDefinition }
		for _, definition in group do
			assert(typeof(definition.name) == "string", `sound definition missing name field in {child.Name}`)
			definitions[definition.name] = definition
		end
	end
end

function AudioServer.playAtPosition(
	soundName: string,
	position: Vector3,
	options: Types.PlayOptions?,
	excludePlayer: Player?
): Types.SoundHandle
	getDefinition(soundName)
	local soundId = generateSoundId()
	firePlaySound(soundId, soundName, Constants.PLAY_MODE_POSITION, position, options, excludePlayer)
	return createHandle(soundId)
end

function AudioServer.playOnInstance(
	soundName: string,
	instance: Instance,
	options: Types.PlayOptions?,
	excludePlayer: Player?
): Types.SoundHandle
	getDefinition(soundName)
	local soundId = generateSoundId()
	firePlaySound(soundId, soundName, Constants.PLAY_MODE_INSTANCE, instance, options, excludePlayer)
	return createHandle(soundId)
end

return AudioServer
