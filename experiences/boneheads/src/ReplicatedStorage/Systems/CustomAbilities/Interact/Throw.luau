local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AvatarAbilities = require("@rbx/AvatarAbilities")
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local ThrowUtil = require(script.Parent.ThrowUtil)
local Rule = AvatarAbilities.Rule

local ACTION_SLOT = 5

local Throw: AvatarAbilities.AbilityDefinition = {
	Name = "Interact",
	Input = {
		InputName = "Interact",
		Mode = "Hold",
		ActionSlot = ACTION_SLOT,
		CustomIcon = "rbxassetid://71984145361462",
		CustomIconActive = "rbxassetid://101534439290003",
	},
	ReadsSensors = { "Carrying" },
	State = {
		chargeStart = Constants.INVALID_STATE_VALUE,
	},
	StartsWhen = Rule.All("Carrying", Rule.Not("DropDebounce")),
	RunsWhile = Rule.All("Carrying"),
	TimedLabels = {
		OnStart = { ThrowThreshold = 0.2 },
	},
}

function Throw.OnStart(managerContext: AvatarAbilities.ManagerContext, abilityContext: AvatarAbilities.AbilityContext)
	if RunService:IsResimulating() then
		-- Rely on server replicating abilityContext.State values
		return
	end

	abilityContext.State.chargeStart = managerContext.Time
end

function Throw.OnStop(managerContext: AvatarAbilities.ManagerContext, abilityContext: AvatarAbilities.AbilityContext)
	local originalChargeStart = abilityContext.State.chargeStart
	abilityContext.State.chargeStart = Constants.INVALID_STATE_VALUE

	if originalChargeStart == Constants.INVALID_STATE_VALUE then
		return
	end

	if managerContext.AbilityManager:HasLabel("ThrowThreshold") then
		-- Released input too quickly for a throw (i.e. ability owner is dropping)
		return
	end

	ThrowUtil.throw(managerContext.AbilityOwner, originalChargeStart, managerContext.Time)
end

return Throw
