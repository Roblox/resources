local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AvatarAbilities = require("@rbx/AvatarAbilities")

local createEmoteMenu = nil
if RunService:IsClient() then
	createEmoteMenu = require(script.Parent.EmoteMenu)
end

local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local EmoteMenuSelectionRequest = script.Parent.Remotes.EmoteMenuSelectionRequest
local Identifiers = AvatarAbilities.Identifiers
local Rule = AvatarAbilities.Rule
local Sensor = Identifiers.Sensor
local All, Not = Rule.All, Rule.Not

local EmoteDefinitions = require(script.Parent.EmoteDefinitions)

local random = Random.new()

local ABILITY_NAME = "Emote"
local ACTION_SLOT = 7
local STOP_ABILITY_VALUE = -1

local Emote: AvatarAbilities.AbilityDefinition = {
	Name = ABILITY_NAME,
	RunsWhile = All(Sensor.Ground),
	StartsWhen = All(Not("EmoteCooldown"), Sensor.Ground, Not(Sensor.IsMoving)),
	RequiresSensors = { Sensor.Ground, Sensor.IsMoving },
	Updates = "onSensorChange",
	Input = {
		InputName = ABILITY_NAME,
		Mode = "Toggle",
		ActionSlot = ACTION_SLOT,
		CustomIcon = "rbxassetid://121802838137152",
		CustomIconActive = "rbxassetid://90425900536225",
	},
	TimedLabels = {
		OnStop = { EmoteCooldown = 0.1 },
	},
}

local function getAnimator(character: Model): Animator?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

local function stopEmoteAnimation(abilityContext: AvatarAbilities.AbilityContext)
	local track = abilityContext.Local.animationTrack
	if track and track.IsPlaying then
		track:Stop()
	end
end

local function isDisllowedAbility(name: string): boolean
	if
		name == "Jumping"
		or name == "Sitting"
		or name == "FreeFall"
		or name == "Swimming" -- Disabled ability, but is still disallowed
		or name == "FallingDown" -- Disabled ability, but is still disallowed
		or name == "Climbing" -- Disabled ability, but is still disallowed
	then
		return true
	end

	return false
end

local function onAbilityStarted(name: string, abilityContext: AvatarAbilities.AbilityContext)
	if isDisllowedAbility(name) then
		stopEmoteAnimation(abilityContext)
	end
end

local function watchForLocomotionAndAnimation(
	managerContext: AvatarAbilities.ManagerContext,
	abilityContext: AvatarAbilities.AbilityContext
)
	if abilityContext.Local.animationTrack and abilityContext.Local.animationTrack.IsPlaying then
		table.insert(
			abilityContext.Local.animationWatchConnections,
			abilityContext.Local.animationTrack.Stopped:Connect(function()
				disconnectAndClear(abilityContext.Local.animationWatchConnections)
				abilityContext:Stop()
			end)
		)
		table.insert(
			abilityContext.Local.animationWatchConnections,
			managerContext.AbilityManager.AbilityStarted:Connect(function(name: string)
				onAbilityStarted(name, abilityContext)
			end)
		)
	else
		abilityContext:Stop()
	end
end

