const Players = game:GetService("Players")
const Workspace = game:GetService("Workspace")

const Camera = Workspace.CurrentCamera
const LocalPlayer = Players.LocalPlayer

-- Sets the camera back to the default behavior.
return function()
	Camera.CameraType = Enum.CameraType.Custom

	const character = LocalPlayer.Character
	const humanoid = if character then character:FindFirstChild("Humanoid") else nil
	if humanoid then
		Camera.CameraSubject = humanoid
	end
end
