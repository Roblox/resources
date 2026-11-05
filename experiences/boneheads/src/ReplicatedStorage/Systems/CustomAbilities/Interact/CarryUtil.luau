local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local HeadConstants = require(ReplicatedStorage.Systems.Head.Constants)
local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local Attributes = Constants.ATTRIBUTES

local holdAnimation = Instance.new("Animation")
holdAnimation.AnimationId = Constants.HOLD_ANIMATION_ID

local CarryUtil = {}

local pendingPickupByOwner: { [Model]: thread? } = {}

function CarryUtil.setPendingPickup(owner: Model, pickupThread: thread?)
	pendingPickupByOwner[owner] = pickupThread
end

function CarryUtil.isPickupPending(owner: Model): boolean
	return pendingPickupByOwner[owner] ~= nil
end

function CarryUtil.cancelDetachedPickups()
	for owner, pickupThread in pendingPickupByOwner do
		if pickupThread and not owner:IsDescendantOf(game) then
			task.cancel(pickupThread)
			pendingPickupByOwner[owner] = nil
		end
	end
end

local function isFree(item: Instance): boolean
	local carrierUserId = item:GetAttribute(Attributes.CARRIER_USER_ID)
	return carrierUserId == nil or carrierUserId == 0
end

-- Worn clothing is parented into the character (a Model with a Humanoid); held items stay in Workspace.
function CarryUtil.isWorn(item: Instance): boolean
	local model = item:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return true
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return false
end

function CarryUtil.getNearestFreeCarryable(rootPart: BasePart): Instance?
	local nearest: Instance? = nil
	local nearestDistance = Constants.PICKUP_RADIUS

	for _, item in CollectionService:GetTagged(Constants.TAG) do
		if not item:IsDescendantOf(Workspace) then
			continue
		end
		if not isFree(item) then
			continue
		end
		if CarryUtil.isWorn(item) then
			continue
		end
		local host = getHostPart(item)
		if not host then
			continue
		end

		local distance = (host.Position - rootPart.Position).Magnitude
		if distance <= nearestDistance then
			nearest = item
			nearestDistance = distance
		end
	end

	return nearest
end

local function isOnStealCooldown(item: Instance, now: number): boolean
	local stolenAt = item:GetAttribute(Attributes.STOLEN_AT)
	return typeof(stolenAt) == "number" and now - stolenAt < Constants.STEAL_COOLDOWN_SECONDS
end

function CarryUtil.getNearestStealable(rootPart: BasePart, thief: Model, now: number): Instance?
	local nearest: Instance? = nil
	local nearestDistance = Constants.PICKUP_RADIUS

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character or character == thief then
			continue
		end

		local weld = CarryableUtil.getWeld(character, Constants.HOLD_WELD_NAME)
		local heldHost = weld and weld.Part1
		if not heldHost then
			continue
		end

		local item = CarryableUtil.getCarryableFromHost(heldHost)
		if isOnStealCooldown(item, now) then
			continue
		end

		local distance = (heldHost.Position - rootPart.Position).Magnitude
		if distance <= nearestDistance then
			nearest = item
			nearestDistance = distance
		end
	end

	return nearest
end

function CarryUtil.detachFromOtherHolders(host: BasePart, keeper: Model)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character or character == keeper then
			continue
		end

		local weld = CarryableUtil.getWeld(character, Constants.HOLD_WELD_NAME)
		if not weld or weld.Part1 ~= host then
			continue
		end

		weld.Part0 = nil
		weld.Part1 = nil
		CarryableUtil.stopCarrying(character, player)
	end
end

function CarryUtil.releaseOwnedBy(userId: number)
	local player = Players:GetPlayerByUserId(userId)
	local character = player and player.Character
	local holdWeld = character and CarryableUtil.getWeld(character, Constants.HOLD_WELD_NAME)
	local headWeld = character and CarryableUtil.getWeld(character, Constants.HEAD_WELD_NAME)

	for _, item in CollectionService:GetTagged(Constants.TAG) do
		if item:GetAttribute(Attributes.CARRIER_USER_ID) ~= userId then
			continue
		end
		if item:GetAttribute(HeadConstants.HEAD_OWNER_ATTRIBUTE) == userId then
			continue
		end

		local host = getHostPart(item)
		if host and holdWeld and holdWeld.Part1 == host then
			holdWeld.Part0 = nil
			holdWeld.Part1 = nil
		end
		if host and headWeld and headWeld.Part1 == host then
			headWeld.Part0 = nil
			headWeld.Part1 = nil
		end
		item:SetAttribute(Attributes.CARRIER_USER_ID, 0)
		CarryableUtil.setCollidable(item, true)
	end

	CarryableUtil.stopCarrying(character, player)
end

function CarryUtil.resolveCarryable(upperTorso: BasePart, owner: Model, now: number): Instance?
	local freeItem = CarryUtil.getNearestFreeCarryable(upperTorso)
	if freeItem then
		return freeItem
	end

	local stealableItem = CarryUtil.getNearestStealable(upperTorso, owner, now)
	if not stealableItem then
		return nil
	end

	stealableItem:SetAttribute(Attributes.STOLEN_AT, now)
	return stealableItem
end

function CarryUtil.tryPickup(owner: Model, player: Player, now: number): boolean
	local weld = CarryableUtil.getWeld(owner, Constants.HOLD_WELD_NAME)
	if not weld or weld.Part1 then
		return false
	end
	if CarryUtil.isPickupPending(owner) then
		return false
	end
	local upperTorso = CarryableUtil.getUpperTorso(owner)
	if not upperTorso then
		return false
	end

	local item = CarryUtil.resolveCarryable(upperTorso, owner, now)
	if not item then
		return false
	end

	local host = getHostPart(item)
	if not host then
		return false
	end

	item:SetAttribute(Attributes.CARRIER_USER_ID, player.UserId)
	item:SetAttribute(Attributes.THROWN_BY_USER_ID, nil)
	item:SetAttribute(Attributes.RELEASE_KIND, nil)
	CarryableUtil.setCollidable(item, false)
	CarryUtil.detachFromOtherHolders(host, owner)

	-- Weld a beat after pickup:
	-- > Welding on the same frame tips an off-balance character into FallingDown-- But even when FallingDown ability disabled, tipped over issues can occur
	-- The character can die, respawn, or drop during the delay, so re-validate before touching anything.
	CarryUtil.setPendingPickup(
		owner,
		task.delay(Constants.PICKUP_WELD_DELAY_SECONDS, function()
			CarryUtil.setPendingPickup(owner, nil)
			if not owner:IsDescendantOf(game) then
				return
			end
			if CarryableUtil.getWeld(owner, Constants.HOLD_WELD_NAME) ~= weld or weld.Part1 ~= nil then
				return
			end
			if not host:IsDescendantOf(game) or not upperTorso:IsDescendantOf(game) then
				return
			end
			if item:GetAttribute(Attributes.CARRIER_USER_ID) ~= player.UserId then
				return
			end
			host.AssemblyLinearVelocity = Vector3.zero
			host.AssemblyAngularVelocity = Vector3.zero
			host.CFrame = CarryableUtil.getCarryCFrame(owner) or upperTorso.CFrame
			CarryableUtil.attachWeld(weld, upperTorso, host)
			CarryableUtil.startCarrying(owner, player)
		end)
	)

	return true
end

return CarryUtil
