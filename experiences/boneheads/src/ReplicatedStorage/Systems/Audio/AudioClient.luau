local ContentProvider = game:GetService("ContentProvider")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Constants)
local Types = require(script.Parent.Types)

local AudioRemotes = script.Parent.Remotes
local playSoundEvent = AudioRemotes.PlaySound
local stopSoundEvent = AudioRemotes.StopSound

local definitions: { [string]: Types.SoundDefinition } = {}
local activeRemoteSounds: { [string]: Sound } = {}
local soundAnchorFolder: Folder? = nil
local soundTemplates: { [string]: Sound } = {}
local soundTemplateFolder: Folder? = nil

local function getOrCreateAnchorFolder(): Folder
	if soundAnchorFolder and soundAnchorFolder.Parent then
		return soundAnchorFolder
	end

	local folder = Instance.new("Folder")
	folder.Name = Constants.SOUND_ANCHOR_FOLDER_NAME
	folder.Parent = Workspace
	soundAnchorFolder = folder
	return folder
end

local function getOrCreateTemplateFolder(): Folder
	if soundTemplateFolder and soundTemplateFolder.Parent then
		return soundTemplateFolder
	end

	local folder = Instance.new("Folder")
	folder.Name = "SoundTemplates"
	folder.Parent = SoundService
	soundTemplateFolder = folder
	return folder
end

local function getDefinition(soundName: string): Types.SoundDefinition
	local definition = definitions[soundName]
	assert(definition, `no sound definition registered for "{soundName}"`)
	return definition
end

local function configureSound(sound: Sound, definition: Types.SoundDefinition, options: Types.PlayOptions?)
	sound.SoundId = definition.assetId
	sound.RollOffMode = Enum.RollOffMode.LinearSquare
	sound.Volume = if options and options.volume then options.volume else definition.volume
	sound.RollOffMinDistance = if options and options.rollOffMinDistance
		then options.rollOffMinDistance
		else definition.rollOffMinDistance
	sound.RollOffMaxDistance = if options and options.rollOffMaxDistance
		then options.rollOffMaxDistance
		else definition.rollOffMaxDistance
	sound.Looped = if options and options.looped ~= nil then options.looped else definition.looped
end

local function applyOptionOverrides(sound: Sound, options: Types.PlayOptions?)
	if not options then
		return
	end
	if options.volume then
		sound.Volume = options.volume
	end
	if options.rollOffMinDistance then
		sound.RollOffMinDistance = options.rollOffMinDistance
	end
	if options.rollOffMaxDistance then
		sound.RollOffMaxDistance = options.rollOffMaxDistance
	end
	if options.looped ~= nil then
		sound.Looped = options.looped
	end
end

local function createConfiguredSound(
	soundName: string,
	definition: Types.SoundDefinition,
	options: Types.PlayOptions?
): Sound
	local template = soundTemplates[soundName]
	if template then
		local sound = template:Clone()
		applyOptionOverrides(sound, options)
		return sound
	end

	local sound = Instance.new("Sound")
	configureSound(sound, definition, options)
	return sound
end

