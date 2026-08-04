--!strict

--[[
	Types used to enforce FeaturePackages DataStore tables.
--]]

export type TableId = string

export type FeaturePackagesData = {
	Tables: {
		[TableId]: any,
	},
}

export type DataCallback = (player: Player, data: any, isPlayerRemoving: boolean?) -> any

return {}
