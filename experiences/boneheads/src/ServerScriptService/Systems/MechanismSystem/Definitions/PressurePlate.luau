local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local AudioServer = require(ServerScriptService.Systems.Audio.AudioServer)
local Constants = require(ServerScriptService.Systems.MechanismSystem.Constants)
local setTorchEnabled = require(ServerScriptService.Systems.MechanismSystem.Utility.setTorchEnabled)
local tweenModelPivot = require(ServerScriptService.Systems.MechanismSystem.Utility.tweenModelPivot)

local ACTIVATED = Constants.ACTIVATED_ATTRIBUTE
local PRESS_DISTANCE = 0.25
local PRESS_DURATION = 0.25

local state: {
	[Model]: {
		connections: { RBXScriptConnection },
		touchingParts: { [BasePart]: RBXScriptConnection },
		torch: MeshPart,
		originalCFrame: CFrame,
		cancelTween: (() -> ())?,
	},
} =
	{}

local function onStart(model: Model, _inputs: { Model })
	local plateModel = model:FindFirstChild("Plate")
	if not (plateModel and plateModel:IsA("Model")) then
		warn(`[PressurePlate] Model {model:GetFullName()} does not have a Model named Plate.`)
		return
	end

	local torch = model:FindFirstChild("Torch")
	if not (torch and torch:IsA("MeshPart")) then
		warn(`[PressurePlate] Model {model:GetFullName()} does not have a MeshPart named Torch.`)
		return
	end

	local collider = model:FindFirstChild("Collider")
	if not (collider and collider:IsA("BasePart")) then
		warn(`[PressurePlate] Model {model:GetFullName()} does not have a BasePart named Collider.`)
		return
	end

	model:SetAttribute(ACTIVATED, false)
	setTorchEnabled(torch, false)

	local originalCFrame = plateModel:GetPivot()
	local pressedCFrame = originalCFrame * CFrame.new(0, -PRESS_DISTANCE, 0)

	state[model] = {
		connections = {},
		touchingParts = {},
		torch = torch,
		originalCFrame = originalCFrame,
		cancelTween = nil,
	}

	local function releasePart(other: BasePart)
		local entry = state[model]
		if not entry then
			return
		end

		local ancestryConnection = entry.touchingParts[other]
		if not ancestryConnection then
			return
		end

		ancestryConnection:Disconnect()
		entry.touchingParts[other] = nil

		if next(entry.touchingParts) == nil then
			model:SetAttribute(ACTIVATED, false)
			setTorchEnabled(torch, false)
			AudioServer.playOnInstance("PlateToggled", model)
			AudioServer.playOnInstance("TorchDeactivate", model)

			if entry.cancelTween then
				entry.cancelTween()
			end

			local tweenInfo = TweenInfo.new(PRESS_DURATION, Enum.EasingStyle.Quint)
			entry.cancelTween = tweenModelPivot(plateModel, originalCFrame, tweenInfo)
		end
	end

	local touchedConnection = collider.Touched:Connect(function(other: BasePart)
		if other.Anchored then
			return
		end

		local entry = state[model]
		if not entry or entry.touchingParts[other] then
			return
		end

		local wasEmpty = next(entry.touchingParts) == nil
		-- TouchEnded never fires for a part that is destroyed or removed while touching.
		entry.touchingParts[other] = other.AncestryChanged:Connect(function()
			if not other:IsDescendantOf(Workspace) then
				releasePart(other)
			end
		end)

		if wasEmpty then
			model:SetAttribute(ACTIVATED, true)
			setTorchEnabled(torch, true)
			AudioServer.playOnInstance("PlateToggled", model)
			AudioServer.playOnInstance("TorchActivate", model)

			if entry.cancelTween then
				entry.cancelTween()
			end

			local tweenInfo = TweenInfo.new(PRESS_DURATION, Enum.EasingStyle.Quint)
			entry.cancelTween = tweenModelPivot(plateModel, pressedCFrame, tweenInfo)
		end
	end)

	local touchEndedConnection = collider.TouchEnded:Connect(releasePart)

	state[model].connections = { touchedConnection, touchEndedConnection }
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

	for _, ancestryConnection in entry.touchingParts do
		ancestryConnection:Disconnect()
	end

	if entry.cancelTween then
		entry.cancelTween()
	end

	state[model] = nil
end

return {
	name = "PressurePlate",
	onStart = onStart,
	onUpdate = onUpdate,
	onStop = onStop,
}
