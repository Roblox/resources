-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

-- Determines if an instance is wireable by checking for the
-- presence of the GetConnectedWires method

local ReflectionService = game:GetService("ReflectionService")

local wireableCache: { [string]: boolean } = {}

local function isWireableInstance(instance: Instance): boolean
	local className = instance.ClassName

	if wireableCache[className] ~= nil then
		return wireableCache[className]
	end

	local classMethods = ReflectionService:GetMethodsOfClass(className, {
		ExcludeInherited = true,
		ExcludeDisplay = true,
	})

	for _, method in classMethods do
		if method.Name == "GetConnectedWires" then
			wireableCache[className] = true
			return true
		end
	end

	wireableCache[className] = false
	return false
end

return isWireableInstance
