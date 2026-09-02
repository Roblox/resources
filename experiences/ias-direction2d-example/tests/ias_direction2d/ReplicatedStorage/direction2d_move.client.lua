local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MoveContext = ReplicatedStorage:WaitForChild("MoveContext")
local MoveAction = MoveContext:WaitForChild("Move")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("Direction2DGui")
local mover = gui:WaitForChild("Mover")
local directionLabel = gui:WaitForChild("DirectionLabel")

local SPEED = 300
local currentDir = Vector2.zero

MoveAction.StateChanged:Connect(function(state)
	currentDir = state
	directionLabel.Text = string.format("dir: %.2f, %.2f", state.X, state.Y)
end)

RunService.RenderStepped:Connect(function(dt)
	if currentDir == Vector2.zero then
		return
	end

	local pos = mover.Position
	local newX = pos.X.Offset + currentDir.X * SPEED * dt
	local newY = pos.Y.Offset - currentDir.Y * SPEED * dt

	mover.Position = UDim2.new(pos.X.Scale, newX, pos.Y.Scale, newY)
end)

print("Direction2D move ready (WASD or left thumbstick)")
