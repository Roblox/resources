-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera

local function getSubjectVelocity(): Vector3
	local subject: (Humanoid | BasePart | Model)? = camera.CameraSubject
	if not subject then
		return Vector3.zero
	end

	if subject:IsA("BasePart") then
		return subject.AssemblyLinearVelocity
	elseif subject:IsA("Model") then
		local primaryPart = subject.PrimaryPart
		if primaryPart then
			return primaryPart.AssemblyLinearVelocity
		else
			return Vector3.zero
		end
	elseif subject:IsA("Humanoid") then
		local rootPart = subject.RootPart
		if rootPart then
			return rootPart.AssemblyLinearVelocity
		end
	end

	error("Invalid subject type")
end

return getSubjectVelocity
