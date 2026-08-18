--[[
	PERSPECTIVE CAMERA V2
		Top down camera behavior which follows the LocalPlayer character
		with a customizable offset. 

		This version also disables the default controls and allows for a way to
		click/tap to move the character, as well as camera rotation.
--]]

const Players = game:GetService("Players")
const Workspace = game:GetService("Workspace")
const RunService = game:GetService("RunService")

const EnablePlayerMovement = require(script.Parent.EnablePlayerMovement)
const DisablePlayerMovement = require(script.Parent.DisablePlayerMovement)
const MoveCharacterToPosition = require(script.Parent.MoveCharacterToPosition)
const SetDefaultCameraBehavior = require(script.Parent.SetDefaultCameraBehavior)

const Constants = require(script.Constants)
const RENDERSTEPPED_BIND_NAME = "UpdateCameraPosition"

const CameraSystemFolder = script.Parent.Parent
const InputsFolder = CameraSystemFolder.Inputs
const CameraControlContext = InputsFolder.CameraControlContext
const InputViewportPositionAction = CameraControlContext.InputViewportPosition
const RotateCameraRightAction = CameraControlContext.RotateCameraRight
const RotateCameraLeftAction = CameraControlContext.RotateCameraLeft
const MoveCharacterAction = CameraControlContext.MoveCharacter

const Camera = workspace.CurrentCamera
const LocalPlayer = Players.LocalPlayer

const connections: { RBXScriptConnection } = {}

local enabled = false
local inputViewportPosition = Vector2.zero
local currentAngle = 0 -- The current angle the camera is facing.
local targetAngle = 0 -- The target angle the camera is attempting to reach.

const function updateCameraPosition(deltaTime: number): ()
	const character = LocalPlayer.Character
	if not character then
		return
	end

	-- Ease the current yaw toward the target. alpha is clamped so a frame
	-- spike can't overshoot. Set ROTATION_SPEED high (or skip the lerp and
	-- assign currentAngle = targetAngle) for an instant snap instead.
	const alpha = math.min(deltaTime * Constants.ROTATION_SPEED, 1)
	currentAngle += (targetAngle - currentAngle) * alpha

	-- Rotate the offset around Y so the camera orbits the character while
	-- still looking straight at it. The focus point never moves.
	const characterPosition = character:GetPivot().Position
	const rotatedOffset = CFrame.fromAxisAngle(Vector3.yAxis, currentAngle) * Constants.CAMERA_OFFSET
	const originPosition = characterPosition + rotatedOffset
	const goalPosition = CFrame.lookAt(originPosition, characterPosition)
	Camera.CFrame = goalPosition
end

const function applyCameraType(): ()
	Camera.CameraType = Enum.CameraType.Scriptable
end

const function enable(): ()
	if enabled then
		return
	end

	-- Incrementing the targetAngle variable will make the camera rotate towards it.
	const rotateRightConnection = RotateCameraRightAction.Pressed:Connect(function()
		targetAngle += Constants.ROTATION_STEP
	end)
	table.insert(connections, rotateRightConnection)

	const rotateLeftConnection = RotateCameraLeftAction.Pressed:Connect(function()
		targetAngle -= Constants.ROTATION_STEP
	end)
	table.insert(connections, rotateLeftConnection)

	-- Update the latest position of the input on the viewport.
	const inputViewportPositionConnection = InputViewportPositionAction.StateChanged:Connect(
		function(viewportPosition: Vector2)
			inputViewportPosition = viewportPosition
		end
	)
	table.insert(connections, inputViewportPositionConnection)

	-- Move the character to a position based on input viewport position.
	const moveCharacterConnection = MoveCharacterAction.Pressed:Connect(function()
		if inputViewportPosition and inputViewportPosition.Magnitude > 1 then
			MoveCharacterToPosition(inputViewportPosition)
		end
	end)
	table.insert(connections, moveCharacterConnection)

	-- Re-apply the scriptable camera on respawn -- Roblox resets CameraType/Subject
	-- on spawn, which would otherwise break our view.
	applyCameraType()
	const charAddedConnection = LocalPlayer.CharacterAdded:Connect(applyCameraType)
	table.insert(connections, charAddedConnection)

	-- Disable default player movement and set camera behavior.
	DisablePlayerMovement()
	RunService:BindToRenderStep(RENDERSTEPPED_BIND_NAME, Enum.RenderPriority.Camera.Value - 1, updateCameraPosition)

	CameraControlContext.Enabled = true
	enabled = true
end

const function disable(): ()
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
	EnablePlayerMovement()

	CameraControlContext.Enabled = false
	enabled = false
end

const CameraBehavior = {
	enable = enable,
	disable = disable,
}

return CameraBehavior
