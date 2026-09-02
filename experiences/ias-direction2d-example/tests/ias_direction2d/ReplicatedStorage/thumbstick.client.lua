local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MoveContext = ReplicatedStorage:WaitForChild("MoveContext")
local MoveAction = MoveContext:WaitForChild("Move")

local ThumbstickContext = ReplicatedStorage:WaitForChild("ThumbstickContext")
local ThumbstickTouch = ThumbstickContext:WaitForChild("ThumbstickAction")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("ThumbstickGui")
local outerRing = gui:WaitForChild("OuterRing")
local innerThumb = outerRing:WaitForChild("InnerThumb")

local OUTER_RADIUS = 80
local INNER_RADIUS = 30
local DEADZONE = 0.1

local originPos = Vector2.zero

ThumbstickTouch.StateChanged:Connect(function(state)
	if originPos == Vector2.zero then
		originPos = state
		outerRing.Position = UDim2.fromOffset(originPos.X, originPos.Y)
		innerThumb.Position = UDim2.fromScale(0.5, 0.5)
		outerRing.Visible = true
	elseif state ~= Vector2.new(-1, -1) then
		local rawDelta = state - originPos
		local maxDist = OUTER_RADIUS - INNER_RADIUS
		local clampedDelta = rawDelta
		if rawDelta.Magnitude > maxDist then
			clampedDelta = rawDelta.Unit * maxDist
		end

		local normalizedX = clampedDelta.X / maxDist
		local normalizedY = clampedDelta.Y / maxDist

		local normMag = math.sqrt(normalizedX * normalizedX + normalizedY * normalizedY)
		if normMag < DEADZONE then
			normalizedX = 0
			normalizedY = 0
		end

		innerThumb.Position = UDim2.new(0.5, clampedDelta.X, 0.5, clampedDelta.Y)

		MoveAction:Fire(Vector2.new(normalizedX, -normalizedY))
	else
		originPos = Vector2.zero
		outerRing.Visible = false
		innerThumb.Position = UDim2.fromScale(0.5, 0.5)

		MoveAction:Fire(Vector2.zero)
	end
end)

print("Touch thumbstick ready")
