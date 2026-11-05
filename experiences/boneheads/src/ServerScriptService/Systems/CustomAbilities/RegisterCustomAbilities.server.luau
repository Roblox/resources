local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarAbilities = require("@rbx/AvatarAbilities")

local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)

local CUSTOM_ABILITIES = {
	ReplicatedStorage.Systems.CustomAbilities.Interact.Carry,
	ReplicatedStorage.Systems.CustomAbilities.Interact.Drop,
	ReplicatedStorage.Systems.CustomAbilities.Interact.Throw,
	ReplicatedStorage.Systems.CustomAbilities.Emote.Emote,
	ReplicatedStorage.Systems.CustomAbilities.Wear.Wear,
}

local DELAY_TIME = 0.25

local function addAbilityTask(character: Model, abilityModule: ModuleScript, inAttemptTime: number?, inError: any?)
	if not character:IsDescendantOf(game) then
		return
	end

	local totalAttemptTime = inAttemptTime or 0.0
	if totalAttemptTime > Constants.WAIT_TIMEOUT_SECONDS then
		if inError then
			warn("addAbilityForCharacter Error:", inError)
		else
			warn("Failed to add ability " .. tostring(abilityModule))
		end
		return
	end

	local ok, errorOrResult = pcall(AvatarAbilities.addAbilityForCharacter, character, abilityModule)
	if not ok then
		task.delay(DELAY_TIME, addAbilityTask, character, abilityModule, totalAttemptTime + DELAY_TIME, errorOrResult)
	end
end

local function onCharacterAdded(character: Model)
	-- Note: There is no "AvatarAbility" readiness flag. Wait til ready (seemingly ready when "Dispatch" is avaialble, but additionally retry add ability calls if failed, to more reliably handle
	local actor = character:WaitForChild(Constants.ABILITY_MANAGER_ACTOR_NAME, Constants.WAIT_TIMEOUT_SECONDS)
	local _dispatch = actor and actor:WaitForChild(Constants.DISPATCH_NAME, Constants.WAIT_TIMEOUT_SECONDS)
	if not actor then
		return
	end

	for _, abilityModule in CUSTOM_ABILITIES do
		addAbilityTask(character, abilityModule)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
