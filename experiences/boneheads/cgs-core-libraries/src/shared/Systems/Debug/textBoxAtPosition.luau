-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)

local textBoxAtPosition = {}

function textBoxAtPosition.create(): Types.DebugTextBoxAtPosition
	local container = Utils.getContainer()

	local anchor = Instance.new("Part")
	anchor.Name = Constants.TEXT_BOX_AT_POSITION.ANCHOR_NAME
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	Utils.makeIntangible(anchor)
	anchor.Parent = container

	local billboard, label = Utils.createBillboard()
	billboard.Adornee = anchor
	billboard.Parent = container

	label.Name = Constants.TEXT_BOX_AT_POSITION.LABEL_NAME

	local debugPositionedTextBox = {
		anchor = anchor,
		billboard = billboard,
		label = label,
	}

	textBoxAtPosition.update(
		debugPositionedTextBox,
		Vector3.zero,
		Constants.TEXT_BOX_AT_POSITION.TEXT,
		Constants.TEXT_BOX_AT_POSITION.COLOR,
		Constants.TEXT_BOX_AT_POSITION.FONT_SIZE
	)

	return debugPositionedTextBox
end

function textBoxAtPosition.update(
	debugPositionedTextBox: Types.DebugTextBoxAtPosition,
	position: Vector3?,
	text: string?,
	color: Color3?,
	textSize: number?
): ()
	debugPositionedTextBox.anchor.Position = position or debugPositionedTextBox.anchor.Position
	debugPositionedTextBox.label.Text = text or debugPositionedTextBox.label.Text
	debugPositionedTextBox.label.TextSize = textSize or debugPositionedTextBox.label.TextSize
	debugPositionedTextBox.label.TextColor3 = color or debugPositionedTextBox.label.TextColor3
end

function textBoxAtPosition.destroy(debugPositionedTextBox: Types.DebugTextBoxAtPosition)
	debugPositionedTextBox.anchor:Destroy()
	debugPositionedTextBox.billboard:Destroy()
	debugPositionedTextBox.label:Destroy()
end

return textBoxAtPosition
