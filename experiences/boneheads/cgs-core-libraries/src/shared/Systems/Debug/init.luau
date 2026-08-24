-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Constants)
local Types = require(script.Types)
local arc = require(script.arc)
local box = require(script.box)
local line = require(script.line)
local lines = require(script.lines)
local sphere = require(script.sphere)
local textBoxAdorning = require(script.textBoxAdorning)
local textBoxAtPosition = require(script.textBoxAtPosition)
local textGroupAdorning = require(script.textGroupAdorning)

local DEBUG_TOGGLES = Constants.DEBUG_TOGGLE :: { [Types.DebugToggleKey]: Types.DebugToggle }
local SYNC_REMOTE_NAME = "SyncDebugAttribute"

local Debug = {}

local idMap: Types.IdMap<Types.IdEntry> = {}
local disabledPrefixes: { string } = {}
local registeredToggleAttributes: { string } = {}
local idCounter = 0
local idCounterIncrement = if RunService:IsClient() then -1 else 1

local function shouldBeEnabled(id: string): boolean
	if not RunService:IsStudio() then
		return false
	end

	for _, prefix in disabledPrefixes do
		if string.sub(id, 1, #prefix) == prefix then
			return false
		end
	end
	return true
end

function Debug.destroy(id: string)
	if not idMap[id] then
		return
	end

	idMap[id].destroy(idMap[id].data)
	idMap[id] = nil
end

function Debug.line(id: string, position1: Vector3, position2: Vector3, color: Color3?, width: number?)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = line.create(), destroy = line.destroy }
	end

	line.update(idMap[id].data, position1, position2, color, width)
end

function Debug.lines(id: string, pointsTable: { Vector3 }, color: Color3?, width: number?)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = lines.create(), destroy = lines.destroy }
	end

	lines.update(idMap[id].data, pointsTable, color, width)
end

function Debug.sphere(id: string, position: Vector3, radius: number, color: Color3?)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = sphere.create(), destroy = sphere.destroy }
	end

	sphere.update(idMap[id].data, position, radius, color)
end

function Debug.textBoxAdorning(
	id: string,
	text: string,
	offset: Vector3?,
	parent: Instance?,
	color: Color3?,
	textSize: number?
)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = textBoxAdorning.create(), destroy = textBoxAdorning.destroy }
	end

	textBoxAdorning.update(idMap[id].data, text, offset, parent, color, textSize)
end

function Debug.textBoxAtPosition(id: string, position: Vector3, text: string?, color: Color3?, textSize: number?)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = textBoxAtPosition.create(), destroy = textBoxAtPosition.destroy }
	end

	textBoxAtPosition.update(idMap[id].data, position, text, color, textSize)
end

function Debug.textGroupAdorning(id: string, entries: { Types.LabelEntry }, offset: Vector3?, adornee: Instance?)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = textGroupAdorning.create(), destroy = textGroupAdorning.destroy }
	end

	textGroupAdorning.update(idMap[id].data, entries, offset, adornee)
end

function Debug.arc(id: string, origin: CFrame, length: number, angle: number, color: Color3?, width: number?)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = arc.create(), destroy = arc.destroy }
	end

	arc.update(idMap[id].data, origin, length, angle, color, width)
end

function Debug.box(id: string, origin: CFrame, size: Vector3?, color: Color3?)
	if not shouldBeEnabled(id) then
		return
	end

	if not idMap[id] then
		idMap[id] = { data = box.create(), destroy = box.destroy }
	end

	box.update(idMap[id].data, origin, size, color)
end

function Debug.setIdEnabled(idPrefix: string, enabled: boolean)
	if enabled then
		local foundIndex = table.find(disabledPrefixes, idPrefix)
		if foundIndex then
			table.remove(disabledPrefixes, foundIndex)
		end
	else
		local foundIndex = table.find(disabledPrefixes, idPrefix)
		if foundIndex then
			return
		end

		table.insert(disabledPrefixes, idPrefix)

		for id in idMap do
			if string.sub(id, 1, #idPrefix) == idPrefix then
				Debug.destroy(id)
			end
		end
	end
end

function Debug.getId(instance: Instance): number
	local currentId = instance:GetAttribute(Constants.DEBUG_ID_ATTRIBUTE) :: number?
	if not currentId then
		currentId = idCounter
		idCounter += idCounterIncrement

		instance:SetAttribute(Constants.DEBUG_ID_ATTRIBUTE, currentId)
	end

	return currentId :: number
end

function Debug.getToggle(toggleKey: Types.DebugToggleKey): boolean
	local toggleInfo = DEBUG_TOGGLES[toggleKey]
	assert(toggleInfo, `Unknown debug toggle key: {toggleKey}`)
	return Workspace:GetAttribute(toggleInfo.ATTRIBUTE) == true
end

function Debug.isToggleEnabled(attribute: string): boolean
	return Workspace:GetAttribute(attribute) == true
end

function Debug.getTogglePrefix(toggleKey: Types.DebugToggleKey): string
	local toggleInfo = DEBUG_TOGGLES[toggleKey]
	assert(toggleInfo, `Unknown debug toggle key: {toggleKey}`)
	return toggleInfo.ID_PREFIX
end

local function onToggleAttributeChanged(toggle: Types.DebugToggle)
	local isEnabled = Workspace:GetAttribute(toggle.ATTRIBUTE) == true
	Debug.setIdEnabled(toggle.ID_PREFIX, isEnabled)
end

function Debug.registerToggle(attribute: string, idPrefix: string): string
	if not RunService:IsStudio() then
		return idPrefix
	end

	local toggle: Types.DebugToggle = { ATTRIBUTE = attribute, ID_PREFIX = idPrefix }
	table.insert(registeredToggleAttributes, attribute)
	onToggleAttributeChanged(toggle)
	Workspace:GetAttributeChangedSignal(attribute):Connect(function()
		onToggleAttributeChanged(toggle)
	end)
	return idPrefix
end

function Debug.start()
	if not RunService:IsStudio() then
		return
	end

	for _, toggle in DEBUG_TOGGLES do
		table.insert(registeredToggleAttributes, toggle.ATTRIBUTE)
		onToggleAttributeChanged(toggle)
		Workspace:GetAttributeChangedSignal(toggle.ATTRIBUTE):Connect(function()
			onToggleAttributeChanged(toggle)
		end)
	end

	if RunService:IsServer() then
		local remote = Instance.new("RemoteEvent")
		remote.Name = SYNC_REMOTE_NAME
		remote.Parent = script

		remote.OnServerEvent:Connect(function(_player: Player, attribute: unknown, value: unknown)
			if typeof(attribute) == "string" and typeof(value) == "boolean" then
				Workspace:SetAttribute(attribute, value)
			end
		end)
	elseif RunService:IsClient() then
		local remote = script:WaitForChild(SYNC_REMOTE_NAME, 10) :: RemoteEvent?
		if not remote then
			warn("Debug: SyncDebugAttribute remote not found - attribute sync will not work")
			return
		end

		local lastSentValues: { [string]: boolean } = {}

		Workspace.AttributeChanged:Connect(function(attribute: string)
			if not table.find(registeredToggleAttributes, attribute) then
				return
			end

			local value = Workspace:GetAttribute(attribute) == true
			if lastSentValues[attribute] == value then
				return
			end

			lastSentValues[attribute] = value
			remote:FireServer(attribute, value)
		end)
	end
end

function Debug.getRegisteredToggleAttributes(): { string }
	return registeredToggleAttributes
end

return Debug
