--[[
	Positions the given blasterViewModel at the right hand grip attachment and welds it
	with a WeldConstraint.
--]]

local function weldBlasterToCharacter(blasterViewModel: Model, character: Model): WeldConstraint
	local rightGripAttachment = character:FindFirstChild("RightHand"):FindFirstChild("RightGripAttachment")
	blasterViewModel:PivotTo(rightGripAttachment.WorldCFrame)

	-- Weld is parented to the view model, so destroying the view model destroys the weld
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = rightGripAttachment.Parent
	weldConstraint.Part1 = blasterViewModel.PrimaryPart
	weldConstraint.Parent = blasterViewModel

	return weldConstraint
end

return weldBlasterToCharacter
