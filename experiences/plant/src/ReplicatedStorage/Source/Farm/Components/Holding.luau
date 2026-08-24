--!strict

--[[
	Handles client-side effects for holding a pickup
--]]

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer :: Player

local Holding = {}
Holding.__index = Holding

export type ClassType = typeof(setmetatable(
	{} :: {
		_characterModel: Model,
	},
	Holding
))

function Holding.new(characterModel: Model): ClassType
	local self = {
		_characterModel = characterModel,
	}

	setmetatable(self, Holding)

	-- Only play animation for local character
	if characterModel == localPlayer.Character then
		self:_onHoldingStarted()
	end

	return self
end

function Holding._onHoldingStarted(self: ClassType)
	-- TODO: Start holding animation
end

function Holding.destroy(self: ClassType)
	-- TODO: Stop holding animation
end

return Holding
