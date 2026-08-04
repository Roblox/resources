--[[
	Provides the ability switch between enabling and disabling camera movement for the player.
--]]

local Workspace = game:GetService("Workspace")

local function togglePlayerCamera(isEnabled: boolean)
	local camera = Workspace.CurrentCamera
	if not isEnabled then
		-- Setting the CameraType to Scriptable will stop the default behavior of the camera
		-- and will only move or change if done within a script.
		camera.CameraType = Enum.CameraType.Scriptable
	else
		-- Return to the default Roblox camera type, StarterPlayer.CameraType = LockFirstPerson
		-- behavior is restored.
		camera.CameraType = Enum.CameraType.Custom
	end
end

return togglePlayerCamera
