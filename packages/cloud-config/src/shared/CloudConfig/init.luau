--!strict

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Signal = require(script.Signal)

-- In a similar vein to private vars/functions in Luau, the DataStore name is prefixed with
-- an underscore as it is not meant to be accessed directly. Adding/setting/removing keys
-- should be done using the setKeyAsync function.
local DATA_STORE_NAME = "_CloudConfig"
local DATA_STORE_KEY = "Configs"
local DATA_STORE_READ_INTERVAL = 60

-- Key/value pairs are stored as attributes so they will automatically replicated to the client.
-- They must also be able to be serialized as JSON for storage in DataStore
-- Since userdata are not able to be serialized as JSON, the types allowed for values have been limited
local ALLOWED_VALUE_TYPES = {
	"number",
	"boolean",
	"string",
	"nil",
}

local configDataStore = RunService:IsServer() and DataStoreService:GetDataStore(DATA_STORE_NAME)

local CloudConfig = {
	_configAttributeHolder = script.ConfigAttributeHolder,
	_changedSignals = {},
	_polling = false,
	_updateInProgress = false,
}

-- Update the locally cached key values from DataStore
function CloudConfig._fetchValuesAsync()
	assert(RunService:IsServer(), "Keys can only be fetched on the server")

	local dataStore = configDataStore :: GlobalDataStore
	local success, result = pcall(function()
		return dataStore:GetAsync(DATA_STORE_KEY)
	end)

	if success and result then
		for key, value in result :: { [string]: any } do
			CloudConfig._configAttributeHolder:SetAttribute(key, value)
		end
	end

	if not success then
		warn(string.format("Failed to fetch key values - %s", result))
	end
end

-- Start a loop to fetch key values from DataStore every <DATA_STORE_READ_INTERVAL> seconds
function CloudConfig._pollForUpdates()
	assert(not CloudConfig._polling, "CloudConfig module already initialized")

	task.spawn(function()
		-- Update loop
		while true do
			CloudConfig._fetchValuesAsync()
			task.wait(DATA_STORE_READ_INTERVAL)
		end
	end)

	CloudConfig._polling = true
end

-- Add a list of keys to the local cache if they don't exist already
function CloudConfig.setDefaultValues(defaults: { [string]: any })
	assert(RunService:IsServer(), "Config default values must be set on the server")

	for key, defaultValue in defaults do
		assert(
			table.find(ALLOWED_VALUE_TYPES, typeof(defaultValue)) ~= nil,
			string.format("Disallowed type '%s' for key: %s", typeof(defaultValue), key)
		)

		-- Make sure to not overwrite an already set value with the default value
		if CloudConfig._configAttributeHolder:GetAttribute(key) ~= nil then
			warn(string.format("Config '%s' is already added", key))
		else
			CloudConfig._configAttributeHolder:SetAttribute(key, defaultValue)
		end
	end
end

-- Return the current cached value of a key
function CloudConfig.getValue(key: string)
	return CloudConfig._configAttributeHolder:GetAttribute(key)
end

-- Return a signal that fires when the specified key changes
function CloudConfig.getValueChangedSignal(key: string)
	local changedSignal = CloudConfig._changedSignals[key]
	if not changedSignal then
		-- Create a custom signal to fire when the attribute changes. This allows
		-- the new value of the key to be passed to the connected function since
		-- this is not done by default when using :GetAttributeChangedSignal()
		changedSignal = Signal.new()
		CloudConfig._changedSignals[key] = changedSignal

		CloudConfig._configAttributeHolder:GetAttributeChangedSignal(key):Connect(function()
			local newValue = CloudConfig._configAttributeHolder:GetAttribute(key)
			changedSignal:Fire(newValue)
		end)
	end

	return changedSignal
end

-- This function should be called in studio to set the value of a key.
-- This directly sets the value in the cloud, attributes are only set at runtime
-- during the polling loop or when the default key values are set.
function CloudConfig.setValueAsync(key: string, value: any)
	assert(RunService:IsStudio(), "Keys must be set in studio")
	assert(not CloudConfig._updateInProgress, "Key update already in progress")
	assert(
		table.find(ALLOWED_VALUE_TYPES, typeof(value)) ~= nil,
		string.format("Disallowed type '%s' for key: %s", typeof(value), key)
	)

	-- Since this module does not do any sort of queuing or management to resolve multiple writes at
	-- once, we disable this function while a write is in progress to prevent keys getting overwritten
	CloudConfig._updateInProgress = true
	local oldValue = nil
	local dataStore = configDataStore :: GlobalDataStore
	local success, result = pcall(function()
		dataStore:UpdateAsync(DATA_STORE_KEY, function(oldConfig)
			local newConfig = oldConfig or {}
			oldValue = newConfig[key]
			newConfig[key] = value

			return newConfig
		end)
	end)
	CloudConfig._updateInProgress = false

	if success then
		print(string.format("Changed key '%s' from '%s' to '%s", key, tostring(oldValue), tostring(value)))
	else
		error(result)
	end
end

if RunService:IsServer() and RunService:IsRunMode() then
	CloudConfig._pollForUpdates()
end

return CloudConfig
