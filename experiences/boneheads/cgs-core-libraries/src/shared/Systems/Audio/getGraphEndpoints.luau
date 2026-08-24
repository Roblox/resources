-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local Types = require(script.Parent.Types)
local isWireableInstance = require(script.Parent.isWireableInstance)

local function getGraphEndpoints(audioGraph: Types.AudioGraph, direction: "Input" | "Output"): { Types.WirableInstance }
	local edgeNodes: { Types.WirableInstance } = {}

	local function checkNode(node: Instance)
		if not isWireableInstance(node) then
			return
		end

		local wireableNode = node :: Types.WirableInstance
		local wires: { Wire } = wireableNode:GetConnectedWires(direction)

		-- 1. No wires in this direction, this is an edge node
		if #wires == 0 then
			table.insert(edgeNodes :: any, wireableNode)
		else
			-- 2. Has wires, but none of them connect to nodes within the graph
			local hasInternalEdge = false

			for _, wire in wires do
				local connectedInstance = if direction == "Output" then wire.TargetInstance else wire.SourceInstance
				if connectedInstance and connectedInstance:IsDescendantOf(audioGraph) then
					hasInternalEdge = true
					break
				end
			end

			if not hasInternalEdge then
				table.insert(edgeNodes :: any, wireableNode)
			end
		end
	end

	checkNode(audioGraph)

	for _, node in audioGraph:GetDescendants() do
		checkNode(node)
	end

	return edgeNodes
end

return getGraphEndpoints
