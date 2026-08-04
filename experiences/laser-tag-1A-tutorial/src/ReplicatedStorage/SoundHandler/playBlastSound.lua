--[[
	Plays blast sounds for a player that has blasted.

	The laser sound instance exist within the blaster's tip attachment (see createThirdPersonModel).
	Gets the tip attachment for the player and plays this sound instance.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getBlasterTipAttachment = require(ReplicatedStorage.Blaster.getBlasterTipAttachment)

local function playBlastSound(playerBlasted: Player)
	-- Get the tip attachment from the player's blaster
	local blasterTipAttachment = getBlasterTipAttachment(playerBlasted)
	if not blasterTipAttachment then
		warn(`Cannot replicate blast sound, unable to find blaster tip attachment for {playerBlasted.Name}`)
		return
	end

	-- Play the Sound instance within the tip attachment
	for _, child in blasterTipAttachment:GetChildren() do
		if child:IsA("Sound") then
			-- Since sounds are reused, call stop to restart the sound in case it is already playing
			child:Stop()
			child:Play()
		end
	end
end

return playBlastSound
