--!strict

local Constants = {
	MINIMUM_CODES_PERCENT_TO_UPDATE = 0.3, -- Once there are 30% or less codes reserved by a server, the reservation needs to update and reserve more

	UPDATE_ATTEMPTS = 3, -- Number of times to retry DataStore/MemoryStore operations
	UPDATE_RETRY_PAUSE_CONSTANT = 2, -- Pause constant for retrying DataStore/MemoryStore operations
	UPDATE_RETRY_PAUSE_EXPONENT_BASE = 2, -- Pause exponent base for retrying DataStore/MemoryStore operations

	RESERVATION_UPDATE_INTERVAL = 30, -- The interval on which servers register used codes and reserve new ones
	MEMORY_STORE_NAME_TEMPLATE = "CodeReservation_%s", -- The MemoryStore name template, formatted with an identifier per batch of codes
	MEMORY_STORE_AVAILABLE_KEY = "Available", -- The MemoryStore key used to store available codes
	MEMORY_STORE_USED_KEY = "Used", -- The MemoryStore key used to store used codes
	MEMORY_STORE_RELEASED_KEY = "Released", -- The MemoryStore key used to store released codes
	MEMORY_STORE_EXPIRATION = 86_400 * 30, -- The expiration time for MemoryStore keys, set to 30 days
	MEMORY_STORE_VALUE_MAX_SIZE = 32_000, -- The maximum size of a MemoryStoreSortedMap value is 32KB per: https://create.roblox.com/docs/cloud-services/memory-stores/sorted-map#limits

	LEADER_UPDATE_INTERVAL = 60, -- The interval on which the leader server saves used codes and makes new ones available
	DATA_STORE_NAME_TEMPLATE = "CodeStorage_%s", -- The DataStore name template, formatted with an identifier per batch of codes
	DATA_STORE_CODES_KEY = "Codes", -- The DataStore key used to store codes
}

return Constants
