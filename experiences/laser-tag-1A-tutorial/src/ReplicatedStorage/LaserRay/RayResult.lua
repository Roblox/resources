--[[
	Defines the result of a ray from a blaster, generated in castLaserRay.

	Describes the destination of the ray as well as the player tagged.
--]]

local RayResult = {}

export type Type = { destination: CFrame, taggedPlayer: Player? }

return RayResult
