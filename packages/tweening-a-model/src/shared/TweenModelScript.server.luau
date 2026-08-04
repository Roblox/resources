--[[
	Demonstrates how to properly tween a model. Models should be tweened from an anchored part.
	If parts within the model are unanchored, weld these parts to the anchored part.
	Otherwise the unanchored parts will not follow the model as it tweens.
	In this case, the Base part is set as the HealthPack's PrimaryPart and all other parts in the model are welded to it.
--]]

local TweenService = game:GetService("TweenService")

-- Define variables to change bounce time and bounce height
local BOUNCE_TIME = 1
local BOUNCE_HEIGHT = 1.5

local healthPack = script.Parent:WaitForChild("HealthPack")
local primaryPart = healthPack.PrimaryPart
local originalCFrame = primaryPart.CFrame

-- Define a TweenInfo object for the Tween, using the previously defined variables
-- repeatCount is set to math.huge so the tween will repeat forever
local tweenInfo = TweenInfo.new(BOUNCE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, math.huge, true, 0)

-- Create the Tween
local tween =
	TweenService:Create(primaryPart, tweenInfo, { CFrame = originalCFrame + Vector3.new(0, BOUNCE_HEIGHT, 0) })

-- Play the Tween
tween:Play()
