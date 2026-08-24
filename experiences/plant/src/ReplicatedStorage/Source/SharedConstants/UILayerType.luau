--!strict

--[[
	Categories of UI layer used to determine behavior when showing or hiding a layer.

	See UIHandler header comment for more info.
--]]

export type EnumType = "Menu" | "HeadsUpDisplay"

local UILayerType = {
	Menu = "Menu" :: "Menu",
	HeadsUpDisplay = "HeadsUpDisplay" :: "HeadsUpDisplay",
}

return UILayerType
