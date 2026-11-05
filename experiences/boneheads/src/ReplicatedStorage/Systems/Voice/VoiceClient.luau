-- Orchestrates all voice/audio systems: pipeline, zones, detection, head flap
local Players = game:GetService("Players")

local HeadBubbles = require(script.Parent.HeadBubbles)
local LocalVoiceMonitor = require(script.Parent.LocalVoiceMonitor)
local TextToSpeech = require(script.Parent.TextToSpeech)
local VoiceEffects = require(script.Parent.VoiceEffects)
local VoiceIntensity = require(script.Parent.VoiceIntensity)
local VoiceZoneDetector = require(script.Parent.VoiceZoneDetector)

local VoiceClient = {}

function VoiceClient.start()
	for _, player in Players:GetPlayers() do
		VoiceEffects.hookPlayer(player)
	end
	Players.PlayerAdded:Connect(function(player: Player)
		VoiceEffects.hookPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		VoiceEffects.unhookPlayer(player)
	end)

	VoiceIntensity.start()
	VoiceZoneDetector.start()
	LocalVoiceMonitor.start()
	TextToSpeech.start()
	HeadBubbles.start()
end

return VoiceClient
