--[[
	Generates data that define a laser's blast, used only in blastClient.

	Data is used to construct the visuals of the blast on the Client, and are used for validation on the Server.

	The blast originates from the center of the player's screen for the local player, even though the visuals
	are shown from the tip of the blaster for all other players
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlastData = require(ReplicatedStorage.Blaster.BlastData)
local getBlasterConfig = require(ReplicatedStorage.Blaster.getBlasterConfig)
local getDirectionsForBlast = require(ReplicatedStorage.LaserRay.getDirectionsForBlast)
local castLaserRay = require(ReplicatedStorage.LaserRay.castLaserRay)

local localPlayer = Players.LocalPlayer
local currentCamera = Workspace.CurrentCamera

local function generateBlastData(): BlastData.Type
	local blasterConfig = getBlasterConfig()

	local rayDirections = getDirectionsForBlast(currentCamera.CFrame, blasterConfig)
	local rayResults = castLaserRay(localPlayer, currentCamera.CFrame.Position, rayDirections)

	-- Construct blast data
	local blastData: BlastData.Type = {
		player = localPlayer,
		originCFrame = currentCamera.CFrame,
		rayResults = rayResults,
	}

	return blastData
end

return generateBlastData
