local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AudioServer = require(ServerScriptService.Systems.Audio.AudioServer)
local Constants = require(ServerScriptService.Systems.MechanismSystem.Constants)

local ACTIVATED = Constants.ACTIVATED_ATTRIBUTE

local state: {
	[Model]: {
		bannerDeactivated: MeshPart,
		bannerActivated: MeshPart,
		currentLabel: TextLabel,
		neededLabel: TextLabel,
		requiredActivations: number,
		activated: boolean,
	},
} =
	{}

local function onStart(model: Model, inputs: { Model })
	local bannerDeactivated = model:FindFirstChild("BannerDeactivated")
	if not (bannerDeactivated and bannerDeactivated:IsA("MeshPart")) then
		warn(`[CounterGate] Model {model:GetFullName()} does not have a MeshPart named BannerDeactivated.`)
		return
	end

	local renderer = model:FindFirstChild("Renderer")
	if not (renderer and renderer:IsA("BasePart")) then
		warn(`[CounterGate] Model {model:GetFullName()} does not have a BasePart named Renderer.`)
		return
	end

	local surfaceGui = renderer:FindFirstChild("SurfaceGui")
	if not (surfaceGui and surfaceGui:IsA("SurfaceGui")) then
		warn(`[CounterGate] Renderer in {model:GetFullName()} does not have a SurfaceGui.`)
		return
	end

	local currentLabel = surfaceGui:FindFirstChild("Current")
	if not (currentLabel and currentLabel:IsA("TextLabel")) then
		warn(`[CounterGate] SurfaceGui in {model:GetFullName()} does not have a TextLabel named Current.`)
		return
	end

	local neededLabel = surfaceGui:FindFirstChild("Needed")
	if not (neededLabel and neededLabel:IsA("TextLabel")) then
		warn(`[CounterGate] SurfaceGui in {model:GetFullName()} does not have a TextLabel named Needed.`)
		return
	end

	local bannerTemplate = ReplicatedStorage:FindFirstChild("Content")
		and ReplicatedStorage.Content:FindFirstChild("Models")
		and ReplicatedStorage.Content.Models:FindFirstChild("BannerActivated")
	if not (bannerTemplate and bannerTemplate:IsA("MeshPart")) then
		warn(`[CounterGate] ReplicatedStorage.Content.Models does not have a MeshPart named BannerActivated.`)
		return
	end

	model:SetAttribute(ACTIVATED, false)

	local bannerActivated = bannerTemplate:Clone()
	bannerActivated.CFrame = bannerDeactivated.CFrame

	local requiredActivations = model:GetAttribute("requiredActivations") :: number? or #inputs

	currentLabel.Text = "0"
	neededLabel.Text = tostring(requiredActivations)

	state[model] = {
		bannerDeactivated = bannerDeactivated,
		bannerActivated = bannerActivated,
		currentLabel = currentLabel,
		neededLabel = neededLabel,
		requiredActivations = requiredActivations,
		activated = false,
	}
end

local function onUpdate(model: Model, inputs: { Model })
	local entry = state[model]
	if not entry then
		return
	end

	local activeCount = 0
	for _, input in inputs do
		if input:GetAttribute(ACTIVATED) then
			activeCount += 1
		end
	end

	entry.currentLabel.Text = tostring(activeCount)

	local shouldActivate = activeCount >= entry.requiredActivations

	if shouldActivate and not entry.activated then
		entry.activated = true
		model:SetAttribute(ACTIVATED, true)
		entry.bannerDeactivated.Parent = nil
		entry.bannerActivated.Parent = model
		AudioServer.playOnInstance("CounterGateCompleted", model)
	elseif not shouldActivate and entry.activated then
		entry.activated = false
		model:SetAttribute(ACTIVATED, false)
		entry.bannerActivated.Parent = nil
		entry.bannerDeactivated.Parent = model
	end
end

local function onStop(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	entry.bannerActivated:Destroy()

	if not entry.bannerDeactivated.Parent then
		entry.bannerDeactivated.Parent = model
	end

	state[model] = nil
end

return {
	name = "CounterGate",
	onStart = onStart,
	onUpdate = onUpdate,
	onStop = onStop,
}
