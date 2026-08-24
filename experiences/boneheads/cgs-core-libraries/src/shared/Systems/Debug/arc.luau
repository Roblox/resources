-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)
local line = require(script.Parent.line)

local ARC_ANGLE_SIGNS = {
	top = CFrame.Angles(-1, 0, 0),
	bottom = CFrame.Angles(1, 0, 0),
	left = CFrame.Angles(0, 1, 0),
	right = CFrame.Angles(0, -1, 0),
	center = CFrame.Angles(0, 0, 0),
}

local arc = {}

function arc.create(): Types.ArcLines
	return {
		top = line.create(),
		bottom = line.create(),
		left = line.create(),
		right = line.create(),
		center = line.create(),
		angle = 0,
		length = 0,
		origin = CFrame.new(),
	}
end

function arc.update(
	arcLines: Types.ArcLines,
	origin: CFrame?,
	length: number?,
	angle: number?,
	color: Color3?,
	width: number?
)
	arcLines.angle = angle or arcLines.angle
	arcLines.length = length or arcLines.length
	arcLines.origin = origin or arcLines.origin

	local halfAngle = arcLines.angle / 2
	local position = arcLines.origin.Position

	for name, signs in ARC_ANGLE_SIGNS :: { [string]: CFrame } do
		local sx, sy, sz = signs:ToEulerAnglesXYZ()
		line.update(
			(arcLines :: any)[name],
			position,
			position
				+ (arcLines.origin * CFrame.Angles(sx * halfAngle, sy * halfAngle, sz * halfAngle)).LookVector
					* arcLines.length,
			color,
			width
		)
	end
end

function arc.destroy(arcLines: Types.ArcLines)
	line.destroy(arcLines.top)
	line.destroy(arcLines.bottom)
	line.destroy(arcLines.left)
	line.destroy(arcLines.right)
	line.destroy(arcLines.center)
end

return arc
