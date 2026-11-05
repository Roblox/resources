local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvatarAbilities = require("@rbx/AvatarAbilities")

local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)

local DISABLED_ABILITIES = { "Swimming", "Sprinting", "Crouching", "Climbing", "Slipping", "FallingDown", "GettingUp" }
local SYNCED_STATE_NAME = "SyncedState"
local ENABLED_ATTRIBUTE = "Enabled"

local function enforceDisabled(syncedState: Instance)
	-- Connect before the initial set so a late CCL re-enable during startup
	-- can't slip through the gap between setting and connecting.
	syncedState:GetAttributeChangedSignal(ENABLED_ATTRIBUTE):Connect(function()
		if syncedState:GetAttribute(ENABLED_ATTRIBUTE) ~= false then
			syncedState:SetAttribute(ENABLED_ATTRIBUTE, false)
		end
	end)

	syncedState:SetAttribute(ENABLED_ATTRIBUTE, false)
end

local function disableAbility(abilities: Instance, abilityName: string)
	local ability = abilities:WaitForChild(abilityName, Constants.WAIT_TIMEOUT_SECONDS)
	local syncedState = ability and ability:WaitForChild(SYNCED_STATE_NAME, Constants.WAIT_TIMEOUT_SECONDS)
	if not ability or not syncedState then
		warn("Timed out waiting for ability: " .. abilityName)
		return
	end

	enforceDisabled(syncedState)
end

local function disableAbilities(character: Model)
	local actor = character:WaitForChild(Constants.ABILITY_MANAGER_ACTOR_NAME, Constants.WAIT_TIMEOUT_SECONDS)
	local abilities = actor and actor:WaitForChild(Constants.ABILITIES_FOLDER_NAME, Constants.WAIT_TIMEOUT_SECONDS)
	if not abilities then
		return
	end

	for _, abilityName in DISABLED_ABILITIES do
		task.spawn(disableAbility, abilities, abilityName)
	end
end

local function onCharacterAdded(character: Model)
	task.spawn(disableAbilities, character)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)

	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local DisableDefaultAbilities = {}

local started = false

function DisableDefaultAbilities.start()
	if started then
		return
	end
	started = true

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
end

return DisableDefaultAbilities
