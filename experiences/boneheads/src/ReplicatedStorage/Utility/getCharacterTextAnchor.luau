local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Systems.Head.Constants)

local getHostPart = require(ReplicatedStorage.Utility.getHostPart)

local function getCharacterTextAnchorFromHead(inHead: Instance): Attachment?
	if inHead:IsA("BasePart") then
		return inHead:FindFirstChild(Constants.CHARACTER_TEXT_ANCHOR_NAME, true) :: Attachment
	elseif inHead:IsA("Model") then
		local host = getHostPart(inHead)
		if host then
			return host:FindFirstChild(Constants.CHARACTER_TEXT_ANCHOR_NAME, true) :: Attachment
		end
	end

	return nil
end

return getCharacterTextAnchorFromHead
