--[[
	Creates a third-person view model blaster for other players to see what blaster
	a player has.

	This model is invisible in first-person because it's inside the character,
	and all parts in the character become locally invisible while in first-person.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local createThirdPersonModel = require(script.createThirdPersonModel)

local attributeChangedConnectionByPlayer = {}

local function onPlayerAdded(player: Player)
	attributeChangedConnectionByPlayer[player] = player
		:GetAttributeChangedSignal(PlayerAttribute.blasterType)
		:Connect(function()
			createThirdPersonModel(player)
		end)
end

local function onPlayerRemoving(player: Player)
	if attributeChangedConnectionByPlayer[player] then
		attributeChangedConnectionByPlayer[player]:Disconnect()
		attributeChangedConnectionByPlayer[player] = nil
	end
end

-- Call onPlayerAdded for any players already in the game
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Call onPlayerAdded for all future players
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
