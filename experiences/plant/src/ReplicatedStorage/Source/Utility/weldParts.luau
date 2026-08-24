--!strict

--[[
	Welds primaryPart to secondaryPart in place
--]]

local function weldParts(primaryPart: BasePart, secondaryPart: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = primaryPart
	weld.Part1 = secondaryPart
	weld.Parent = secondaryPart

	return weld
end

return weldParts
