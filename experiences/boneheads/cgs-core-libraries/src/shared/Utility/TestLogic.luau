-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

type TestFunction<T> = (context: T) -> boolean

local TestLogic = {}

function TestLogic.AND<T>(...: TestFunction<T>): TestFunction<T>
	local testFunctions = { ... }

	return function(context: T): boolean
		for _, testFunction in testFunctions do
			if not testFunction(context) then
				return false
			end
		end

		return true
	end
end

function TestLogic.OR<T>(...: TestFunction<T>): TestFunction<T>
	local testFunctions = { ... }

	return function(context: T): boolean
		for _, testFunction in testFunctions do
			if testFunction(context) then
				return true
			end
		end

		return false
	end
end

function TestLogic.NOT<T>(testFunction: TestFunction<T>): TestFunction<T>
	return function(context: T): boolean
		return not testFunction(context)
	end
end

return TestLogic
