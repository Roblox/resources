--!nocheck
--[[
	Handles all visual logic for the Client's first-person laser blaster, including
		- Animations for the blaster rig: playing an idle animation and a blast animation when the blaster activates
		- A visual indicator for when the player can blast (cooldown bar)
		- Informs the HUDGui to flash the hitmarker when a blast connects with a target player

	In addition, this plays a "holding" character animation to raise the character's arm
	so that other players see your arm up. This is meant to be used in combination with
	ThirdPersonBlasterVisuals, which creates the third-person blaster view model that all other
	players see the character's arm holding up.

	The first-person rig is positioned in front of the camera on RenderStepped to make it look
	like your character is holding it.

	Visuals are removed and added when the blaster type changes for the player.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local BlastData = require(ReplicatedStorage.Blaster.BlastData)
local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local PlayerState = require(ReplicatedStorage.PlayerState)
local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)

local runBlastVisuals = require(script.runBlastVisuals)
local setupAnimations = require(script.setupAnimations)
local addCooldownBar = require(script.addCooldownBar)
local runCooldownBarEffect = require(script.runCooldownBarEffect)

local laserBlastedBindableEvent = ReplicatedStorage.Instances.LaserBlastedBindableEvent

local RIG_OFFSET_FROM_CAMERA = CFrame.new(2, -2, -3) * CFrame.Angles(math.rad(0.25), math.rad(95.25), 0)

local localPlayer = Players.LocalPlayer
local currentCamera = Workspace.CurrentCamera

local rigModel = nil
local cooldownBar = nil
local animations = {}

local function addFirstPersonVisuals()
	local blasterConfig = getBlasterConfig()

	-- Add the first person rig
	rigModel = blasterConfig.RigModel:Clone()
	rigModel.Parent = Workspace

	-- Add the cooldownBar
	cooldownBar = addCooldownBar(rigModel.PrimaryPart.CooldownBarAttachment)

	animations = setupAnimations(blasterConfig, rigModel)
end

local function removeFirstPersonVisuals()
	for _, animation in animations do
		animation:Stop()
		animation:Destroy()
		animation = nil
	end
	if rigModel then
		-- This also destroys the cooldown bar since it is parented to the rig
		rigModel:Destroy()
		rigModel = nil
	end
end

-- Run first person visual effects when a blast occurs
laserBlastedBindableEvent.Event:Connect(function(blastData: BlastData.Type)
	runBlastVisuals(rigModel.PrimaryPart.TipAttachment, blastData, animations.blastAnimation)
	runCooldownBarEffect(cooldownBar)
end)

-- Bind the rig to the camera if it exists
RunService.RenderStepped:Connect(function()
	if rigModel then
		-- Update to rig's CFrame relative to the camera's position and RIG_OFFSET_FROM_CAMERA
		rigModel:PivotTo(currentCamera.CFrame * RIG_OFFSET_FROM_CAMERA)
	end
end)

-- Handles changing visuals when the blasterType changes while playing
localPlayer:GetAttributeChangedSignal(PlayerAttribute.blasterType):Connect(function()
	local playerState = localPlayer:GetAttribute(PlayerAttribute.playerState)
	if playerState == PlayerState.Playing then
		removeFirstPersonVisuals()
		addFirstPersonVisuals()
	end
end)

-- Handles changing visuals when the playerState changes
localPlayer:GetAttributeChangedSignal(PlayerAttribute.playerState):Connect(function()
	local newPlayerState = localPlayer:GetAttribute(PlayerAttribute.playerState)
	-- Remove the visuals when the player is selecting a blaster (e.g. spawns)
	if newPlayerState == PlayerState.SelectingBlaster then
		removeFirstPersonVisuals()
	-- Add the visuals back when the player finishes selecting the blaster.
	elseif newPlayerState == PlayerState.Playing then
		addFirstPersonVisuals()
	end
end)
