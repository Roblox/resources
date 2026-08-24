--!strict

--[[
	Adds a screen blur, increases FOV, and rotates the camera slightly to the side.
	Enables itself when a menu is visible to shift focus from the 3d world to the UI.

	Movement, jumping, and manual camera adjustments are disabled while the effect is enabled
	to ensure the camera returns to its prior position without a jarring "jump" if the player moved
	during the effect.
--]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local CharacterLoadedWrapper = require(ReplicatedStorage.Source.CharacterLoadedWrapper)
local LocalWalkJumpManager = require(ReplicatedStorage.Source.LocalWalkJumpManager)
local UIHandler = require(ReplicatedStorage.Source.UI.UIHandler)
local TweenGroup = require(ReplicatedStorage.Source.TweenGroup)
local PlayerFacingString = require(ReplicatedStorage.Source.SharedConstants.PlayerFacingString)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local localPlayer = Players.LocalPlayer :: Player
local camera = Workspace.CurrentCamera :: Camera
local menuBlurPrefab: BlurEffect = getInstance(ReplicatedStorage, "Instances", "MenuBlurPrefab")
local blurGoal = menuBlurPrefab.Size

local characterLoadedWrapper = CharacterLoadedWrapper.new(localPlayer)

local blurInstance = menuBlurPrefab:Clone()
blurInstance.Size = 0

local FOV_OFFSET = 30
local TWEEN_INFO = TweenInfo.new(0.6)
local CAMERA_ANGLE_OFFSET = math.rad(-30)
local BASE_FOV = camera.FieldOfView

local ViewingMenuEffect = {}
ViewingMenuEffect._instance = blurInstance :: BlurEffect
ViewingMenuEffect._returnToCFrame = nil :: CFrame?
ViewingMenuEffect._enableTweenGroup = TweenGroup.new(
	TweenService:Create(blurInstance, TWEEN_INFO, {
		Size = blurGoal,
	}),
	TweenService:Create(camera, TWEEN_INFO, { FieldOfView = BASE_FOV + FOV_OFFSET })
)
ViewingMenuEffect._disableTweenGroup = TweenGroup.new(
	TweenService:Create(blurInstance, TWEEN_INFO, {
		Size = 0,
	}),
	TweenService:Create(camera, TWEEN_INFO, { FieldOfView = BASE_FOV })
)

function ViewingMenuEffect.start()
	blurInstance.Parent = Lighting
	ViewingMenuEffect._listenToMenuVisibility()
end

function ViewingMenuEffect._listenToMenuVisibility()
	UIHandler.areMenusVisibleChanged:Connect(function(areMenusVisible: any)
		if areMenusVisible :: boolean then
			ViewingMenuEffect._onMenusVisible()
		else
			ViewingMenuEffect._onMenusInvisible()
		end
	end)
end

function ViewingMenuEffect._onMenusVisible()
	if not ViewingMenuEffect._returnToCFrame then
		-- No ongoing disable animation to cancel, need to disable camera and movement.
		ViewingMenuEffect._returnToCFrame = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable
		ViewingMenuEffect._disableMovement()
	end

	local cameraTween = TweenService:Create(camera, TWEEN_INFO, {
		CFrame = ViewingMenuEffect._getRotatedCFrame(ViewingMenuEffect._returnToCFrame :: CFrame),
	})

	-- This overrides the disableTweenGroup and cancels it if started while disable is still tweening
	ViewingMenuEffect._enableTweenGroup:play()
	cameraTween:Play()
end

function ViewingMenuEffect._onMenusInvisible()
	local cameraTween = TweenService:Create(camera, TWEEN_INFO, {
		CFrame = ViewingMenuEffect._returnToCFrame,
	})

	task.spawn(function()
		local playbackState = cameraTween.Completed:Wait()
		if playbackState == Enum.PlaybackState.Completed then
			-- Disable successfully completed without cancelling. Reset the camera and re-enable character movement.
			ViewingMenuEffect._returnToCFrame = nil
			camera.CameraType = Enum.CameraType.Custom

			-- If the character respawns during this effect while the CameraType is not Custom, it doesn't get automatically
			-- reset to the new humanoid
			if characterLoadedWrapper:isLoaded() then
				local character = localPlayer.Character :: Model
				local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
				camera.CameraSubject = humanoid
			end
			ViewingMenuEffect._enableMovement()
		end
	end)

	cameraTween:Play()
	ViewingMenuEffect._disableTweenGroup:play()
end

function ViewingMenuEffect._getRotatedCFrame(startingCFrame: CFrame)
	local rx, ry, rz = startingCFrame:ToEulerAnglesYXZ()
	local newOrientation = CFrame.fromOrientation(rx, ry + CAMERA_ANGLE_OFFSET, rz)
	local rotatedCFrame = CFrame.new(startingCFrame.Position) * newOrientation

	return rotatedCFrame
end

function ViewingMenuEffect._disableMovement()
	LocalWalkJumpManager.getWalkValueManager():setMultiplier(PlayerFacingString.ValueManager.ViewingMenu, 0)
	LocalWalkJumpManager.getJumpValueManager():setMultiplier(PlayerFacingString.ValueManager.ViewingMenu, 0)
end

function ViewingMenuEffect._enableMovement()
	LocalWalkJumpManager.getWalkValueManager():removeMultiplier(PlayerFacingString.ValueManager.ViewingMenu)
	LocalWalkJumpManager.getJumpValueManager():removeMultiplier(PlayerFacingString.ValueManager.ViewingMenu)
end

return ViewingMenuEffect
