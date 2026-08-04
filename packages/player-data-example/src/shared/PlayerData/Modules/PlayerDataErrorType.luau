--!strict

--[[
	Pseudo enums used as player data error types to compare by name
	rather than comparing typo-prone strings.
--]]

export type EnumType = "DataStoreError" | "SessionLocked"

local PlayerDataErrorType = {
	DataStoreError = "DataStoreError" :: "DataStoreError",
	SessionLocked = "SessionLocked" :: "SessionLocked",
}

return PlayerDataErrorType
