-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Constants)
local Types = require(script.Types)

local disconnectAndClear = require(ReplicatedStorage.Core.Utility.disconnectAndClear)

local MiniMap = {}

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

type MapFrameResult = {
	frame: Frame,
	mapClip: CanvasGroup,
	mapContent: Frame,
	markersFrame: Frame,
	edgeIndicatorsFrame: Frame,
	backgroundLabel: ImageLabel?,
	playerMarkerFrame: Frame?,
}

local function getWorldToMapSpace(
	worldPos: Vector3,
	playerPos: Vector3,
	worldRadius: number,
	mapSize: Vector2,
	clipShape: string
): (Vector2, number, boolean)
	local dx = worldPos.X - playerPos.X
	local dz = worldPos.Z - playerPos.Z

	-- Normalize to map space (-1 to 1), then to pixels
	local nx = dx / worldRadius
	local ny = dz / worldRadius

	local px = (nx * 0.5 + 0.5) * mapSize.X
	local py = (ny * 0.5 + 0.5) * mapSize.Y

	local dist = math.sqrt(dx * dx + dz * dz)

	local isOnMap: boolean
	if clipShape == "circle" then
		isOnMap = dist <= worldRadius
	else
		-- Rectangle: check each axis independently
		isOnMap = math.abs(dx) <= worldRadius and math.abs(dz) <= worldRadius
	end

	return Vector2.new(px, py), dist, isOnMap
end

local function createLine(p1: Vector2, p2: Vector2, thickness: number, color: Color3, parent: Frame)
	local delta = p2 - p1
	local length = delta.Magnitude
	local angle = math.deg(math.atan2(delta.Y, delta.X))
	local mid = (p1 + p2) / 2

	local line = Instance.new("Frame")
	line.Name = "Line"
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromOffset(mid.X, mid.Y)
	line.Size = UDim2.fromOffset(length, thickness)
	line.Rotation = angle
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.Parent = parent
end

local function createMarkerFrame(config: Types.MarkerConfig): Frame
	local color: Color3 = config.color or Constants.DEFAULT_MARKER.color :: Color3
	local zIndex: number = config.zIndex or Constants.DEFAULT_MARKER.zIndex :: number
	local borderColor: Color3 = config.borderColor or Constants.DEFAULT_MARKER.borderColor :: Color3
	local labelSize: number = config.labelSize or Constants.DEFAULT_LABEL_SIZE
	local labelColor: Color3 = config.labelColor or Constants.DEFAULT_LABEL_COLOR
	local labelFont: Font = config.labelFont or Constants.DEFAULT_LABEL_FONT

	local frame = Instance.new("Frame")
	frame.Name = "Marker"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromOffset(config.size.X, config.size.Y)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = zIndex

	if config.shape == "image" and config.image then
		local image = Instance.new("ImageLabel")
		image.Name = "Icon"
		image.Size = UDim2.fromScale(1, 1)
		image.BackgroundTransparency = 1
		image.Image = config.image
		image.ImageColor3 = config.imageColor or color
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = frame
	else
		if config.shape == "triangle" or config.shape == "arrow" then
			local w = config.size.X
			local h = config.size.Y
			local top = Vector2.new(w / 2, 0)
			local bl = Vector2.new(0, h)
			local br = Vector2.new(w, h)
			local thickness = math.max(2, math.floor(math.min(w, h) / 6))

			createLine(top, bl, thickness, color, frame)
			createLine(top, br, thickness, color, frame)
			createLine(bl, br, thickness, color, frame)
		else
			local visual = Instance.new("Frame")
			visual.Name = "Visual"
			visual.Size = UDim2.fromScale(1, 1)
			visual.BackgroundColor3 = color
			visual.BorderSizePixel = 0
			visual.Parent = frame

			if config.shape == "circle" then
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = visual
			elseif config.shape == "diamond" then
				visual.Rotation = 45
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 2)
				corner.Parent = visual
			end

			if config.borderSize and config.borderSize > 0 then
				local stroke = Instance.new("UIStroke")
				stroke.Color = borderColor
				stroke.Thickness = config.borderSize
				stroke.Parent = visual
			end
		end
	end

	if config.label then
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = Constants.MARKER_LABEL_OFFSET
		label.Size = UDim2.new(1, 20, 0, labelSize)
		label.BackgroundTransparency = 1
		label.TextColor3 = labelColor
		label.TextSize = labelSize
		label.FontFace = labelFont
		label.Text = config.label
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.Parent = frame
	end

	return frame
