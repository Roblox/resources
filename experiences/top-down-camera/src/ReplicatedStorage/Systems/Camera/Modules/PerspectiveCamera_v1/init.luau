--[[
	PERSPECTIVE CAMERA V1
		Top down camera behavior which follows the LocalPlayer character
		with a customizable offset.
--]]

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const SetDefaultCameraBehavior = require(script.Parent.SetDefaultCameraBehavior)

const Constants = require(script.Constants)
const RENDERSTEPPED_BIND_NAME = "UpdateCameraPosition"

const Camera = workspace.CurrentCamera
const LocalPlayer = Players.LocalPlayer

const connections: { RBXScriptConnection } = {}
local enabled = false -- This is a mutable variable, therefore we can't declare it using the `const` keyword!

const function updateCameraPosition(deltaTime: number)
	const character = LocalPlayer.Character
	if not character then
		return
	end

	const characterPosition = character:GetPivot().Position
	const originPosition = characterPosition + Constants.CAMERA_OFFSET
	const goalPosition = CFrame.lookAt(originPosition, characterPosition)
	Camera.CFrame = goalPosition
end

const function applyCameraType(): ()
	Camera.CameraType = Enum.CameraType.Scriptable
end

const function enable()
	if enabled then
		return
	end

	-- Re-apply the scriptable camera on respawn -- Roblox resets CameraType/Subject
	-- on spawn, which would otherwise break our view.
	applyCameraType()
	const charAddedConnection = LocalPlayer.CharacterAdded:Connect(applyCameraType)
	table.insert(connections, charAddedConnection)

	-- Set camera behavior.
	RunService:BindToRenderStep(RENDERSTEPPED_BIND_NAME, Enum.RenderPriority.Camera.Value - 1, updateCameraPosition)

	enabled = true
end

const function disable()
	if not enabled then
		return
	end

	-- Clear all connections.
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)

	-- Set camera back to the default behavior.
	RunService:UnbindFromRenderStep(RENDERSTEPPED_BIND_NAME)
	SetDefaultCameraBehavior()

	enabled = false
end

const CameraBehavior = {
	enable = enable,
	disable = disable,
}

return CameraBehavior
