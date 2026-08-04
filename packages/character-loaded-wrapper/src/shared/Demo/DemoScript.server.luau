--[[
	Provides an API to use when referencing a Player's character to make sure it is "Fully loaded", which is defined as:
		1) Character is a descendant of workspace
		2) Character has a PrimaryPart set
		3) Character contains a child which is a Humanoid
		4) The Humanoid's RootPart property is not nil

	This differs from Player.CharacterAdded and Player.CharacterAppearanceLoaded which fire before a character is parented to workspace and does not guarantee these other conditions.

	This wrapper provides a died event when the first of the following happens:
		1) Humanoid's .Died event fires
		2) Character is removed

	This can be useful for cases where a character can be removed without the humanoid dying, such as if :LoadCharacter() is called before a character dies.
	Cleanup code often needs to run when a character's "lifespan" is over, whether it be because the humanoid died or because the character is removed.
	To avoid having to connect to both events in multiple places, this wrapper moves both events into one.
--]]

local Players = game:GetService("Players")

local CharacterLoadedWrapper = require(script.Parent.Parent.CharacterLoadedWrapper)

local function onPlayerAdded(player: Player)
	local characterLoadedWrapper = CharacterLoadedWrapper.new(player)
	characterLoadedWrapper.loaded:Connect(function()
		print(string.format("[CharacterLoadedWrapper] %s character loaded", player.Name))
	end)
	characterLoadedWrapper.died:Connect(function()
		print(string.format("[CharacterLoadedWrapper] %s character died", player.Name))
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
