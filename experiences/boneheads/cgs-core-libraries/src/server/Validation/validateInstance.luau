-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

--[[
	Ensures the instance is not an 'imposter' and is of the expected class.

	In cases where the server is expecting an instance, exploiters can pass a table with keys
	that mimic the instance's properties but set to whatever they want.

	e.g.
	local fakePart = {
		Position = Vector3.new()
	}

	remoteExpectingPart:FireServer(fakePart)

	It is unsafe for the server to blindly accept the position of this fake part without
	checking it is a valid instance first.
]]

local function validateInstance(instance: Instance, expectedClass: string): boolean
	if typeof(instance) ~= "Instance" then
		return false
	end

	return instance:IsA(expectedClass)
end

return validateInstance
