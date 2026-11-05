local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AbilityConstants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local bindTagged = require(ReplicatedStorage.Utility.bindTagged)
local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local CARRYABLE_TAG = AbilityConstants.TAG
local CARRIER_USER_ID_ATTRIBUTE = AbilityConstants.ATTRIBUTES.CARRIER_USER_ID

export type Impact = {
	item: Instance,
	host: BasePart,
	otherPart: BasePart,
	speed: number,
}

type Listener = (impact: Impact) -> ()

local touchConnections: { [Instance]: RBXScriptConnection } = {}
local pendingHostConnections: { [Instance]: RBXScriptConnection } = {}
local listeners: { Listener } = {}

local function isCarried(item: Instance): boolean
	local carrierUserId = item:GetAttribute(CARRIER_USER_ID_ATTRIBUTE)
	return carrierUserId ~= nil and carrierUserId ~= 0
end

-- Worn clothing is parented into the character (a Model with a Humanoid); it moves with the
-- body and its Touched fires constantly, so it must never read as a free-item impact.
local function isWorn(item: Instance): boolean
	local model = item:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return true
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return false
end

local function onTouched(item: Instance, host: BasePart, otherPart: BasePart)
	if otherPart:IsDescendantOf(item) then
		return
	end

	if isCarried(item) or isWorn(item) then
		return
	end

	local impact: Impact = {
		item = item,
		host = host,
		otherPart = otherPart,
		speed = host.AssemblyLinearVelocity.Magnitude,
	}

	for _, listener in table.clone(listeners) do
		task.spawn(listener, impact)
	end
end

local function bindTouch(item: Instance, host: BasePart)
	touchConnections[item] = host.Touched:Connect(function(otherPart: BasePart)
		onTouched(item, host, otherPart)
	end)
end

local function onCarryableAdded(item: Instance)
	if touchConnections[item] then
		return
	end

	local host = getHostPart(item)
	if host then
		bindTouch(item, host)
		return
	end

	if pendingHostConnections[item] then
		return
	end

	-- Under StreamingEnabled (or with a late PrimaryPart) the item's parts can arrive after the
	-- tag; bind once a host is available.
	pendingHostConnections[item] = item.DescendantAdded:Connect(function()
		local resolvedHost = getHostPart(item)
		if not resolvedHost then
			return
		end

		local pending = pendingHostConnections[item]
		if pending then
			pending:Disconnect()
			pendingHostConnections[item] = nil
		end

		bindTouch(item, resolvedHost)
	end)
end

local function onCarryableRemoved(item: Instance)
	local connection = touchConnections[item]
	if connection then
		connection:Disconnect()
		touchConnections[item] = nil
	end

	local pending = pendingHostConnections[item]
	if pending then
		pending:Disconnect()
		pendingHostConnections[item] = nil
	end
end

local Collision = {}

local started = false

function Collision.start()
	if started then
		return
	end
	started = true

	bindTagged(CARRYABLE_TAG, { Workspace }, onCarryableAdded, onCarryableRemoved)
end

-- Fires for every touch on a free (not carried or worn) carryable in Workspace; listeners apply
-- their own speed thresholds and cooldowns.
function Collision.onImpact(listener: Listener): () -> ()
	table.insert(listeners, listener)

	return function()
		local index = table.find(listeners, listener)
		if index then
			table.remove(listeners, index)
		end
	end
end

return Collision