end

local function updateMarkerFrame(frame: Frame, config: Types.MarkerConfig)
	local color: Color3 = config.color or Constants.DEFAULT_MARKER.color :: Color3
	local zIndex: number = config.zIndex or Constants.DEFAULT_MARKER.zIndex :: number
	local borderColor: Color3 = config.borderColor or Constants.DEFAULT_MARKER.borderColor :: Color3
	local labelSize: number = config.labelSize or Constants.DEFAULT_LABEL_SIZE
	local labelColor: Color3 = config.labelColor or Constants.DEFAULT_LABEL_COLOR
	local labelFont: Font = config.labelFont or Constants.DEFAULT_LABEL_FONT

	frame.Size = UDim2.fromOffset(config.size.X, config.size.Y)
	frame.ZIndex = zIndex

	local icon = frame:FindFirstChild("Icon") :: ImageLabel?
	local visual = frame:FindFirstChild("Visual") :: Frame?

	if config.shape == "image" and config.image then
		if visual then
			visual:Destroy()
		end
		if icon then
			icon.Image = config.image
			icon.ImageColor3 = config.imageColor or color
		else
			local image = Instance.new("ImageLabel")
			image.Name = "Icon"
			image.Size = UDim2.fromScale(1, 1)
			image.BackgroundTransparency = 1
			image.Image = config.image
			image.ImageColor3 = config.imageColor or color
			image.ScaleType = Enum.ScaleType.Fit
			image.Parent = frame
		end
	else
		if icon then
			icon:Destroy()
		end
		if visual then
			visual.BackgroundColor3 = color
		else
			local newVisual = Instance.new("Frame")
			newVisual.Name = "Visual"
			newVisual.Size = UDim2.fromScale(1, 1)
			newVisual.BackgroundColor3 = color
			newVisual.BorderSizePixel = 0
			newVisual.Parent = frame

			if config.shape == "circle" then
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1, 0)
				corner.Parent = newVisual
			elseif config.shape == "diamond" then
				newVisual.Rotation = 45
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 2)
				corner.Parent = newVisual
			end

			if config.borderSize and config.borderSize > 0 then
				local stroke = Instance.new("UIStroke")
				stroke.Color = borderColor
				stroke.Thickness = config.borderSize
				stroke.Parent = newVisual
			end
		end
	end

	local existingLabel = frame:FindFirstChild("Label") :: TextLabel?
	if config.label then
		if existingLabel then
			existingLabel.Size = UDim2.new(1, 20, 0, labelSize)
			existingLabel.TextColor3 = labelColor
			existingLabel.TextSize = labelSize
			existingLabel.FontFace = labelFont
			existingLabel.Text = config.label
		else
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.AnchorPoint = Vector2.new(0.5, 0)
			label.Position = Constants.MARKER_LABEL_OFFSET
			label.BackgroundTransparency = 1
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.Size = UDim2.new(1, 20, 0, labelSize)
			label.TextColor3 = labelColor
			label.TextSize = labelSize
			label.FontFace = labelFont
			label.Text = config.label
			label.Parent = frame
		end
	elseif existingLabel then
		existingLabel:Destroy()
	end
end

local function updateBackground(
	backgroundLabel: ImageLabel,
	backgroundConfig: Types.MapBackgroundConfig,
	playerPos: Vector3,
	worldRadius: number
)
	-- Scale: visible portion of background image
	local scaleX = (worldRadius * 2) / backgroundConfig.worldSize.X
	local scaleY = (worldRadius * 2) / backgroundConfig.worldSize.Y

	backgroundLabel.Size = UDim2.fromScale(1 / scaleX, 1 / scaleY)

	local centerX = backgroundConfig.worldCenter.X
	local centerZ = backgroundConfig.worldCenter.Y
	if backgroundConfig.imageOffset then
		centerX += backgroundConfig.imageOffset.X
		centerZ += backgroundConfig.imageOffset.Y
	end
	local offsetX = (playerPos.X - centerX) / backgroundConfig.worldSize.X
	local offsetZ = (playerPos.Z - centerZ) / backgroundConfig.worldSize.Y

	local mapOffsetX = offsetX / scaleX
	local mapOffsetY = offsetZ / scaleY
	backgroundLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	backgroundLabel.Position = UDim2.fromScale(0.5 - mapOffsetX, 0.5 - mapOffsetY)

	if backgroundConfig.rotation then
		backgroundLabel.Rotation = backgroundConfig.rotation
	end

	if backgroundConfig.imageColor then
		backgroundLabel.ImageColor3 = backgroundConfig.imageColor
	end
