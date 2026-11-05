local ServerScriptService = game:GetService("ServerScriptService")

local AudioServer = require(ServerScriptService.Systems.Audio.AudioServer)
local Constants = require(ServerScriptService.Systems.MechanismSystem.Constants)
local setTorchEnabled = require(ServerScriptService.Systems.MechanismSystem.Utility.setTorchEnabled)
local tweenModelPivot = require(ServerScriptService.Systems.MechanismSystem.Utility.tweenModelPivot)

local ACTIVATED = Constants.ACTIVATED_ATTRIBUTE
local DEFAULT_ROTATE_DURATION = 0.5
local DEFAULT_ROTATE_ANGLE = 90

local state: {
	[Model]: {
		prompt: ProximityPrompt,
		connection: RBXScriptConnection,
		torch: MeshPart,
		handleModel: Model,
		originalCFrame: CFrame,
		activatedCFrame: CFrame,
		cancelTween: (() -> ())?,
	},
} =
	{}

local function onStart(model: Model, _inputs: { Model })
	local handleModel = model:FindFirstChild("Handle")
	if not (handleModel and handleModel:IsA("Model")) then
		warn(`[Lever] Model {model:GetFullName()} does not have a Model named Handle.`)
		return
	end

	local knob = handleModel:FindFirstChild("Knob")
	if not (knob and knob:IsA("MeshPart")) then
		warn(`[Lever] Handle in {model:GetFullName()} does not have a MeshPart named Knob.`)
		return
	end

	local torch = model:FindFirstChild("Torch")
	if not (torch and torch:IsA("MeshPart")) then
		warn(`[Lever] Model {model:GetFullName()} does not have a MeshPart named Torch.`)
		return
	end

	model:SetAttribute(ACTIVATED, false)
	setTorchEnabled(torch, false)

	local rotateDuration = model:GetAttribute("rotateDuration") :: number? or DEFAULT_ROTATE_DURATION
	local rotateAngle = model:GetAttribute("rotateAngle") :: number? or DEFAULT_ROTATE_ANGLE
	local originalCFrame = handleModel:GetPivot()
	local parentCFrame = model:GetPivot()
	local localCFrame = parentCFrame:ToObjectSpace(originalCFrame)
	local rotatedLocal = localCFrame * CFrame.Angles(math.rad(rotateAngle), 0, 0)
	local activatedCFrame = parentCFrame:ToWorldSpace(rotatedLocal)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Use"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("triggerSound", "LeverToggle")
	prompt.Parent = knob

	local connection = prompt.Triggered:Connect(function(player: Player)
		local entry = state[model]
		if not entry then
			return
		end

		local activated = not model:GetAttribute(ACTIVATED)
		model:SetAttribute(ACTIVATED, activated)
		setTorchEnabled(torch, activated)
		AudioServer.playOnInstance("LeverToggle", model, nil, player)

		if activated then
			AudioServer.playOnInstance("TorchActivate", model)
		else
			AudioServer.playOnInstance("TorchDeactivate", model)
		end

		if entry.cancelTween then
			entry.cancelTween()
		end

		local targetCFrame = if activated then activatedCFrame else originalCFrame
		local tweenInfo = TweenInfo.new(rotateDuration, Enum.EasingStyle.Back)
		entry.cancelTween = tweenModelPivot(handleModel, targetCFrame, tweenInfo)
	end)

	state[model] = {
		prompt = prompt,
		connection = connection,
		torch = torch,
		handleModel = handleModel,
		originalCFrame = originalCFrame,
		activatedCFrame = activatedCFrame,
		cancelTween = nil,
	}
end

local function onUpdate(_model: Model, _inputs: { Model }) end

local function onStop(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	entry.connection:Disconnect()
	entry.prompt:Destroy()

	if entry.cancelTween then
		entry.cancelTween()
	end

	state[model] = nil
end

return {
	name = "Lever",
	onStart = onStart,
	onUpdate = onUpdate,
	onStop = onStop,
}
