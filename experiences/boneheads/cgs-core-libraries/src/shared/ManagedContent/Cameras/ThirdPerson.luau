-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Mouse = require(ReplicatedStorage.Core.Systems.Mouse)
local dampFactor = require(ReplicatedStorage.Core.Utility.dampFactor)
local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)
local getSubjectCenter = require(ReplicatedStorage.Core.Systems.Camera.Utility.getSubjectCenter)
local getSubjectVelocity = require(ReplicatedStorage.Core.Systems.Camera.Utility.getSubjectVelocity)

local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer
local lookInput: InputAction? = nil
local gamepadCameraInput: InputAction? = nil

local FOV = 60
local MIN_PITCH = math.rad(-85)
local MAX_PITCH = math.rad(85)
local FOV_SMOOTH_SPEED = 10
local SIDE_SMOOTH_SPEED = 10
local DISTANCE_SMOOTH_SPEED = 10
local COLLISION_RADIUS = 0.2
local FOCUS_OFFSET = CFrame.new(0, 0, -10)
local SHOULDER_OFFSET = Vector3.new(0, 0, 10)
local HORIZONTAL_SPEED = 15
local VERTICAL_SPEED = 12
local MAX_HORIZONTAL_DISTANCE = 5
local MAX_VERTICAL_DISTANCE = 5

local GAMEPAD_DEADZONE = 0.1
local GAMEPAD_SPEED = Vector2.new(math.rad(180), math.rad(100))

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.RespectCanCollide = true
raycastParams.CollisionGroup = "EnvironmentOnly"

local connections: { RBXScriptConnection } = {}
local touchInputObject: InputObject? = nil
local pitch = 0
local yaw = 0
local zoom = 1
local targetSide = 1
local side = targetSide
local targetDistanceScale = 1
local distanceScale = targetDistanceScale
local horizontalOffset = Vector3.zero
local verticalOffset = Vector3.zero

local isEnabled = false
local isMouseLocked = false

local function incrementPitch(amount: number)
	pitch = math.clamp(pitch + amount, MIN_PITCH, MAX_PITCH)
end

local function incrementYaw(amount: number)
	yaw = (yaw + amount) % (math.pi * 2)
end

local function onCharacterAdded(character: Model)
	raycastParams.FilterDescendantsInstances = { character }
end

local function onInputChanged(inputObject: InputObject, isProcessed: boolean)
	local isTouchInput = inputObject == touchInputObject

	if not isTouchInput and isProcessed then
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.MouseMovement or isTouchInput then
		-- Calculate coefficient for 'size of objects on screen'.
		-- This is used to scale the input so objects move at a consistent speed across the screen
		-- when looking around, regardless of FOV.
		local coefficient = math.tan(math.rad(camera.FieldOfView) / 2)
		local sensitivity = UserGameSettings.MouseSensitivity * 0.25 -- In game sensitivity goes from 0 to 4, we want to map that to 0 to 1

		incrementPitch(-math.rad(inputObject.Delta.Y) * coefficient * sensitivity)
		incrementYaw(-math.rad(inputObject.Delta.X * coefficient) * sensitivity)
	end
end

local function onInputBegan(inputObject: InputObject, isProcessed: boolean)
	if isProcessed then
		return
	end

	if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
		if not isMouseLocked then
			Mouse.pushBehavior("thirdPersonCamera", Enum.MouseBehavior.LockCurrentPosition)
		end
	elseif inputObject.UserInputType == Enum.UserInputType.Touch then
		if touchInputObject then
			return
		end

		touchInputObject = inputObject
	end
end

