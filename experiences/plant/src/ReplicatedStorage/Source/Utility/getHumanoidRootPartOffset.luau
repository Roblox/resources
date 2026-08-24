--!strict

--[[
	Returns the height offset from the bottom of a character to the middle of its HumanoidRootPart
--]]

local function getHumanoidRootPartOffset(humanoid: Humanoid)
	local rootPart = humanoid.RootPart
	assert(rootPart, "Humanoid has no RootPart set")

	return (rootPart.Size.Y * 0.5) + humanoid.HipHeight
end

return getHumanoidRootPartOffset
