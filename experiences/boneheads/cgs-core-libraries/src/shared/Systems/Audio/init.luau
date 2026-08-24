-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera

local Constants = require(script.Constants)
local Types = require(script.Types)

local getGraphEndpoints = require(script.getGraphEndpoints)
local getGraphPlayers = require(script.getGraphPlayers)
local selectRandomInstance = require(script.selectRandomInstance)

export type AudioEvent = Types.AudioEvent
export type AudioGroup = Types.AudioGroup
export type AudioGraph = Types.AudioGraph
export type AudioBus = Types.AudioBus
export type AudioHost = Types.AudioHost

local audioBuses: { [string]: AudioBus } = {}
local audioGraphs: { [AudioGroup]: { [AudioEvent]: AudioGraph } } = {}

local activeAudioGraphPlayers: { [AudioGraph]: { AudioPlayer } } = {}
local activeAudioPlayersFolder: Folder
local mainDeviceOutput: AudioDeviceOutput

local Audio = {}

local function getActiveGraphPlayers(audioGraph: AudioGraph): { AudioPlayer }
	return activeAudioGraphPlayers[audioGraph] or {}
end

local function saveActiveGraphPlayers(audioGraph: AudioGraph)
	activeAudioGraphPlayers[audioGraph] = getGraphPlayers(audioGraph)
	audioGraph.Destroying:Connect(function()
		activeAudioGraphPlayers[audioGraph] = nil
	end)
end

function Audio.getBus(audioBus: string): AudioBus?
	return audioBuses[audioBus]
end

function Audio.getGraph(audioGroup: string, audioEvent: string): AudioGraph?
	return audioGraphs[audioGroup] and audioGraphs[audioGroup][audioEvent]
end

function Audio.create(audioGroup: string, audioEvent: string, parent: AudioHost?): AudioGraph
	local audioGraph = Audio.getGraph(audioGroup, audioEvent)
	assert(audioGraph, `Audio graph "{audioGroup}/{audioEvent}" does not exist`)

	local audioGraphClone = audioGraph:Clone()
	local audioGraphBus = audioGraphClone:GetAttribute(Constants.INTERNAL_BUS_ATTRIBUTE) :: string?

	-- Get audio graph output(s) and wire to target output. Target output is either:
	-- 1. AudioEmitter if parent is provided (3D audio)
	-- 2. AudioBus if audio bus attribute is provided (2D audio w/ Bus)
	-- 3. AudioDeviceOutput if neither of the above is provided (2D audio)
	local targetOutput: Types.WirableInstance

	if parent then
		local audioEmitter = Instance.new("AudioEmitter")

		audioEmitter.AudioInteractionGroup = audioGraphBus or ""
		audioEmitter.Parent = parent

		audioEmitter.Destroying:Connect(function()
			audioGraphClone:Destroy()
		end)

		audioGraphClone.Destroying:Connect(function()
			audioEmitter:Destroy()
		end)

		targetOutput = audioEmitter :: Types.WirableInstance
	else
		local audioBus = audioGraphBus and Audio.getBus(audioGraphBus)
		if audioBus then
			local busInputValue = audioBus:FindFirstChild(Constants.GRAPH_INPUT_NAME)
			assert(
				busInputValue and busInputValue:IsA("ObjectValue"),
				`Audio bus "{audioBus.Name}" is missing {Constants.GRAPH_INPUT_NAME} ObjectValue.`
			)

			targetOutput = busInputValue.Value :: Types.WirableInstance
		end
	end

	for _, child in audioGraphClone:GetChildren() do
		if child.Name == Constants.GRAPH_OUTPUT_NAME then
			assert(
				child:IsA("ObjectValue"),
				`_graphOutput value in "{audioGroup}/{audioEvent}" is not an ObjectValue instance.`
			)

			local graphOutput = child.Value :: Types.WirableInstance

			local outputWire = Instance.new("Wire")
			outputWire.SourceInstance = graphOutput
			outputWire.TargetInstance = targetOutput or mainDeviceOutput
			outputWire.TargetName = "Input"
			outputWire.Parent = graphOutput
		end
	end

	-- Get audio graph players and cache them
	saveActiveGraphPlayers(audioGraphClone)

	-- Parent to sound service
	audioGraphClone.Parent = activeAudioPlayersFolder

	return audioGraphClone
end

function Audio.play(audioGraph: AudioGraph)
	local audioPlayers = getActiveGraphPlayers(audioGraph)
	for _, audioPlayer in audioPlayers do
		local initialTimePosition = audioPlayer:GetAttribute(Constants.INITIAL_TIME_POSITION_ATTRIBUTE) :: number?
		audioPlayer.TimePosition = initialTimePosition or 0
		audioPlayer:Play()
	end
