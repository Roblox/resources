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

local function onCharacterAdded(character: Model)
	local abilityManager = AvatarAbilities.waitForAbilityManager(character, Constants.WAIT_TIMEOUT_SECONDS)
	if not abilityManager then
		return
	end

	for _, abilityModule in CUSTOM_ABILITIES do
		abilityManager:AddAbility(abilityModule)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

if AvatarAbilities.waitForAbilityManager == nil then
	error(
		"AvatarAbilities.waitForAbilityManager is nil. Ensure the 'Beta Feature' flag 'AvatarAbilities Character Controller Library' is enabled (https://create.roblox.com/docs/characters/character-controller-library/quick-start)"
	)
	return
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
