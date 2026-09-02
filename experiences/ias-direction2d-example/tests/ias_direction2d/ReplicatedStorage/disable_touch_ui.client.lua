local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

GuiService.TouchControlsEnabled = false

local function setScriptableCamera()
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		camera:GetPropertyChangedSignal("CameraType"):Connect(function()
			if camera.CameraType ~= Enum.CameraType.Scriptable then
				camera.CameraType = Enum.CameraType.Scriptable
			end
		end)
	end
end

setScriptableCamera()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(setScriptableCamera)
