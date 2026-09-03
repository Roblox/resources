-- Replace Humanoid physics with a ControllerManager when a character loads into the workspace

local Players = game:GetService("Players")

local function initialize(character)
	local cm = Instance.new("ControllerManager")

	local gc = Instance.new("GroundController")
	local ac = Instance.new("AirController")
	gc.Parent = cm
	ac.Parent = cm
	Instance.new("ClimbController").Parent = cm
	Instance.new("SwimController").Parent = cm

	local humanoid = character.Humanoid
	cm.RootPart = humanoid.RootPart
	gc.GroundOffset = humanoid.HipHeight
	cm.FacingDirection = cm.RootPart.CFrame.LookVector
	ac.MaintainLinearMomentum = true
	ac.MoveMaxForce = 0
	ac.MaintainAngularMomentum = false

	local floorSensor = Instance.new("ControllerPartSensor")
	floorSensor.SensorMode = Enum.SensorMode.Floor
	floorSensor.SearchDistance = gc.GroundOffset + 0.5
	floorSensor.Name = "GroundSensor"

	local ladderSensor = Instance.new("ControllerPartSensor")
	ladderSensor.SensorMode = Enum.SensorMode.Ladder
	ladderSensor.SearchDistance = 1.5
	ladderSensor.Name = "ClimbSensor"

	local waterSensor = Instance.new("BuoyancySensor")

	cm.GroundSensor = floorSensor
	cm.ClimbSensor = ladderSensor

	waterSensor.Parent = cm.RootPart
	floorSensor.Parent = cm.RootPart
	ladderSensor.Parent = cm.RootPart
	cm.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character.Humanoid.EvaluateStateMachine = false -- Disable Humanoid state machine and physics
		task.wait() -- ensure post-load Humanoid computations are complete (such as hip height)
		initialize(character)
	end)
end)
