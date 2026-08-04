--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedConstants = require(ReplicatedStorage.FeaturePackagesCore.Configs.SharedConstants)
local playSound = require(ReplicatedStorage.FeaturePackagesCore.Utils.playSound)
local UITween = require(ReplicatedStorage.FeaturePackagesCore.Modules.UITween)

local player = Players.LocalPlayer :: Player
local PlayerGui = player:WaitForChild("PlayerGui")

local function playParticles(position: Vector2, size: Vector2, parent: GuiObject)
	local random = Random.new()
	local center = position + size / 2

	-- Create particles
	for _ = 1, SharedConstants.Effects.Purchase.Particle.COUNT do
		local particleSize = size * random:NextNumber(0.3, 0.8)
		local particlePosition = center
			+ Vector2.new(random:NextInteger(-size.X, size.X), random:NextInteger(-size.Y, size.Y))
				* SharedConstants.Effects.Purchase.Particle.SPREAD.MIN

		local particle = Instance.new("ImageLabel")
		particle.Size = UDim2.fromOffset(particleSize.X, particleSize.Y)
		particle.Position = UDim2.fromOffset(particlePosition.X, particlePosition.Y)
		particle.BackgroundTransparency = 1
		particle.ImageColor3 = SharedConstants.Effects.Purchase.Particle.COLOR
		particle.Image = `rbxassetid://{SharedConstants.Effects.Purchase.Particle.ASSET_ID}`
		particle.Parent = parent

		local lifetime = random:NextNumber(
			SharedConstants.Effects.Purchase.Particle.LIFETIME.MIN,
			SharedConstants.Effects.Purchase.Particle.LIFETIME.MAX
		)
		local targetPosition = center
			+ Vector2.new(random:NextInteger(-size.X, size.X), random:NextInteger(-size.Y, size.Y))
				* SharedConstants.Effects.Purchase.Particle.SPREAD.MAX
		local targetRotation = random:NextInteger(-360, 360)

		UITween.rotation(particle, targetRotation, lifetime)
		UITween.transparency(particle, 1, lifetime)
		UITween.position(particle, UDim2.fromOffset(targetPosition.X, targetPosition.Y), lifetime)
	end
end

local function playAnimation(imageLabels: { ImageLabel }, overrideTransparency: boolean?, solidBackground: boolean?)
	local purchaseEffectGui = Instance.new("ScreenGui")
	purchaseEffectGui.Name = "CollectGui"
	purchaseEffectGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	purchaseEffectGui.DisplayOrder = math.huge
	purchaseEffectGui.ResetOnSpawn = false
	purchaseEffectGui.Parent = PlayerGui

	local purchaseEffectFrame = Instance.new("Frame")
	purchaseEffectFrame.Size = UDim2.fromScale(1, 1)
	purchaseEffectFrame.BackgroundTransparency = 1
	purchaseEffectFrame.Parent = purchaseEffectGui

	for _, imageLabel in ipairs(imageLabels) do
		local size = imageLabel.AbsoluteSize
		local position = imageLabel.AbsolutePosition
		local center = position + size / 2

		-- Create identical item image in canvas group
		local itemImageLabel = imageLabel:Clone()
		itemImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		itemImageLabel.Position = UDim2.fromOffset(center.X, center.Y)
		itemImageLabel.Size = UDim2.fromOffset(size.X, size.Y)
		itemImageLabel.BackgroundTransparency = 1
		itemImageLabel.ImageTransparency = 0
		itemImageLabel.Parent = purchaseEffectFrame

		-- Play animations
		local tweenToCenter = UITween.position(
			itemImageLabel,
			UDim2.fromScale(0.5, 0.5),
			SharedConstants.Effects.Purchase.DURATION / 3, -- Three tweens in total, each 1/3 of the total duration
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out
		) :: Tween

		local solidBackgroundFrame = Instance.new("Frame")
		solidBackgroundFrame.Visible = false
		if solidBackground then
			solidBackgroundFrame.Visible = true
			local prompt = PlayerGui:WaitForChild("MissionsGui"):WaitForChild("Prompt") :: CanvasGroup
			solidBackgroundFrame.Parent = prompt
			solidBackgroundFrame.Size = UDim2.fromScale(1, 1)
			solidBackgroundFrame.BackgroundColor3 = Color3.new(0, 0, 0)
			solidBackgroundFrame.BackgroundTransparency = 1
			task.spawn(UITween.transparency, solidBackgroundFrame, 0, SharedConstants.Effects.Purchase.DURATION / 6)
		end

		tweenToCenter.Completed:Once(function()
			local tweenDown = UITween.position(
				itemImageLabel,
				UDim2.fromScale(0.5, 1.5),
				SharedConstants.Effects.Purchase.DURATION / 3, -- Three tweens in total, each 1/3 of the total duration
				Enum.EasingStyle.Back,
				Enum.EasingDirection.In
			)
			if solidBackground then
				task.spawn(UITween.transparency, solidBackgroundFrame, 1, SharedConstants.Effects.Purchase.DURATION / 6)
			end

			tweenDown.Completed:Once(function()
				purchaseEffectGui:Destroy()
			end)
		end)

		task.spawn(playParticles, position, size, purchaseEffectFrame)

		if overrideTransparency then -- Do not call transparency tween if we are overriding it
			continue
		end
		task.spawn(UITween.transparency, imageLabel, 1, SharedConstants.Effects.Purchase.DURATION / 3) -- Three tweens in total, each 1/3 of the total duration
	end
end

local function playPurchaseEffect(
	imageLabels: { ImageLabel },
	overrideTransparency: boolean?,
	solidBackground: boolean?
)
	task.spawn(playSound, SharedConstants.Sounds.Ids.PURCHASE_EFFECT, SharedConstants.Sounds.VOLUME / 2)

	playAnimation(imageLabels, overrideTransparency or false, solidBackground or false)
end

return playPurchaseEffect
