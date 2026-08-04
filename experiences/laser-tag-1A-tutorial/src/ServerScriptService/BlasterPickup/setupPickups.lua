--[[
	Parses all the pickups in the world, reading their BlasterType attributes to add
	the corresponding blaster view model into its preview spot.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BlasterPickupAttribute = require(ReplicatedStorage.BlasterPickupAttribute)

local blasterPickupsFolder = Workspace.World.Map.BlasterPickups

local function setupPickups()
	for _, blasterPickup in blasterPickupsFolder:GetChildren() do
		local blasterType = blasterPickup:GetAttribute(BlasterPickupAttribute.blasterType)
		local blasterViewModel = ReplicatedStorage.Instances.LaserBlastersFolder:FindFirstChild(blasterType).ViewModel
		local blasterView = blasterViewModel:Clone()
		blasterView:PivotTo(blasterPickup.Base.BlasterAttachment.WorldCFrame)
		blasterView.PrimaryPart.Anchored = true
		blasterView.Parent = blasterPickup
	end
end

return setupPickups