local function onInputEnded(inputObject: InputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
		if not isMouseLocked then
			Mouse.popBehavior("thirdPersonCamera")
		end
	elseif inputObject == touchInputObject then
		touchInputObject = nil
	end
end

local ThirdPerson = {}

function ThirdPerson.enable()
	if isEnabled then
		return
	end
	isEnabled = true

	local character = player.Character
	if character then
		onCharacterAdded(character)
	end

	table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
	table.insert(connections, UserInputService.InputEnded:Connect(onInputEnded))
	table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
	table.insert(connections, player.CharacterAdded:Connect(onCharacterAdded))

	if isMouseLocked then
		Mouse.pushBehavior("thirdPersonCamera", Enum.MouseBehavior.LockCenter)
	end

	if not (lookInput and gamepadCameraInput) then
		task.spawn(function()
			repeat
				local foundBoth = true

				if not lookInput then
					local foundLookinput = player:QueryDescendants("InputAction #Look") :: { InputAction }
					if #foundLookinput > 0 then
						lookInput = foundLookinput[1]
					else
						foundBoth = false
					end
				end

				if not gamepadCameraInput then
					local foundGamepadInput = player:QueryDescendants("InputAction #GamepadCamera") :: { InputAction }
					if #foundGamepadInput > 0 then
						gamepadCameraInput = foundGamepadInput[1]
					else
						foundBoth = false
					end
				end

				if not foundBoth then
					task.wait()
				end
			until foundBoth
		end)
	end
end

function ThirdPerson.disable()
	if not isEnabled then
		return
	end
	isEnabled = false

	disconnectAndClear(connections)

	Mouse.popBehavior("thirdPersonCamera")
end

function ThirdPerson.lockMouse()
	isMouseLocked = true

	if isEnabled then
		Mouse.pushBehavior("thirdPersonCamera", Enum.MouseBehavior.LockCenter)
	end
end

function ThirdPerson.unlockMouse()
	isMouseLocked = false

	if isEnabled then
		Mouse.popBehavior("thirdPersonCamera")
	end
end

function ThirdPerson.setCollisionFilter(instances: { Instance })
	raycastParams.FilterDescendantsInstances = instances
end

function ThirdPerson.step(delta: number)
	-- Read gamepad input
	if gamepadCameraInput then
		local gamepadInput: Vector2 = gamepadCameraInput:GetState()
		if gamepadInput.Magnitude > GAMEPAD_DEADZONE then
			local inputStrength = math.map(gamepadInput.Magnitude, GAMEPAD_DEADZONE, 1, 0, 1)
			gamepadInput = gamepadInput.Unit * inputStrength

			incrementPitch(gamepadInput.Y * GAMEPAD_SPEED.Y * UserGameSettings.GamepadCameraSensitivity * delta)
			incrementYaw(-gamepadInput.X * GAMEPAD_SPEED.X * UserGameSettings.GamepadCameraSensitivity * delta)
		end
	end

	-- Update camera FOV
	local targetZoomedFov = FOV / zoom
	camera.FieldOfView = math.lerp(camera.FieldOfView, targetZoomedFov, dampFactor(FOV_SMOOTH_SPEED, delta))

	-- Update side
	side = math.lerp(side, targetSide, dampFactor(SIDE_SMOOTH_SPEED, delta))

	-- Update distance
	distanceScale = math.lerp(distanceScale, targetDistanceScale, dampFactor(DISTANCE_SMOOTH_SPEED, delta))

	-- Apply offset based on velocity
	local velocity = getSubjectVelocity()
	horizontalOffset -= Vector3.new(velocity.X, 0, velocity.Z) * delta
	verticalOffset -= Vector3.new(0, velocity.Y, 0) * delta

	if horizontalOffset.Magnitude > MAX_HORIZONTAL_DISTANCE then
		horizontalOffset = horizontalOffset.Unit * MAX_HORIZONTAL_DISTANCE
	end
	if verticalOffset.Magnitude > MAX_VERTICAL_DISTANCE then
		verticalOffset = verticalOffset.Unit * MAX_VERTICAL_DISTANCE
	end

	horizontalOffset = horizontalOffset:Lerp(Vector3.zero, dampFactor(HORIZONTAL_SPEED, delta))
	verticalOffset = verticalOffset:Lerp(Vector3.zero, dampFactor(VERTICAL_SPEED, delta))

	-- Calculate target position
	local center = getSubjectCenter() + horizontalOffset + verticalOffset
	local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local origin = CFrame.new(center) * rotation

	local target = origin:PointToWorldSpace(SHOULDER_OFFSET * Vector3.new(side, 1, distanceScale))

	-- Collision detection
	local result = Workspace:Spherecast(center, COLLISION_RADIUS, target - center, raycastParams)
	if result then
		target = center + (target - center).Unit * result.Distance
	end
	camera.CFrame = CFrame.new(target) * rotation

	-- Move the camera
	camera.Focus = camera.CFrame * FOCUS_OFFSET

	-- Fire look input
	if lookInput then
		lookInput:Fire(camera.CFrame.LookVector)
	end
end

function ThirdPerson.setZoom(newZoom: number)
	zoom = newZoom
end

function ThirdPerson.setDistanceScale(newDistanceScale: number)
	targetDistanceScale = newDistanceScale
end

function ThirdPerson.setSide(isRightSide: boolean)
	targetSide = if isRightSide then 1 else -1
end

return ThirdPerson
