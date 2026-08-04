--[[
	The fireRaycast function fires a ray from an Attachment position, visualizing the path of the ray and the surface normal that was hit.
	A model named "Device" rotates around in a circle, pointing the ray at various objects.
--]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Define the maximum distance to cast the ray
local RAYCAST_DISTANCE = 100

local instances = script.Parent:WaitForChild("Instances")
local device = instances.Device
local laserOrigin = device.Body.LaserOrigin
local arrow = device.Arrow

-- Define raycast parameters to exclude the raycasting device and arrow visualization
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = { device, arrow }
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function fireRaycast()
	-- Get the position and direction that the diode is pointing
	local rayOrigin = laserOrigin.WorldCFrame.Position
	-- LookVector has a magnitude of 1, so it is multiplied by RAYCAST_DISTANCE to get the full length of the ray
	local rayDirection = laserOrigin.WorldCFrame.LookVector * RAYCAST_DISTANCE

	-- Raycast from the rayOrigin in the direction of rayDirection
	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	-- If the raycast hit something, update the visualization
	if raycastResult then
		-- The raycastResult object contains the position that was hit, the surface normal, and the instance that was hit
		arrow.CFrame = CFrame.new(raycastResult.Position, raycastResult.Position + raycastResult.Normal)
		arrow.BillboardGui.TextLabel.Text = raycastResult.Instance.Name
	end
end

-- Run the raycast function every frame
RunService.Heartbeat:Connect(fireRaycast)
