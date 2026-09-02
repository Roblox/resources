-- Get services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")

-- Remote event to update the UI
local uiEvent = ReplicatedStorage:WaitForChild("UIEvent")

-- Data store for saving the player's gold chunks
local goldStore = DataStoreService:GetDataStore("PlayerGold")

-- Table to store the player's gold chunks for a single game session
local playerGold = {}

-- Constants
local GOLD_VALUE = 10 -- How much each gold chunk is worth
local GOLD_REGEN_DELAY = 2 -- The delay before a chunk respawns (in seconds)
local AUTOSAVE_INTERVAL = 30 -- How often the player's chunks are saved (in seconds)

-- Function to handle the player collecting a gold chunk
local function processGoldTouch(chunk, player)
	-- Hide the chunk when the player collects it
	chunk.Parent = nil

	-- Add the chunk to the player's session gold score
	local userId = player.UserId

	playerGold[userId] = (playerGold[userId] or 0) + GOLD_VALUE
	print(player.Name, "now has", playerGold[userId], "gold")

	-- Update the UI to reflect the new gold score for this session
	uiEvent:FireClient(player, {
		gold = playerGold[userId],
		doTween = true,
		showAlert = false,
	})

	-- Wait a bit and then respawn the gold chunk that was just collected
	task.delay(GOLD_REGEN_DELAY, function()
		chunk.Parent = workspace.GoldChunks
	end)
end

-- Loop through all parts tagged with "Gold" and connect them to touch detection
for _, chunk in ipairs(CollectionService:GetTagged("Gold")) do
	chunk.Touched:Connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if player then
			processGoldTouch(chunk, player)
		end
	end)
end

-- Function to save the player's gold to the data store
local function saveGold(player, value)
	local userId = player.UserId

	local success, err = pcall(function()
		goldStore:SetAsync(userId, value)
	end)
	if not success then
		warn("Could not save gold for", player.Name, ":", err)
	end
end

-- Function to handle the player joining the game
local function onPlayerAdded(player)
	local userId = player.UserId

	print(player.Name, "has joined the game")

	-- Try to load the player's gold from the data store
	local success, storedGold = pcall(function()
		return goldStore:GetAsync(userId)
	end)

	if success then
		-- Set the current session gold score using the data store value for the player
		local currentGold = storedGold or 0
		playerGold[userId] = currentGold

		-- Update the UI with the data store value for the player
		uiEvent:FireClient(player, {
			gold = currentGold,
			doTween = false,
			showAlert = false,
		})
		print("Loaded", currentGold, "gold for", player.Name)
	else
		-- Notify the player their gold couldn't be loaded
		uiEvent:FireClient(player, { showAlert = true })
		warn("Could not load gold for", player.Name)
	end

	-- Start the autosave coroutine to save the player's gold every 30 seconds
	coroutine.wrap(function()
		while player.Parent do
			task.wait(AUTOSAVE_INTERVAL)
			if playerGold[userId] then
				saveGold(player, playerGold[userId])
				print("Autosaving", playerGold[userId], "gold for", player.Name)
			end
		end
	end)()
end

-- Function to handle the player leaving the game
local function onPlayerRemoving(player)
	local userId = player.UserId
	print(player.Name, "has left the game")

	-- Check if the player's gold was tracked
	if playerGold[userId] then
		-- Save the player's gold to the data store before they leave
		saveGold(player, playerGold[userId])
	end
end

-- Connect the joining and leaving player events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
