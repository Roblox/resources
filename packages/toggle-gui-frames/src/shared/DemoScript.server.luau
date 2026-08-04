local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local mainGui = script.Parent.MainGui

for _, player in Players:GetPlayers() do
	local gui = mainGui:Clone()
	gui.Parent = player.PlayerGui
end

-- Place MainGui into StarterGui so that all players who join will get it automatically
mainGui.Parent = StarterGui
