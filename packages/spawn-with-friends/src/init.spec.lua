local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.Packages.Dev.JestGlobals)
local expect = JestGlobals.expect
local it = JestGlobals.it

it("should require the module without erroring", function()
	expect(function()
		require(script.Parent)
	end).never.toThrow()
end)