end

local function positionEdgeIndicator(
	edgeFrame: Frame,
	mapCenter: Vector2,
	mapRadius: number,
	direction: Vector2,
	edgePadding: number,
	pointToTarget: boolean,
	clipShape: string
)
	local clampedPos: Vector2

	if clipShape == "circle" then
		local clampedDist = mapRadius - edgePadding
		clampedPos = mapCenter + direction * clampedDist
	else -- rectangle/roundedRectangle
		local absX = math.abs(direction.X)
		local absY = math.abs(direction.Y)
		local halfSize = mapRadius - edgePadding

		if absX > absY then
			local scale = halfSize / absX
			clampedPos = mapCenter + direction * scale
		else
			local scale = halfSize / absY
			clampedPos = mapCenter + direction * scale
		end
	end

	edgeFrame.Position = UDim2.fromOffset(clampedPos.X, clampedPos.Y)

	if pointToTarget then
		local angle = math.atan2(direction.Y, direction.X)
		edgeFrame.Rotation = math.deg(angle) + 90 -- UI rotation 0 is up
	end
end

local function getPlayerPositionAndRotation(): (Vector3?, number, number)
	local character = localPlayer.Character
	if not character then
		return nil, 0, 0
	end

	local rootPart = character.PrimaryPart
	if not rootPart then
		return nil, 0, 0
	end

	local position = rootPart.Position
	local sourceCFrame = if camera then camera.CFrame else rootPart.CFrame
	local _, cameraRotY, _ = sourceCFrame:ToEulerAnglesYXZ()
	local _, characterRotY, _ = rootPart.CFrame:ToEulerAnglesYXZ()

	return position, cameraRotY, characterRotY
end

