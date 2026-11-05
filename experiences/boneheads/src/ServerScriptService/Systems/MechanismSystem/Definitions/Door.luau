local ServerScriptService = game:GetService("ServerScriptService")

local AudioServer = require(ServerScriptService.Systems.Audio.AudioServer)
local Constants = require(ServerScriptService.Systems.MechanismSystem.Constants)
local tweenModelPivot = require(ServerScriptService.Systems.MechanismSystem.Utility.tweenModelPivot)

local ACTIVATED = Constants.ACTIVATED_ATTRIBUTE
local DEFAULT_OPEN_ANGLE = 100
local DEFAULT_OPEN_DURATION = 0.75
local DEFAULT_CLOSE_DURATION = 0.25
local DEFAULT_ROTATION_DIRECTION = 1

local state: {
	[Model]: {
		originalCFrame: CFrame,
		openAngle: number,
		openDuration: number,
		closeDuration: number,
		cancelTween: (() -> ())?,
		activated: boolean,
	},
} =
	{}

local function onStart(model: Model, _inputs: { Model })
	model:SetAttribute(ACTIVATED, false)

	state[model] = {
		originalCFrame = model:GetPivot(),
		openAngle = model:GetAttribute("openAngle") :: number? or DEFAULT_OPEN_ANGLE,
		openDuration = model:GetAttribute("openDuration") :: number? or DEFAULT_OPEN_DURATION,
		closeDuration = model:GetAttribute("closeDuration") :: number? or DEFAULT_CLOSE_DURATION,
		cancelTween = nil,
		activated = false,
	}
end

local function onUpdate(model: Model, inputs: { Model })
	local entry = state[model]
	if not entry then
		return
	end

	local allActive = true
	for _, input in inputs do
		if not input:GetAttribute(ACTIVATED) then
			allActive = false
			break
		end
	end

	if allActive and not entry.activated then
		entry.activated = true
		model:SetAttribute(ACTIVATED, true)
		AudioServer.playOnInstance("DoorOpen", model)

		if entry.cancelTween then
			entry.cancelTween()
		end

		local rotationDirection = model:GetAttribute("rotationDirection") :: number? or DEFAULT_ROTATION_DIRECTION
		local openCFrame = entry.originalCFrame * CFrame.Angles(0, math.rad(entry.openAngle * rotationDirection), 0)
		local tweenInfo = TweenInfo.new(entry.openDuration, Enum.EasingStyle.Back)
		entry.cancelTween = tweenModelPivot(model, openCFrame, tweenInfo)
	elseif not allActive and entry.activated then
		entry.activated = false
		model:SetAttribute(ACTIVATED, false)
		AudioServer.playOnInstance("DoorClose", model)

		if entry.cancelTween then
			entry.cancelTween()
		end

		local tweenInfo = TweenInfo.new(entry.closeDuration, Enum.EasingStyle.Quint)
		entry.cancelTween = tweenModelPivot(model, entry.originalCFrame, tweenInfo)
	end
end

local function onStop(model: Model)
	local entry = state[model]
	if not entry then
		return
	end

	if entry.cancelTween then
		entry.cancelTween()
	end

	state[model] = nil
end

return {
	name = "Door",
	onStart = onStart,
	onUpdate = onUpdate,
	onStop = onStop,
}
