local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AbilityConstants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local Constants = require(script.Parent.Constants)
local HeadConstants = require(ReplicatedStorage.Systems.Head.Constants)
local createSubjectSmoother = require(script.Parent.SubjectSmoother)
local getHumanoidRootPart = require(ReplicatedStorage.Utility.getHumanoidRootPart)

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CameraController = {}

local RENDER_STEP_NAME = "BoneheadCamera"

local HEAD_TAG = HeadConstants.HEAD_TAG
local OWNER_ATTRIBUTE = HeadConstants.HEAD_OWNER_ATTRIBUTE
local CARRYABLE_TAG = AbilityConstants.TAG
local CARRY_OWNER_ATTRIBUTE = AbilityConstants.ATTRIBUTES.CARRIER_USER_ID

local THIRD_PERSON_SMOOTH_TIME = Constants.THIRD_PERSON_SMOOTH_TIME
local THIRD_PERSON_ENGAGE_DISTANCE = Constants.THIRD_PERSON_ENGAGE_DISTANCE
local THIRD_PERSON_SNAP_DISTANCE = Constants.THIRD_PERSON_SNAP_DISTANCE
local THIRD_PERSON_FOLLOW_HEIGHT = Constants.THIRD_PERSON_FOLLOW_HEIGHT
local FIRST_PERSON_DISTANCE = Constants.FIRST_PERSON_DISTANCE

local FOLLOW_HEIGHT_OFFSET = Vector3.new(0, THIRD_PERSON_FOLLOW_HEIGHT, 0)

local followSmoother = createSubjectSmoother(
	THIRD_PERSON_SMOOTH_TIME,
	Vector3.zero,
	THIRD_PERSON_SNAP_DISTANCE,
	THIRD_PERSON_ENGAGE_DISTANCE
)

local active = false
local cameraAnchor: BasePart? = nil
local ownedHead: Model? = nil

local function ensureAnchor(): BasePart
	if cameraAnchor and cameraAnchor.Parent then
		return cameraAnchor
	end
	local anchor = Instance.new("Part")
	anchor.Name = "CameraFollowAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Massless = true
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Archivable = false
	anchor.Parent = Workspace
	cameraAnchor = anchor
	return anchor
end

local function getOwnedHead(): Model?
	if ownedHead and ownedHead.Parent then
		return ownedHead
	end
	ownedHead = nil
	for _, head in CollectionService:GetTagged(HEAD_TAG) do
		if head:IsA("Model") and head:GetAttribute(OWNER_ATTRIBUTE) == localPlayer.UserId then
			ownedHead = head
			break
		end
	end
	return ownedHead
end

local function rootFollowPoint(character: Instance?): Vector3?
	if not (character and character:IsA("Model")) then
		return nil
	end
	local rootPart = getHumanoidRootPart(character)
	return rootPart and rootPart.Position + FOLLOW_HEIGHT_OFFSET
end

local function getFollowTarget(): Vector3?
	local head = getOwnedHead()
	if not head then
		return rootFollowPoint(localPlayer.Character)
	end

	local headPos = head:GetPivot().Position

	local carryOwnerId = head:GetAttribute(CARRY_OWNER_ATTRIBUTE) :: number?
	if carryOwnerId and carryOwnerId ~= 0 then
		local carrier = Players:GetPlayerByUserId(carryOwnerId)
		return (carrier and rootFollowPoint(carrier.Character)) or headPos
	end
	if CollectionService:HasTag(head, CARRYABLE_TAG) then
		return headPos
	end
	return rootFollowPoint(head.Parent) or headPos
end

local function isFirstPerson(): boolean
	local head = getOwnedHead()
	if not (camera and head) then
		return false
	end
	return (head:GetPivot().Position - camera.CFrame.Position).Magnitude < FIRST_PERSON_DISTANCE
end

local function setLocalHeadHidden(hidden: boolean)
	local head = getOwnedHead()
	if not head then
		return
	end
	local modifier = if hidden then 1 else 0
	for _, part in head:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = modifier
		end
	end
end

local function step(delta: number)
	setLocalHeadHidden(isFirstPerson())
	local target = getFollowTarget()
	if not target then
		active = false
		return
	end
	local anchor = ensureAnchor()
	if not active then
		active = true
		anchor.Position = target
		followSmoother.reset()
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = anchor
	end
	anchor.Position = followSmoother.update(target, delta) :: Vector3
end

local function onCharacterAdded()
	-- The engine points CameraSubject at the new Humanoid on spawn; re-activating re-applies the anchor.
	active = false
end

function CameraController.start()
	active = false
	localPlayer.CharacterAdded:Connect(onCharacterAdded)
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value, step)
end

return CameraController
