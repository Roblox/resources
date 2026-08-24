-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Parent.Constants)

local camera = Workspace.CurrentCamera

local function getSubjectCenter(): Vector3
	local subject: (Humanoid | BasePart | Model)? = camera.CameraSubject
	if not subject then
		return Vector3.zero
	end

	if subject:IsA("BasePart") then
		return subject.CFrame:PointToWorldSpace(Constants.HEAD_OFFSET)
	elseif subject:IsA("Model") then
		local primaryPart = subject.PrimaryPart
		if primaryPart then
			return primaryPart.CFrame:PointToWorldSpace(Constants.HEAD_OFFSET)
		else
			return subject:GetPivot():PointToWorldSpace(Constants.HEAD_OFFSET)
		end
	elseif subject:IsA("Humanoid") then
		local rootPart = subject.RootPart
		if rootPart then
			return rootPart.CFrame:PointToWorldSpace(Constants.HEAD_OFFSET)
		end
	end

	error("Invalid subject type")
end

return getSubjectCenter
