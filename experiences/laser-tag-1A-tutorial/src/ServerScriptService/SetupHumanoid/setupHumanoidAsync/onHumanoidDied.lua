--!nocheck
--[[
	Logic run when a player's humanoid dies (gets tagged out)
		- player state changes to TaggedOut
		- Tagged Out indicator appears above player
		- player is prevented from falling over
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(ReplicatedStorage.PlayerState)
local PlayerAttribute = require(ReplicatedStorage.PlayerAttribute)
local taggedOutIndicatorGuiPrefab = ReplicatedStorage.Instances.Guis.TaggedOutIndicatorGuiPrefab

local function onHumanoidDied(player: Player, humanoid: Humanoid)
	-- Update player state to be tagged out
	player:SetAttribute(PlayerAttribute.playerState, PlayerState.TaggedOut)

	-- Add Tagged Out indicator to character
	local newIndicator = taggedOutIndicatorGuiPrefab:Clone()
	local character = humanoid.Parent
	newIndicator.Parent = character:FindFirstChild("Head")

	-- Add an AlignOrientation to the character to prevent it from falling over
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.RigidityEnabled = true
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = humanoid.RootPart.RootAttachment
	alignOrientation.CFrame = humanoid.RootPart.CFrame
	alignOrientation.Parent = humanoid.RootPart
end

return onHumanoidDied
