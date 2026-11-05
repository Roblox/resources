local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AimConstants = require(ReplicatedStorage.Systems.Aim.Constants)
local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local Players = game:GetService("Players")

local isFiniteVector = require(ReplicatedStorage.Utility.isFiniteVector)

local Attributes = Constants.ATTRIBUTES

export type ActivationState = { handsEmptyAtStart: boolean, chargeStart: number }

local ThrowUtil = {}

ThrowUtil.MIN_AIM_MAGNITUDE = 1e-3

function ThrowUtil.forgetDetachedOwners(
	inoutActivationByOwner: { [Model]: ActivationState },
	inoutLastPickupByOwner: { [Model]: number }
)
	for owner in inoutActivationByOwner do
		if not owner:IsDescendantOf(game) then
			inoutActivationByOwner[owner] = nil
		end
	end
	for owner in inoutLastPickupByOwner do
		if not owner:IsDescendantOf(game) then
			inoutLastPickupByOwner[owner] = nil
		end
	end
end

function ThrowUtil.getCharge(chargeStart: number, time: number): number
	return math.clamp((time - chargeStart) / Constants.MAX_CHARGE_TIME, 0, 1)
end

function ThrowUtil.getThrowCharge(character): number?
	if not character then
		return nil
	end

	local actor = character:FindFirstChild("AbilityManagerActor")
	local abilitiesFolder = actor and actor:FindFirstChild("Abilities")
	local interactConfig = abilitiesFolder and abilitiesFolder:FindFirstChild("Interact")
	local interactSyncedState = interactConfig and interactConfig:FindFirstChild("SyncedState")
	local chargeStart = interactSyncedState and interactSyncedState:GetAttribute("chargeStart")
	if typeof(chargeStart) ~= "number" or chargeStart == Constants.INVALID_STATE_VALUE then
		return nil
	end

	return ThrowUtil.getCharge(chargeStart, time())
end

function ThrowUtil.clampAimPitch(aimDirection: Vector3): Vector3
	if not isFiniteVector(aimDirection) or aimDirection.Magnitude < 1e-4 then
		return Vector3.new(0, 0, -1)
	end
	local unit = aimDirection.Unit
	local flat = Vector3.new(unit.X, 0, unit.Z)
	if flat.Magnitude < 1e-4 then
		return unit
	end
	flat = flat.Unit
	local maxPitch = math.rad(Constants.THROW_MAX_PITCH_DEGREES)
	local pitch = math.clamp(math.asin(math.clamp(unit.Y, -1, 1)), -maxPitch, maxPitch)
	return flat * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
end

function ThrowUtil.throw(owner: Model, originalChargeStart: number, currentTime: number): boolean
	local weld = CarryableUtil.getWeld(owner, Constants.HOLD_WELD_NAME)
	if not weld or not weld.Part1 then
		return false
	end
	local host = weld.Part1
	local item = CarryableUtil.getCarryableFromHost(host)

	local player = Players:GetPlayerFromCharacter(owner)
	if not player then
		return false
	end

	local charge = ThrowUtil.getCharge(originalChargeStart, currentTime)

	local aimPoint = player and player:GetAttribute(AimConstants.AIM_POINT_ATTRIBUTE)
	local rootPart = owner.PrimaryPart
	local aimSource = if rootPart then rootPart.CFrame.LookVector else Vector3.new(0, 0, -1)
	if typeof(aimPoint) == "Vector3" and rootPart then
		local toAim = aimPoint - rootPart.Position
		if toAim.Magnitude >= ThrowUtil.MIN_AIM_MAGNITUDE then
			aimSource = toAim
		end
	end

	local aim = ThrowUtil.clampAimPitch(aimSource)

	item:SetAttribute(Attributes.RELEASE_KIND, Constants.RELEASE_KIND_THROW)
	CarryableUtil.releaseHeldItem(owner, weld, item, player)

	host.AssemblyLinearVelocity = Vector3.zero
	host.AssemblyAngularVelocity = Vector3.zero
	local speed = Constants.THROW_MIN_FORCE + (Constants.THROW_MAX_FORCE - Constants.THROW_MIN_FORCE) * charge
	host:ApplyImpulse(aim * speed * host.AssemblyMass)
	if player then
		item:SetAttribute(Attributes.THROWN_BY_USER_ID, player.UserId)
		player:SetAttribute(AimConstants.AIM_POINT_ATTRIBUTE, nil)
	end

	return true
end

return ThrowUtil
