-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local function validateVector3(vector3: Vector3): boolean
	-- Make sure this is actually a Vector3
	if typeof(vector3) ~= "Vector3" then
		return false
	end

	-- Make sure the vector3 does not contain any NaN components
	if vector3 ~= vector3 then
		return false
	end

	return true
end

return validateVector3
