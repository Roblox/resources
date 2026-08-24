--!strict

--[[
	Creates a queue for ProjectileIcons to be created based on deltas passed into animateDeltas.
	Provides an iconCompleted event for the caller to play any custom animations when a ProjectileIcon reaches its target.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ThreadQueue = require(ReplicatedStorage.Source.ThreadQueue)
local Signal = require(ReplicatedStorage.Source.Signal)
local ProjectileIcon = require(script.Parent.UIComponents.ProjectileIcon)

local MAX_QUEUE_LENGTH = 10 -- Used to prevent animations from being on screen for too long, like if someone buys 1,000 items
local SECONDS_BETWEEN_SPAWNS = 0.15 -- Used to prevent all the icons from being created in the same instant

local ProjectileIconQueue = {}
ProjectileIconQueue.__index = ProjectileIconQueue

export type ClassType = typeof(setmetatable(
	{} :: {
		_threadQueue: ThreadQueue.ClassType,
		_iconParentScreenGui: ScreenGui,
		_targetGui: GuiObject,
		iconCompleted: Signal.ClassType,
	},
	ProjectileIconQueue
))

function ProjectileIconQueue.new(iconParentScreenGui: ScreenGui, targetGui: GuiObject): ClassType
	local self = {
		_threadQueue = ThreadQueue.new(SECONDS_BETWEEN_SPAWNS, MAX_QUEUE_LENGTH, true),
		_iconParentScreenGui = iconParentScreenGui,
		_targetGui = targetGui,
		iconCompleted = Signal.new(),
	}

	setmetatable(self, ProjectileIconQueue)

	return self
end

function ProjectileIconQueue.animateDeltas(self: ClassType, deltasByItemPrefab: { [Model]: number })
	-- Play animations
	for itemPrefab, delta in pairs(deltasByItemPrefab) do
		-- We're only animating new items being added, not items spent or used
		if delta > 0 then
			for _ = 1, delta do
				self:_animateItem(itemPrefab)
			end
		end
	end
end

function ProjectileIconQueue._animateItem(self: ClassType, itemPrefab: Model)
	task.spawn(function()
		self._threadQueue:submitAsync(function()
			-- Destroys itself when animation completes, no need to explicitly destroy
			local absolutePosition: Vector2 = self._targetGui.AbsolutePosition
			local absoluteSize: Vector2 = self._targetGui.AbsoluteSize
			local targetCoordinates = absolutePosition + absoluteSize / 2
			local projectileIcon = ProjectileIcon.new(itemPrefab, self._iconParentScreenGui)

			-- Connects to heartbeat, so this is deferred (yields). No chance .completed fires before we connect
			projectileIcon:launchToward(targetCoordinates)
			projectileIcon.completed:Wait()
			self.iconCompleted:Fire()
		end)
	end)
end

function ProjectileIconQueue.destroy(self: ClassType)
	self.iconCompleted:DisconnectAll()
end

return ProjectileIconQueue
