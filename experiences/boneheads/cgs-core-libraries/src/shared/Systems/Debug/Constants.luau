-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

return {
	LINE = {
		WIDTH = 0.05,
		TRANSPARENCY = 0.5,
		NAME = "DebugLine",
		COLOR = Color3.fromRGB(0, 255, 0),
	},
	SPHERE = {
		RADIUS = 5,
		TRANSPARENCY = 0.7,
		NAME = "DebugSphere",
		COLOR = Color3.fromRGB(0, 0, 255),
	},
	TEXT_BOX_ADORNING = {
		FONT_SIZE = 14,
		COLOR = Color3.fromRGB(255, 0, 0),
		LABEL_NAME = "DebugTextBoxAdorning",
		OFFSET = Vector3.new(0, 5, 0),
		TEXT = "",
	},
	TEXT_BOX_AT_POSITION = {
		FONT_SIZE = 14,
		COLOR = Color3.fromRGB(255, 255, 255),
		LABEL_NAME = "DebugTextBoxPositioned",
		ANCHOR_NAME = "DebugTextAnchor",
		TEXT = "",
	},
	BOX = {
		TRANSPARENCY = 0.7,
		NAME = "DebugBox",
	},
	BILLBOARD = {
		BILLBOARD_SIZE = UDim2.fromOffset(200, 50),
		BILLBOARD_NAME = "DebugBillboard",
	},
	CONTAINER_NAME = "DebugVisualizations",

	DEBUG_ID_ATTRIBUTE = "DebugID",
	DEBUG_TOGGLE = {
		PATHFINDING = {
			ATTRIBUTE = "debugPathfinding",
			ID_PREFIX = "_PATHFINDING_",
		},
		BEHAVIOR = {
			ATTRIBUTE = "debugBehavior",
			ID_PREFIX = "_BEHAVIOR_",
		},
	},
}
