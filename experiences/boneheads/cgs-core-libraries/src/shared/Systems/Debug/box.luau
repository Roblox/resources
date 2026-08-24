-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Constants = require(script.Parent.Constants)
local Utils = require(script.Parent.Utils)

local box = {}

function box.create(): Part
	local part = Instance.new("Part")
	part.Name = Constants.BOX.NAME
	part.Material = Enum.Material.Neon
	part.Transparency = Constants.BOX.TRANSPARENCY
	part.Position = Vector3.zero

	Utils.makeIntangible(part)

	part.Parent = Utils.getContainer()

	return part
end

function box.update(part: Part, origin: CFrame?, size: Vector3?, color: Color3?)
	part.CFrame = origin or part.CFrame
	part.Size = size or part.Size
	part.Color = color or part.Color
end

function box.destroy(part: Part)
	part:Destroy()
end

return box
