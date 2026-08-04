--!strict

local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

assert(RunService:IsClient(), "Geofence can only be used on the client")

local GET_REGION_RETRY_AMOUNT = 10
local GET_REGION_RETRY_INTERVAL = 1

local PolicyType = {
	Allow = "Allow",
	Deny = "Deny",
}

local retryAsync = require(script.retryAsync)
local localPlayer = Players.LocalPlayer :: Player
local localRegion = ""

local Geofence = {
	_initialized = false,
	_policies = {} :: { [string]: any },
	_connections = {} :: { [string]: RBXScriptConnection },
}

-- Attempt to retrieve the LocalPlayer's region code
function Geofence._initialize()
	assert(not Geofence._initialized, "Module already initialized")
	Geofence._initialized = true

	task.spawn(function()
		-- Retry <GET_REGION_RETRY_AMOUNT> times with a <GET_REGION_RETRY_INTERVAL> second wait between each try
		local success, result = retryAsync(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(localPlayer)
		end, GET_REGION_RETRY_AMOUNT, GET_REGION_RETRY_INTERVAL)

		if success then
			localRegion = result

			-- Retroactively enforce policy on anything that may have been missed while retrieving the region
			for tag in Geofence._policies do
				local instances = CollectionService:GetTagged(tag)
				for _, instance in instances do
					Geofence._enforcePolicy(instance, tag)
				end
			end
		else
			warn("Failed to get region code!")
		end
	end)
end

-- Decide whether to destroy an object based on policy set for the tag
function Geofence._enforcePolicy(instance: Instance, tag: string)
	local policyInfo = Geofence._policies[tag]
	assert(policyInfo ~= nil, string.format("No policy exists for tag: %s", tag))

	local shouldDestroy = false
	if policyInfo.policy == PolicyType.Allow then
		shouldDestroy = table.find(policyInfo.regions, localRegion) == nil
	elseif policyInfo.policy == PolicyType.Deny then
		shouldDestroy = table.find(policyInfo.regions, localRegion) ~= nil
	end

	if shouldDestroy then
		-- Destroy is deferred to avoid running into issues where an instance is destroyed
		-- at the same time as being parented, which will fail and output a warning
		task.defer(instance.Destroy, instance)
	end
end

function Geofence._setTagPolicyForRegions(tag: string, regions: { string }, policy: string)
	if not Geofence._policies[tag] then
		Geofence._policies[tag] = {}
	end

	Geofence._policies[tag].policy = policy
	Geofence._policies[tag].regions = regions

	if not Geofence._connections[tag] then
		-- Any new instances created with the tag are subject to the policy
		Geofence._connections[tag] = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			Geofence._enforcePolicy(instance, tag)
		end)
	end

	-- Make sure all current instances with the tag have the policy applied
	for _, instance in CollectionService:GetTagged(tag) do
		Geofence._enforcePolicy(instance, tag)
	end
end

-- A full list of country region codes can be found here:
-- https://create.roblox.com/docs/reference/engine/classes/LocalizationService#GetCountryRegionForPlayerAsync

-- Enable instances with tags *only* for the specified region codes
function Geofence.enableForRegions(tags: { string }, regions: { string })
	for _, tag in tags do
		Geofence._setTagPolicyForRegions(tag, regions, PolicyType.Allow)
	end
end

-- Disable instances with tags for the specified region codes
function Geofence.disableForRegions(tags: { string }, regions: { string })
	for _, tag in tags do
		Geofence._setTagPolicyForRegions(tag, regions, PolicyType.Deny)
	end
end

Geofence._initialize()

return Geofence
