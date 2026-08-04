--[[
	Demonstrates connecting to common player, character and humanoid events.
	Events covered: PlayerAdded, PlayerRemoving, CharacterAdded, CharacterRemoving, CharacterAppearanceLoaded and Died (humanoid).
--]]

local Players = game:GetService("Players")

local function onPlayerAdded(player: Player)
	print(player.Name, "has joined the Experience")

	local function onCharacterAdded(character: Model)
		print(player.Name, "character was added to Workspace")

		local humanoid = character:WaitForChild("Humanoid")

		local function onDied()
			print(player.Name, "Humanoid has died")
		end
		humanoid.Died:Connect(onDied)
	end

	local function onCharacterRemoving(_)
		print(player.Name, "character is being removed from Workspace")
	end

	local function onCharacterAppearanceLoaded(_)
		print(player.Name, "character appearance has loaded")
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)
	player.CharacterAppearanceLoaded:Connect(onCharacterAppearanceLoaded)
end

local function onPlayerRemoving(player: Player)
	print(player.Name, "is leaving the Experience")
end

for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
