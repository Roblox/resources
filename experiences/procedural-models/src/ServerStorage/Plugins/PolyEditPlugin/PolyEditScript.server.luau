if not plugin then
	return
end

local toolbar = plugin:CreateToolbar("PolyEdit")
local toggleButton = toolbar:CreateButton("PolyEdit", "Open the PolyEdit panel", "")
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 300, 340, 240, 260)
local widget = plugin:CreateDockWidgetPluginGuiAsync("PolyEdit_MainWidget", widgetInfo)
widget.Title = "PolyEdit"
widget.Name = "PolyEdit"

local started = false
local function ensureStarted()
	if started then
		return
	end
	started = true
	require(script.Parent.PolyEditModule).start(plugin, widget)
end

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
	if widget.Enabled then
		ensureStarted()
	end
end)

toggleButton:SetActive(widget.Enabled)
if widget.Enabled then
	ensureStarted()
end
