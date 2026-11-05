local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CarryConstants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local Constants = require(script.Parent.Constants)
local HeadConstants = require(ReplicatedStorage.Systems.Head.Constants)
local bindTagged = require(ReplicatedStorage.Utility.bindTagged)
local getPlayerHead = require(ReplicatedStorage.Utility.getPlayerHead)

local DEATH_PLANE_TAG = Constants.DEATH_PLANE_TAG
local TARGET_SPAWN_NAME = Constants.TARGET_SPAWN_NAME
local DEBOUNCE_DURATION = Constants.DEBOUNCE_DURATION
local SPAWN_VERTICAL_OFFSET = Constants.SPAWN_VERTICAL_OFFSET
local HEAD_TAG = HeadConstants.HEAD_TAG
local HEAD_OWNER_ATTRIBUTE = HeadConstants.HEAD_OWNER_ATTRIBUTE
local CARRIER_USER_ID_ATTRIBUTE = CarryConstants.ATTRIBUTES.CARRIER_USER_ID

local connections: { [Instance]: RBXScriptConnection } = {}
local recentlyTeleported: { [string]: boolean } = {}

local function onDeathPlaneTouched(deathPlane: BasePart, targetSpawn: ObjectValue, other: BasePart)
	local parent = other.Parent
	if not (parent and parent:IsA("Model")) then
		return
	end

	local player = Players:GetPlayerFromCharacter(parent)
	local headModel: Model? = nil

	if not player and CollectionService:HasTag(parent, HEAD_TAG) then
		local ownerUserId = parent:GetAttribute(HEAD_OWNER_ATTRIBUTE) :: number?
		if not ownerUserId then
			return
		end
		player = Players:GetPlayerByUserId(ownerUserId)
		headModel = parent
	end

	if not player then
		return
	end

	local debounceKey = if headModel then `head_{player.UserId}` else `body_{player.UserId}`

	if recentlyTeleported[debounceKey] then
		return
	end

	local spawnPart = targetSpawn.Value
	if not (spawnPart and spawnPart:IsA("PVInstance")) then
		warn(`[DeathPlane] {deathPlane:GetFullName()} TargetSpawn has an invalid value`)
		return
	end

	recentlyTeleported[debounceKey] = true

	local spawnCFrame = spawnPart:GetPivot() + Vector3.new(0, SPAWN_VERTICAL_OFFSET, 0)

	if headModel then
		headModel:PivotTo(spawnCFrame)
	else
		local character = player.Character
		if character then
			character:PivotTo(spawnCFrame)
		end

		local ownedHead = getPlayerHead(player.UserId)
		if ownedHead then
			local carrierUserId = ownedHead:GetAttribute(CARRIER_USER_ID_ATTRIBUTE) :: number?
			local isCarriedByOther = carrierUserId and carrierUserId ~= 0 and carrierUserId ~= player.UserId
			if not isCarriedByOther then
				ownedHead:PivotTo(spawnCFrame)
			end
		end
	end

	task.delay(DEBOUNCE_DURATION, function()
		recentlyTeleported[debounceKey] = nil
	end)
end

local function onDeathPlaneAdded(instance: Instance)
	if not instance:IsA("BasePart") then
		warn(`[DeathPlane] {instance:GetFullName()} is not a BasePart`)
		return
	end

	local targetSpawn = instance:FindFirstChild(TARGET_SPAWN_NAME)
	if not targetSpawn or not targetSpawn:IsA("ObjectValue") then
		warn(`[DeathPlane] {instance:GetFullName()} missing ObjectValue child "{TARGET_SPAWN_NAME}"`)
		return
	end

	connections[instance] = instance.Touched:Connect(function(other: BasePart)
		onDeathPlaneTouched(instance, targetSpawn, other)
	end)
end

local function onDeathPlaneRemoved(instance: Instance)
	local connection = connections[instance]
	if connection then
		connection:Disconnect()
		connections[instance] = nil
	end
end

local DeathPlane = {}

function DeathPlane.start()
	bindTagged(DEATH_PLANE_TAG, { Workspace }, onDeathPlaneAdded, onDeathPlaneRemoved)
end

return DeathPlane
