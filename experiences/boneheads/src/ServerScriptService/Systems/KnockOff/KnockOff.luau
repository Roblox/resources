local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Collision = require(ReplicatedStorage.Systems.Collision.Collision)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local HeadConstants = require(ReplicatedStorage.Systems.Head.Constants)
local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local Attributes = Constants.ATTRIBUTES
local THROWN_BY_USER_ID = Attributes.THROWN_BY_USER_ID
local PROJECTILE_REST_SPEED = Constants.PROJECTILE_REST_SPEED
local HEAD_TAG = HeadConstants.HEAD_TAG

local KnockOff = {}
local started = false

local lastKnockOffAt: { [Model]: number } = {}
local attributeConnections: { [Instance]: RBXScriptConnection } = {}
local activeProjectiles: { [Instance]: number? } = {}
local projectileArmedByItem: { [Instance]: boolean } = {}

local function resolveVictimCharacter(part: BasePart): Model?
	local model = part:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") then
			return model
		end
		-- The visible head is a separate model welded to its wearer (not parented under the
		-- character), so a hit on a worn head must map back to the current carrier.
		if CollectionService:HasTag(model, HEAD_TAG) then
			local carrierUserId = model:GetAttribute(Attributes.CARRIER_USER_ID) :: number?
			if not carrierUserId or carrierUserId == 0 then
				return nil
			end

			local carrier = Players:GetPlayerByUserId(carrierUserId)
			local carrierCharacter = carrier and carrier.Character
			if not carrierCharacter then
				return nil
			end

			local headWeld = CarryableUtil.getWeld(carrierCharacter, Constants.HEAD_WELD_NAME)
			if not headWeld or headWeld.Part1 ~= getHostPart(model) then
				return nil
			end

			return carrierCharacter
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end

local function clearProjectile(item: Instance)
	activeProjectiles[item] = nil
	projectileArmedByItem[item] = nil
	item:SetAttribute(THROWN_BY_USER_ID, nil)
end

local function onImpact(impact: Collision.Impact)
	local item = impact.item
	if item:IsA("Accessory") then
		return
	end
	if impact.speed < Constants.MIN_HIT_SPEED then
		return
	end

	local thrower = activeProjectiles[item]
	if not thrower then
		return
	end

	local victim = resolveVictimCharacter(impact.otherPart)
	if not victim then
		return
	end

	local victimPlayer = Players:GetPlayerFromCharacter(victim)
	if victimPlayer and victimPlayer.UserId == thrower then
		return
	end

	local now = os.clock()
	if now - (lastKnockOffAt[victim] or 0) < Constants.KNOCK_OFF_COOLDOWN_SECONDS then
		return
	end
	lastKnockOffAt[victim] = now
	task.delay(Constants.KNOCK_OFF_COOLDOWN_SECONDS, function()
		if lastKnockOffAt[victim] == now then
			lastKnockOffAt[victim] = nil
		end
	end)

	local referencePart = victim:FindFirstChild("HumanoidRootPart") :: BasePart? or CarryableUtil.getUpperTorso(victim)
	if not referencePart then
		return
	end
	CarryableUtil.ejectHead(victim, referencePart)

	clearProjectile(item)
end

local function connectItem(item: Instance)
	if attributeConnections[item] then
		return
	end

	local function refreshProjectile()
		-- Reset the armed flag with the marker: a re-thrown item must re-arm from scratch, or a
		-- stale armed flag lets the first pre-impulse Heartbeat disarm the fresh throw.
		activeProjectiles[item] = item:GetAttribute(THROWN_BY_USER_ID) :: number?
		projectileArmedByItem[item] = nil
	end
	refreshProjectile()
	attributeConnections[item] = item:GetAttributeChangedSignal(THROWN_BY_USER_ID):Connect(refreshProjectile)
end

local function disconnectItem(item: Instance)
	local attributeConnection = attributeConnections[item]
	if attributeConnection then
		attributeConnection:Disconnect()
		attributeConnections[item] = nil
	end

	activeProjectiles[item] = nil
	projectileArmedByItem[item] = nil
end

function KnockOff.start()
	if started then
		return
	end
	started = true

	for _, item in CollectionService:GetTagged(Constants.TAG) do
		connectItem(item)
	end
	CollectionService:GetInstanceAddedSignal(Constants.TAG):Connect(connectItem)
	CollectionService:GetInstanceRemovedSignal(Constants.TAG):Connect(disconnectItem)

	Collision.onImpact(onImpact)

	-- A projectile only stops being tracked once it has actually flown and then come to rest;
	-- arming first avoids clearing a fresh throw before its impulse ramps up the velocity.
	RunService.Heartbeat:Connect(function()
		for item in activeProjectiles do
			local host = getHostPart(item)
			if not host then
				clearProjectile(item)
				continue
			end

			if host.AssemblyLinearVelocity.Magnitude >= PROJECTILE_REST_SPEED then
				projectileArmedByItem[item] = true
			elseif projectileArmedByItem[item] then
				clearProjectile(item)
			end
		end
	end)
end

return KnockOff
