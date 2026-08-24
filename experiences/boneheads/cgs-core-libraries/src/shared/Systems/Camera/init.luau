-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local RunService = game:GetService("RunService")

local Types = require(script.Types)

export type CameraController = Types.CameraController

local BIND_NAME = "Camera"
local BIND_PRIORITY = Enum.RenderPriority.Camera.Value

local baseCamera: CameraController? = nil
local activeCamera: CameraController? = nil
local cameraStack: { CameraController } = {}
local modifierStack: { CameraController } = {}

local function step(delta: number)
	if activeCamera then
		activeCamera.step(delta)
	end

	for _, modifier in modifierStack do
		modifier.step(delta)
	end
end

local function updateActiveCamera()
	local newCamera = baseCamera
	if #cameraStack > 0 then
		newCamera = cameraStack[#cameraStack]
	end

	if newCamera == activeCamera then
		return
	end

	if activeCamera then
		activeCamera.disable()
	end
	if newCamera then
		newCamera.enable()
	end

	activeCamera = newCamera
end

local Camera = {}

function Camera.setBaseCamera(camera: CameraController)
	if baseCamera then
		baseCamera.disable()
	end

	baseCamera = camera
	updateActiveCamera()
end

function Camera.pushCamera(camera: CameraController)
	table.insert(cameraStack, camera)
	updateActiveCamera()
end

function Camera.popCamera(camera: CameraController)
	local index = table.find(cameraStack, camera)
	if not index then
		return
	end

	table.remove(cameraStack, index)
	updateActiveCamera()
end

function Camera.pushModifier(modifier: CameraController)
	table.insert(modifierStack, modifier)
	modifier.enable()
end

function Camera.popModifier(modifier: CameraController)
	local index = table.find(modifierStack, modifier)
	if not index then
		return
	end

	modifier.disable()
	table.remove(modifierStack, index)
end

function Camera.start()
	RunService:BindToRenderStep(BIND_NAME, BIND_PRIORITY, step)
end

return Camera
