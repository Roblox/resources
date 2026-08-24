--!strict

--[[
	Creates an icon at a random starting location within set bounds with the given prefab model,
	and provides a method that launches the icon toward a position on the screen following a projectile curve.
	Once the icon reaches its target, it is automatically destroyed.

	The size is tweened from 0 to max size and back to 0 throughout its flight according to a custom tween function.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Signal = require(ReplicatedStorage.Source.Signal)
local ModelViewport = require(ReplicatedStorage.Source.UI.UIComponents.ModelViewport)
local getExponentialTweenValueWithMidpoint =
	require(ReplicatedStorage.Source.Utility.getExponentialTweenValueWithMidpoint)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local itemAnimationPrefab: Frame = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "ItemIconAnimationPrefab")
local camera = Workspace.CurrentCamera :: Camera
local random = Random.new()

local ANIMATION_LENGTH_SECONDS = 1 -- Time from spawn until it lands at its target
local PROJECTILE_GRAVITY_SCALAR = 2 -- Multiplied by screen height later for projectile acceleration
local ICON_SPAWN_BOUNDS_SCALE = { -- Icons spawn randomly within these specified bounds
	X = {
		Min = 0.4,
		Max = 0.6,
	},
	Y = {
		Min = 0.4,
		Max = 0.6,
	},
}

local ProjectileIcon = {}
ProjectileIcon.__index = ProjectileIcon

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Frame,
		_isLaunched: boolean,
		_heartbeatConnection: RBXScriptConnection?,
		completed: Signal.ClassType,
	},
	ProjectileIcon
))

function ProjectileIcon.new(itemPrefab: Model, iconParent: LayerCollector | GuiObject): ClassType
	local self = {
		_instance = itemAnimationPrefab:Clone(),
		_isLaunched = false,
		_heartbeatConnection = nil,
		completed = Signal.new(),
	}

	setmetatable(self, ProjectileIcon)
	self:_setup(itemPrefab, iconParent)

	return self
end

function ProjectileIcon._setup(self: ClassType, itemPrefab: Model, iconParent: LayerCollector | GuiObject)
	local bounds = ICON_SPAWN_BOUNDS_SCALE
	local randomX = random:NextNumber(bounds.X.Min, bounds.X.Max)
	local randomY = random:NextNumber(bounds.Y.Min, bounds.Y.Max)

	local itemIcon = self._instance
	itemIcon.Position = UDim2.fromScale(randomX, randomY)
	itemIcon.Size = UDim2.fromScale(0, 0)

	-- Parented to itemIcon, which we destroy later. No need to destroy this explicitly
	local modelViewport = ModelViewport.new({
		model = itemPrefab,
	})
	modelViewport:setParent(itemIcon)
	itemIcon.Parent = iconParent
end

function ProjectileIcon.launchToward(self: ClassType, targetPosition: Vector2)
	assert(not self._isLaunched, "ProjectileIcon cannot be launched more than once.")
	self._isLaunched = true

	local startTimeMs = DateTime.now().UnixTimestampMillis

	-- We want the icon to animate from its position to the target gui in a projectile curve.
	-- To achieve this, we need to solve for the initial velocity given
	-- the start and end position, accounting for gravity and time in flight.

	-- We know starting and target positions:
	local startPosition = self._instance.AbsolutePosition

	-- We define acceleration (gravity) in pixels/second^2, a = acceleration,
	-- using screen height to get a nice arc regardless of screen size:
	local acceleration = Vector2.new(0, camera.ViewportSize.Y * PROJECTILE_GRAVITY_SCALAR)

	-- Set how long the icon should take to reach its destination:
	local totalTime = ANIMATION_LENGTH_SECONDS

	-- We know the equation for projectile motion at any time t:
	-- p = p0 + (V)(t) + 0.5(a)(t^2)

	-- Then solve for V, the instantaneous initial velocity to achieve our goal within totalTime:
	-- V = [(p - p0) - 0.5(a)(t^2)]/t

	-- Plug in our numbers:
	local initialVelocity = ((targetPosition - startPosition) - (0.5 * acceleration * totalTime ^ 2)) / totalTime

	-- Update the position every heartbeat according to time passed
	self._heartbeatConnection = RunService.Heartbeat:Connect(function()
		self:_update(startPosition, initialVelocity, startTimeMs, acceleration, totalTime)
	end)
end

function ProjectileIcon._update(
	self: ClassType,
	startPosition: Vector2,
	initialVelocity: Vector2,
	startTimeMs: number,
	acceleration: Vector2,
	totalTime: number
)
	local deltaTimeSeconds = (DateTime.now().UnixTimestampMillis - startTimeMs) / 1000
	local position = startPosition + (initialVelocity * deltaTimeSeconds) + (0.5 * acceleration * deltaTimeSeconds ^ 2)

	local alpha = deltaTimeSeconds / totalTime
	local sizeScalar = getExponentialTweenValueWithMidpoint(alpha, 0.7)
	local currentSize =
		UDim2.fromScale(itemAnimationPrefab.Size.X.Scale * sizeScalar, itemAnimationPrefab.Size.Y.Scale * sizeScalar)

	local instance = self._instance
	instance.Position = UDim2.fromOffset(position.X, position.Y)
	instance.Size = currentSize

	if deltaTimeSeconds > totalTime then
		-- End of lifetime reached
		self.completed:Fire()
		self:destroy()
	end
end

function ProjectileIcon.destroy(self: ClassType)
	self.completed:DisconnectAll()

	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
	end

	if self._instance then
		self._instance:Destroy()
	end
end

return ProjectileIcon
