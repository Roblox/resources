local Constants = {}

Constants.VOICE_ZONE_TAG = "VoiceZone"
Constants.VOICE_PRESET_ATTRIBUTE = "VoicePreset"
Constants.DEFAULT_VOICE_PRESET = "Normal"

Constants.INITIAL_NOISE_FLOOR = 0.002
Constants.SPEECH_THRESHOLD_MULTIPLIER = 3.5
Constants.SPEECH_THRESHOLD_OFFSET = 0.005
Constants.VOICE_LEVEL_NORMALIZATION_MAX = 0.04
Constants.HEAD_FLAP_LEVEL_THRESHOLD = 0.005

Constants.BUBBLE_DURATION_SECONDS = 6
Constants.BUBBLE_TEXT_SIZE = 18
Constants.CHAT_RANGE = 30
Constants.BUBBLE_BACKGROUND_COLOR = Color3.fromRGB(20, 20, 25)
Constants.BUBBLE_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
Constants.BUBBLE_MAX_WIDTH = 220
Constants.BUBBLE_MAX_HEIGHT = 400
Constants.BUBBLE_LABEL_NAME = "Bubble"
Constants.BUBBLE_BILLBOARD_NAME = "ChatBubbles"

export type PresetConfig = {
	PitchShifter: { Bypass: boolean, Pitch: number? }?,
	Chorus: { Bypass: boolean, Depth: number?, Rate: number?, Mix: number? }?,
	Flanger: { Bypass: boolean, Depth: number?, Rate: number?, Mix: number? }?,
	Distortion: { Bypass: boolean, Level: number? }?,
	Equalizer: { Bypass: boolean, LowGain: number?, MidGain: number?, HighGain: number? }?,
	Echo: { Bypass: boolean, DelayTime: number?, Feedback: number?, WetLevel: number? }?,
	Reverb: { Bypass: boolean, WetLevel: number?, DecayTime: number? }?,
	TextureId: string?,
}

export type NodeChain = {
	PitchShifter: AudioPitchShifter,
	Chorus: AudioChorus,
	Flanger: AudioFlanger,
	Distortion: AudioDistortion,
	Equalizer: AudioEqualizer,
	Echo: AudioEcho,
	Reverb: AudioReverb,
	CurrentPreset: string,
}

Constants.VOICE_PRESETS = {
	Normal = {
		PitchShifter = { Bypass = true },
		Chorus = { Bypass = true },
		Flanger = { Bypass = true },
		Distortion = { Bypass = true },
		Equalizer = { Bypass = true },
		Echo = { Bypass = true },
		Reverb = { Bypass = true },
	},

	Helium = {
		PitchShifter = { Bypass = false, Pitch = 1.7 },
		Chorus = { Bypass = true },
		Flanger = { Bypass = true },
		Distortion = { Bypass = true },
		Equalizer = { Bypass = true },
		Echo = { Bypass = true },
		Reverb = { Bypass = true },
		TextureId = "rbxassetid://135109635270176",
	},

	DeepMonster = {
		PitchShifter = { Bypass = false, Pitch = 0.8 },
		Chorus = { Bypass = true },
		Flanger = { Bypass = true },
		Distortion = { Bypass = true },
		Equalizer = { Bypass = false, LowGain = 8, MidGain = 0, HighGain = -8 },
		Echo = { Bypass = true },
		Reverb = { Bypass = false, WetLevel = 0.2, DecayTime = 0.7 },
		TextureId = "rbxassetid://84283160327491",
	},

	WalkieTalkie = {
		PitchShifter = { Bypass = false, Pitch = 1.1 },
		Chorus = { Bypass = true },
		Flanger = { Bypass = false, Depth = 0.7, Rate = 0.6, Mix = 0.2 },
		Distortion = { Bypass = false, Level = 0.5 },
		Equalizer = { Bypass = false, LowGain = -30, MidGain = 12, HighGain = -25 },
		Echo = { Bypass = true },
		Reverb = { Bypass = true },
	},

	AlienHivemind = {
		PitchShifter = { Bypass = false, Pitch = 1.3 },
		Chorus = { Bypass = true },
		Flanger = { Bypass = false, Depth = 0.5, Rate = 10, Mix = 1.0 },
		Distortion = { Bypass = true },
		Equalizer = { Bypass = true },
		Echo = { Bypass = false, DelayTime = 0.1, Feedback = 0.2, WetLevel = 0.3 },
		Reverb = { Bypass = true },
		TextureId = "rbxassetid://81222470958911",
	},

	MountainYodel = {
		PitchShifter = { Bypass = true },
		Chorus = { Bypass = true },
		Flanger = { Bypass = true },
		Distortion = { Bypass = true },
		Equalizer = { Bypass = true },
		Echo = { Bypass = false, DelayTime = 0.1, Feedback = 0.2, WetLevel = 0.3 },
		Reverb = { Bypass = true },
	},

	CaveEcho = {
		PitchShifter = { Bypass = true },
		Chorus = { Bypass = true },
		Flanger = { Bypass = true },
		Distortion = { Bypass = true },
		Equalizer = { Bypass = true },
		Echo = { Bypass = true },
		Reverb = { Bypass = false, WetLevel = 0.8, DecayTime = 7.0 },
	},

	Robot = {
		PitchShifter = { Bypass = false, Pitch = 1.1 },
		Chorus = { Bypass = true },
		Flanger = { Bypass = true },
		Distortion = { Bypass = false, Level = 0.4 },
		Equalizer = { Bypass = false, LowGain = -30, MidGain = 12, HighGain = -25 },
		Echo = { Bypass = true },
		Reverb = { Bypass = true },
	},
} :: { [string]: PresetConfig }

return Constants
