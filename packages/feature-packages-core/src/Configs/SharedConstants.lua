--!strict

--[[
	Constants for variables shared by all FeaturePackagess.
--]]

local SharedConstants = {
	Stores = {
		FeaturePackages = {
			NAME = "BloxKitStore",
			SUFFIX = "_bloxkitStore",
		},
		LEGACY = {
			-- If Bundles was integrated before DataStore consolidation, uncomment this block so that we know to lazy-migrate the existing data into the new single table
			-- Bundles = {
			-- 	NAME = "BundlesStore",
			-- 	SUFFIX = "_bundleStore",
			-- },
		},
	},
	Tags = {
		UI = {
			UIGLOW_TAG = "UIGlow",
			UISHEEN_TAG = "UISheen",
			UIHOVER_TAG = "UIHover",
			UILOADING_STROKE_TAG = "UILoadingStroke",
			UIBUTTON_TAG = "UIButton",
		},
		Timer = {
			TEXT = "FeaturePackages_Timer_Text",
			PROGRESS_BAR = "FeaturePackages_Timer_ProgressBar",
			ROUND_PROGRESS_BAR = "FeaturePackages_Timer_RoundProgressBar",
		},
	},
	Sounds = {
		VOLUME = 0.2,
		Ids = {
			PROMPT_OPENED = "17161253544",
			PROMPT_CLOSED = "17161255584",
			PURCHASE_EFFECT = "17161210152",
			PURCHASE_BUTTON_ACTIVATED = "17161225362",
			BUTTON_ACTIVATED = "17161216230",
			BUTTON_HOVER = "17161204665",
		},
	},
	Effects = {
		Purchase = {
			Particle = {
				COUNT = 10,
				COLOR = Color3.fromRGB(50, 177, 255),
				ASSET_ID = "16539788437",
				LIFETIME = {
					MIN = 1,
					MAX = 2,
				},
				SPREAD = {
					MIN = 1,
					MAX = 2,
				},
			},
			DURATION = 2,
		},
	},
}

return SharedConstants
