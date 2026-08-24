--!strict

--[[
	Handles client-side squash animations for the rooster NPCs around the market

	Note: Typically, using an actual AnimationTrack would be preferred because it gives more flexibility
	and is more performant than tweening properties. However, here we do the latter because this is a sample
	project, and use of animations is restricted to only the uploader. Therefore, if we used the Roblox animation system,
	the animations would not be available to anyone getting a standalone copy of this place.
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local SQUASH_FACTOR = 1.1
local ANIMATION_TIME = 0.6
local SQUASH_SCALAR = Vector3.new(SQUASH_FACTOR, 1 / SQUASH_FACTOR, SQUASH_FACTOR)

local random = Random.new()

local AnimatedRoosterNPC = {}
AnimatedRoosterNPC.__index = AnimatedRoosterNPC

export type ClassType = typeof(setmetatable(
	{} :: {
		_instance: Model,
		_loopedAnimationTween: Tween?,
	},
	AnimatedRoosterNPC
))

function AnimatedRoosterNPC.new(npcModel: Model): ClassType
	local self = {
		_instance = npcModel,
	}

	setmetatable(self, AnimatedRoosterNPC)

	-- Offset animations to add some variation across roosters
	task.delay(math.random() * ANIMATION_TIME, self._startAnimation, self)

	return self
end

function AnimatedRoosterNPC._startAnimation(self: ClassType)
	local mesh: MeshPart = getInstance(self._instance, "Mesh")
	local tweenInfo = TweenInfo.new(
		ANIMATION_TIME,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.InOut,
		-1,
		true,
		random:NextNumber(1.5, 3)
	)
	local squashedMeshSize = mesh.Size * SQUASH_SCALAR

	local tween = TweenService:Create(mesh, tweenInfo, {
		Size = squashedMeshSize,
		CFrame = mesh.CFrame * CFrame.new(0, -(mesh.Size - squashedMeshSize).Y / 2, 0),
	})
	tween:Play()
	self._loopedAnimationTween = tween
end

function AnimatedRoosterNPC.destroy(self: ClassType)
	if self._loopedAnimationTween then
		self._loopedAnimationTween:Cancel()
	end
end

return AnimatedRoosterNPC
