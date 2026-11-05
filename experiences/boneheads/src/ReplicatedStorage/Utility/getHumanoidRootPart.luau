local function getHumanoidRootPart(character: Model?): BasePart?
	return (character and character:FindFirstChild("HumanoidRootPart")) :: BasePart?
end

return getHumanoidRootPart