end

function Audio.playRandom(audioGraph: AudioGraph)
	local audioPlayers = getActiveGraphPlayers(audioGraph)
	local audioPlayer = selectRandomInstance(audioPlayers)

	if audioPlayer then
		local initialTimePosition = audioPlayer:GetAttribute(Constants.INITIAL_TIME_POSITION_ATTRIBUTE) :: number?
		audioPlayer.TimePosition = initialTimePosition or 0
		audioPlayer:Play()
	end
end

function Audio.playOnce(audioGroup: string, audioEvent: string, parent: AudioHost?)
	local audioGraph = Audio.create(audioGroup, audioEvent, parent)
	local audioPlayers = getActiveGraphPlayers(audioGraph)

	-- Calculate the longest duration among all players
	local maxDuration = 0
	for _, audioPlayer in audioPlayers do
		local duration = audioPlayer.TimeLength / audioPlayer.PlaybackSpeed
		maxDuration = math.max(maxDuration, duration)

		if audioPlayer.Looping then
			error(`AudioPlayer in "{audioGroup}/{audioEvent}" is set to loop. Cannot use playOnce with looping audio.`)
		end
	end

	-- Play all audio players
	Audio.play(audioGraph)

	-- Destroy the graph after the longest audio finishes
	task.delay(maxDuration, function()
		audioGraph:Destroy()
	end)
end

function Audio.playRandomOnce(audioGroup: string, audioEvent: string, parent: AudioHost?)
	local audioGraph = Audio.create(audioGroup, audioEvent, parent)
	local audioPlayers = getActiveGraphPlayers(audioGraph)

	-- Select a random audio player
	local audioPlayer = selectRandomInstance(audioPlayers)

	if audioPlayer then
		if audioPlayer.Looping then
			error(
				`AudioPlayer in "{audioGroup}/{audioEvent}" is set to loop. Cannot use playRandomOnce with looping audio.`
			)
		end

		audioPlayer:Play()

		local duration = audioPlayer.TimeLength / audioPlayer.PlaybackSpeed
		task.delay(duration, function()
			audioGraph:Destroy()
		end)
	else
		audioGraph:Destroy()
	end
end

function Audio.pause(audioGraph: AudioGraph)
	for _, audioPlayer in getActiveGraphPlayers(audioGraph) do
		audioPlayer:Stop()
	end
end

function Audio.resume(audioGraph: AudioGraph)
	for _, audioPlayer in getActiveGraphPlayers(audioGraph) do
		audioPlayer:Play()
	end
end

function Audio.setSpeed(audioGraph: AudioGraph, speed: number)
	for _, audioPlayer in getActiveGraphPlayers(audioGraph) do
		audioPlayer.PlaybackSpeed = speed
	end
end

function Audio.setPosition(audioGraph: AudioGraph, position: number)
	for _, audioPlayer in getActiveGraphPlayers(audioGraph) do
		audioPlayer.TimePosition = position
	end
end

