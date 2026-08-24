--!strict

--[[
	A simple loading screen class

	This doesn't tie into the game's core UI system as it needs to be created before the game
	(including most of its code) has finished replicating so it can replace the default Roblox
	loading screen as soon as possible.
--]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local instancesFolder = ReplicatedFirst:FindFirstChild("Instances")
assert(instancesFolder, "Missing Instances folder in ReplicatedFirst")
local loadingScreenPrefab = instancesFolder:FindFirstChild("LoadingScreenPrefab")
assert(loadingScreenPrefab, "Missing LoadingScreenPrefab in ReplicatedFirst.Instances")
local localPlayer = Players.LocalPlayer :: Player

local MIN_RUNTIME = 2
local FADE_LENGTH = 1
local SPINNER_REVOLUTIONS_PER_SECOND = 1
local DEGREES_PER_REVOLUTION = 360

local LoadingScreen = {}
LoadingScreen._instance = loadingScreenPrefab:Clone() :: ScreenGui
LoadingScreen._startTime = 0
LoadingScreen._spinnerConnection = nil :: RBXScriptConnection?

function LoadingScreen.enableAsync()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	LoadingScreen._instance.Parent = playerGui

	-- Now our loading screen is in place, we can remove Roblox's default one
	ReplicatedFirst:RemoveDefaultLoadingScreen()

	LoadingScreen._startTime = os.clock()

	-- We aren't using getInstance here (or elsewhere in this file) as it is a descendant of ReplicatedStorage and we
	-- don't want to wait for it to load since this is a loading screen in ReplicatedFirst
	local spinnerLabel = LoadingScreen._instance
		:FindFirstChild("SizingFrame")
		:FindFirstChild("ContentFrame")
		:FindFirstChild("SpinnerImageLabel") :: ImageLabel
	LoadingScreen._spinnerConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		spinnerLabel.Rotation += (SPINNER_REVOLUTIONS_PER_SECOND * DEGREES_PER_REVOLUTION * deltaTime)
	end)
	LoadingScreen._startTime = os.clock()
end

function LoadingScreen.updateDetailText(text: string)
	local detailTextLabel = LoadingScreen._instance
		:FindFirstChild("SizingFrame")
		:FindFirstChild("ContentFrame")
		:FindFirstChild("TextContentFrame")
		:FindFirstChild("DetailTextLabel") :: TextLabel

	detailTextLabel.Text = text
end

function LoadingScreen.disableAsync()
	-- The loading screen flickering for a split second is jarring, so we
	-- are implementing a minimum runtime
	local runTime = os.clock() - LoadingScreen._startTime
	task.wait(math.max(0, MIN_RUNTIME - runTime))

	if LoadingScreen._spinnerConnection then
		LoadingScreen._spinnerConnection:Disconnect()
	end

	local sizingFrame = LoadingScreen._instance:FindFirstChild("SizingFrame") :: Frame
	local contentFrame = sizingFrame:FindFirstChild("ContentFrame") :: Frame
	local logoImageLabel = sizingFrame:FindFirstChild("LogoImageLabel") :: Frame
	contentFrame.Visible = false

	local fadeTweenBackground = TweenService:Create(
		LoadingScreen._instance:FindFirstChild("Background") :: Frame,
		TweenInfo.new(FADE_LENGTH),
		{ BackgroundTransparency = 1 }
	)
	local fadeTweenLogo = TweenService:Create(logoImageLabel, TweenInfo.new(FADE_LENGTH), { ImageTransparency = 1 })

	task.spawn(function()
		fadeTweenBackground:Play()
		fadeTweenLogo:Play()
		fadeTweenLogo.Completed:Wait()
		LoadingScreen._instance:Destroy()
	end)
end

return LoadingScreen
