--!strict

--[[
	UI Component that creates a ViewportFrame frame with a given model fit perfectly inside its viewport regardless
	of model size and aspect ratio
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ColorTheme = require(ReplicatedStorage.Source.SharedConstants.ColorTheme)

local createInstanceTree = require(ReplicatedStorage.Source.Utility.createInstanceTree)
local getInstance = require(ReplicatedStorage.Source.Utility.getInstance)

local prefabInstance: ViewportFrame = getInstance(ReplicatedStorage, "Instances", "GuiPrefabs", "ModelViewportPrefab")

export type ModelViewportProperties = {
	model: Model,
	fieldOfView: number?,
	lightingAmbient: Color3?,
	lightColor: Color3?,
	lightDirection: Vector3?,
}

local DEFAULT_FIELD_OF_VIEW = 20
local DEFAULT_LIGHTING_AMBIENT = ColorTheme.LightGray
local DEFAULT_LIGHT_COLOR = ColorTheme.Gray
local DEFAULT_LIGHT_DIRECTION = Vector3.new(-1, -1, -1)

local ModelViewport = {}
ModelViewport.__index = ModelViewport

export type ClassType = typeof(setmetatable(
	{} :: {
		_fieldOfView: number,
		_instance: ViewportFrame,
		_model: Model?,
		_camera: Camera?,
		_modelCFrame: CFrame?,
		_modelSize: Vector3?,
	},
	ModelViewport
))

function ModelViewport.new(properties: ModelViewportProperties): ClassType
	local self = {
		_fieldOfView = properties.fieldOfView or DEFAULT_FIELD_OF_VIEW,
		_instance = prefabInstance:Clone(),
		_model = nil,
		_camera = nil,
		_modelCFrame = nil,
		_modelSize = nil,
	}
	setmetatable(self, ModelViewport)

	assert(properties.model.PrimaryPart, "The modelPrefab does not have a PrimaryPart set")

	self:_setup(properties)

	return self
end

function ModelViewport.setParent(self: ClassType, parent: Instance)
	self._instance.Parent = parent
end

function ModelViewport._buildTree(self: ClassType, properties: ModelViewportProperties)
	self._instance.Ambient = properties.lightingAmbient or DEFAULT_LIGHTING_AMBIENT
	self._instance.LightColor = properties.lightColor or DEFAULT_LIGHT_COLOR
	self._instance.LightDirection = properties.lightDirection or DEFAULT_LIGHT_DIRECTION

	-- Camera objects don't replicate, so we'll create this one at runtime
	-- rather than placing one inside the prefab instance
	local camera = createInstanceTree({
		className = "Camera",
		properties = {
			FieldOfView = self._fieldOfView,
			FieldOfViewMode = Enum.FieldOfViewMode.Vertical,
		},
	})
	camera.Parent = self._instance
	self._instance.CurrentCamera = camera

	local model = properties.model:Clone()
	model:PivotTo(CFrame.new())
	self._modelCFrame, self._modelSize = model:GetBoundingBox()
	model.Parent = self._instance
	self._model = model
	self._camera = camera
end

function ModelViewport._setup(self: ClassType, properties: ModelViewportProperties)
	self:_buildTree(properties)

	-- In order to ensure the object always fits, we need to update the camera's orientation
	-- whenever the frame's aspect ratio changes.
	-- We don't need to store this connection as it will be disconnected when the ViewportFrame
	-- is destroyed.
	self._instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_updateCameraAngle()
	end)
	self:_updateCameraAngle()
end

function ModelViewport.pivotModel(self: ClassType, cFrame: CFrame)
	local model = self._model :: Model
	model:PivotTo(cFrame)
end

function ModelViewport.getModelPivot(self: ClassType): CFrame
	local model = self._model :: Model
	return model:GetPivot()
end

function ModelViewport._updateCameraAngle(self: ClassType)
	-- Our Camera's FieldOfView mode is Vertical, which means the horizontal FieldOfView
	-- is determined by the aspect ratio
	local aspectRatio = self._instance.AbsoluteSize.X / self._instance.AbsoluteSize.Y
	local verticalFOV = math.rad(self._fieldOfView)
	local horizontalFOV = math.rad(self._fieldOfView * aspectRatio)

	-- We are trying to find the distance the camera needs to be set back to fit the size of an object in a given direction in view.
	-- To do this, we solve for the adjacent side of a right angle triangle with opposite size/2 and theta of FOV/2:
	--       FOV
	--       /|\
	--      / | \
	--     /  |D \
	--    /   |I  \
	--   /    |S   \
	--  /     |T    \
	-- /______|______\
	--       SIZE
	local modelSize = self._modelSize :: Vector3
	local distanceToFitHorizontal = (0.5 * modelSize.X) / math.tan(0.5 * horizontalFOV)
	local distanceToFitVertical = (0.5 * modelSize.Y) / math.tan(0.5 * verticalFOV)

	-- To ensure the object fits, we will pick the greatest of the horizontal and vertical distance
	local distanceToFit = math.max(distanceToFitHorizontal, distanceToFitVertical)

	-- We then apply half of the depth of the model so we are going back from the object's outer edge
	local totalDistance = distanceToFit + (0.5 * modelSize.Z)
	local modelCFrame = self._modelCFrame :: CFrame
	local cameraTarget = modelCFrame * CFrame.new(0, 0, totalDistance)

	-- Finally, we are placing the camera at this distance, looking back towards the model
	local camera = self._camera :: Camera
	camera.CFrame = CFrame.lookAt(cameraTarget.Position, modelCFrame.Position)
end

function ModelViewport.destroy(self: ClassType)
	if self._instance.Parent then
		self._instance:Destroy()
	end
end

return ModelViewport