local function onBusAdded(audioBus: AudioBus)
	audioBuses[audioBus.Name] = audioBus

	-- Identify and save bus input
	local graphInputs = getGraphEndpoints(audioBus, "Input")
	local graphInput = graphInputs[1]

	assert(#graphInputs == 1, `Audio bus "{audioBus.Name}" should have exactly one graph input.`)

	local inputValue = Instance.new("ObjectValue")
	inputValue.Name = Constants.GRAPH_INPUT_NAME
	inputValue.Value = graphInput
	inputValue.Parent = audioBus

	-- Identify and connect bus output to AudioDeviceOutput
	local graphOutputs = getGraphEndpoints(audioBus, "Output")
	local graphOutput = graphOutputs[1]

	assert(#graphOutputs == 1, `Audio bus "{audioBus.Name}" should have exactly one graph output.`)

	local outputWire = Instance.new("Wire")
	outputWire.SourceInstance = graphOutput
	outputWire.TargetInstance = mainDeviceOutput
	outputWire.TargetName = "Input"
	outputWire.Parent = graphOutput

	-- Create AudioListener if bus requires 3D audio
	local hasListener = audioBus:GetAttribute(Constants.HAS_LISTENER_ATTRIBUTE) :: boolean?
	if hasListener == true then
		local audioListener = Instance.new("AudioListener")
		audioListener.Name = `{audioBus.Name}Listener`
		audioListener.AudioInteractionGroup = audioBus.Name
		audioListener.Parent = Camera

		local listenerWire = Instance.new("Wire")
		listenerWire.SourceInstance = audioListener
		listenerWire.TargetInstance = graphInput
		listenerWire.TargetName = "Input"
		listenerWire.Parent = audioListener
	elseif hasListener == nil then
		warn(
			`Audio bus "{audioBus.Name}" is missing hasListener attribute. Add an empty hasListener attribute if this is intentional.`
		)
	end
end

local function onGraphRemoved(audioGroup: string, audioEvent: string)
	if not audioGraphs[audioGroup] or not audioGraphs[audioGroup][audioEvent] then
		return
	end

	audioGraphs[audioGroup][audioEvent] = nil
end

local function onGraphAdded(audioGroup: string, audioEvent: string, audioBus: string?, audioGraph: AudioGraph)
	if audioGraphs[audioGroup] and audioGraphs[audioGroup][audioEvent] then
		warn(`Audio graph "{audioGroup}/{audioEvent}" already exists.`)
		return
	end

	-- Add audio graph to the index
	audioGraphs[audioGroup] = audioGraphs[audioGroup] or {}
	audioGraphs[audioGroup][audioEvent] = audioGraph

	audioGraph.Destroying:Connect(function()
		onGraphRemoved(audioGroup, audioEvent)
	end)

	-- Identify and save audio output
	local graphOutputs = getGraphEndpoints(audioGraph, "Output")
	assert(#graphOutputs > 0, `Failed to identify audio output for graph "{audioGroup}/{audioEvent}". Is there a loop?`)

	for _, graphOutput in graphOutputs do
		local objectValue = Instance.new("ObjectValue")
		objectValue.Name = Constants.GRAPH_OUTPUT_NAME
		objectValue.Value = graphOutput
		objectValue.Parent = audioGraph
	end

	-- Assign audio bus attribute
	if audioBus and audioBus ~= "" then
		audioGraph:SetAttribute(Constants.INTERNAL_BUS_ATTRIBUTE, audioBus)
	end

	-- Save audio player time positions
	local audioPlayers = getGraphPlayers(audioGraph)
	for _, audioPlayer in audioPlayers do
		audioPlayer:SetAttribute(Constants.INITIAL_TIME_POSITION_ATTRIBUTE, audioPlayer.TimePosition)
	end
end

local function onGroupAdded(audioGroupFolder: Instance)
	local audioGroup: AudioGroup = audioGroupFolder.Name
	local audioGroupBus = audioGroupFolder:GetAttribute(Constants.BUS_ATTRIBUTE) :: string?

	if audioGroupBus == nil then
		warn(
			`Audio group "{audioGroup}" is missing audioBus attribute. Add an empty audioBus attribute if this is intentional.`
		)
	end

	for _, audioGraph in audioGroupFolder:GetChildren() do
		local audioEvent: AudioEvent = audioGraph.Name
		onGraphAdded(audioGroup, audioEvent, audioGroupBus, audioGraph)
	end

	audioGroupFolder.ChildAdded:Connect(function(audioGraph: Instance)
		local audioEvent: AudioEvent = audioGraph.Name
		onGraphAdded(audioGroup, audioEvent, audioGroupBus, audioGraph)
	end)
end

function Audio.start(audioContent: Folder)
	-- Clone SoundService setup template (MainListener + MainOutput + Players)
	local audioSetup = script.Templates.Audio:Clone()
	audioSetup.Parent = SoundService

	local mainListener = audioSetup.MainListener
	mainDeviceOutput = audioSetup.MainOutput
	activeAudioPlayersFolder = audioSetup.Players

	-- Wire the listener to the device output and parent to camera
	local listenerWire = Instance.new("Wire")
	listenerWire.SourceInstance = mainListener
	listenerWire.TargetInstance = mainDeviceOutput
	listenerWire.TargetName = "Input"
	listenerWire.Parent = mainListener

	mainListener.Parent = Camera

	-- Load and index audio graphs and buses from provided folder
	local audioGraphFolder = audioContent:FindFirstChild("Players")
	local audioBusFolder = audioContent:FindFirstChild("Busses")

	assert(audioGraphFolder, "Audio.Players folder does not exist")
	assert(audioBusFolder, "Audio.Busses folder does not exist")

	-- Scan through audio buses and build index
	for _, audioBus in audioBusFolder:GetChildren() do
		onBusAdded(audioBus)
	end

	-- Scan through audio graphs and build index
	for _, audioGroupFolder in audioGraphFolder:GetChildren() do
		onGroupAdded(audioGroupFolder)
	end

	audioGraphFolder.ChildAdded:Connect(onGroupAdded)
end

return Audio
