local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryUtil = require(ReplicatedStorage.Systems.CustomAbilities.Interact.CarryUtil)

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		CarryUtil.releaseOwnedBy(player.UserId)
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	CarryUtil.releaseOwnedBy(player.UserId)
end)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
