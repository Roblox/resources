--[[
	Calls the given callback for all existing players in the game, and any that join thereafter.
	Useful in situations where you want to run code for every player, even players who are already in the game.

	The DemoScript uses safePlayerAdded to ensure all players in the game have a billboard with their name above their character's heads.
--]]

local safePlayerAdded = require(script.Parent.Parent.safePlayerAdded)

local nameBillboardGui = script.Parent.NameBillboardGui

local function addBillboardToPlayer(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local billboard = nameBillboardGui:Clone()
		local textLabel = billboard.TextLabel
		textLabel.Text = player.Name
		billboard.Enabled = true
		billboard.Parent = character
	end)
end

safePlayerAdded(addBillboardToPlayer)
