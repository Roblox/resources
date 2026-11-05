local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local HeadConstants = require(ReplicatedStorage.Systems.Head.Constants)

local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local HEAD_MODEL_NAME = "HeadModel"

local HeadSpawner = {}
local started = false

local headByUserId: { [number]: Model } = {}

local function initializeNameLabel(inHost: BasePart, inPlayer: Player)
	local anchor = Instance.new("Attachment")
	anchor.Name = HeadConstants.CHARACTER_TEXT_ANCHOR_NAME
	anchor.Parent = inHost

	local billboard = Instance.new("BillboardGui")
	billboard.Name = HeadConstants.NAME_BILLBOARD_NAME
	billboard.Adornee = anchor
	billboard.Size = UDim2.fromOffset(HeadConstants.NAME_MAX_WIDTH, HeadConstants.NAME_MAX_HEIGHT)
	billboard.StudsOffsetWorldSpace = Vector3.zero
	billboard.MaxDistance = HeadConstants.NAME_VIEW_RANGE
	billboard.ResetOnSpawn = false
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.PlayerToHideFrom = inPlayer
	billboard.Parent = inHost

	local label = Instance.new("TextLabel")
	label.Name = HeadConstants.NAME_LABEL_NAME
	label.TextColor3 = HeadConstants.NAME_TEXT_COLOR
	label.TextSize = HeadConstants.NAME_TEXT_SIZE
	label.TextTransparency = 0
	label.BackgroundTransparency = 1
	label.TextWrapped = false
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Text = inPlayer.Name
	label.Size = UDim2.fromOffset(0, 0)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0.5, 4)
	label.FontFace = Font.fromEnum(Enum.Font.Gotham)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = billboard

	local subtitleConstraint = Instance.new("UISizeConstraint")
	subtitleConstraint.MaxSize = Vector2.new(HeadConstants.NAME_MAX_WIDTH, HeadConstants.NAME_MAX_HEIGHT)
	subtitleConstraint.Parent = label
end

local function releaseWeldsReferencing(model: Model)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		for _, weldName in { Constants.HOLD_WELD_NAME, Constants.HEAD_WELD_NAME } do
			local weld = CarryableUtil.getWeld(character, weldName)
			if weld and weld.Part1 and weld.Part1:IsDescendantOf(model) then
				weld.Part0 = nil
				weld.Part1 = nil
				if weldName == Constants.HOLD_WELD_NAME then
					CarryableUtil.stopCarrying(character, player)
				end
			end
		end
	end
end

local function destroyHead(userId: number)
	local model = headByUserId[userId]
	if model then
		releaseWeldsReferencing(model)
		model:Destroy()
		headByUserId[userId] = nil
	end
end

local function ensureWeld(character: Model, name: string): WeldConstraint
	local existing = character:FindFirstChild(name)
	if existing and existing:IsA("WeldConstraint") then
		return existing
	end
	local weld = Instance.new("WeldConstraint")
	weld.Name = name
	weld.Parent = character
	return weld
end

local function getHeadModelTemplate(): Model?
	local content = ReplicatedStorage:FindFirstChild("Content")
	local characters = content and content:FindFirstChild("Characters")
	local template = characters and characters:FindFirstChild(HEAD_MODEL_NAME)
	return if template and template:IsA("Model") then template else nil
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild(HeadConstants.HEAD_PART_NAME) :: BasePart?
	if not humanoid or not head then
		return
	end

	ensureWeld(character, Constants.HOLD_WELD_NAME)
	local headWeld = ensureWeld(character, Constants.HEAD_WELD_NAME)

	-- Hide the built-in head but keep it welded, so the character assembly never changes.
	humanoid.RequiresNeck = false
	local surfaceAppearance = head:FindFirstChildOfClass("SurfaceAppearance")
	if surfaceAppearance then
		surfaceAppearance:Destroy()
	end
	head.Transparency = 1
	head.CanCollide = false

	destroyHead(player.UserId)

	local template = getHeadModelTemplate()
	if not template then
		warn(`[HeadSpawner] {HEAD_MODEL_NAME} not found under ReplicatedStorage.Content.Characters; skipping head`)
		return
	end

	local model = template:Clone()
	local host = getHostPart(model)
	assert(host, "HeadModel missing PrimaryPart")
	initializeNameLabel(host, player)

	model.Parent = Workspace

	model:SetAttribute(HeadConstants.HEAD_OWNER_ATTRIBUTE, player.UserId)
	CollectionService:AddTag(model, Constants.TAG)
	CollectionService:AddTag(model, HeadConstants.HEAD_TAG)
	model:SetAttribute(Constants.ATTRIBUTES.CARRIER_USER_ID, player.UserId)
	CarryableUtil.setCollidable(model, false)

	CarryableUtil.attachToHeadSlot(character, headWeld, host)

	headByUserId[player.UserId] = model
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	player.CharacterRemoving:Connect(function()
		destroyHead(player.UserId)
	end)
end

function HeadSpawner.start()
	if started then
		return
	end
	started = true

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		destroyHead(player.UserId)
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return HeadSpawner
