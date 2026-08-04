--!strict

--[[
	Demonstrates a geofencing system to block content from users based on their region.
--]]

local CollectionService = game:GetService("CollectionService")

local Geofence = require(script.Parent.Parent.Geofence)

Geofence.disableForRegions({ "HideInUS" }, { "US" })
Geofence.enableForRegions({ "ShowInUS" }, { "US" })

CollectionService:AddTag(script.Parent:WaitForChild("HotdogA"), "ShowInUS")
CollectionService:AddTag(script.Parent:WaitForChild("HotdogB"), "HideInUS")
