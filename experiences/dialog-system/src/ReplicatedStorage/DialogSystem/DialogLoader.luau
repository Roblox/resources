--!strict
-- Loads all modules in the DialogData folder, one ModuleScript per NPC.
-- Also defines types. These could be in their own type declaration file,
-- but this module is already fairly minimal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type Mood = {
	image: string?,
	sound: string?,
	animation: string?,
	shake: boolean?,
}

export type Screen = {
	text: string,
	mood: Mood?,
}

export type Dialog = {
	id: string,
	animation: string?,
	screens: { Screen },
}

local DialogData: { [string]: Dialog } = {}

-- Recursively freeze a table and any nested tables. Mood records are often
-- shared by reference across screens, so guard against re-freezing.
local function deepFreeze<T>(value: T): T
	if typeof(value) == "table" and not table.isfrozen(value :: any) then
		for _, v in value :: any do
			deepFreeze(v)
		end
		table.freeze(value :: any)
	end
	return value
end

-- Load all child modules (the actual dialog and moods)
for _, child in ReplicatedStorage.DialogData:GetChildren() do
	if child:IsA("ModuleScript") then
		local dialog = require(child) :: any
		if typeof(dialog) ~= "table" or typeof(dialog.id) ~= "string" or dialog.id == "" then
			error(`[DialogLoader] {child:GetFullName()} did not return a Dialog with a string ID; skipping.`)
		end
		if DialogData[dialog.id] then
			error(`[DialogLoader] Duplicate dialog id "{dialog.id}" in {child:GetFullName()}.`)
		end
		DialogData[dialog.id] = deepFreeze(dialog)
	end
end

table.freeze(DialogData)

return DialogData
