local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)
local bindTagged = require(ReplicatedStorage.Utility.bindTagged)

export type MechanismDefinition = Types.MechanismDefinition

local definitions: { [string]: Types.MechanismDefinition } = {}
local mechanisms: { [Model]: { definition: Types.MechanismDefinition, inputs: { Model } } } = {}

local function getInputs(model: Model): { Model }
	local inputs: { Model } = {}
	local inputsFolder = model:FindFirstChild(Constants.INPUTS_FOLDER)
	if inputsFolder then
		for _, child in inputsFolder:GetChildren() do
			if child:IsA("ObjectValue") and (child.Value and child.Value:IsA("Model")) then
				table.insert(inputs, child.Value :: Model)
			end
		end
	end
	return inputs
end

local function onMechanismAdded(model: Instance)
	if not model:IsA("Model") then
		warn(`[MechanismSystem] Tried to add {model.Name} to registry, but it is not a model.`)
		return
	end

	local definitionName = model:GetAttribute(Constants.MODULE_ATTRIBUTE)
	if not definitionName then
		warn(`[MechanismSystem] Model {model:GetFullName()} has no mechanismModule attribute`)
		return
	end

	if type(definitionName) ~= "string" then
		warn(`[MechanismSystem] Model {model:GetFullName()}'s mechanismModule attribute is not a string`)
		return
	end

	local definition = definitions[definitionName]
	if not definition then
		warn(`[MechanismSystem] No definition found for "{definitionName}"`)
		return
	end

	local inputs = getInputs(model)
	mechanisms[model] = { definition = definition, inputs = inputs }
	definition.onStart(model, inputs)
end

local function onMechanismRemoved(model: Instance)
	if not model:IsA("Model") then
		warn(`[MechanismSystem] Tried to remove {model.Name} from registry, but it is not a model.`)
		return
	end

	local entry = mechanisms[model]
	if not entry then
		return
	end

	if entry.definition.onStop then
		entry.definition.onStop(model)
	end

	mechanisms[model] = nil
end

local MechanismSystem = {}

function MechanismSystem.autoLoad(target: Instance)
	for _, child in target:GetChildren() do
		if child:IsA("ModuleScript") then
			local definition = require(child) :: Types.MechanismDefinition
			definitions[definition.name] = definition
		end
	end
end

function MechanismSystem.start()
	RunService.Heartbeat:Connect(function()
		for model, entry in mechanisms do
			entry.definition.onUpdate(model, entry.inputs)
		end
	end)

	bindTagged(Constants.MECHANISM_TAG, { Workspace }, onMechanismAdded, onMechanismRemoved)
end

return MechanismSystem
