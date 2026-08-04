--!strict

--[[
	Types used to enforce in-experience Currencies.
--]]

export type AssetId = number
export type CurrencyId = string
export type GamePassId = number

export type Currency = {
	displayName: string,
	icon: AssetId?,
	symbol: string?,
}

export type CurrencyList = { [CurrencyId]: Currency? }

export type PriceType = "Marketplace" | "InExperience" | "GamePass"

export type BasePricing = {
	priceType: PriceType,
}

export type InExperiencePricing = BasePricing & {
	priceType: "InExperience",
	icon: AssetId,
	currencyId: CurrencyId,
	price: number,
}

export type MarketplacePricing = BasePricing & {
	priceType: "Marketplace",
	devProductId: AssetId,
}

export type GamePassPricing = BasePricing & {
	priceType: "GamePass",
	gamePassId: GamePassId,
}

export type Pricing = InExperiencePricing | MarketplacePricing | GamePassPricing

local CurrencyTypes = {
	PriceType = {
		Marketplace = "Marketplace" :: "Marketplace",
		InExperience = "InExperience" :: "InExperience",
		GamePass = "GamePass" :: "GamePass",
	},
}

return CurrencyTypes
