local CollectionService = game:GetService("CollectionService")

local CONVEYOR_TAG = "Conveyor"
local DEFAULT_CONVEYOR_SPEED = 10

local function setupConveyor(conveyor: Instance)
	if not conveyor:IsA("BasePart") then
		-- If the conveyor is not a BasePart, we cannot set its velocity
		return
	end

	-- Set the conveyor's velocity based on its Speed attribute
	local speed = conveyor:GetAttribute("Speed") or DEFAULT_CONVEYOR_SPEED

	conveyor.Anchored = true
	conveyor.AssemblyLinearVelocity = conveyor.CFrame:VectorToWorldSpace(Vector3.zAxis * -speed)

	-- Hide the direction indicator if it exists
	local directionIndicator = conveyor:FindFirstChildWhichIsA("SurfaceGui")
	if directionIndicator then
		directionIndicator.Enabled = false
	end
end

-- Setup all existing conveyors
for _, conveyor in CollectionService:GetTagged(CONVEYOR_TAG) do
	setupConveyor(conveyor)
end

-- Setup new conveyors as they are added
CollectionService:GetInstanceAddedSignal(CONVEYOR_TAG):Connect(setupConveyor)
