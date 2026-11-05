local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CarryUtil = require(ReplicatedStorage.Systems.CustomAbilities.Interact.CarryUtil)
local CarryableUtil = require(ReplicatedStorage.Systems.CustomAbilities.CarryableUtil)
local Constants = require(ReplicatedStorage.Systems.CustomAbilities.Constants)
local bindTagged = require(ReplicatedStorage.Utility.bindTagged)

local function setUpClothing(item: Instance)
	if not item:IsA("Accessory") then
		return
	end

	local handle = item:FindFirstChild(Constants.ACCESSORY_HANDLE_NAME)
	if not (handle and handle:IsA("BasePart")) then
		return
	end

	local collider = item:FindFirstChild(Constants.COLLIDER_NAME)
	if not (collider and collider:IsA("BasePart")) then
		warn(
			`[ClothingColliders] {item:GetFullName()} has no {Constants.COLLIDER_NAME} part, so it collides with its unfitted Handle`
		)
		return
	end

	collider.Anchored = handle.Anchored
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true

	if not collider:FindFirstChild(Constants.COLLIDER_WELD_NAME) then
		local weld = Instance.new("WeldConstraint")
		weld.Name = Constants.COLLIDER_WELD_NAME
		weld.Part0 = collider
		weld.Part1 = handle
		weld.Parent = collider
	end

	local worn = CarryUtil.isWorn(item)
	CarryableUtil.setColliderMassless(item, worn)
	if worn then
		collider.CanCollide = false
	end
end

local ClothingColliders = {}

function ClothingColliders.start()
	bindTagged(Constants.TAG, { Workspace }, setUpClothing, function() end)
end

return ClothingColliders
