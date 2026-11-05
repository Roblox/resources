local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AvatarAbilities = require("@rbx/AvatarAbilities")
local CarryUtil = require(script.Parent.CarryUtil)
local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local Rule = AvatarAbilities.Rule

local Attributes = Constants.ATTRIBUTES
local ACTION_SLOT = 5

local Carry: AvatarAbilities.AbilityDefinition = {
	Name = "Carry",
	Input = {
		InputName = "Interact",
		Mode = "Press",
		ActionSlot = ACTION_SLOT,
		CustomIcon = "rbxassetid://71984145361462",
		CustomIconActive = "rbxassetid://101534439290003",
	},
	State = {
		handsEmptyAtStart = Constants.INVALID_STATE_VALUE,
	},
	RunsWhile = Rule.Any("DropDebounce", "Carrying"), -- Consider DropDebounce for keeping ability active, to accomodate frame delay on setting "Carrying" attribute
	TimedLabels = {
		OnStart = { DropDebounce = 0.3 },
	},
}

function Carry.OnStart(managerContext: AvatarAbilities.ManagerContext, abilityContext: AvatarAbilities.AbilityContext)
	if RunService:IsResimulating() then
		-- Rely on server replicating abilityContext.State values
		return
	end

	abilityContext.State.handsEmptyAtStart = Constants.INVALID_STATE_VALUE
	CarryUtil.cancelDetachedPickups()

	local owner = managerContext.AbilityOwner
	local player = Players:GetPlayerFromCharacter(owner)
	if not player then
		return
	end

	local weld = CarryableUtil.getWeld(owner, Constants.HOLD_WELD_NAME)
	local handsEmptyAtStart = weld == nil or weld.Part1 == nil
	if handsEmptyAtStart then
		-- Preventing clients from predicting 'pickup', since it could lead to diverging states
		-- > Could rollback state if detected, but gets complicated
		-- > Or could, alternative restrict writes to the server only, but that leads to odd side-effects w/ or without latency (particularly with server-only "detachFromOtherHolders")
		if RunService:IsServer() then
			CarryUtil.tryPickup(owner, player, managerContext.Time)
		end
	end

	abilityContext.State.handsEmptyAtStart = if handsEmptyAtStart
		then Constants.HANDS_EMPTY_VALUE
		else Constants.HANDS_NOT_EMPTY_VALUE
end

local CarryingSensor: AvatarAbilities.SensorRegistration = {
	Name = "Carrying",
	Make = function(managerContext: AvatarAbilities.ManagerContext, _abilityContext: AvatarAbilities.AbilityContext?)
		local player = Players:GetPlayerFromCharacter(managerContext.AbilityOwner)
		local conn = nil

		local function read()
			if player == nil then
				return false
			end

			local isCarrying = player:GetAttribute(Attributes.IS_CARRYING)
			return isCarrying ~= nil and isCarrying == true
		end

		local function wake(notify)
			if player then
				conn = player:GetAttributeChangedSignal(Attributes.IS_CARRYING):Connect(notify)
			end
		end

		local function cleanup()
			if conn then
				conn:Disconnect()
			end
		end

		return AvatarAbilities.reactiveSensor(read, wake, cleanup)
	end,
}

Carry.RegistersSensors = { CarryingSensor }

return Carry
