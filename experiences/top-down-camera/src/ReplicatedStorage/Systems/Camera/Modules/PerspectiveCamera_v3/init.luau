--[[
	PERSPECTIVE CAMERA V3
		RTS-style free-panning perspective camera. Owns a FocusPosition that pans
		across the ground plane and orbits it via a yawed CAMERA_OFFSET. Input is
		driven through the shared CameraControlContext.
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
const MoveCameraAction = CameraControlContext.MoveCamera

const Camera = workspace.CurrentCamera
const LocalPlayer = Players.LocalPlayer

const connections: { RBXScriptConnection } = {}

local enabled = false

-- The focus point we pan around; rotation orbits CAMERA_OFFSET about it.
-- targetAngle is what input drives; currentAngle eases toward it each frame.
local focusPosition = Vector3.zero
local moveCameraAxis = Vector2.zero -- (x = right/left, y = forward/backward)
local inputViewportPosition = Vector2.zero
local currentAngle = 0
local targetAngle = 0

const function updateCameraPosition(deltaTime: number): ()
	-- Ease the current yaw toward the target. alpha is clamped so a frame
	-- spike can't overshoot. Raise ROTATION_SPEED (or assign currentAngle =
	-- targetAngle) for an instant snap instead.
	const alpha = math.min(deltaTime * Constants.ROTATION_SPEED, 1)
	currentAngle += (targetAngle - currentAngle) * alpha

	const rotatedOffset = CFrame.fromAxisAngle(Vector3.yAxis, currentAngle) * Constants.CAMERA_OFFSET

	-- Ground-plane basis from the current yaw, so panning follows the rotated view.
	const flatLook = Vector3.new(-rotatedOffset.X, 0, -rotatedOffset.Z)
	const forwardXZ = if flatLook.Magnitude > 0 then flatLook.Unit else Vector3.zAxis
	const rightXZ = forwardXZ:Cross(Vector3.yAxis)

	-- Pan the focus we own outright -- nothing else can stomp this between frames.
	focusPosition += (rightXZ * moveCameraAxis.X + forwardXZ * moveCameraAxis.Y) * Constants.PAN_SPEED * deltaTime
	Camera.CFrame = CFrame.lookAt(focusPosition + rotatedOffset, focusPosition)
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

	-- Store the latest pan axis; updateCameraPosition applies it every frame.
	const moveCameraConnection = MoveCameraAction.StateChanged:Connect(function(axis: Vector2)
		moveCameraAxis = axis
	end)
	table.insert(connections, moveCameraConnection)

	-- Re-apply the scriptable camera on respawn -- Roblox resets CameraType/Subject
	-- on spawn, which would otherwise break our view.
	applyCameraType()
	const charAddedConnection = LocalPlayer.CharacterAdded:Connect(applyCameraType)
	table.insert(connections, charAddedConnection)

	-- Disable player movement, take over the camera and start panning from a clean origin.
	DisablePlayerMovement()
	RunService:BindToRenderStep(RENDERSTEPPED_BIND_NAME, Enum.RenderPriority.Camera.Value - 1, updateCameraPosition)
	moveCameraAxis = Vector2.zero
	focusPosition = Vector3.zero

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

const IsometricCamera = {
	enable = enable,
	disable = disable,
}

return IsometricCamera
