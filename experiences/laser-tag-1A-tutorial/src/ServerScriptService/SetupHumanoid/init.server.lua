--[[
	Entry point for humanoid setup logic upon spawning
--]]

local Players = game:GetService("Players")

local setupHumanoidAsync = require(script.setupHumanoidAsync)

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	setupHumanoidAsync(player, humanoid)
end

local function onPlayerAdded(player: Player)
	-- Call onCharacterAdded if the player already has a character
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	-- Call onCharacterAdded for all future character spawns for this player
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
end

-- Call onPlayerAdded for any players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
-- Call onPlayerAdded for all future players
Players.PlayerAdded:Connect(onPlayerAdded)
