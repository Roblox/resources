--[[
	Gets the tip attachment of the player's third person blaster model.
	
	The tip attachment is used for the following:
	- provides an origin for lasers when replicating the blast to other players
	- the parent of the laser blasts's Sound object
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local viewModelName = require(ReplicatedStorage.ViewModelName)

local function getBlasterTipAttachment(player: Player): Attachment?
	local character = player.Character
	if not character then
		return
	end

	-- 'BlasterViewModel' name originates from 'createThirdPersonModel'
	local blasterViewModel = character:FindFirstChild(viewModelName)
	if not blasterViewModel then
		return
	end

	return blasterViewModel.PrimaryPart.TipAttachment
end

return getBlasterTipAttachment
