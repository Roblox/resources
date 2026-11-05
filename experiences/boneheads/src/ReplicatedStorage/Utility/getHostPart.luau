local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)

local function getHostPart(item: Instance): BasePart?
	local collider = item:FindFirstChild(Constants.COLLIDER_NAME)
	if collider and collider:IsA("BasePart") then
		return collider
	end

	if item:IsA("BasePart") then
		return item
	elseif item:IsA("Model") then
		return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
	end
	return item:FindFirstChildWhichIsA("BasePart", true)
end

return getHostPart
