local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- We will keep track of what checkpoint each player has last touched
local lastCheckpointByPlayer: { [Player]: BasePart } = {}

-- When a player spawns, teleport them to their last checkpoint
local function onCharacterAdded(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	local checkpoint = lastCheckpointByPlayer[player]
	if not checkpoint then
		-- This player has not touched any checkpoint yet, so we do nothing
		return
	end

	-- Wait for character to load into the game
	if not character.Parent then
		character.AncestryChanged:Wait()
		task.wait()
	end

	-- Determine the target location for the character
	local checkpointOffsetY = checkpoint.Size.Y / 2
	local hipHeightOffsetY = humanoid.HipHeight
	local rootPartOffsetY = humanoid.RootPart.Size.Y / 2
	local totalOffsetY = checkpointOffsetY + hipHeightOffsetY + rootPartOffsetY

	local targetCFrame = checkpoint.CFrame + totalOffsetY * Vector3.yAxis
	character:PivotTo(targetCFrame)
end

local function setupCheckpoint(checkpoint: Instance)
	if not checkpoint:IsA("BasePart") then
		return
	end

	-- When a player touches a checkpoint, we update their last touched checkpoint
	local function onCheckpointTouched(hit: BasePart)
		local character = hit.Parent
		if not character then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if (not humanoid) or humanoid.Health <= 0 then
			-- Cannot switch checkpoints if the player is dead
			return
		end

		lastCheckpointByPlayer[player] = checkpoint
	end

	checkpoint.Touched:Connect(onCheckpointTouched)
end

-- Connect the character added event for each player
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)

-- Clean up the player's checkpoint data when they leave
Players.PlayerRemoving:Connect(function(player)
	lastCheckpointByPlayer[player] = nil
end)

-- Listen for checkpoint touches
for _, checkpoint in CollectionService:GetTagged("Checkpoint") do
	setupCheckpoint(checkpoint)
end

-- Listen for new checkpoints being added
CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(setupCheckpoint)
