--!nocheck
--[[
	Sets the player's portrait for the HUD Gui.
--]]

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local function setPlayerPortrait(gui: ScreenGui)
	local playerPortrait = gui.PlayerDisplay.PlayerPortrait

	local userId = localPlayer.UserId
	local thumbType = "AvatarHeadShot"
	local rbxthumbContentString = `rbxthumb://type={thumbType}&id={userId}&w=150&h=150`
	playerPortrait.Image = rbxthumbContentString
end

return setPlayerPortrait
