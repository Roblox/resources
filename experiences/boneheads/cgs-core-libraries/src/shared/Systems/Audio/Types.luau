-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

type Wirable = {
	GetConnectedWires: (self: Wirable, pin: string) -> { Wire },
	GetInputPins: (self: Wirable) -> { string },
	GetOutputPins: (self: Wirable) -> { string },
}

export type WirableInstance = Wirable & Instance

export type AudioEvent = string
export type AudioGroup = string

export type AudioGraph = Instance
export type AudioBus = Instance

export type AudioHost = Attachment | Camera | PVInstance

return nil
