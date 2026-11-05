local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AimConstants = require(ReplicatedStorage.Systems.Aim.Constants)
local AvatarAbilities = require("@rbx/AvatarAbilities")
local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local Rule = AvatarAbilities.Rule

local Attributes = Constants.ATTRIBUTES
local ACTION_SLOT = 5

local Drop: AvatarAbilities.AbilityDefinition = {
	Name = "Drop",
	Input = {
		InputName = "Interact",
		Mode = "Hold",
		ActionSlot = ACTION_SLOT,
		CustomIcon = "rbxassetid://71984145361462",
		CustomIconActive = "rbxassetid://101534439290003",
	},
	StartsWhen = Rule.All("Carrying", Rule.Not("DropDebounce")),
	RunsWhile = Rule.All("Carrying"),
	TimedLabels = {
		OnStart = { DropWindow = 0.2 },
	},
}

local function drop(owner: Model)
	local weld = CarryableUtil.getWeld(owner, Constants.HOLD_WELD_NAME)
	if not weld or not weld.Part1 then
		return
	end
	local host = weld.Part1
	local item = CarryableUtil.getCarryableFromHost(host)
	local player = Players:GetPlayerFromCharacter(owner)
	if not player then
		return
	end

	item:SetAttribute(Attributes.RELEASE_KIND, Constants.RELEASE_KIND_DROP)
	CarryableUtil.releaseHeldItem(owner, weld, item, player)
	if RunService:IsServer() then
		host.AssemblyLinearVelocity = Vector3.zero
		host.AssemblyAngularVelocity = Vector3.zero
		if player then
			player:SetAttribute(AimConstants.AIM_POINT_ATTRIBUTE, nil)
		end
	end
end

function Drop.OnStop(managerContext: AvatarAbilities.ManagerContext, _abilityContext: AvatarAbilities.AbilityContext)
	if not managerContext.AbilityManager:HasLabel("DropWindow") then
		-- Released input too late for a drop (i.e. ability owner is throwing)
		return
	end

	drop(managerContext.AbilityOwner)
end

return Drop
