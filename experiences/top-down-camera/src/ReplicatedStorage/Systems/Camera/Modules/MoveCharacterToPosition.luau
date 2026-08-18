const Players = game:GetService("Players")
const Workspace = game:GetService("Workspace")

const RAYCAST_DISTANCE = 100
const INDICATOR_DELAY_TO_DESTROY = 1

const Camera = workspace.CurrentCamera
const LocalPlayer = Players.LocalPlayer

const function createMoveTargetIndicator(position: Vector3): ()
	const indicator = Instance.new("Part")
	indicator.Color = Color3.fromRGB(0, 255, 0)
	indicator:PivotTo(CFrame.new(position))
	indicator.Name = "MoveTargetIndicator"
	indicator.Size = Vector3.one
	indicator.CanCollide = false
	indicator.Transparency = 0
	indicator.CanQuery = false
	indicator.Anchored = true
	indicator.Parent = Workspace

	-- Destroy the indicator after a delay.
	task.delay(INDICATOR_DELAY_TO_DESTROY, function()
		indicator:Destroy()
	end)
end

-- Takes a position from the viewport and calls :MoveTo() to try and
-- move the LocalPlayer Character to that position.
return function(viewportPosition: Vector2): ()
	const character = LocalPlayer.Character
	if not character then
		return
	end

	const humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	-- Exclude our own character so the ray hits the map, not us.
	const raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	const viewportRay = Camera:ViewportPointToRay(viewportPosition.X, viewportPosition.Y)
	const result = workspace:Raycast(viewportRay.Origin, viewportRay.Direction * RAYCAST_DISTANCE, raycastParams)

	-- Very simple point-to-point movement.
	const resultPosition = if result then result.Position else nil
	if resultPosition then
		createMoveTargetIndicator(resultPosition)
		humanoid:MoveTo(resultPosition)
	end
end
