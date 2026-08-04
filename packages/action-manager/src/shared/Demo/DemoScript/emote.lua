--!strict

local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player

local function emote()
	local character = player.Character
	if character then
		-- This should be casting to :: LocalScript? but Instance? can't be converted to LocalScript?
		-- so we'll just cast to any? for now
		local animateScript = character:FindFirstChild("Animate") :: any?
		if animateScript then
			animateScript.PlayEmote:Invoke("dance")
		end
	end
end

return emote
