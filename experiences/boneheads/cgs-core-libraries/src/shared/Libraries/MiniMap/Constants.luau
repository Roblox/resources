-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)

local DEFAULT_ANCHOR_POINT = Vector2.new(1, 0)
local DEFAULT_BACKGROUND_COLOR = Color3.fromRGB(20, 20, 30)
local DEFAULT_BACKGROUND_TRANSPARENCY = 0.3
local DEFAULT_BORDER_COLOR = Color3.fromRGB(80, 80, 100)
local DEFAULT_CLIP_CORNER_RADIUS = UDim.new(0, 8)

local DEFAULT_ZOOM_MIN = 50
local DEFAULT_ZOOM_MAX = 500
local DEFAULT_ZOOM_STEP = 25

local DEFAULT_PLAYER_MARKER: Types.MarkerConfig = {
	shape = "triangle",
	color = Color3.fromRGB(100, 200, 255),
	size = Vector2.new(12, 12),
}

local DEFAULT_EDGE_INDICATORS: Types.EdgeIndicatorConfig = {
	enabled = true,
	shape = "arrow",
	color = Color3.fromRGB(255, 200, 50),
	size = Vector2.new(10, 10),
	edgePadding = 10,
	clampToEdge = true,
	pointToTarget = true,
}

local DEFAULT_LABEL_FONT = Font.fromEnum(Enum.Font.GothamBold)

local DEFAULT_MARKER: Types.MarkerConfig = {
	shape = "circle",
	color = Color3.fromRGB(255, 80, 80),
	size = Vector2.new(8, 8),
	borderSize = 1,
	borderColor = Color3.fromRGB(0, 0, 0),
	zIndex = 2,
}

local Constants = {
	-- Defaults used for fallback values and initialization
	DEFAULT_ANCHOR_POINT = DEFAULT_ANCHOR_POINT,
	DEFAULT_BACKGROUND_COLOR = DEFAULT_BACKGROUND_COLOR,
	DEFAULT_BACKGROUND_TRANSPARENCY = DEFAULT_BACKGROUND_TRANSPARENCY,
	DEFAULT_BORDER_COLOR = DEFAULT_BORDER_COLOR,
	DEFAULT_CLIP_CORNER_RADIUS = DEFAULT_CLIP_CORNER_RADIUS,

	-- Z-Index layers
	DEFAULT_BACKGROUND_Z_INDEX = 1,
	DEFAULT_MAP_Z_INDEX = 1,

	-- Default marker config
	DEFAULT_MARKER = DEFAULT_MARKER,

	DEFAULT_ZOOM_MIN = DEFAULT_ZOOM_MIN,
	DEFAULT_ZOOM_MAX = DEFAULT_ZOOM_MAX,
	DEFAULT_ZOOM_STEP = DEFAULT_ZOOM_STEP,

	-- Labels
	MARKER_LABEL_OFFSET = UDim2.fromOffset(0, 10),
	DEFAULT_LABEL_SIZE = 12,
	DEFAULT_LABEL_COLOR = Color3.fromRGB(255, 255, 255),
	DEFAULT_LABEL_FONT = DEFAULT_LABEL_FONT,

	DEFAULT_MINIMAP_CONFIG = {
		size = UDim2.fromOffset(200, 200),
		position = UDim2.new(1, -20, 0, 20),
		anchorPoint = DEFAULT_ANCHOR_POINT,
		clipShape = "circle",
		clipCornerRadius = DEFAULT_CLIP_CORNER_RADIUS,
		backgroundColor = DEFAULT_BACKGROUND_COLOR,
		backgroundTransparency = DEFAULT_BACKGROUND_TRANSPARENCY,
		borderColor = DEFAULT_BORDER_COLOR,
		borderSize = 2,
		worldRadius = 100,
		rotation = "player",
		playerMarker = DEFAULT_PLAYER_MARKER,
		edgeIndicators = DEFAULT_EDGE_INDICATORS,
		zoomEnabled = false,
		zoomMin = DEFAULT_ZOOM_MIN,
		zoomMax = DEFAULT_ZOOM_MAX,
		zoomStep = DEFAULT_ZOOM_STEP,
	} :: Types.MiniMapConfig,
}

return Constants
