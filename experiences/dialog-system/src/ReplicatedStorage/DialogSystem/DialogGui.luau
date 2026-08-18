--!strict
-- Builds the dialog ScreenGui from DialogConfig.UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DialogConfig = require(ReplicatedStorage.DialogSystem.DialogConfig)

local DialogGui = {}

export type Parts = {
	panel: Frame,
	image: ImageLabel,
	text: TextLabel,
	-- Single advance button. Caller flips its label between "Next" and "Exit"
	advanceBtn: TextButton,
}

function DialogGui.build(): (ScreenGui, Parts)
	local ui = DialogConfig.UI

	local gui = Instance.new("ScreenGui")
	gui.Name = "DialogGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = ui.PanelSize
	panel.AnchorPoint = ui.PanelAnchor
	panel.Position = ui.PanelPosition
	panel.BackgroundColor3 = ui.BackgroundColor
	panel.BackgroundTransparency = ui.BackgroundTransparency
	panel.BorderSizePixel = 0
	-- Let the portrait spill past the panel edges instead of being clipped.
	panel.ClipsDescendants = false
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = ui.CornerRadius
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = ui.AccentColor
	stroke.Thickness = 1.5
	stroke.Transparency = 0.4
	stroke.Parent = panel

	-- Content holds the text and button, inset by padding. The portrait is a
	-- direct child of the panel (below) so this padding still lets it overflow.
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = content

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.Size = ui.ImageSize
	image.AnchorPoint = Vector2.new(0, 0)
	image.Position = UDim2.fromOffset(-ui.ImageOverflowLeft, -ui.ImageOverflowTop)
	image.BackgroundColor3 = ui.ButtonColor
	image.BackgroundTransparency = 0.5
	image.BorderSizePixel = 0
	image.ScaleType = Enum.ScaleType.Fit
	image.Image = ""
	image.Parent = panel

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 8)
	imageCorner.Parent = image

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.AnchorPoint = Vector2.new(1, 0)
	text.Position = UDim2.fromScale(1, 0)
	text.Size = UDim2.new(1, -(ui.ImageSize.X.Offset + 16), 1, -44)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.Gotham
	text.TextSize = ui.TextSize
	text.TextColor3 = ui.TextColor
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.RichText = true
	text.Text = ""
	text.Parent = content

	local function makeButton(name: string, label: string, position: UDim2): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.fromOffset(120, 32)
		btn.AnchorPoint = Vector2.new(1, 1)
		btn.Position = position
		btn.BackgroundColor3 = ui.ButtonColor
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 16
		btn.TextColor3 = ui.TextColor
		btn.Text = label
		btn.Visible = false
		btn.Parent = content

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = ui.ButtonHoverColor
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = ui.ButtonColor
		end)

		return btn
	end

	local advanceBtn = makeButton("Advance", "Next \u{25B6}", UDim2.fromScale(1, 0))

	return gui, {
		panel = panel,
		image = image,
		text = text,
		advanceBtn = advanceBtn,
	}
end

return DialogGui
