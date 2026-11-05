local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AbilityConstants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local AudioClient = require(ReplicatedStorage.Systems.Audio.AudioClient)
local bindTagged = require(ReplicatedStorage.Utility.bindTagged)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local CARRYABLE_TAG = AbilityConstants.TAG
local CARRIER_USER_ID_ATTRIBUTE = AbilityConstants.ATTRIBUTES.CARRIER_USER_ID
local RELEASE_KIND_ATTRIBUTE = AbilityConstants.ATTRIBUTES.RELEASE_KIND
local RELEASE_KIND_DROP = AbilityConstants.RELEASE_KIND_DROP
local RELEASE_KIND_THROW = AbilityConstants.RELEASE_KIND_THROW
local HEAD_WELD_NAME = AbilityConstants.HEAD_WELD_NAME

local THROW_SOUND = "Throw"
local DROP_SOUND = "Drop"
local PICKUP_SOUND = "Pickup"
local HEAD_ATTACH_SOUND = "HeadAttach"
local HEAD_DETACH_SOUND = "HeadDetach"
local CLOTH_EQUIP_SOUND = "ClothEquip"
local CLOTH_REMOVE_SOUND = "ClothRemove"

local WELD_WAIT_TIMEOUT_SECONDS = 10

local carrierConnections: { [Instance]: RBXScriptConnection } = {}
local lastCarrierByItem: { [Instance]: number? } = {}

local headWeldConnections: { [Instance]: RBXScriptConnection } = {}
local lastHeadPartByWeld: { [Instance]: BasePart? } = {}
local headDetachedByWeld: { [Instance]: boolean } = {}

local function isCarrier(userId: number?): boolean
	return userId ~= nil and userId ~= 0
end

local function playSound(soundName: string, play: () -> ())
	if not AudioClient.hasDefinition(soundName) then
		warn(`[CarrySfx] missing sound "{soundName}"`)
		return
	end

	play()
end

local function playOnPart(part: BasePart?, soundName: string)
	if not part then
		return
	end

	playSound(soundName, function()
		AudioClient.playOnInstance(soundName, part)
	end)
end

local function playAtPosition(position: Vector3, soundName: string)
	playSound(soundName, function()
		AudioClient.playAtPosition(soundName, position)
	end)
end

local function onCarrierChanged(item: Instance)
	local carrier = item:GetAttribute(CARRIER_USER_ID_ATTRIBUTE) :: number?
	local previousCarrier = lastCarrierByItem[item]
	lastCarrierByItem[item] = carrier

	if isCarrier(previousCarrier) and not isCarrier(carrier) then
		local releaseKind = item:GetAttribute(RELEASE_KIND_ATTRIBUTE)
		if releaseKind == RELEASE_KIND_DROP then
			playOnPart(getHostPart(item), DROP_SOUND)
		elseif releaseKind == RELEASE_KIND_THROW then
			playOnPart(getHostPart(item), THROW_SOUND)
		end
		return
	end

	if isCarrier(carrier) and carrier ~= previousCarrier then
		playOnPart(getHostPart(item), PICKUP_SOUND)
	end
end

local function onCarryableAdded(item: Instance)
	if carrierConnections[item] then
		return
	end

	lastCarrierByItem[item] = item:GetAttribute(CARRIER_USER_ID_ATTRIBUTE) :: number?
	carrierConnections[item] = item:GetAttributeChangedSignal(CARRIER_USER_ID_ATTRIBUTE):Connect(function()
		onCarrierChanged(item)
	end)
end

local function onCarryableRemoved(item: Instance)
	local connection = carrierConnections[item]
	if connection then
		connection:Disconnect()
		carrierConnections[item] = nil
	end

	lastCarrierByItem[item] = nil
end

local function onHeadWeldChanged(weld: WeldConstraint)
	local part1 = weld.Part1
	local previous = lastHeadPartByWeld[weld]
	lastHeadPartByWeld[weld] = part1

	if previous ~= nil and part1 == nil then
		headDetachedByWeld[weld] = true
		playOnPart(previous, HEAD_DETACH_SOUND)
		return
	end

	if part1 ~= nil and previous == nil then
		if headDetachedByWeld[weld] then
			headDetachedByWeld[weld] = false
			playOnPart(part1, HEAD_ATTACH_SOUND)
		end
	end
end

local function watchHeadWeld(weld: WeldConstraint)
	if headWeldConnections[weld] then
		return
	end

	lastHeadPartByWeld[weld] = weld.Part1
	headDetachedByWeld[weld] = false
	headWeldConnections[weld] = weld:GetPropertyChangedSignal("Part1"):Connect(function()
		onHeadWeldChanged(weld)
	end)

	weld.Destroying:Once(function()
		local connection = headWeldConnections[weld]
		if connection then
			connection:Disconnect()
		end
		headWeldConnections[weld] = nil
		lastHeadPartByWeld[weld] = nil
		headDetachedByWeld[weld] = nil
	end)
end

local function isClothingCarryable(child: Instance): boolean
	return child:IsA("Accessory") and CollectionService:HasTag(child, CARRYABLE_TAG)
end

local function onAccessoryEquipped(child: Instance)
	if not isClothingCarryable(child) then
		return
	end

	playOnPart(getHostPart(child), CLOTH_EQUIP_SOUND)
end

local function onAccessoryRemoved(child: Instance)
	if not isClothingCarryable(child) then
		return
	end

	local host = getHostPart(child)
	if not host then
		return
	end

	playAtPosition(host.Position, CLOTH_REMOVE_SOUND)
end

local function onCharacterAdded(character: Model)
	task.spawn(function()
		local weld = character:WaitForChild(HEAD_WELD_NAME, WELD_WAIT_TIMEOUT_SECONDS)
		if weld and weld:IsA("WeldConstraint") then
			watchHeadWeld(weld)
		end
	end)

	local connections = {
		character.ChildAdded:Connect(onAccessoryEquipped),
		character.ChildRemoved:Connect(onAccessoryRemoved),
	}
	character.Destroying:Once(function()
		disconnectAndClear(connections)
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local CarrySfx = {}

local started = false

function CarrySfx.start()
	if started then
		return
	end
	started = true

	bindTagged(CARRYABLE_TAG, { Workspace }, onCarryableAdded, onCarryableRemoved)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return CarrySfx
