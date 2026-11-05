local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local function getAvatarTemplate(): Model?
	local content = ReplicatedStorage.Content
	local characters = content:FindFirstChild("Characters")
	local playersFolder = characters and characters:FindFirstChild("Players")
	if not playersFolder then
		warn("[AvatarSpawner] Content/Characters/Players folder not found in ReplicatedStorage!")
		return nil
	end

	for _, child in playersFolder:GetChildren() do
		if child:IsA("Model") then
			return child
		end
	end

	warn("[AvatarSpawner] No avatar Models found in Content/Characters/Players!")
	return nil
end

local function installStarterCharacter(): boolean
	local template = getAvatarTemplate()
	if not template then
		return false
	end

	local starter = template:Clone()
	starter.Name = "StarterCharacter"

	local humanoid = starter:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.RigType = Enum.HumanoidRigType.R15
	end

	local existing = StarterPlayer:FindFirstChild("StarterCharacter")
	if existing then
		existing:Destroy()
	end
	starter.Parent = StarterPlayer
	return true
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		task.wait(Players.RespawnTime)
		if player.Parent then
			player:LoadCharacterAsync()
		end
	end)
end

local function onPlayerAdded(player: Player)
	-- Disable ragdoll. Instead dismember in "Dead" ability
	StarterPlayer.CharacterBreakJointsOnDeath = true

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player:LoadCharacterAsync()
end

local CustomAvatarSpawner = {}

function CustomAvatarSpawner.start()
	if not installStarterCharacter() then
		return
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return CustomAvatarSpawner
