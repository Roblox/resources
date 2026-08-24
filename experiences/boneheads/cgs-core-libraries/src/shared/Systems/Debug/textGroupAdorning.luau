-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local Utils = require(script.Parent.Utils)

local textGroupAdorning = {}

function textGroupAdorning.create(): Types.DebugTextGroupAdorning
	local billboard = Instance.new("BillboardGui")
	billboard.Name = Constants.BILLBOARD.BILLBOARD_NAME
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(200, 70)
	billboard.Adornee = Workspace.Terrain

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = billboard

	billboard.Parent = Utils.getContainer()

	return {
		billboard = billboard,
		labels = {},
	}
end

function textGroupAdorning.update(
	data: Types.DebugTextGroupAdorning,
	entries: { Types.LabelEntry },
	offset: Vector3?,
	adornee: Instance?
): ()
	data.billboard.StudsOffset = offset or data.billboard.StudsOffset
	data.billboard.Adornee = adornee or data.billboard.Adornee

	for i, entry in entries do
		if not data.labels[i] then
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 0)
			label.AutomaticSize = Enum.AutomaticSize.Y
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.LayoutOrder = i
			label.Parent = data.billboard
			data.labels[i] = label
		end

		local label = data.labels[i]
		label.Text = entry.text
		label.TextColor3 = entry.color or Constants.TEXT_BOX_ADORNING.COLOR
		label.TextSize = entry.textSize or Constants.TEXT_BOX_ADORNING.FONT_SIZE
	end

	for i = #entries + 1, #data.labels do
		data.labels[i]:Destroy()
		data.labels[i] = nil
	end
end

function textGroupAdorning.destroy(data: Types.DebugTextGroupAdorning): ()
	data.billboard:Destroy()
end

return textGroupAdorning
