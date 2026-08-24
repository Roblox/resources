-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Constants)

type BehaviorEntry = {
	id: string,
	behavior: Enum.MouseBehavior,
}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local behaviorStack: { BehaviorEntry } = {}
local canMouseLock = true

local function updateMouseLock()
	if not canMouseLock then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif #behaviorStack == 0 then
		UserInputService.MouseBehavior = Constants.DEFAULT_BEHAVIOR
	else
		UserInputService.MouseBehavior = behaviorStack[#behaviorStack].behavior
	end
end

local Mouse = {}

function Mouse.getWorldPosition(): Vector3
	local mouseLocation = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local character = player.Character
	if character then
		raycastParams.FilterDescendantsInstances = { character }
	end

	local result =
		Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * Constants.WORLD_CHECK_DISTANCE, raycastParams)

	if result then
		return result.Position
	else
		return mouseRay.Origin + mouseRay.Direction * Constants.WORLD_CHECK_DISTANCE
	end
end

function Mouse.pushBehavior(id: string, behavior: Enum.MouseBehavior)
	Mouse.popBehavior(id)

	table.insert(behaviorStack, {
		id = id,
		behavior = behavior,
	})

	updateMouseLock()
end

function Mouse.popBehavior(id: string)
	for index, entry in behaviorStack do
		if entry.id == id then
			table.remove(behaviorStack, index)
			break
		end
	end

	updateMouseLock()
end

return Mouse
