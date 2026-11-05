-- Monitors the local player's microphone input to drive their own jaw animation
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)
local VoiceIntensity = require(script.Parent.VoiceIntensity)

local LocalVoiceMonitor = {}

local localPlayer = Players.LocalPlayer

function LocalVoiceMonitor.start()
	local monitoring = false

	local function monitorAudioInput(audioInput: Instance)
		if monitoring or not audioInput:IsA("AudioDeviceInput") then
			return
		end
		monitoring = true

		local analyzer = Instance.new("AudioAnalyzer")
		analyzer.Name = "VoiceLevelAnalyzer"
		analyzer.SpectrumEnabled = false
		analyzer.Parent = audioInput

		local wire = Instance.new("Wire")
		wire.SourceInstance = audioInput
		wire.TargetInstance = analyzer
		wire.Parent = audioInput

		local noiseFloor = Constants.INITIAL_NOISE_FLOOR

		local heartbeatConnection: RBXScriptConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			local rawLevel = math.max(analyzer.RmsLevel, analyzer.PeakLevel)

			if rawLevel < noiseFloor then
				noiseFloor = noiseFloor * 0.95 + rawLevel * 0.05
			end

			local speechThreshold = noiseFloor * Constants.SPEECH_THRESHOLD_MULTIPLIER
				+ Constants.SPEECH_THRESHOLD_OFFSET
			local cleanSignal = math.max(0, rawLevel - speechThreshold)
			local normalizedVolume = math.clamp(cleanSignal / Constants.VOICE_LEVEL_NORMALIZATION_MAX, 0, 1)

			if rawLevel >= speechThreshold then
				VoiceIntensity.feedVoice(localPlayer.UserId, normalizedVolume)
			end
		end)

		audioInput.Destroying:Once(function()
			heartbeatConnection:Disconnect()
			monitoring = false
		end)
	end

	local existing = localPlayer:FindFirstChildOfClass("AudioDeviceInput")
		or localPlayer:FindFirstChildWhichIsA("AudioDeviceInput", true)
	if existing then
		monitorAudioInput(existing)
	end

	localPlayer.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("AudioDeviceInput") then
			monitorAudioInput(descendant)
		end
	end)
end

return LocalVoiceMonitor
