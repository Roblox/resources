--[[
	The loadAnimationTrack function is used to load an animation on an Animator by providing an animation asset ID.
--]]

local Players = game:GetService("Players")

local loadAnimationTrack = require(script.Parent.Parent.loadAnimationTrack)

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

-- Create a new Animation object and load it onto the Animator given an animationId
local myAnimationTrack = loadAnimationTrack(animator, "rbxassetid://12259828678")

-- Play the animation
myAnimationTrack:Play()

-- Stop the animation after 5 seconds
task.wait(5)
myAnimationTrack:Stop()
