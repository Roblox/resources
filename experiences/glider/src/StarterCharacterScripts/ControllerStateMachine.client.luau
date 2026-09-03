-- A simple state machine implementation for hooking a ControllerManager to a Humanoid.
-- Runs an update function on the PreAnimate event that sets ControllerManager movement inputs
-- and checks for state transition events.
-- Creates a Jump action and "JumpImpulse" attribute on the ControllerManager.

local rs = game:GetService("RunService")
local cas = game:GetService("ContextActionService")

local character = script.Parent
local cm = character:WaitForChild("ControllerManager")
local humanoid = character:WaitForChild("Humanoid")

-- Returns true if the controller is assigned, in world, and being simulated
local function isControllerActive(controller: ControllerBase)
	return cm.ActiveController == controller and controller.Active
end

-- Returns true if the Buoyancy sensor detects the root part is submerged in water, and we aren't already swimming
local function checkSwimmingState()
	return character.HumanoidRootPart.BuoyancySensor.TouchingSurface
		and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming
end

-- Returns true if neither the GroundSensor or ClimbSensor found a Part and, we don't have the AirController active.
local function checkFreefallState()
	return (
		cm.GroundSensor.SensedPart == nil
		and cm.ClimbSensor.SensedPart == nil
		and not (isControllerActive(cm.AirController) or character.HumanoidRootPart.BuoyancySensor.TouchingSurface)
	) or humanoid:GetState() == Enum.HumanoidStateType.Jumping
end

-- Returns true if the GroundSensor found a Part, we don't have the GroundController active, and we didn't just Jump
local function checkRunningState()
	return cm.GroundSensor.SensedPart ~= nil
		and not isControllerActive(cm.GroundController)
		and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
end

-- Returns true of the ClimbSensor found a Part and we don't have the ClimbController active.
local function checkClimbingState()
	return cm.ClimbSensor.SensedPart ~= nil and not isControllerActive(cm.ClimbController)
end

-- The Controller determines the type of locomotion and physics behavior
-- Setting the humanoid state is just so animations will play, not required
local function updateStateAndActiveController()
	if checkSwimmingState() then
		cm.ActiveController = cm.SwimController
		humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
	elseif checkClimbingState() then
		cm.ActiveController = cm.ClimbController
		humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
	elseif checkRunningState() then
		cm.ActiveController = cm.GroundController
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	elseif checkFreefallState() then
		cm.ActiveController = cm.AirController
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

-- Take player input from Humanoid and apply directly to the ControllerManager.
local function updateMovementDirection()
	local dir = character.Humanoid.MoveDirection
	cm.MovingDirection = dir

	if dir.Magnitude > 0 then
		cm.FacingDirection = dir
	else
		if isControllerActive(cm.SwimController) then
			cm.FacingDirection = cm.RootPart.CFrame.UpVector
		else
			cm.FacingDirection = cm.RootPart.CFrame.LookVector
		end
	end
end

-- Manage attribute for configuring Jump power
cm:SetAttribute("JumpImpulse", Vector3.new(0, 200, 0))

-- Jump input
local function doJump(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin and isControllerActive(cm.GroundController) then
		local jumpImpulse = cm:GetAttribute("JumpImpulse")
		cm.RootPart:ApplyImpulse(jumpImpulse)

		character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		cm.ActiveController = cm.AirController

		-- floor receives equal and opposite force
		local floor = cm.GroundSensor.SensedPart
		if floor then
			floor:ApplyImpulseAtPosition(-jumpImpulse, cm.GroundSensor.HitFrame.Position)
		end
	end
end
cas:BindAction("Jump", doJump, true, Enum.KeyCode.Space)

--------------------------------
-- Main character update loop --
local function stepController(t, dt)
	updateMovementDirection()

	updateStateAndActiveController()
end
rs.PreAnimation:Connect(stepController)

-----------------
-- Debug info ---

--humanoid.StateChanged:Connect(function(oldState, newState)
--	print("Change state: " .. tostring(newState) .. " | Change controller: " .. tostring(cm.ActiveController))
--end)
