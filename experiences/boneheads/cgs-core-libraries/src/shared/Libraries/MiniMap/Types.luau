-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type MarkerShape = "circle" | "diamond" | "triangle" | "arrow" | "image"

export type ClipShape = "circle" | "rectangle" | "roundedRectangle"

export type Rotation = "player" | "north"

export type MarkerConfig = {
	shape: MarkerShape,
	color: Color3?,
	size: Vector2,
	image: string?,
	imageColor: Color3?,
	borderColor: Color3?,
	borderSize: number?,
	zIndex: number?,
	label: string?,
	labelColor: Color3?,
	labelFont: Font?,
	labelSize: number?,
	visible: boolean?,
}

export type EdgeIndicatorConfig = {
	enabled: boolean,
	shape: MarkerShape,
	color: Color3?,
	size: Vector2,
	image: string?,
	imageColor: Color3?,
	edgePadding: number,
	clampToEdge: boolean,
	pointToTarget: boolean,
	maxDistance: number?,
}

export type MapBackgroundConfig = {
	image: string,
	imageColor: Color3?,
	worldCenter: Vector2,
	worldSize: Vector2,
	imageOffset: Vector2?,
	rotation: number?,
}

export type MiniMapConfig = {
	size: UDim2,
	position: UDim2,
	anchorPoint: Vector2?,
	clipShape: ClipShape,
	clipSize: UDim2?,
	clipCornerRadius: UDim?,
	backgroundColor: Color3?,
	backgroundTransparency: number?,
	borderColor: Color3?,
	borderSize: number?,
	borderImage: string?,
	borderImageSize: UDim2?,

	worldRadius: number,
	rotation: Rotation?,

	playerMarker: MarkerConfig?,
	background: MapBackgroundConfig?,
	edgeIndicators: EdgeIndicatorConfig?,

	zoomEnabled: boolean?,
	zoomMin: number?,
	zoomMax: number?,
	zoomStep: number?,
}

export type Marker = {
	id: string,
	instance: Instance?,
	worldPosition: Vector3?,
	config: MarkerConfig,
	edgeIndicator: EdgeIndicatorConfig?,
	frame: Frame?,
	edgeFrame: Frame?,
}

export type MiniMap = {
	frame: Frame,
	config: MiniMapConfig,
	addMarker: (
		id: string,
		config: MarkerConfig,
		instance: Instance?,
		worldPosition: Vector3?,
		edgeIndicator: EdgeIndicatorConfig?
	) -> (),
	removeMarker: (id: string) -> (),
	updateMarkerConfig: (id: string, config: MarkerConfig) -> (),
	setConfig: (config: MiniMapConfig) -> (),
	setBackground: (background: MapBackgroundConfig?) -> (),
	setVisible: (visible: boolean) -> (),
	setWorldRadius: (radius: number) -> (),
	destroy: () -> (),
}

return {}
