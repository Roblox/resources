local ServerScriptService = game:GetService("ServerScriptService")

local AudioServer = require(ServerScriptService.Systems.Audio.AudioServer)
local Constants = require(ServerScriptService.Systems.MechanismSystem.Constants)
local setTorchEnabled = require(ServerScriptService.Systems.MechanismSystem.Utility.setTorchEnabled)
local tweenModelPivot = require(ServerScriptService.Systems.MechanismSystem.Utility.tweenModelPivot)

local ACTIVATED = Constants.ACTIVATED_ATTRIBUTE
local DEFAULT_ACTIVATION_DURATION = 9
local DEFAULT_FLIP_DURATION = 0.5

local state: {
	[Model]: {
		connections: { RBXScriptConnection },
		timerThread: thread?,
		targetModel: Model,
		textLabel: TextLabel,
		torch: MeshPart,
		originalCFrame: CFrame,
		flipDuration: number,
		cancelTween: (() -> ())?,
		activated: boolean,
	},
} =
	{}

local function deactivate(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	entry.activated = false
	model:SetAttribute(ACTIVATED, false)
	setTorchEnabled(entry.torch, false)
	AudioServer.playOnInstance("WoodHingeRotate", model)
	AudioServer.playOnInstance("TorchDeactivate", model)
	entry.textLabel.Text = ""

	if entry.cancelTween then
		entry.cancelTween()
	end

	local tweenInfo = TweenInfo.new(entry.flipDuration, Enum.EasingStyle.Back)
	entry.cancelTween = tweenModelPivot(entry.targetModel, entry.originalCFrame, tweenInfo)
end

local function onStart(model: Model, _inputs: { Model })
	local targetModel = model:FindFirstChild("Target")
	if not (targetModel and targetModel:IsA("Model")) then
		warn(`[Target] Model {model:GetFullName()} does not have a Model named Target.`)
		return
	end

	local renderer = targetModel:FindFirstChild("Renderer")
	if not (renderer and renderer:IsA("BasePart")) then
		warn(`[Target] Target in {model:GetFullName()} does not have a BasePart named Renderer.`)
		return
	end

	local surfaceGui = renderer:FindFirstChild("SurfaceGui")
	if not (surfaceGui and surfaceGui:IsA("SurfaceGui")) then
		warn(`[Target] Renderer in {model:GetFullName()} does not have a SurfaceGui.`)
		return
	end

	local textLabel = surfaceGui:FindFirstChild("TextLabel")
	if not (textLabel and textLabel:IsA("TextLabel")) then
		warn(`[Target] SurfaceGui in {model:GetFullName()} does not have a TextLabel.`)
		return
	end

	local torch = model:FindFirstChild("Torch")
	if not (torch and torch:IsA("MeshPart")) then
		warn(`[Target] Model {model:GetFullName()} does not have a MeshPart named Torch.`)
		return
	end

	local collider = model:FindFirstChild("Collider")
	if not (collider and collider:IsA("BasePart")) then
		warn(`[Target] Model {model:GetFullName()} does not have a BasePart named Collider.`)
		return
	end

	model:SetAttribute(ACTIVATED, false)
	setTorchEnabled(torch, false)
	textLabel.Text = ""

	local duration = model:GetAttribute("activationDuration") :: number? or DEFAULT_ACTIVATION_DURATION
	local flipDuration = model:GetAttribute("flipDuration") :: number? or DEFAULT_FLIP_DURATION
	local originalCFrame = targetModel:GetPivot()
	local flippedCFrame = originalCFrame * CFrame.Angles(0, 0, math.rad(180))

	state[model] = {
		connections = {},
		timerThread = nil,
		targetModel = targetModel,
		textLabel = textLabel,
		torch = torch,
		originalCFrame = originalCFrame,
		flipDuration = flipDuration,
		cancelTween = nil,
		activated = false,
	}

	local touchedConnection = collider.Touched:Connect(function(other: BasePart)
		if other.Anchored then
			return
		end

		local entry = state[model]
		if not entry or entry.activated then
			return
		end

		entry.activated = true
		model:SetAttribute(ACTIVATED, true)
		setTorchEnabled(torch, true)
		AudioServer.playOnInstance("WoodHingeRotate", model)
		AudioServer.playOnInstance("TorchActivate", model)

		if entry.cancelTween then
			entry.cancelTween()
		end

		local tweenInfo = TweenInfo.new(flipDuration, Enum.EasingStyle.Back)
		entry.cancelTween = tweenModelPivot(targetModel, flippedCFrame, tweenInfo)

		entry.timerThread = task.spawn(function()
			for remaining = duration, 1, -1 do
				textLabel.Text = tostring(remaining)
				AudioServer.playOnInstance("TimerTickDown", model)
				task.wait(1)
			end
			textLabel.Text = "0"
			deactivate(model)
		end)
	end)

	state[model].connections = { touchedConnection }
end

local function onUpdate(_model: Model, _inputs: { Model }) end

local function onStop(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	for _, connection in entry.connections do
		connection:Disconnect()
	end

	if entry.timerThread then
		task.cancel(entry.timerThread)
	end

	if entry.cancelTween then
		entry.cancelTween()
	end

	state[model] = nil
end

return {
	name = "Target",
	onStart = onStart,
	onUpdate = onUpdate,
	onStop = onStop,
}
