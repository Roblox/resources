--!strict

--[[
	Types used to enforce FeaturePackages Items.
--]]

export type AssetId = number

export type ItemType = "DevProduct" | "Robux"

type ItemCaption = {
	text: string,
	color: Color3?,
}

type ItemMetadata = {
	caption: ItemCaption?,
	hideName: boolean?,
	hidePrice: boolean?,
}

type DisplayInfo = {
	icon: AssetId,
	displayName: string?,
}

export type BaseItem = {
	itemType: ItemType,
	featured: boolean?,
	metadata: ItemMetadata?,
}

export type DevProductItem = BaseItem & {
	itemType: "DevProduct",
	devProductId: AssetId,
}

export type RobuxItem = BaseItem & DisplayInfo & {
	itemType: "Robux",
	priceInRobux: number,
}

export type Item = DevProductItem | RobuxItem

local ItemTypes = {
	ItemType = {
		DevProduct = "DevProduct" :: "DevProduct",
		Robux = "Robux" :: "Robux",
	},
}

return ItemTypes