local function createMapFrame(config: Types.MiniMapConfig): MapFrameResult
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MiniMap"
	mainFrame.Size = config.size
	mainFrame.Position = config.position
	mainFrame.AnchorPoint = config.anchorPoint or Constants.DEFAULT_ANCHOR_POINT
	mainFrame.BackgroundColor3 = config.backgroundColor or Constants.DEFAULT_BACKGROUND_COLOR
	mainFrame.BackgroundTransparency = config.backgroundTransparency or Constants.DEFAULT_BACKGROUND_TRANSPARENCY
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = Constants.DEFAULT_MAP_Z_INDEX

	if config.borderImage then
		-- Border image with overhang: mainFrame transparent, clip provides fill
		mainFrame.BackgroundTransparency = 1

		local borderImg = Instance.new("ImageLabel")
		borderImg.Name = "BorderImage"
		borderImg.AnchorPoint = Vector2.new(0.5, 0.5)
		borderImg.Position = UDim2.fromScale(0.5, 0.5)
		borderImg.Size = config.borderImageSize or UDim2.fromScale(1, 1)
		borderImg.BackgroundTransparency = 1
		borderImg.Image = config.borderImage
		borderImg.ScaleType = Enum.ScaleType.Stretch
		borderImg.ZIndex = Constants.DEFAULT_MAP_Z_INDEX + 200
		borderImg.Parent = mainFrame
	elseif config.borderSize and config.borderSize > 0 then
		local stroke = Instance.new("UIStroke")
		stroke.Color = config.borderColor or Constants.DEFAULT_BORDER_COLOR
		stroke.Thickness = config.borderSize
		stroke.Parent = mainFrame
	end

	-- CanvasGroup for circular clipping
	local mapClip = Instance.new("CanvasGroup")
	mapClip.Name = "MapClip"
	mapClip.Size = config.clipSize or UDim2.fromScale(1, 1)
	mapClip.AnchorPoint = Vector2.new(0.5, 0.5)
	mapClip.Position = UDim2.fromScale(0.5, 0.5)
	mapClip.BackgroundTransparency = 1
	mapClip.BorderSizePixel = 0
	mapClip.Parent = mainFrame

	if config.clipShape == "circle" then
		local mainCorner = Instance.new("UICorner")
		mainCorner.CornerRadius = UDim.new(1, 0)
		mainCorner.Parent = mainFrame
		local clipCorner = Instance.new("UICorner")
		clipCorner.CornerRadius = UDim.new(1, 0)
		clipCorner.Parent = mapClip
	elseif config.clipShape == "roundedRectangle" then
		local radius = config.clipCornerRadius or Constants.DEFAULT_CLIP_CORNER_RADIUS
		local mainCorner = Instance.new("UICorner")
		mainCorner.CornerRadius = radius
		mainCorner.Parent = mainFrame
		local clipCorner = Instance.new("UICorner")
		clipCorner.CornerRadius = radius
		clipCorner.Parent = mapClip
	end

	local mapContent = Instance.new("Frame")
	mapContent.Name = "MapContent"
	mapContent.Size = UDim2.fromScale(1, 1)
	mapContent.AnchorPoint = Vector2.new(0.5, 0.5)
	mapContent.Position = UDim2.fromScale(0.5, 0.5)
	mapContent.BackgroundTransparency = 1
	mapContent.BorderSizePixel = 0
	mapContent.Parent = mapClip

	local backgroundImageLabel: ImageLabel? = nil
	if config.background then
		local background = Instance.new("ImageLabel")
		background.Name = "Background"
		background.Size = UDim2.fromScale(1, 1)
		background.Position = UDim2.fromScale(0, 0)
		background.AnchorPoint = Vector2.new(0.5, 0.5)
		background.BackgroundTransparency = 1
		background.Image = config.background.image
		background.ScaleType = Enum.ScaleType.Stretch
		background.ZIndex = Constants.DEFAULT_BACKGROUND_Z_INDEX
		background.Parent = mapContent
		backgroundImageLabel = background
	end

	local markersFrame = Instance.new("Frame")
	markersFrame.Name = "Markers"
	markersFrame.Size = UDim2.fromScale(1, 1)
	markersFrame.Position = UDim2.fromScale(0, 0)
	markersFrame.BackgroundTransparency = 1
	markersFrame.BorderSizePixel = 0
	markersFrame.Parent = mapContent

	local edgeIndicators = Instance.new("Frame")
	edgeIndicators.Name = "EdgeIndicators"
	edgeIndicators.Size = UDim2.fromScale(1, 1)
	edgeIndicators.Position = UDim2.fromScale(0, 0)
	edgeIndicators.BackgroundTransparency = 1
	edgeIndicators.BorderSizePixel = 0
	edgeIndicators.ZIndex = Constants.DEFAULT_MAP_Z_INDEX + 300
	edgeIndicators.Parent = mainFrame

	local playerMarkerFrame: Frame? = nil
	if config.playerMarker then
		local playerMarker = createMarkerFrame(config.playerMarker)
		playerMarker.Name = "PlayerMarker"
		playerMarker.Position = UDim2.fromScale(0.5, 0.5)
		playerMarker.ZIndex = Constants.DEFAULT_MAP_Z_INDEX + 300
		playerMarker.Parent = mainFrame
		playerMarkerFrame = playerMarker
	end

	return {
		frame = mainFrame,
		mapClip = mapClip,
		mapContent = mapContent,
		markersFrame = markersFrame,
		edgeIndicatorsFrame = edgeIndicators,
		backgroundLabel = backgroundImageLabel,
		playerMarkerFrame = playerMarkerFrame,
	}
end

