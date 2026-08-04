--!strict

--[[
	Most of this was taken from the ProximityPrompt CoreScript.
	Images have been reuploaded in case the internal files get moved around/no longer exist.
--]]

type InputToStringMapping = { [Enum.KeyCode | Enum.UserInputType]: string }

return {
	KeyboardButtonImage = {
		[Enum.KeyCode.Backspace] = "rbxassetid://13471227918",
		[Enum.KeyCode.Return] = "rbxassetid://13470705747",
		[Enum.KeyCode.LeftShift] = "rbxassetid://13470706643",
		[Enum.KeyCode.RightShift] = "rbxassetid://13470706643",
		[Enum.KeyCode.Tab] = "rbxassetid://13470709899",
	} :: InputToStringMapping,
	MouseButtonImage = {
		[Enum.UserInputType.MouseButton1] = "rbxassetid://13489692470",
		[Enum.UserInputType.MouseButton2] = "rbxassetid://13489693292",
		[Enum.UserInputType.MouseButton3] = "rbxassetid://13489694025",
	} :: InputToStringMapping,
	KeyboardButtonIconMapping = {
		["'"] = "rbxassetid://13471372204",
		[","] = "rbxassetid://13471373021",
		["`"] = "rbxassetid://13470701681",
		["."] = "rbxassetid://13470704934",
		[" "] = "rbxassetid://13470707649",
	},
	KeyCodeToTextMapping = {
		[Enum.KeyCode.LeftControl] = "Ctrl",
		[Enum.KeyCode.RightControl] = "Ctrl",
		[Enum.KeyCode.LeftAlt] = "Alt",
		[Enum.KeyCode.RightAlt] = "Alt",
		[Enum.KeyCode.F1] = "F1",
		[Enum.KeyCode.F2] = "F2",
		[Enum.KeyCode.F3] = "F3",
		[Enum.KeyCode.F4] = "F4",
		[Enum.KeyCode.F5] = "F5",
		[Enum.KeyCode.F6] = "F6",
		[Enum.KeyCode.F7] = "F7",
		[Enum.KeyCode.F8] = "F8",
		[Enum.KeyCode.F9] = "F9",
		[Enum.KeyCode.F10] = "F10",
		[Enum.KeyCode.F11] = "F11",
		[Enum.KeyCode.F12] = "F12",
		[Enum.KeyCode.PageUp] = "PgUp",
		[Enum.KeyCode.PageDown] = "PgDn",
		[Enum.KeyCode.Home] = "Home",
		[Enum.KeyCode.End] = "End",
		[Enum.KeyCode.Insert] = "Ins",
		[Enum.KeyCode.Delete] = "Del",
	} :: InputToStringMapping,
	DefaultFontSize = 14,
	KeyCodeToFontSize = {
		[Enum.KeyCode.LeftControl] = 12,
		[Enum.KeyCode.RightControl] = 12,
		[Enum.KeyCode.LeftAlt] = 12,
		[Enum.KeyCode.RightAlt] = 12,
		[Enum.KeyCode.F10] = 12,
		[Enum.KeyCode.F11] = 12,
		[Enum.KeyCode.F12] = 12,
		[Enum.KeyCode.PageUp] = 8,
		[Enum.KeyCode.PageDown] = 8,
		[Enum.KeyCode.Home] = 8,
		[Enum.KeyCode.End] = 10,
		[Enum.KeyCode.Insert] = 10,
		[Enum.KeyCode.Delete] = 10,
	},
}
