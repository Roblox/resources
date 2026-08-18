const Players = game:GetService("Players")
const LocalPlayer = Players.LocalPlayer

-- Disables the LocalPlayer default movement.
return function()
	const playerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return
	end

	local controls = require(playerModule):GetControls()
	controls:Disable()
end
