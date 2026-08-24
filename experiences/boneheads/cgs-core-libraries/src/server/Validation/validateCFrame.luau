-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local validateVector3 = require(script.Parent.validateVector3)

local function validateCFrame(cframe: CFrame): boolean
	-- Make sure this is actually a CFrame
	if typeof(cframe) ~= "CFrame" then
		return false
	end

	if not validateVector3(cframe.Position) then
		return false
	end

	if not validateVector3(cframe.LookVector) then
		return false
	end

	return true
end

return validateCFrame
