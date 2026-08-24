--!strict

--[[
	Provides types that can be used to categorize groups of UserInputTypes.
	For example, instead of checking against Gamepad1 .. Gamepad8, you can just check
	if it's in the "Gamepad" category.

	This categorization logic is in InputCategorizer
--]]

export type EnumType = "KeyboardMouse" | "Gamepad" | "Touch" | "Other"

local InputCategory = {
	KeyboardMouse = "KeyboardMouse" :: "KeyboardMouse",
	Gamepad = "Gamepad" :: "Gamepad",
	Touch = "Touch" :: "Touch",
	Other = "Other" :: "Other",
}

return InputCategory