function MiniMap.create(parent: Instance, config: Types.MiniMapConfig?): Types.MiniMap
	local mergedConfig: Types.MiniMapConfig = table.clone(Constants.DEFAULT_MINIMAP_CONFIG) :: any
	if config then
		for key, value in config :: any do
			(mergedConfig :: any)[key] = value
		end
	end

	-- Create UI
	local result = createMapFrame(mergedConfig)
	local frame = result.frame
	frame.Parent = parent

	local markers: { [string]: Types.Marker } = {}
	local connections: { RBXScriptConnection } = {}

	local mapClip = result.mapClip
	local mapContent = result.mapContent
	local markersFrame = result.markersFrame
	local edgeIndicatorsFrame = result.edgeIndicatorsFrame
	local backgroundLabel = result.backgroundLabel
	local playerMarkerFrame = result.playerMarkerFrame

	local minimap: Types.MiniMap

	local function removeMarker(id: string)
		local marker = markers[id]
		if not marker then
			return
		end

		if marker.frame then
			marker.frame:Destroy()
		end

		if marker.edgeFrame then
			marker.edgeFrame:Destroy()
		end

		markers[id] = nil
	end

	local function addMarker(
		id: string,
		markerConfig: Types.MarkerConfig,
		instance: Instance?,
		worldPosition: Vector3?,
		edgeIndicator: Types.EdgeIndicatorConfig?
	)
		if markers[id] then
			removeMarker(id)
		end

		local markerFrame = createMarkerFrame(markerConfig)
		markerFrame.Parent = markersFrame

		markers[id] = {
			id = id,
			instance = instance,
			worldPosition = worldPosition,
			config = markerConfig,
			edgeIndicator = edgeIndicator,
			frame = markerFrame,
			edgeFrame = nil,
		}
	end

	local function updateMarkerConfig(id: string, markerConfig: Types.MarkerConfig)
		local marker = markers[id]
		if marker and marker.frame then
			local oldShape = marker.config.shape
			marker.config = markerConfig

			if oldShape ~= markerConfig.shape then
				local oldFrame = marker.frame
				local frameParent = oldFrame.Parent or markersFrame
				local position = oldFrame.Position
				local visible = oldFrame.Visible
				local rotation = oldFrame.Rotation

				oldFrame:Destroy()

				local rebuiltFrame = createMarkerFrame(markerConfig)
				rebuiltFrame.Position = position
				rebuiltFrame.Visible = visible
				rebuiltFrame.Rotation = rotation
				rebuiltFrame.Parent = frameParent
				marker.frame = rebuiltFrame
				return
			end

			updateMarkerFrame(marker.frame, markerConfig)
		end
	end

	local function setBackground(background: Types.MapBackgroundConfig?)
		mergedConfig.background = background

		if background then
			if not backgroundLabel then
				local newBackgroundLabel = Instance.new("ImageLabel")
				newBackgroundLabel.Name = "Background"
				newBackgroundLabel.Size = UDim2.fromScale(1, 1)
				newBackgroundLabel.Position = UDim2.fromScale(0, 0)
				newBackgroundLabel.AnchorPoint = Vector2.new(0.5, 0.5)
				newBackgroundLabel.BackgroundTransparency = 1
				newBackgroundLabel.ScaleType = Enum.ScaleType.Stretch
				newBackgroundLabel.ZIndex = Constants.DEFAULT_BACKGROUND_Z_INDEX
				newBackgroundLabel.Parent = mapContent
				backgroundLabel = newBackgroundLabel
			end

			local bgRef = backgroundLabel :: ImageLabel
			bgRef.Image = background.image
			bgRef.Visible = true
		elseif backgroundLabel then
			backgroundLabel.Visible = false
		end
	end

	local function setVisible(visible: boolean)
		frame.Visible = visible
	end

	local function setWorldRadius(radius: number)
		if mergedConfig.zoomEnabled then
			local zMin = mergedConfig.zoomMin or Constants.DEFAULT_ZOOM_MIN
			local zMax = mergedConfig.zoomMax or Constants.DEFAULT_ZOOM_MAX
			radius = math.clamp(radius, zMin, zMax)
		end

		mergedConfig.worldRadius = radius
	end

	local function setConfig(newConfig: Types.MiniMapConfig)
		mergedConfig = newConfig
		minimap.config = newConfig

		frame:Destroy()
		local newResult = createMapFrame(newConfig)
		frame = newResult.frame
		frame.Parent = parent
		minimap.frame = frame

		mapClip = newResult.mapClip
		mapContent = newResult.mapContent
		markersFrame = newResult.markersFrame
		edgeIndicatorsFrame = newResult.edgeIndicatorsFrame
		backgroundLabel = newResult.backgroundLabel
		playerMarkerFrame = newResult.playerMarkerFrame

		for _, marker in markers do
			if marker.frame then
				marker.frame:Destroy()
			end
			if marker.edgeFrame then
				marker.edgeFrame:Destroy()
			end

			local newFrame = createMarkerFrame(marker.config)
			newFrame.Parent = markersFrame
			marker.frame = newFrame
			marker.edgeFrame = nil
		end
	end

	local function destroy()
		disconnectAndClear(connections)

		for id in markers do
			removeMarker(id)
		end

		if frame and frame.Parent then
			frame:Destroy()
		end
	end

	-- Update loop
	local function updateMiniMap()
		local playerPos, playerRotY, characterRotY = getPlayerPositionAndRotation()
		if not playerPos then
			return
		end

		local mapSize = mapClip.AbsoluteSize
		local mapCenter = mapClip.AbsoluteSize * 0.5
		local mapRadius = math.min(mapSize.X, mapSize.Y) * 0.5
		local rotationMode = mergedConfig.rotation

		if backgroundLabel and mergedConfig.background then
			updateBackground(backgroundLabel, mergedConfig.background, playerPos, mergedConfig.worldRadius)
		end

		if rotationMode == "player" then
			mapContent.Rotation = math.deg(playerRotY)
		else
			mapContent.Rotation = 0
		end

		-- Player marker shows character facing relative to map rotation
		if playerMarkerFrame then
			if rotationMode == "player" then
				playerMarkerFrame.Rotation = math.deg(playerRotY - characterRotY)
			else
				playerMarkerFrame.Rotation = math.deg(-characterRotY)
			end
		end

		for _, marker in markers do
			if not marker.frame then
				continue
			end

			local worldPosition: Vector3? = marker.worldPosition
			if
				not worldPosition
				and marker.instance
				and marker.instance.Parent
				and marker.instance:IsA("PVInstance")
			then
				worldPosition = marker.instance:GetPivot().Position
			end

			if not worldPosition then
				continue
			end

			local mapPosition, distance, isOnMap =
				getWorldToMapSpace(worldPosition, playerPos, mergedConfig.worldRadius, mapSize, mergedConfig.clipShape)
			local showMarker = isOnMap and (marker.config.visible ~= false)

			marker.frame.Visible = showMarker
			if showMarker then
				marker.frame.Position = UDim2.fromOffset(mapPosition.X, mapPosition.Y)
			end

			local edgeConfig = marker.edgeIndicator or mergedConfig.edgeIndicators
			if not edgeConfig or not edgeConfig.enabled or isOnMap then
				if marker.edgeFrame then
					marker.edgeFrame.Visible = false
				end
				continue
			end

			local maxDistance = edgeConfig.maxDistance
			local showEdge = not maxDistance or distance <= maxDistance

			if not showEdge or not edgeConfig.clampToEdge then
				if marker.edgeFrame then
					marker.edgeFrame.Visible = false
				end
				continue
			end

			if not marker.edgeFrame then
				local newEdge = createMarkerFrame({
					shape = edgeConfig.shape,
					color = edgeConfig.color,
					size = edgeConfig.size,
					image = edgeConfig.image,
					imageColor = edgeConfig.imageColor,
				})
				newEdge.Name = "EdgeIndicator"
				newEdge.Parent = edgeIndicatorsFrame
				marker.edgeFrame = newEdge
			end

			local edgeFrame = marker.edgeFrame :: Frame
			edgeFrame.Visible = true
			local dx = worldPosition.X - playerPos.X
			local dz = worldPosition.Z - playerPos.Z

			-- Rotate direction by camera in player mode
			if rotationMode == "player" then
				local cos = math.cos(playerRotY)
				local sin = math.sin(playerRotY)
				local rx = dx * cos - dz * sin
				local rz = dx * sin + dz * cos
				dx = rx
				dz = rz
			end

			local direction = Vector2.new(dx, dz).Unit
			positionEdgeIndicator(
				edgeFrame,
				mapCenter,
				mapRadius,
				direction,
				edgeConfig.edgePadding,
				edgeConfig.pointToTarget,
				mergedConfig.clipShape
			)
		end
	end

	-- Connect update loop
	table.insert(connections, RunService.Heartbeat:Connect(updateMiniMap))

	if mergedConfig.zoomEnabled then
		local function onInputChanged(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				local delta = input.Position.Z
				local step = mergedConfig.zoomStep or Constants.DEFAULT_ZOOM_STEP
				local zMin = mergedConfig.zoomMin or Constants.DEFAULT_ZOOM_MIN
				local zMax = mergedConfig.zoomMax or Constants.DEFAULT_ZOOM_MAX
				local newRadius = mergedConfig.worldRadius - (delta * step)
				newRadius = math.clamp(newRadius, zMin, zMax)
				setWorldRadius(newRadius)
			end
		end

		table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
	end

	minimap = {
		frame = frame,
		config = mergedConfig,
		addMarker = addMarker,
		removeMarker = removeMarker,
		updateMarkerConfig = updateMarkerConfig,
		setConfig = setConfig,
		setBackground = setBackground,
		setVisible = setVisible,
		setWorldRadius = setWorldRadius,
		destroy = destroy,
	}

	return minimap
end

return MiniMap
