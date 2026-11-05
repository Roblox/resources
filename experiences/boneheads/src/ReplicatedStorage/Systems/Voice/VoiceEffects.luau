-- Core voice pipeline: hooks players, wires audio chain, applies presets, TTS
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)
local VoiceIntensity = require(script.Parent.VoiceIntensity)
local getHostPart = require(ReplicatedStorage.Utility.getHostPart)
local getPlayerHead = require(ReplicatedStorage.Utility.getPlayerHead)
local VOICE_PRESETS = Constants.VOICE_PRESETS

local HEAD_WAIT_INTERVAL = 0.2
local HEAD_WAIT_TIMEOUT = 10

local VoiceEffects = {}

local playerVoiceChains: { [number]: Constants.NodeChain } = {}
local playerVoicePresets: { [number]: string } = {}

local function simulateTextFlap(userId: number, text: string)
	local syllables = math.max(1, math.floor(#text / 3))
	local duration = math.clamp(syllables * 0.12, 0.4, 4.0)
	local interval = duration / syllables

	task.spawn(function()
		for i = 1, syllables do
			local volume = 0.4 + 0.6 * math.abs(math.sin(i * 1.2))
			VoiceIntensity.feedVoice(userId, volume)
			task.wait(interval)
		end
		VoiceIntensity.feedVoice(userId, 0)
	end)
end

function VoiceEffects.getCurrentPresetTextureId(userId: number): string?
	if playerVoicePresets[userId] and VOICE_PRESETS[playerVoicePresets[userId]] then
		return VOICE_PRESETS[playerVoicePresets[userId]].TextureId
	end

	return nil
end

function VoiceEffects.getChain(userId: number): Constants.NodeChain?
	return playerVoiceChains[userId]
end

function VoiceEffects.applyPresetToPlayer(userId: number, presetName: string)
	playerVoicePresets[userId] = presetName

	local chain = playerVoiceChains[userId]
	if not chain or chain.CurrentPreset == presetName then
		return
	end

	local preset = VOICE_PRESETS[presetName] or VOICE_PRESETS[Constants.DEFAULT_VOICE_PRESET]
	chain.CurrentPreset = presetName

	local function setProps(node: Instance, props: { [string]: any }?)
		if not props then
			return
		end
		for prop, value in props do
			(node :: any)[prop] = value
		end
	end

	setProps(chain.PitchShifter, preset.PitchShifter)
	setProps(chain.Chorus, preset.Chorus)
	setProps(chain.Flanger, preset.Flanger)
	setProps(chain.Distortion, preset.Distortion)
	setProps(chain.Equalizer, preset.Equalizer)
	setProps(chain.Echo, preset.Echo)
	setProps(chain.Reverb, preset.Reverb)
end

function VoiceEffects.hookPlayer(player: Player)
	playerVoicePresets[player.UserId] = ""
	local localPlayer = Players.LocalPlayer
	if player == localPlayer then
		return
	end

	local function onCharacterAdded(character: Model)
		local deviceInput = player:WaitForChild("AudioDeviceInput", 10) :: AudioDeviceInput?
		local emitter = character:WaitForChild("AudioEmitter", 10) :: AudioEmitter?

		if not deviceInput or not emitter then
			return
		end

		local function destroyDefaultWires()
			local targets: { Instance } = { character, player, deviceInput, emitter }
			for _, container in targets do
				for _, child in container:GetChildren() do
					if child:IsA("Wire") and child.Name ~= "CustomVoiceWire" then
						if child.TargetInstance == emitter or child.SourceInstance == deviceInput then
							child:Destroy()
						end
					end
				end
			end
		end

		destroyDefaultWires()

		local pitch = Instance.new("AudioPitchShifter")
		local chorus = Instance.new("AudioChorus")
		local flanger = Instance.new("AudioFlanger")
		local distortion = Instance.new("AudioDistortion")
		local equalizer = Instance.new("AudioEqualizer")
		local echo = Instance.new("AudioEcho")
		local reverb = Instance.new("AudioReverb")

		pitch.Parent = character
		chorus.Parent = character
		flanger.Parent = character
		distortion.Parent = character
		equalizer.Parent = character
		echo.Parent = character
		reverb.Parent = character

		playerVoiceChains[player.UserId] = {
			PitchShifter = pitch,
			Chorus = chorus,
			Flanger = flanger,
			Distortion = distortion,
			Equalizer = equalizer,
			Echo = echo,
			Reverb = reverb,
			CurrentPreset = "",
		}

		local function connect(source: Instance, target: Instance)
			local wire = Instance.new("Wire")
			wire.Name = "CustomVoiceWire"
			wire.SourceInstance = source
			wire.TargetInstance = target
			wire.Parent = character
		end

		local emitterAnalyzer = Instance.new("AudioAnalyzer")
		emitterAnalyzer.Name = "EmitterAnalyzer"
		emitterAnalyzer.SpectrumEnabled = false
		emitterAnalyzer.Parent = character

		connect(deviceInput, pitch)
		connect(pitch, chorus)
		connect(chorus, flanger)
		connect(flanger, distortion)
		connect(distortion, equalizer)
		connect(equalizer, echo)
		connect(echo, reverb)
		connect(reverb, emitter)
		connect(reverb, emitterAnalyzer)

		task.defer(destroyDefaultWires)

		local flapConnection: RBXScriptConnection
		flapConnection = RunService.Heartbeat:Connect(function()
			if not character.Parent then
				return
			end
			local level = math.max(emitterAnalyzer.RmsLevel, emitterAnalyzer.PeakLevel)
			if level > Constants.HEAD_FLAP_LEVEL_THRESHOLD then
				VoiceIntensity.feedVoice(
					player.UserId,
					math.clamp(level / Constants.VOICE_LEVEL_NORMALIZATION_MAX, 0, 1)
				)
			end
		end)

		character.Destroying:Once(function()
			flapConnection:Disconnect()
		end)

		task.spawn(function()
			local elapsed = 0
			local headModel = getPlayerHead(player.UserId)
			while not headModel and elapsed < HEAD_WAIT_TIMEOUT do
				task.wait(HEAD_WAIT_INTERVAL)
				elapsed += HEAD_WAIT_INTERVAL
				headModel = getPlayerHead(player.UserId)
			end

			if character.Parent == nil or not emitter:IsDescendantOf(game) then
				return
			end

			if not headModel then
				return
			end

			local headHost = getHostPart(headModel)
			if headHost then
				emitter.Parent = headHost
			end
		end)

		VoiceEffects.applyPresetToPlayer(player.UserId, Constants.DEFAULT_VOICE_PRESET)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

function VoiceEffects.speakText(player: Player, text: string)
	local chain = playerVoiceChains[player.UserId]
	if not chain then
		if player == Players.LocalPlayer then
			simulateTextFlap(player.UserId, text)
		end
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local existing = character:FindFirstChild("VoiceTTS") :: AudioTextToSpeech?
	local tts: AudioTextToSpeech
	if existing then
		tts = existing
	else
		tts = Instance.new("AudioTextToSpeech")
		tts.Name = "VoiceTTS"
		tts.VoiceId = "1"
		tts.Parent = character

		local wire = Instance.new("Wire")
		wire.Name = "CustomVoiceWire"
		wire.SourceInstance = tts
		wire.TargetInstance = chain.PitchShifter
		wire.Parent = character
	end

	tts.Text = text
	task.spawn(function()
		tts:LoadAsync()
		tts:Play()
	end)
end

function VoiceEffects.unhookPlayer(player: Player)
	playerVoiceChains[player.UserId] = nil
	playerVoicePresets[player.UserId] = nil
end

return VoiceEffects
