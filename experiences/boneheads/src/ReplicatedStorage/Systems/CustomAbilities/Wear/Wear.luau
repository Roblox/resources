local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AvatarAbilities = require("@rbx/AvatarAbilities")
local CarryUtil = require(ReplicatedStorage.Systems.CustomAbilities.Interact.CarryUtil)
local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local Players = game:GetService("Players")
local WearUtil = require(ReplicatedStorage.Systems.CustomAbilities.Wear.WearUtil)

local ACTION_SLOT = 6

local Wear: AvatarAbilities.AbilityDefinition = {
	Name = "Wear",
	Input = {
		InputName = "Wear",
		Mode = "Hold",
		ActionSlot = ACTION_SLOT,
		CustomIcon = "rbxassetid://116517673048325",
		CustomIconActive = "rbxassetid://108395972232389",
	},
}

function Wear.OnStart(managerContext: AvatarAbilities.ManagerContext, _abilityContext: AvatarAbilities.AbilityContext)
	if not RunService:IsServer() then
		return
	end

	local owner = managerContext.AbilityOwner
	local upperTorso = CarryableUtil.getUpperTorso(owner)
	if not upperTorso then
		return
	end
	local holdWeld = CarryableUtil.getWeld(owner, Constants.HOLD_WELD_NAME)
	local headWeld = CarryableUtil.getWeld(owner, Constants.HEAD_WELD_NAME)
	if not holdWeld or not headWeld then
		return
	end

	local player = Players:GetPlayerFromCharacter(managerContext.AbilityOwner)
	if not player then
		return
	end

	local handsHost = holdWeld.Part1
	local headHost = headWeld.Part1

	if handsHost then
		local heldItem = CarryableUtil.getCarryableFromHost(handsHost)
		if heldItem:IsA("Accessory") then
			-- Accessory APIs (GetAccessories/AddAccessory) are banned inside the sim callback; run after it.
			if RunService:IsServer() then
				task.defer(WearUtil.wearHeldClothing, owner, holdWeld, heldItem, upperTorso)
			end
			CarryableUtil.stopCarrying(owner, player)
			return
		end

		-- Put the held item on the head, ejecting whatever is currently worn.
		local rootPart = (owner:FindFirstChild("HumanoidRootPart") :: BasePart?) or upperTorso
		CarryableUtil.ejectHead(owner, rootPart)
		holdWeld.Part0 = nil
		holdWeld.Part1 = nil
		CarryableUtil.attachToHeadSlot(owner, headWeld, handsHost)
		CarryableUtil.stopCarrying(owner, player)
	elseif headHost then
		headWeld.Part0 = nil
		headWeld.Part1 = nil
		headHost.CFrame = CarryableUtil.getCarryCFrame(owner) or upperTorso.CFrame
		CarryableUtil.attachWeld(holdWeld, upperTorso, headHost)
		CarryableUtil.startCarrying(owner, player)
	else
		-- Accessory APIs (GetAccessories) are banned inside the sim callback; run after it, server-only.
		-- Skip while a Carry pickup is mid-flight so we don't fill the hands and strand its pending weld.
		if RunService:IsServer() and not CarryUtil.isPickupPending(owner) then
			task.defer(WearUtil.takeOffClothing, owner, holdWeld, upperTorso)
		end
	end
end

return Wear
