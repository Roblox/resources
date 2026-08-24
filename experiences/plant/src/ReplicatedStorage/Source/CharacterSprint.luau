--!strict

--[[
	Increases WalkSpeed when the player is outside of a farm to
	make walking around the market area less cumbersome
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
local LocalWalkJumpManager = require(ReplicatedStorage.Source.LocalWalkJumpManager)
local ZoneIdTag = require(ReplicatedStorage.Source.SharedConstants.CollectionServiceTag.ZoneIdTag)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)

local localPlayer = Players.LocalPlayer :: Player

local SPRINT_OFFSET = 20

local CharacterSprint = {}
CharacterSprint._started = false
CharacterSprint._characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer)

function CharacterSprint.start()
	assert(not CharacterSprint._started, "CharacterSprint started more than once")
	CharacterSprint._started = true
	CharacterSprint._listenForFarmZone()
end

function CharacterSprint._listenForFarmZone()
	local farmZoneAddedSignal = CollectionService:GetInstanceAddedSignal(ZoneIdTag.InFarm)
	local farmZoneRemovedSignal = CollectionService:GetInstanceRemovedSignal(ZoneIdTag.InFarm)

	-- Stop sprinting while the player is inside of a farm
	farmZoneAddedSignal:Connect(function(instance: Instance)
		if not CharacterSprint._shouldChangeSpeed(instance) then
			return
		end

		LocalWalkJumpManager.getWalkValueManager():removeOffset(PlayerFacingString.ValueManager.Sprint)
	end)

	-- Sprint while the player is outside of a farm
	farmZoneRemovedSignal:Connect(function(instance: Instance)
		if not CharacterSprint._shouldChangeSpeed(instance) then
			return
		end

		LocalWalkJumpManager.getWalkValueManager():setOffset(PlayerFacingString.ValueManager.Sprint, SPRINT_OFFSET)
	end)
end

function CharacterSprint._shouldChangeSpeed(instance: Instance)
	assert(
		instance:IsA("Model"),
		string.format(
			"InFarm Zone tag was added to %s (%s), but is meant only for character models",
			instance:GetFullName(),
			instance.ClassName
		)
	)
	-- Only listen to the owner's character entering a farm
	local playerMaybe = Players:GetPlayerFromCharacter(instance) :: Player?
	if playerMaybe ~= localPlayer then
		return false
	end

	if not CharacterSprint._characterLoadedWrapper:isLoaded() then
		return false
	end

	return true
end

return CharacterSprint
