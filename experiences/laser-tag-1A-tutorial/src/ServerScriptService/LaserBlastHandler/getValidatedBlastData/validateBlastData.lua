--[[
	Validates the types within the BlastData object.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlastData = require(ReplicatedStorage.Blaster.BlastData)

local function validateBlastData(blastData: BlastData.Type)
	if typeof(blastData) ~= "table" then
		return false
	elseif typeof(blastData.originCFrame) ~= "CFrame" then
		return false
	elseif typeof(blastData.rayResults) ~= "table" then
		return false
	end

	return true
end

return validateBlastData
