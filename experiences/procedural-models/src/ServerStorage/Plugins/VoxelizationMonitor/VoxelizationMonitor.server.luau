--!strict
-- Studio plugin: watches VOXEL_BOUNDS-tagged ProceduralModels at EDIT TIME. Polls each
-- PM's WorldPivot and Size every Heartbeat (signal-based listeners on WorldPivot can be
-- unreliable in plugin contexts), and when something changes bumps Version on the moved
-- PM and every neighbor whose AABB overlap is affected. Sweeps the PM's Generated folder
-- before each bump to dodge the merge-on-bake stale-children quirk.
--
-- Completely inert outside edit mode (play tests, run mode).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local BOUNDS_TAG = "VOXEL_BOUNDS"

local LOG_PREFIX = "[VoxelizerMonitor]"

local function isEditMode(): boolean
	return RunService:IsStudio() and not RunService:IsRunning()
end

print(LOG_PREFIX, "loaded. edit mode =", isEditMode())

type AABB = { min: Vector3, max: Vector3 }

local function worldAABB(pm: ProceduralModel): AABB
	local pivot = pm:GetPivot()
	local h = pm.Size * 0.5
	local minP = Vector3.new(math.huge, math.huge, math.huge)
	local maxP = -minP
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			for sz = -1, 1, 2 do
				local corner = pivot * Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)
				minP = Vector3.new(math.min(minP.X, corner.X), math.min(minP.Y, corner.Y), math.min(minP.Z, corner.Z))
				maxP = Vector3.new(math.max(maxP.X, corner.X), math.max(maxP.Y, corner.Y), math.max(maxP.Z, corner.Z))
			end
		end
	end
	return { min = minP, max = maxP }
end

local function overlaps(a: AABB, b: AABB): boolean
	return a.max.X >= b.min.X
		and a.min.X <= b.max.X
		and a.max.Y >= b.min.Y
		and a.min.Y <= b.max.Y
		and a.max.Z >= b.min.Z
		and a.min.Z <= b.max.Z
end

local function computeOverlap(target: ProceduralModel): { [ProceduralModel]: true }
	local box = worldAABB(target)
	local out: { [ProceduralModel]: true } = {}
	for _, pm in CollectionService:GetTagged(BOUNDS_TAG) do
		if pm ~= target and pm:IsA("ProceduralModel") then
			if overlaps(box, worldAABB(pm)) then
				out[pm] = true
			end
		end
	end
	return out
end

local function clearGenerated(pm: ProceduralModel)
	local generated = pm:FindFirstChild("Generated")
	if generated then
		generated:ClearAllChildren()
	end
end

local function bump(pm: ProceduralModel)
	local v = pm:GetAttribute("Version")
	local newV = (typeof(v) == "number" and v or 0) + 1
	pm:SetAttribute("Version", newV)
	print(LOG_PREFIX, "  bumped", pm.Name, "→ Version", newV)
end

local DEBOUNCE_SECONDS = 0.1

local lastOverlap: { [ProceduralModel]: { [ProceduralModel]: true } } = {}
local lastPivot: { [ProceduralModel]: CFrame } = {}
local lastSize: { [ProceduralModel]: Vector3 } = {}
local pending: { [ProceduralModel]: true } = {}
local pendingThread: thread? = nil

local function ensureTracked(pm: ProceduralModel)
	if lastPivot[pm] then
		return
	end
	lastPivot[pm] = pm:GetPivot()
	lastSize[pm] = pm.Size
	lastOverlap[pm] = computeOverlap(pm)
	print(LOG_PREFIX, "tracking", pm:GetFullName())
end

local function untrack(pm: ProceduralModel)
	local prev = lastOverlap[pm]
	local bumpCount = 0
	if prev then
		for n in prev do
			if n.Parent then
				bump(n)
				lastOverlap[n] = computeOverlap(n)
				bumpCount += 1
			end
		end
	end
	print(LOG_PREFIX, "untrack", pm.Name, "→ bumped", bumpCount, "previous neighbor(s)")
	lastPivot[pm] = nil
	lastSize[pm] = nil
	lastOverlap[pm] = nil
end

local function flush()
	pendingThread = nil
	local moved = pending
	pending = {}
	local moverCount = 0
	for _ in moved do
		moverCount += 1
	end
	print(LOG_PREFIX, "SETTLED — flushing", moverCount, "mover(s)")

	-- Bump each mover plus every neighbor in (old overlap set) ∪ (new overlap set). The
	-- union (vs symmetric difference) catches the case where a peer with matching
	-- orientation stays overlapping during a drag — its voxel ownership still needs
	-- re-evaluation against our new position.
	local toBump: { [ProceduralModel]: true } = {}
	for movedPM in moved do
		if not movedPM.Parent then
			continue
		end
		toBump[movedPM] = true
		local now = computeOverlap(movedPM)
		local prev = lastOverlap[movedPM] or {}
		for n in now do
			toBump[n] = true
		end
		for n in prev do
			toBump[n] = true
		end
		lastOverlap[movedPM] = now
	end

	local bumped = 0
	for pm in toBump do
		if pm.Parent then
			bump(pm)
			-- Refresh this PM's overlap snapshot. Without this, a PM that got bumped
			-- because it was in a mover's overlap would never have its own lastOverlap
			-- updated — which breaks future delete-time fan-out (untrack relies on
			-- lastOverlap[pm] to know who needs to re-bake when pm is destroyed).
			lastOverlap[pm] = computeOverlap(pm)
			bumped += 1
		end
	end
	print(LOG_PREFIX, "flush bumped", bumped, "PM(s)")
end

local function markDirty(pm: ProceduralModel)
	pending[pm] = true
	-- Debounced flush: each new dirty cancels the previous timer and restarts it. The
	-- flush only fires after changes have been quiet for DEBOUNCE_SECONDS, which keeps
	-- our clear+bump from racing with the engine's auto-bake mid-drag (the cause of the
	-- mid-resize flicker and the 50% empty result).
	if pendingThread then
		task.cancel(pendingThread)
	end
	pendingThread = task.delay(DEBOUNCE_SECONDS, flush)
end

-- Poll each frame for pivot/size changes.
RunService.Heartbeat:Connect(function()
	if not isEditMode() then
		return
	end
	for _, pm in CollectionService:GetTagged(BOUNDS_TAG) do
		if not pm:IsA("ProceduralModel") then
			continue
		end
		ensureTracked(pm)
		local nowPivot = pm:GetPivot()
		local nowSize = pm.Size
		if nowPivot ~= lastPivot[pm] or nowSize ~= lastSize[pm] then
			lastPivot[pm] = nowPivot
			lastSize[pm] = nowSize
			print(LOG_PREFIX, "dirty:", pm.Name)
			markDirty(pm)
		end
	end
end)

CollectionService:GetInstanceAddedSignal(BOUNDS_TAG):Connect(function(inst)
	if not isEditMode() then
		return
	end
	if inst:IsA("ProceduralModel") then
		ensureTracked(inst)
		markDirty(inst)
	end
end)

CollectionService:GetInstanceRemovedSignal(BOUNDS_TAG):Connect(function(inst)
	if not isEditMode() then
		return
	end
	if inst:IsA("ProceduralModel") then
		untrack(inst)
	end
end)

-- Bootstrap: seed tracking state for any PMs already tagged at plugin load.
if isEditMode() then
	local count = 0
	for _, pm in CollectionService:GetTagged(BOUNDS_TAG) do
		if pm:IsA("ProceduralModel") then
			ensureTracked(pm)
			count += 1
		end
	end
	print(LOG_PREFIX, "bootstrap tracked", count, "tagged PM(s)")
end
