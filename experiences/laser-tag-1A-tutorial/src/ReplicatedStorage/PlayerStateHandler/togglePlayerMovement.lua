--[[
	Provides the ability to toggle between allowing and prevent the player from moving their character.
--]]

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local player = Players.LocalPlayer

local function togglePlayerMovement(isEnabled: boolean)
	local character = player.Character
	local humanoid = character.Humanoid

	if not isEnabled then
		humanoid.JumpHeight = 0
		humanoid.WalkSpeed = 0
	else
		humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
		humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
	end
end

return togglePlayerMovement