local function handleClientPlayEmoteRequest(
	managerContext: AvatarAbilities.ManagerContext,
	abilityContext: AvatarAbilities.AbilityContext,
	inEmoteIndex: number
)
	local element = EmoteDefinitions[inEmoteIndex]
	assert(element, `no emote defined at index {inEmoteIndex}`)

	local assetId = element.assetIds[random:NextInteger(1, #element.assetIds)]

	-- Lazy load Emote animation(s)
	if not abilityContext.Local.animations[assetId] then
		local newAnimation = Instance.new("Animation")
		newAnimation.Name = element.id
		newAnimation.AnimationId = assetId
		abilityContext.Local.animations[assetId] = newAnimation
	end

	if abilityContext.Local.animator == nil then
		abilityContext.Local.animator = getAnimator(managerContext.AbilityOwner) -- lazily load animator when needed
	end

	if not abilityContext.Local.animator then
		return
	end

	stopEmoteAnimation(abilityContext)

	local track = abilityContext.Local.animator:LoadAnimation(abilityContext.Local.animations[assetId])
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	track:Play()

	abilityContext.Local.animationTrack = track
	watchForLocomotionAndAnimation(managerContext, abilityContext)
end

function Emote.OnSetup(managerContext: AvatarAbilities.ManagerContext, abilityContext: AvatarAbilities.AbilityContext)
	if RunService:IsServer() then
		abilityContext.Local.animationWatchConnections = {}
		abilityContext.Local.animator = nil
		abilityContext.Local.animations = {}
		abilityContext.Local.connections = {}
		table.insert(
			abilityContext.Local.connections,
			EmoteMenuSelectionRequest.OnServerEvent:Connect(function(player: Player, emoteIndex: unknown)
				if player ~= Players:GetPlayerFromCharacter(managerContext.AbilityOwner) then
					return
				end

				if not managerContext.AbilityManager:IsAbilityActive(ABILITY_NAME) then
					return
				end

				if typeof(emoteIndex) ~= "number" then
					return
				end

				if emoteIndex == STOP_ABILITY_VALUE then
					abilityContext:Stop()
					return
				end

				if EmoteDefinitions[emoteIndex] == nil then
					return
				end

				handleClientPlayEmoteRequest(managerContext, abilityContext, emoteIndex)
			end)
		)
	end

	if RunService:IsClient() then
		abilityContext.Local.emoteMenu = createEmoteMenu({
			elements = EmoteDefinitions,
			onSelected = function(inEmoteIndex: number)
				EmoteMenuSelectionRequest:FireServer(inEmoteIndex)
			end,
			onDismissed = function()
				abilityContext:Stop()
				EmoteMenuSelectionRequest:FireServer(STOP_ABILITY_VALUE) -- Notify server to stop ability
			end,
		})
	end
end

function Emote.OnTeardown(
	_managerContext: AvatarAbilities.ManagerContext,
	abilityContext: AvatarAbilities.AbilityContext
)
	if RunService:IsServer() then
		stopEmoteAnimation(abilityContext)
		abilityContext.Local.animator = nil
		abilityContext.Local.animationTrack = nil

		if abilityContext.Local.animations then
			for _, animation in abilityContext.Local.animations do
				animation:Destroy()
			end
		end

		if abilityContext.Local.connections then
			disconnectAndClear(abilityContext.Local.connections)
		end

		if abilityContext.Local.animationWatchConnections then
			disconnectAndClear(abilityContext.Local.animationWatchConnections)
		end
	end

	if RunService:IsClient() then
		if abilityContext.Local.emoteMenu then
			abilityContext.Local.emoteMenu.destroy()
			abilityContext.Local.emoteMenu = nil
		end
	end
end

function Emote.OnStart(_managerContext: AvatarAbilities.ManagerContext, abilityContext: AvatarAbilities.AbilityContext)
	-- Phase 1: Open Emote Menu for client
	if RunService:IsClient() and not RunService:IsResimulating() then
		task.spawn(abilityContext.Local.emoteMenu.open)
	end
end

function Emote.OnStop(_managerContext: AvatarAbilities.ManagerContext, abilityContext: AvatarAbilities.AbilityContext)
	if RunService:IsServer() then
		stopEmoteAnimation(abilityContext)
	end

	if RunService:IsClient() then
		task.defer(abilityContext.Local.emoteMenu.close)
	end
end

function Emote.OnUpdate(_managerContext: AvatarAbilities.ManagerContext, abilityContext: AvatarAbilities.AbilityContext)
	if abilityContext.Sensors.RBX_IsMoving.value == true then
		abilityContext:Stop()
	end
end

return Emote
