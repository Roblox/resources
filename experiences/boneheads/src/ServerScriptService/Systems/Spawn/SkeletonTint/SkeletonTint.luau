local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(script.Parent.Constants)
local HeadConstants = require(ReplicatedStorage.Systems.Head.Constants)

local TINTS = Constants.TINTS

local tintIndexByUserId: { [number]: number } = {}
local characterAddedConnectionByPlayer: { [Player]: RBXScriptConnection } = {}

local function getLeastUsedTintIndex(): number
	local useCounts = table.create(#TINTS, 0)
	for _, tintIndex in tintIndexByUserId do
		useCounts[tintIndex] += 1
	end

	local leastUsedIndex = 1
	for tintIndex, useCount in useCounts do
		if useCount < useCounts[leastUsedIndex] then
			leastUsedIndex = tintIndex
		end
	end
	return leastUsedIndex
end

local function getOrAssignTint(userId: number): Color3?
	local tintIndex = tintIndexByUserId[userId]
	if tintIndex then
		return TINTS[tintIndex]
	end

	-- Deferred events can land after the player left; assigning then would hold a tint slot forever.
	if not Players:GetPlayerByUserId(userId) then
		return nil
	end

	tintIndex = getLeastUsedTintIndex()
	tintIndexByUserId[userId] = tintIndex
	return TINTS[tintIndex]
end

-- Skeleton parts carry more than one SurfaceAppearance and the engine renders an arbitrary
-- one, so every copy must be tinted or some limbs come out untinted.
local function tintPart(part: BasePart, tint: Color3)
	for _, child in part:GetChildren() do
		if child:IsA("SurfaceAppearance") then
			child.Color = tint
		end
	end
end

local function onCharacterAdded(player: Player, character: Model)
	local tint = getOrAssignTint(player.UserId)
	if not tint then
		return
	end

	-- Only direct children: accessory handles are nested under their Accessory, so clothing keeps its colors.
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") then
			tintPart(child, tint)
		end
	end
end

local function onHeadAdded(head: Instance)
	local ownerUserId = head:GetAttribute(HeadConstants.HEAD_OWNER_ATTRIBUTE)
	if typeof(ownerUserId) ~= "number" then
		return
	end

	local tint = getOrAssignTint(ownerUserId)
	if not tint then
		return
	end

	for _, descendant in head:GetDescendants() do
		if descendant:IsA("BasePart") then
			tintPart(descendant, tint)
		end
	end
end

local function onPlayerAdded(player: Player)
	getOrAssignTint(player.UserId)

	characterAddedConnectionByPlayer[player] = player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	local connection = characterAddedConnectionByPlayer[player]
	if connection then
		connection:Disconnect()
		characterAddedConnectionByPlayer[player] = nil
	end

	tintIndexByUserId[player.UserId] = nil
end

local SkeletonTint = {}

function SkeletonTint.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(onPlayerRemoving)

	CollectionService:GetInstanceAddedSignal(HeadConstants.HEAD_TAG):Connect(onHeadAdded)
	for _, head in CollectionService:GetTagged(HeadConstants.HEAD_TAG) do
		onHeadAdded(head)
	end
end

return SkeletonTint