local function createAnchorPart(position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "SoundAnchor"
	part.Size = Constants.SOUND_ANCHOR_SIZE
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.new(position)
	part.Parent = getOrCreateAnchorFolder()
	return part
end

local function cleanupSound(sound: Sound, anchorPart: Part?, soundId: string?)
	sound:Destroy()

	if anchorPart then
		anchorPart:Destroy()
	end

	if soundId then
		activeRemoteSounds[soundId] = nil
	end
end

local function setupAutoCleanup(sound: Sound, anchorPart: Part?, soundId: string?)
	if soundId then
		sound.Destroying:Once(function()
			activeRemoteSounds[soundId] = nil
		end)
	end

	if sound.Looped then
		return
	end

	sound.Ended:Once(function()
		cleanupSound(sound, anchorPart, soundId)
	end)
end

local function noopSoundHandle(): Types.SoundHandle
	return { stop = function() end }
end

local function playAtPositionInternal(
	soundName: string,
	position: Vector3,
	options: Types.PlayOptions?,
	soundId: string?
): Types.SoundHandle
	local definition = getDefinition(soundName)
	-- An empty assetId never loads, so its Sound never fires Ended and would leak the anchor part.
	if definition.assetId == "" then
		return noopSoundHandle()
	end

	local anchorPart = createAnchorPart(position)

	local sound = createConfiguredSound(soundName, definition, options)
	sound.Parent = anchorPart
	sound:Play()

	if soundId then
		activeRemoteSounds[soundId] = sound
	end

	setupAutoCleanup(sound, anchorPart, soundId)

	local function stop()
		cleanupSound(sound, anchorPart, soundId)
	end

	return { stop = stop }
end

local function playOnInstanceInternal(
	soundName: string,
	target: Instance,
	options: Types.PlayOptions?,
	soundId: string?
): Types.SoundHandle
	local definition = getDefinition(soundName)
	if definition.assetId == "" then
		return noopSoundHandle()
	end

	local soundParent: Instance = target
	if target:IsA("Model") then
		local primaryPart = target.PrimaryPart
		if not primaryPart then
			warn(primaryPart, `cannot play sound on Model without PrimaryPart: {target:GetFullName()}`)
			return noopSoundHandle()
		end
		soundParent = primaryPart
	end

	local sound = createConfiguredSound(soundName, definition, options)
	sound.Parent = soundParent
	sound:Play()

	if soundId then
		activeRemoteSounds[soundId] = sound
	end

	setupAutoCleanup(sound, nil, soundId)

	local function stop()
		cleanupSound(sound, nil, soundId)
	end

	return { stop = stop }
end

local function onPlaySound(soundId: string, soundName: string, mode: string, target: any, options: Types.PlayOptions?)
	if not definitions[soundName] then
		warn(`[AudioClient] unknown sound name from server: "{soundName}"`)
		return
	end

	if mode == Constants.PLAY_MODE_POSITION then
		playAtPositionInternal(soundName, target :: Vector3, options, soundId)
	elseif mode == Constants.PLAY_MODE_INSTANCE then
		if not target then
			warn(`[AudioClient] instance target is nil for sound "{soundName}", skipping`)
			return
		end
		playOnInstanceInternal(soundName, target :: Instance, options, soundId)
	end
end

local function onStopSound(soundId: string)
	local sound = activeRemoteSounds[soundId]
	if not sound then
		return
	end

	local anchorPart: Part? = nil
	local parent = sound.Parent
	if parent and parent:IsA("Part") and parent.Name == "SoundAnchor" then
		anchorPart = parent :: Part
	end

	cleanupSound(sound, anchorPart, soundId)
end

local AudioClient = {}

function AudioClient.hasDefinition(soundName: string): boolean
	return definitions[soundName] ~= nil
end

function AudioClient.loadDefinitions(folder: Instance)
	for _, child in folder:GetChildren() do
		if not child:IsA("ModuleScript") then
			continue
		end

		local group = require(child) :: { Types.SoundDefinition }
		for _, definition in group do
			assert(typeof(definition.name) == "string", `sound definition missing name field in {child.Name}`)
			definitions[definition.name] = definition
		end
	end

	local templateFolder = getOrCreateTemplateFolder()
	local templates: { Sound } = {}
	for name, definition in definitions do
		if definition.assetId == "" then
			continue
		end

		local template = Instance.new("Sound")
		template.Name = name
		template.SoundId = definition.assetId
		template.RollOffMode = Enum.RollOffMode.LinearSquare
		template.Volume = definition.volume
		template.RollOffMinDistance = definition.rollOffMinDistance
		template.RollOffMaxDistance = definition.rollOffMaxDistance
		template.Looped = definition.looped
		template.Parent = templateFolder
		soundTemplates[name] = template
		table.insert(templates, template)
	end

	-- Preload the template instances (decodes the audio) so clone-and-play starts instantly.
	task.spawn(function()
		ContentProvider:PreloadAsync(templates)
	end)
end

local function onPromptTriggered(prompt: ProximityPrompt, _player: Player)
	local soundName = prompt:GetAttribute("triggerSound")
	if typeof(soundName) ~= "string" then
		return
	end

	if not definitions[soundName] then
		warn(`[AudioClient] unknown triggerSound attribute: "{soundName}"`)
		return
	end

	local target = prompt.Parent
	if not target then
		return
	end

	playOnInstanceInternal(soundName, target, nil, nil)
end

function AudioClient.start()
	playSoundEvent.OnClientEvent:Connect(onPlaySound)
	stopSoundEvent.OnClientEvent:Connect(onStopSound)
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
end

function AudioClient.playAtPosition(
	soundName: string,
	position: Vector3,
	options: Types.PlayOptions?
): Types.SoundHandle
	return playAtPositionInternal(soundName, position, options, nil)
end

function AudioClient.playOnInstance(
	soundName: string,
	instance: Instance,
	options: Types.PlayOptions?
): Types.SoundHandle
	return playOnInstanceInternal(soundName, instance, options, nil)
end

return AudioClient
