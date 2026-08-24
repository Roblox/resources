-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)

local textBoxAdorning = {}

function textBoxAdorning.create(): Types.DebugTextBoxAdorning
	local billboard, label = Utils.createBillboard()
	billboard.Adornee = Workspace.Terrain
	label.Name = Constants.TEXT_BOX_ADORNING.LABEL_NAME

	local debugParentedTextBox = {
		billboard = billboard,
		label = label,
	}

	textBoxAdorning.update(
		debugParentedTextBox,
		Constants.TEXT_BOX_ADORNING.TEXT,
		Constants.TEXT_BOX_ADORNING.OFFSET,
		Utils.getContainer(),
		Constants.TEXT_BOX_ADORNING.COLOR,
		Constants.TEXT_BOX_ADORNING.FONT_SIZE
	)

	billboard.Parent = Utils.getContainer()

	return debugParentedTextBox
end

function textBoxAdorning.update(
	debugParentedTextBox: Types.DebugTextBoxAdorning,
	text: string?,
	offset: Vector3?,
	adornee: Instance?,
	color: Color3?,
	textSize: number?
): ()
	debugParentedTextBox.label.Text = text or debugParentedTextBox.label.Text
	debugParentedTextBox.billboard.StudsOffset = offset or debugParentedTextBox.billboard.StudsOffset
	debugParentedTextBox.billboard.Adornee = adornee or debugParentedTextBox.billboard.Adornee
	debugParentedTextBox.label.TextSize = textSize or debugParentedTextBox.label.TextSize
	debugParentedTextBox.label.TextColor3 = color or debugParentedTextBox.label.TextColor3
end

function textBoxAdorning.destroy(debugParentedTextBox: Types.DebugTextBoxAdorning)
	debugParentedTextBox.billboard:Destroy()
	debugParentedTextBox.label:Destroy()
end

return textBoxAdorning
