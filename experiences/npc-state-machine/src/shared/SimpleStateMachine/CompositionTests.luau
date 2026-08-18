--[[
These are helpful functions that let us combine many TestFunctions into one.
It's useful for writing more complex transition tests.
]]

local Types = require(script.Parent.Types)

type Context = Types.Context
type TestFunction = Types.TestFunction

-- AND
-- If all of the TestFunctions you provide are TRUE, it returns TRUE.
-- But if even one is FALSE, it returns FALSE.
local function AND(...: TestFunction): TestFunction
	local tests = { ... }
	return function(context: Context): boolean
		for _, test in tests do
			if not test(context) then
				return false
			end
		end
		return true
	end
end

-- OR
-- If any of the TestFunctions you provide is TRUE, it returns TRUE.
-- Only if every TestFunction is FALSE, it returns FALSE.
local function OR(...: TestFunction): TestFunction
	local tests = { ... }
	return function(context: Context): boolean
		for _, test in tests do
			if test(context) then
				return true
			end
		end
		return false
	end
end

-- NOT
-- If the TestFunction you provide is TRUE, it returns FALSE.
-- Or, if the TestFunction is FALSE, it returns TRUE.
local function NOT(test: TestFunction): TestFunction
	return function(context: Context): boolean
		return not test(context)
	end
end

return {
	AND = AND,
	OR = OR,
	NOT = NOT,
}
