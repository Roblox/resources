local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local HeadConstants = require(ReplicatedStorage.Systems.Head.Constants)
local getAnimator = require(ReplicatedStorage.Utility.getAnimator)

local Attributes = Constants.ATTRIBUTES

local holdAnimation = Instance.new("Animation")
holdAnimation.AnimationId = Constants.HOLD_ANIMATION_ID

local CarryableUtil = {}

function CarryableUtil.getWeld(character: Model, weldName: string): WeldConstraint?
	local weld = character:FindFirstChild(weldName)
	return if weld and weld:IsA("WeldConstraint") then weld else nil
end

function CarryableUtil.attachWeld(weld: WeldConstraint, part0: BasePart, part1: BasePart)
	part1.Anchored = false
	weld.Part0 = part0
	weld.Part1 = part1
end

function CarryableUtil.attachToHeadSlot(character: Model, headWeld: WeldConstraint, host: BasePart)
	local head = character:FindFirstChild(HeadConstants.HEAD_PART_NAME) :: BasePart?
	assert(head, `missing {HeadConstants.HEAD_PART_NAME} on {character:GetFullName()}`)
	host.CFrame = head.CFrame
	CarryableUtil.attachWeld(headWeld, head, host)
end

function CarryableUtil.getUpperTorso(character: Model): BasePart?
	local part = character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart")
	return if part and part:IsA("BasePart") then part else nil
end

function CarryableUtil.getCarryCFrame(character: Model): CFrame?
	local reference = CarryableUtil.getUpperTorso(character)
	if not reference then
		return nil
	end
	return reference.CFrame * CFrame.new(0, Constants.CARRY_HEIGHT, -Constants.CARRY_DISTANCE)
end

function CarryableUtil.getCarryableFromHost(host: BasePart): Instance
	if CollectionService:HasTag(host, Constants.TAG) then
		return host
	end
	local ancestor = host.Parent
	while ancestor do
		if CollectionService:HasTag(ancestor, Constants.TAG) then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return host
end

function CarryableUtil.playHoldAnimation(character: Model)
	if not RunService:IsServer() then
		return
	end
	local animator = getAnimator(character)
	if not animator then
		return
	end
	CarryableUtil.stopHoldAnimation(character)
	local track = animator:LoadAnimation(holdAnimation)
	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = true
	track:Play()
end

function CarryableUtil.stopHoldAnimation(character: Model)
	if not RunService:IsServer() then
		return
	end
	local animator = getAnimator(character)
	if not animator then
		return
	end
	for _, track in animator:GetPlayingAnimationTracks() do
		if track.Animation and track.Animation.AnimationId == Constants.HOLD_ANIMATION_ID then
			track:Stop()
		end
	end
end

function CarryableUtil.stopCarrying(character: Model?, player: Player?)
	if player then
		player:SetAttribute(Attributes.IS_CARRYING, false)
	end
	if character then
		CarryableUtil.stopHoldAnimation(character)
	end
end

function CarryableUtil.startCarrying(character: Model?, player: Player?)
	if player then
		player:SetAttribute(Attributes.IS_CARRYING, true)
	end
	if character then
		CarryableUtil.playHoldAnimation(character)
	end
end

function CarryableUtil.setCollidable(item: Instance, collidable: boolean)
	local collider = item:FindFirstChild(Constants.COLLIDER_NAME)
	if collider and collider:IsA("BasePart") then
		collider.CanCollide = collidable
		return
	end

	if item:IsA("BasePart") then
		item.CanCollide = collidable
	end
	for _, descendant in item:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = collidable
		end
	end
end

function CarryableUtil.setColliderMassless(item: Instance, massless: boolean)
	local collider = item:FindFirstChild(Constants.COLLIDER_NAME)
	if collider and collider:IsA("BasePart") then
		collider.Massless = massless
	end
end

function CarryableUtil.releaseHeldItem(owner: Model, weld: WeldConstraint, item: Instance, player: Player)
	weld.Part0 = nil
	weld.Part1 = nil
	item:SetAttribute(Attributes.CARRIER_USER_ID, 0)
	CarryableUtil.setCollidable(item, true)
	CarryableUtil.stopCarrying(owner, player)
end

function CarryableUtil.launchEjected(host: BasePart, referencePart: BasePart)
	host.AssemblyLinearVelocity = Vector3.zero
	host.AssemblyAngularVelocity = Vector3.zero
	local velocity = -referencePart.CFrame.LookVector * Constants.EJECT_FORCE
		+ Vector3.new(0, Constants.EJECT_UP_FORCE, 0)
	host:ApplyImpulse(velocity * host.AssemblyMass)
end

function CarryableUtil.ejectHead(character: Model, referencePart: BasePart)
	local headWeld = CarryableUtil.getWeld(character, Constants.HEAD_WELD_NAME)
	if not headWeld then
		return
	end
	local headHost = headWeld.Part1
	if not headHost then
		return
	end

	local headItem = CarryableUtil.getCarryableFromHost(headHost)
	headWeld.Part0 = nil
	headWeld.Part1 = nil
	CarryableUtil.setCollidable(headItem, true)
	headItem:SetAttribute(Attributes.CARRIER_USER_ID, 0)

	if RunService:IsServer() then
		CarryableUtil.launchEjected(headHost, referencePart)
	end
end

return CarryableUtil
