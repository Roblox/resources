--!strict
-- Server-side animation playback for dialog NPCs. Owns a per-NPC reference count
-- and the currently playing animation tracks, so multiple players can converse
-- with the same NPC without one leaving cutting another's animations short. Driven
-- on the server so every nearby player sees the same talking/gesture animations.
--
-- Each NPC has two animation slots: base (looping idle) and gesture (mood animation).

local NPCAnimator = {}

local BASE_FADE = 0.20
local GESTURE_FADE = 0.15

type Slot = "base" | "gesture"

-- Tracks are keyed by slot name so playSlot can index them dynamically.
type AnimState = {
	refs: number,
	tracks: { [string]: AnimationTrack? },
}

local npcAnimState: { [Instance]: AnimState } = {}

local function findAnimator(npc: Instance): Animator?
	local controller = npc:FindFirstChildOfClass("Humanoid") or npc:FindFirstChildOfClass("AnimationController")
	if not controller then
		return nil
	end
	local animator = controller:FindFirstChildOfClass("Animator")
	if not animator then
		local created = Instance.new("Animator")
		created.Parent = controller
		animator = created
	end
	return animator
end

local function stopTrack(track: AnimationTrack?, fadeTime: number?)
	if not track then
		return
	end
	track:Stop(fadeTime or GESTURE_FADE)
end

local function loadTrack(npc: Instance, assetId: string): AnimationTrack
	local animator = findAnimator(npc)
	if not animator then
		error(
			`[DialogService] {npc:GetFullName()} has no AnimationController or Humanoid; cannot load animation {assetId}.`
		)
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = assetId
	local track = animator:LoadAnimation(anim)
	anim:Destroy()
	if not track then
		error(`[DialogService] Failed to load animation {assetId} on {npc:GetFullName()}.`)
	end
	return track
end

local SLOT_CONFIG: { [Slot]: { fade: number, looped: boolean, priority: Enum.AnimationPriority } } = {
	base = { fade = BASE_FADE, looped = true, priority = Enum.AnimationPriority.Idle },
	gesture = { fade = GESTURE_FADE, looped = false, priority = Enum.AnimationPriority.Action },
}

local function playSlot(npc: Instance, slot: Slot, assetId: string?)
	local state = npcAnimState[npc]
	if not state then
		return
	end
	local cfg = SLOT_CONFIG[slot]
	stopTrack(state.tracks[slot], cfg.fade)
	state.tracks[slot] = nil
	if not assetId or assetId == "" then
		return
	end
	local track = loadTrack(npc, assetId)
	track.Looped = cfg.looped
	track.Priority = cfg.priority
	track:Play(cfg.fade)
	state.tracks[slot] = track
end

-- Begin (or join) a conversation with the NPC
function NPCAnimator.acquire(npc: Instance, baseAnimId: string?)
	local state = npcAnimState[npc]
	if state then
		state.refs += 1
		return
	end
	npcAnimState[npc] = { refs = 1, tracks = {} }
	playSlot(npc, "base", baseAnimId)
end

-- Play the one-shot mood gesture, nil or "" to clear it
function NPCAnimator.playGesture(npc: Instance, gestureAnimId: string?)
	playSlot(npc, "gesture", gestureAnimId)
end

-- Leave a conversation. When the last participant leaves, every track stops
-- and the NPC's state is dropped.
function NPCAnimator.release(npc: Instance)
	local state = npcAnimState[npc]
	if not state then
		return
	end
	state.refs -= 1
	if state.refs > 0 then
		return
	end
	stopTrack(state.tracks["base"], BASE_FADE)
	stopTrack(state.tracks["gesture"], GESTURE_FADE)
	npcAnimState[npc] = nil
end

-- Force-stop and forget the NPC. Used when the NPC instance is being removed
-- mid-dialog.
function NPCAnimator.clear(npc: Instance)
	local state = npcAnimState[npc]
	if not state then
		return
	end
	stopTrack(state.tracks["base"], 0)
	stopTrack(state.tracks["gesture"], 0)
	npcAnimState[npc] = nil
end

return NPCAnimator
