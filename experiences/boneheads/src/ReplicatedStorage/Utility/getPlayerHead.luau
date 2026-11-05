local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Systems.Head.Constants)

local HEAD_TAG = Constants.HEAD_TAG
local HEAD_OWNER_ATTRIBUTE = Constants.HEAD_OWNER_ATTRIBUTE

local function getPlayerHead(userId: number): Model?
	for _, model in CollectionService:GetTagged(HEAD_TAG) do
		if model:IsA("Model") and model:GetAttribute(HEAD_OWNER_ATTRIBUTE) == userId then
			return model
		end
	end
	return nil
end

return getPlayerHead
