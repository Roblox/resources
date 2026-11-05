local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)

local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local Attributes = Constants.ATTRIBUTES

local WearUtil = {}

local function getAccessoryHandle(accessory: Accessory): BasePart?
	local handle = accessory:FindFirstChild(Constants.ACCESSORY_HANDLE_NAME)
	return if handle and handle:IsA("BasePart") then handle else nil
end

function WearUtil.blockAutoEquip(accessory: Accessory)
	local handle = getAccessoryHandle(accessory)
	if handle then
		handle.CanTouch = false
	end
end

function WearUtil.ejectWornAccessory(accessory: Accessory, referencePart: BasePart)
	local host = getHostPart(accessory)
	accessory.Parent = Workspace
	accessory:SetAttribute(Attributes.CARRIER_USER_ID, 0)
	CarryableUtil.setCollidable(accessory, true)
	CarryableUtil.setColliderMassless(accessory, false)

	if host and RunService:IsServer() then
		host.Anchored = false
		-- Loose accessories auto-equip on touch when a slot is empty; block that engine behavior.
		WearUtil.blockAutoEquip(accessory)
		host.CFrame = referencePart.CFrame * CFrame.new(0, Constants.EJECT_POP_HEIGHT, 0)
		CarryableUtil.launchEjected(host, referencePart)
	end
end

function WearUtil.takeOffClothing(character: Model, holdWeld: WeldConstraint, referencePart: BasePart)
	-- Deferred off the sim callback, so bail if the hands are no longer empty.
	if holdWeld.Part1 then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local accessory: Accessory? = nil
	for _, worn in humanoid:GetAccessories() do
		if CollectionService:HasTag(worn, Constants.TAG) then
			accessory = worn
			break
		end
	end
	if not accessory then
		return
	end

	local host = getHostPart(accessory)
	if not host then
		return
	end

	-- Reparent out of the character so it counts as held (not worn), then weld to the hand.
	accessory.Parent = Workspace
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		accessory:SetAttribute(Attributes.CARRIER_USER_ID, player.UserId)
	end
	CarryableUtil.setCollidable(accessory, false)
	CarryableUtil.setColliderMassless(accessory, false)
	-- Loose/held accessories auto-equip on touch when a slot is empty; block that engine behavior.
	WearUtil.blockAutoEquip(accessory)
	host.CFrame = CarryableUtil.getCarryCFrame(character) or referencePart.CFrame
	CarryableUtil.attachWeld(holdWeld, referencePart, host)
	CarryableUtil.startCarrying(character, player)
end

function WearUtil.wearHeldClothing(
	character: Model,
	holdWeld: WeldConstraint,
	accessory: Accessory,
	referencePart: BasePart
)
	-- Deferred off the sim callback, so bail if the item is no longer the one being held.
	if holdWeld.Part1 ~= getHostPart(accessory) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	holdWeld.Part0 = nil
	holdWeld.Part1 = nil

	for _, worn in humanoid:GetAccessories() do
		if worn ~= accessory and worn.AccessoryType == accessory.AccessoryType then
			WearUtil.ejectWornAccessory(worn, referencePart)
		end
	end

	humanoid:AddAccessory(accessory)
	CarryableUtil.setColliderMassless(accessory, true)
end

return WearUtil
