local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = ReplicatedStorage.Systems

local AimClient = require(Systems.Aim.AimClient)
local AudioClient = require(ReplicatedStorage.Systems.Audio.AudioClient)
local CameraController = require(Systems.Camera.CameraController)
local CarrySfx = require(Systems.CarrySfx.CarrySfx)
local Collision = require(Systems.Collision.Collision)
local HeadAnimator = require(Systems.Head.HeadAnimator)
local ImpactSfx = require(Systems.ImpactSfx.ImpactSfx)
local VoiceClient = require(Systems.Voice.VoiceClient)

local SoundDefinitions = ReplicatedStorage.Systems.Audio.SoundDefinitions

local function initialize()
	AudioClient.loadDefinitions(SoundDefinitions)

	AudioClient.start()
	CarrySfx.start()
	Collision.start()
	ImpactSfx.start()
	AimClient.start()
	CameraController.start()
	HeadAnimator.start()
	VoiceClient.start()
end

initialize()
