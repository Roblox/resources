local SpawnWithFriends = script:FindFirstAncestor("SpawnWithFriends")

local TELEPORT_BEGIN_MESSAGE = "Teleporting %s to a random friend..."
local NO_FRIEND_ERROR = "Couldn't teleport %s to a friend: no friend is present in the server"
local NO_SUITABLE_POINT_ERROR = "Couldn't teleport %s to a friend: no suitable teleportation point was found"
local TELEPORT_SUCCESS_MESSAGE = "Successfully teleported %s to %s"

local Players = game:GetService("Players")

local TeleportToPlayer = require(SpawnWithFriends.Packages.TeleportToPlayer)
local SpawnWithFriendsConfiguration = require(SpawnWithFriends.SpawnWithFriendsConfiguration)

local function log(...)
	local configuration = SpawnWithFriendsConfiguration.getValues()
	if configuration.showLogs then
		print(...)
	end
end

local function teleportToRandomFriend(playerToTeleport: Player)
	local configuration = SpawnWithFriendsConfiguration.getValues()
	log(string.format(TELEPORT_BEGIN_MESSAGE, playerToTeleport.Name))

	local candidates = {}
	local random = Random.new()
	for _, player in ipairs(Players:GetChildren()) do
		if player ~= playerToTeleport then
			local isFriends = false
			if configuration.bypassFriendshipCheck then
				isFriends = true
			else
				local success, message = pcall(function()
					isFriends = player:IsFriendsWith(playerToTeleport.UserId)
				end)
				if not success then
					log("Failed to check friendship status", message)
				end
			end

			if isFriends then
				local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if rootPart and rootPart.Velocity.magnitude < configuration.maxCharacterVelocity then
					-- Note: inserting at a random index is guaranteed to result in a shuffled array
					table.insert(candidates, random:NextInteger(1, #candidates + 1), player)
				end
			end
		end
	end

	if #candidates == 0 then
		log(string.format(NO_FRIEND_ERROR, playerToTeleport.Name))
		return false
	end

	for _, player in ipairs(candidates) do
		local teleportSuccess = TeleportToPlayer.teleport(playerToTeleport, player, configuration.teleportDistance)
		if teleportSuccess then
			log(string.format(TELEPORT_SUCCESS_MESSAGE, playerToTeleport.Name, player.Name))
			return true
		end
	end

	log(string.format(NO_SUITABLE_POINT_ERROR, playerToTeleport.Name))
	return false
end

return teleportToRandomFriend
