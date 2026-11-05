local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local overlay = nil
local connection = nil
local forceCloseThread = nil
local bAnimateDestroy = true
local assetInfo = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, false, 0)
local bIsClosing = false
local FORCE_CLOSE_TIMEOUT = 10

local function createOverlay()
	local loadingScreen = Instance.new("ScreenGui")
	loadingScreen.Name = "InstructionsOverlay"
	loadingScreen.IgnoreGuiInset = true
	loadingScreen.ResetOnSpawn = false
	loadingScreen.DisplayOrder = 10
	loadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	container.BorderSizePixel = 0
	container.Parent = loadingScreen

	local instructionsImage = Instance.new("ImageLabel")
	instructionsImage.Size = UDim2.fromScale(1, 1)
	instructionsImage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	instructionsImage.Image = "rbxassetid://129776233188360"
	instructionsImage.ScaleType = Enum.ScaleType.Fit
	instructionsImage.Parent = container

	return loadingScreen
end

local function clearOverlay()
	if overlay then
		overlay:Destroy()
		overlay = nil
	end

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if forceCloseThread then
		task.cancel(forceCloseThread)
		forceCloseThread = nil
	end

	bIsClosing = false
end

local function destroyOverlay()
	bIsClosing = true

	if bAnimateDestroy then
		local frame = overlay:FindFirstChildOfClass("Frame") :: Frame
		if frame then
			local shrinkTween = TweenService:Create(
				frame,
				assetInfo,
				{ Size = UDim2.fromOffset(0, 0), Rotation = math.floor(frame.Rotation / 360) * 360 }
			)

			shrinkTween:Play()
			shrinkTween.Completed:Connect(function()
				shrinkTween:Destroy()

				clearOverlay()
			end)
			return
		end
	end
	clearOverlay()
end

local InstructionsOverlay = {}

function InstructionsOverlay.autoHide()
	connection = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.None or Enum.UserInputType.Focus == input.UserInputType then
			return
		end

		if bIsClosing then
			return
		end

		destroyOverlay()
	end)

	forceCloseThread = task.delay(FORCE_CLOSE_TIMEOUT, function()
		if bIsClosing then
			return
		end
		forceCloseThread = nil
		destroyOverlay()
	end)
end

function InstructionsOverlay.show()
	if not overlay then
		overlay = createOverlay()
	end

	if not overlay then
		return
	end

	overlay.Parent = playerGui
end

return InstructionsOverlay
