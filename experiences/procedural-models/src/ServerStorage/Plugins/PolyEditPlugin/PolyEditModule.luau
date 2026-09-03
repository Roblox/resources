local module = {}

local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Identity tag: edited PMs get this tag so the standalone GuidMaintainer
-- plugin stamps + maintains a unique Guid attribute on them. Consumers
-- (generators, modifier watchers) look the PM up via
-- CollectionService:GetTagged("HAS_GUID") instead of scanning all of
-- Workspace.
local GUID_TAG = "HAS_GUID"

local DATA_FOLDER_NAME = "PolyEditData"
local POLY_ATTR = "PolyEditPolygon"
local VERTEX_ATTR = "PolyEditVertexIndex"
local GHOST_ATTR = "PolyEditGhostAfter"
local ARM_ATTR = "PolyEditArmAfter"
-- User-visible boolean on the polygon Model. When true, the polygon is a
-- chain (no closing segment between V_n and V_1) and the editor's arm /
-- ghost between those two vertices is suppressed. Generators (Landmass,
-- Fence, …) read the same attribute and decide for themselves what an
-- "open" polygon means.
local OPEN_ATTR = "Open"

local VERTEX_DIAMETER = 0.55
local GHOST_DIAMETER = 0.4
local ARM_RADIUS = 0.06
local HIT_PIXELS = 12
local NEW_RADIUS = 4
local NEW_SIDES = 3

local COLOR_VERTEX_IDLE = Color3.fromRGB(60, 170, 255)
local COLOR_VERTEX_HOVER = Color3.fromRGB(150, 220, 255)
local COLOR_VERTEX_SELECT = Color3.fromRGB(255, 150, 60)
local COLOR_GHOST_IDLE = Color3.fromRGB(255, 210, 80)
local COLOR_GHOST_HOVER = Color3.fromRGB(255, 245, 160)
local COLOR_ARM = Color3.fromRGB(120, 180, 220)

local pluginRef
local widget
local active = false
local activated = false

local hoverTarget = nil
local selectedPart = nil
local dragState = nil
local selectedPolygons = {}
local lastInteractivePolygon = nil
local insideRecord = false

local mouseRef
local mouseConns = {}
local vertexConns = {}
local modelConns = {}
local processing = {}
local pendingDirty = {}

local detachModel
local makeGhostFor
local updateVisual
local bumpProceduralVersion

local function isPolygon(model)
	return model:IsA("Model") and model:GetAttribute(POLY_ATTR) == true
end

local function isOpen(model)
	return model:GetAttribute(OPEN_ATTR) == true
end

local function getVertices(model)
	local verts = {}
	for _, child in model:GetChildren() do
		local idx = child:GetAttribute(VERTEX_ATTR)
		if idx then
			table.insert(verts, { part = child, index = idx })
		end
	end
	table.sort(verts, function(a, b)
		return a.index < b.index
	end)
	return verts
end

local function reindexVertices(model)
	local verts = getVertices(model)
	for i, v in verts do
		if v.index ~= i then
			v.part:SetAttribute(VERTEX_ATTR, i)
			v.part.Name = "V" .. i
		end
	end
end

local function clearGhosts(model)
	for _, child in model:GetChildren() do
		if child:GetAttribute(GHOST_ATTR) ~= nil then
			if hoverTarget == child then
				hoverTarget = nil
			end
			child:Destroy()
		end
	end
end

local function clearArms(model)
	for _, child in model:GetChildren() do
		if child:GetAttribute(ARM_ATTR) ~= nil then
			child:Destroy()
		end
	end
end

local function styleInvisiblePart(part, diameter)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * diameter
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Locked = true
	part.Transparency = 1
	part.Material = Enum.Material.SmoothPlastic
end

local function addHandle(part, diameter)
	local a = Instance.new("SphereHandleAdornment")
	a.Name = "PolyEditHandle"
	a.Adornee = part
	a.Radius = diameter * 0.5
	a.AlwaysOnTop = true
	a.ZIndex = 5
	a.Visible = false
	a.Parent = part
	return a
end

local function addArmAdornment(part, length)
	local a = Instance.new("CylinderHandleAdornment")
	a.Name = "PolyEditHandle"
	a.Adornee = part
	a.Height = length
	a.Radius = ARM_RADIUS
	a.AlwaysOnTop = true
	a.ZIndex = 4
	a.Color3 = COLOR_ARM
	a.Transparency = 0.1
	a.Visible = true
	a.Parent = part
	return a
end

local function styleArmAnchor(part)
	part.Size = Vector3.one * 0.05
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Locked = true
	part.Transparency = 1
end

local function updateArmCFrame(armPart, fromPos, toPos)
	local diff = toPos - fromPos
	local length = diff.Magnitude
	if length < 1e-4 then
		return
	end
	local mid = (fromPos + toPos) * 0.5
	armPart.CFrame = CFrame.lookAt(mid, toPos)
	local handle = armPart:FindFirstChild("PolyEditHandle")
	if handle and handle:IsA("CylinderHandleAdornment") then
		handle.Height = length
	end
end

local function makeArmFor(model, fromPos, toPos, afterIndex)
	local diff = toPos - fromPos
	local length = diff.Magnitude
	if length < 1e-4 then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = "Arm"
	styleArmAnchor(p)
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = CFrame.lookAt((fromPos + toPos) * 0.5, toPos)
	p:SetAttribute(ARM_ATTR, afterIndex)
	addArmAdornment(p, length)
	p.Parent = model
	return p
end

local function isModelSelected(model)
	return model ~= nil and selectedPolygons[model] == true
end

local function refreshPartMarker(part, model)
	local handle = part:FindFirstChild("PolyEditHandle")
	if not handle then
		return
	end
	if part:GetAttribute(ARM_ATTR) ~= nil then
		handle.Visible = true
	else
		handle.Visible = isModelSelected(model or part.Parent)
	end
end

local function refreshModelMarkers(model)
	for _, child in model:GetChildren() do
		if child:FindFirstChild("PolyEditHandle") then
			refreshPartMarker(child, model)
		end
	end
end

local function clearHandlesIn(part)
	for _, child in part:GetChildren() do
		if child.Name == "PolyEditHandle" or child.Name == "PolyEditHighlight" then
			child:Destroy()
		end
	end
end

local function clearVertexHandles(model)
	for _, child in model:GetChildren() do
		if child:GetAttribute(VERTEX_ATTR) ~= nil then
			clearHandlesIn(child)
		end
	end
end

local function addVertexHandles(model)
	for _, child in model:GetChildren() do
		if child:GetAttribute(VERTEX_ATTR) ~= nil then
			clearHandlesIn(child)
			addHandle(child, VERTEX_DIAMETER)
			updateVisual(child)
			refreshPartMarker(child, model)
		end
	end
end

updateVisual = function(part)
	if not part or not part.Parent then
		return
	end
	if part:GetAttribute(ARM_ATTR) ~= nil then
		return
	end
	local handle = part:FindFirstChild("PolyEditHandle")
	if not handle then
		return
	end
	local isGhost = part:GetAttribute(GHOST_ATTR) ~= nil
	if isGhost then
		if hoverTarget == part then
			handle.Color3 = COLOR_GHOST_HOVER
			handle.Transparency = 0.05
			handle.Radius = GHOST_DIAMETER * 0.6
		else
			handle.Color3 = COLOR_GHOST_IDLE
			handle.Transparency = 0.4
			handle.Radius = GHOST_DIAMETER * 0.5
		end
	else
		if selectedPart == part then
			handle.Color3 = COLOR_VERTEX_SELECT
			handle.Transparency = 0
			handle.Radius = VERTEX_DIAMETER * 0.65
		elseif hoverTarget == part then
			handle.Color3 = COLOR_VERTEX_HOVER
			handle.Transparency = 0
			handle.Radius = VERTEX_DIAMETER * 0.6
		else
			handle.Color3 = COLOR_VERTEX_IDLE
			handle.Transparency = 0.1
			handle.Radius = VERTEX_DIAMETER * 0.5
		end
	end
end

local function setHoverTarget(part)
	if hoverTarget == part then
		return
	end
	local old = hoverTarget
	hoverTarget = part
	if old and old.Parent then
		updateVisual(old)
	end
	if part then
		updateVisual(part)
	end
end

local function setSelected(part)
	if selectedPart == part then
		return
	end
	local old = selectedPart
	selectedPart = part
	if old and old.Parent then
		updateVisual(old)
	end
	if part then
		updateVisual(part)
	end
end

local function rebuildGhosts(model)
	clearGhosts(model)
	local verts = getVertices(model)
	local n = #verts
	if n < 2 then
		return
	end
	-- Open chains have one fewer edge: the segment from V_n back to V_1
	-- is suppressed.
	local edgeCount = isOpen(model) and (n - 1) or n
	for i = 1, edgeCount do
		local a = verts[i].part.Position
		local b = verts[(i % n) + 1].part.Position
		local mid = (a + b) * 0.5
		makeGhostFor(model, mid, verts[i].index)
	end
end

local function rebuildArms(model)
	clearArms(model)
	local verts = getVertices(model)
	local n = #verts
	if n < 2 then
		return
	end
	local edgeCount = isOpen(model) and (n - 1) or n
	for i = 1, edgeCount do
		local a = verts[i].part.Position
		local b = verts[(i % n) + 1].part.Position
		makeArmFor(model, a, b, verts[i].index)
	end
end

local function updateAdjacentArms(model, vertexIndex)
	local verts = getVertices(model)
	local n = #verts
	if n < 2 then
		return
	end
	local positions = {}
	for _, v in verts do
		positions[v.index] = v.part.Position
	end
	local prevAfter = (vertexIndex == 1) and n or (vertexIndex - 1)
	local affected = { [vertexIndex] = true, [prevAfter] = true }
	for _, child in model:GetChildren() do
		local af = child:GetAttribute(ARM_ATTR)
		if af and affected[af] then
			local from = positions[af]
			local toIdx = (af == n) and 1 or (af + 1)
			local to = positions[toIdx]
			if from and to then
				updateArmCFrame(child, from, to)
			end
		end
	end
end

local function markDirty(model)
	if insideRecord then
		return
	end
	if pendingDirty[model] then
		return
	end
	pendingDirty[model] = true
	task.defer(function()
		pendingDirty[model] = nil
		if not model.Parent or not isPolygon(model) then
			return
		end
		if dragState and dragState.model == model then
			return
		end
		if isModelSelected(model) then
			addVertexHandles(model)
			rebuildArms(model)
			rebuildGhosts(model)
		else
			clearVertexHandles(model)
			clearArms(model)
			clearGhosts(model)
		end
	end)
end

local function projectToPlane(vertex)
	if processing[vertex] then
		return
	end
	if dragState and dragState.vertex == vertex then
		return
	end
	local model = vertex.Parent
	if not model or not isPolygon(model) then
		return
	end
	local pivot = model:GetPivot()
	local localPos = pivot:PointToObjectSpace(vertex.Position)
	if math.abs(localPos.Y) > 1e-4 then
		processing[vertex] = true
		local snapped = pivot:PointToWorldSpace(Vector3.new(localPos.X, 0, localPos.Z))
		vertex.CFrame = CFrame.new(snapped)
		processing[vertex] = false
	end
	markDirty(model)
end

local function detachVertex(part)
	local c = vertexConns[part]
	if c then
		c:Disconnect()
		vertexConns[part] = nil
	end
end

local function attachVertex(part)
	detachVertex(part)
	vertexConns[part] = part:GetPropertyChangedSignal("CFrame"):Connect(function()
		projectToPlane(part)
	end)
end

local function ensurePartConfig(part)
	part.CanQuery = false
	part.CanCollide = false
	part.CanTouch = false
	part.Locked = true
	part.Transparency = 1
	part.Anchored = true
end

local function makeVertexAt(model, position, index)
	local p = Instance.new("Part")
	p.Name = "V" .. index
	styleInvisiblePart(p, VERTEX_DIAMETER)
	p.Position = position
	p:SetAttribute(VERTEX_ATTR, index)
	p.Parent = model
	if isModelSelected(model) then
		addHandle(p, VERTEX_DIAMETER)
		updateVisual(p)
		refreshPartMarker(p, model)
	end
	return p
end

makeGhostFor = function(model, position, afterIndex)
	local p = Instance.new("Part")
	p.Name = "Ghost"
	styleInvisiblePart(p, GHOST_DIAMETER)
	p.Position = position
	addHandle(p, GHOST_DIAMETER)
	p:SetAttribute(GHOST_ATTR, afterIndex)
	p.Parent = model
	refreshPartMarker(p, model)
	updateVisual(p)
	return p
end

local function attachModel(model)
	if modelConns[model] then
		return
	end
	for _, child in model:GetChildren() do
		local isVert = child:GetAttribute(VERTEX_ATTR) ~= nil
		if isVert then
			ensurePartConfig(child)
			clearHandlesIn(child)
			attachVertex(child)
		end
	end
	clearGhosts(model)
	clearArms(model)
	clearVertexHandles(model)
	modelConns[model] = {
		model.ChildAdded:Connect(function(child)
			if child:GetAttribute(VERTEX_ATTR) then
				attachVertex(child)
				markDirty(model)
			end
		end),
		model.ChildRemoved:Connect(function(child)
			local wasVertex = child:GetAttribute(VERTEX_ATTR) ~= nil
			detachVertex(child)
			if hoverTarget == child then
				hoverTarget = nil
			end
			if selectedPart == child then
				selectedPart = nil
			end
			if wasVertex then
				markDirty(model)
			end
		end),
		model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(Workspace) then
				detachModel(model)
			end
		end),
		model:GetAttributeChangedSignal(OPEN_ATTR):Connect(function()
			markDirty(model)
			bumpProceduralVersion(model)
		end),
	}
	refreshModelMarkers(model)
end

detachModel = function(model)
	local conns = modelConns[model]
	if not conns then
		return
	end
	for _, c in conns do
		c:Disconnect()
	end
	modelConns[model] = nil
	selectedPolygons[model] = nil
	if lastInteractivePolygon == model then
		lastInteractivePolygon = nil
	end
	for _, child in model:GetChildren() do
		detachVertex(child)
		clearHandlesIn(child)
		if hoverTarget == child then
			hoverTarget = nil
		end
		if selectedPart == child then
			selectedPart = nil
		end
	end
	clearGhosts(model)
	clearArms(model)
	if dragState and dragState.model == model then
		dragState = nil
	end
end

local function sanitizeWorkspace()
	for _, descendant in Workspace:GetDescendants() do
		if descendant.Name == "PolyEditHighlight" then
			descendant:Destroy()
		else
			local g = descendant:GetAttribute(GHOST_ATTR)
			local a = descendant:GetAttribute(ARM_ATTR)
			if g ~= nil or a ~= nil then
				local parent = descendant.Parent
				if not parent or not isPolygon(parent) then
					descendant:Destroy()
				end
			elseif descendant.Name == "PolyEditHandle" then
				local parent = descendant.Parent
				local managed = parent
					and (
						parent:GetAttribute(VERTEX_ATTR) ~= nil
						or parent:GetAttribute(GHOST_ATTR) ~= nil
						or parent:GetAttribute(ARM_ATTR) ~= nil
					)
				if not managed then
					descendant:Destroy()
				end
			end
		end
	end
end

local function scanWorkspace()
	sanitizeWorkspace()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("Model") and descendant:GetAttribute(POLY_ATTR) then
			attachModel(descendant)
		end
	end
end

function bumpProceduralVersion(polygonModel)
	local ancestor = polygonModel.Parent
	while ancestor do
		if ancestor.ClassName == "ProceduralModel" then
			-- Identity: tag the PM so the GuidMaintainer plugin stamps +
			-- maintains a unique Guid attribute on it. Consumers look the
			-- PM up by tag without scanning Workspace.
			if not CollectionService:HasTag(ancestor, GUID_TAG) then
				CollectionService:AddTag(ancestor, GUID_TAG)
			end

			-- Generators walk the polygon Model descendants directly via
			-- the GUID lookup, so we don't serialize any vertex/bounds
			-- data here anymore — just maintain the tag + version.
			local current = ancestor:GetAttribute("Version")
			if type(current) == "number" then
				ancestor:SetAttribute("Version", current + 1)
			else
				ancestor:SetAttribute("Version", 1)
			end
			return
		end
		ancestor = ancestor.Parent
	end
end

local function recordChange(name, fn)
	local prev = insideRecord
	insideRecord = true
	local id = ChangeHistoryService:TryBeginRecording(name, name)
	if not id then
		local ok, err = pcall(fn)
		insideRecord = prev
		if not ok then
			error(err)
		end
		return
	end
	local ok, err = pcall(fn)
	ChangeHistoryService:FinishRecording(
		id,
		ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel
	)
	insideRecord = prev
	if not ok then
		error(err)
	end
end

local function promoteGhostInternal(ghost)
	local model = ghost.Parent
	if not model or not isPolygon(model) then
		return nil, nil
	end
	local afterIdx = ghost:GetAttribute(GHOST_ATTR)
	if not afterIdx then
		return nil, nil
	end
	local position = ghost.Position
	for _, child in model:GetChildren() do
		local idx = child:GetAttribute(VERTEX_ATTR)
		if idx and idx > afterIdx then
			child:SetAttribute(VERTEX_ATTR, idx + 1)
			child.Name = "V" .. (idx + 1)
		end
	end
	ghost:Destroy()
	local newVert = makeVertexAt(model, position, afterIdx + 1)
	reindexVertices(model)
	clearGhosts(model)
	rebuildArms(model)
	return newVert, model
end

local function deleteVertex(vertex)
	if not vertex or not vertex.Parent then
		return
	end
	local model = vertex.Parent
	if not isPolygon(model) then
		return
	end
	if not vertex:GetAttribute(VERTEX_ATTR) then
		return
	end
	local verts = getVertices(model)
	if #verts <= 3 then
		return
	end
	recordChange("PolyEdit: Delete Vertex", function()
		if selectedPart == vertex then
			selectedPart = nil
		end
		if hoverTarget == vertex then
			hoverTarget = nil
		end
		vertex:Destroy()
		reindexVertices(model)
		if isModelSelected(model) then
			rebuildArms(model)
			rebuildGhosts(model)
		end
		bumpProceduralVersion(model)
	end)
	lastInteractivePolygon = model
end

local RESET_HALF = 12

local function resetPolygon(model)
	if not model or not model.Parent or not isPolygon(model) then
		return
	end
	recordChange("PolyEdit: Reset Polygon", function()
		for _, v in getVertices(model) do
			if hoverTarget == v.part then
				hoverTarget = nil
			end
			if selectedPart == v.part then
				selectedPart = nil
			end
			v.part:Destroy()
		end
		clearGhosts(model)
		clearArms(model)
		local pivot = model:GetPivot()
		local corners = {
			Vector3.new(-RESET_HALF, 0, -RESET_HALF),
			Vector3.new(RESET_HALF, 0, -RESET_HALF),
			Vector3.new(RESET_HALF, 0, RESET_HALF),
			Vector3.new(-RESET_HALF, 0, RESET_HALF),
		}
		for i, localPos in corners do
			makeVertexAt(model, pivot:PointToWorldSpace(localPos), i)
		end
		if isModelSelected(model) then
			rebuildArms(model)
			rebuildGhosts(model)
		end
		bumpProceduralVersion(model)
	end)
	lastInteractivePolygon = model
end

local function getDataFolder()
	return ServerStorage:FindFirstChild(DATA_FOLDER_NAME)
end

local function ensureDataFolder()
	if getDataFolder() then
		return
	end
	recordChange("PolyEdit: Enable", function()
		local folder = Instance.new("Folder")
		folder.Name = DATA_FOLDER_NAME
		folder.Parent = ServerStorage
	end)
end

local function getEditorPivot()
	local cam = Workspace.CurrentCamera
	if not cam then
		return CFrame.new(0, 5, 0)
	end
	local pos = cam.CFrame.Position + cam.CFrame.LookVector * 14
	return CFrame.new(pos)
end

local function uniquePolygonName()
	local i = 1
	while true do
		local name = string.format("Polygon%02d", i)
		if not Workspace:FindFirstChild(name) then
			return name
		end
		i += 1
	end
end

local function createNewPolygon()
	local model
	recordChange("PolyEdit: New Polygon", function()
		model = Instance.new("Model")
		model.Name = uniquePolygonName()
		model:SetAttribute(POLY_ATTR, true)
		local pivot = getEditorPivot()
		model.WorldPivot = pivot
		for i = 1, NEW_SIDES do
			local theta = (i - 1) / NEW_SIDES * math.pi * 2
			local localPos = Vector3.new(math.cos(theta) * NEW_RADIUS, 0, math.sin(theta) * NEW_RADIUS)
			local worldPos = pivot:PointToWorldSpace(localPos)
			makeVertexAt(model, worldPos, i)
		end
		model.Parent = Workspace
	end)
	if model then
		lastInteractivePolygon = model
		Selection:Set({ model })
	end
end

local function screenRadiusAt(cameraPos, worldPos, pixels)
	local cam = Workspace.CurrentCamera
	if not cam then
		return 0.45
	end
	local distance = (worldPos - cameraPos).Magnitude
	local fovRad = math.rad(cam.FieldOfView)
	local viewHeight = cam.ViewportSize.Y
	if viewHeight <= 0 then
		return 0.45
	end
	return 2 * distance * math.tan(fovRad / 2) / viewHeight * pixels
end

local function hitTest(origin, direction)
	local bestPart = nil
	local bestT = math.huge
	for model in pairs(selectedPolygons) do
		for _, child in model:GetChildren() do
			local isV = child:GetAttribute(VERTEX_ATTR) ~= nil
			local isG = child:GetAttribute(GHOST_ATTR) ~= nil
			if isV or isG then
				local toP = child.Position - origin
				local proj = toP:Dot(direction)
				if proj > 0 then
					local closest = origin + direction * proj
					local dist = (child.Position - closest).Magnitude
					local threshold = screenRadiusAt(origin, child.Position, HIT_PIXELS)
					local visualRadius = (isG and GHOST_DIAMETER or VERTEX_DIAMETER) * 0.5
					if threshold < visualRadius then
						threshold = visualRadius
					end
					if dist < threshold and proj < bestT then
						bestPart = child
						bestT = proj
					end
				end
			end
		end
	end
	return bestPart
end

local function rayPlaneIntersect(origin, direction, planePoint, planeNormal)
	local denom = direction:Dot(planeNormal)
	if math.abs(denom) < 1e-6 then
		return nil
	end
	local t = (planePoint - origin):Dot(planeNormal) / denom
	if t < 0 then
		return nil
	end
	return origin + direction * t
end

local SNAP_PIXELS = 18
local GRID_SIZE = 1.0
local SETTING_GRID_SNAP = "PolyEditGridSnap"
local gridSnapEnabled = false

local function snapToGrid(model, worldPos)
	local pivot = model:GetPivot()
	local localP = pivot:PointToObjectSpace(worldPos)
	return pivot:PointToWorldSpace(
		Vector3.new(math.round(localP.X / GRID_SIZE) * GRID_SIZE, 0, math.round(localP.Z / GRID_SIZE) * GRID_SIZE)
	)
end

local function findVertexSnap(model, draggedVertex, candidatePos, camPos)
	for _, child in model:GetChildren() do
		if child ~= draggedVertex and child:GetAttribute(VERTEX_ATTR) ~= nil then
			local threshold = screenRadiusAt(camPos, child.Position, SNAP_PIXELS)
			if threshold < VERTEX_DIAMETER then
				threshold = VERTEX_DIAMETER
			end
			if (child.Position - candidatePos).Magnitude < threshold then
				return child
			end
		end
	end
	return nil
end

local function beginDragOn(vertex, model, recordingId)
	local pivot = model:GetPivot()
	dragState = {
		vertex = vertex,
		model = model,
		planePoint = pivot.Position,
		planeNormal = pivot.UpVector,
		recordingId = recordingId,
		vertexIndex = vertex:GetAttribute(VERTEX_ATTR),
	}
	lastInteractivePolygon = model
	clearGhosts(model)
end

local function startDrag(vertex)
	local model = vertex.Parent
	if not model or not isPolygon(model) then
		return
	end
	insideRecord = true
	local id = ChangeHistoryService:TryBeginRecording("PolyEdit: Move Vertex", "PolyEdit: Move Vertex")
	beginDragOn(vertex, model, id)
end

local function updateDrag(origin, direction)
	if not dragState then
		return
	end
	local hit = rayPlaneIntersect(origin, direction, dragState.planePoint, dragState.planeNormal)
	if not hit then
		return
	end
	if gridSnapEnabled then
		hit = snapToGrid(dragState.model, hit)
	end
	local snapTarget = findVertexSnap(dragState.model, dragState.vertex, hit, origin)
	dragState.snapTarget = snapTarget
	if snapTarget then
		hit = snapTarget.Position
	end
	processing[dragState.vertex] = true
	dragState.vertex.CFrame = CFrame.new(hit)
	processing[dragState.vertex] = false
	if dragState.vertexIndex then
		updateAdjacentArms(dragState.model, dragState.vertexIndex)
	end
end

local function endDrag(commit)
	if not dragState then
		return
	end
	local model = dragState.model
	local id = dragState.recordingId
	local snapTarget = dragState.snapTarget
	local draggedVertex = dragState.vertex
	local stillSelected = isModelSelected(model)
	dragState = nil

	local merged = false
	if commit and model and model.Parent and snapTarget and snapTarget.Parent then
		local verts = getVertices(model)
		if #verts > 3 then
			if selectedPart == draggedVertex then
				selectedPart = snapTarget
			end
			if hoverTarget == draggedVertex then
				hoverTarget = nil
			end
			draggedVertex:Destroy()
			reindexVertices(model)
			merged = true
		end
	end

	if commit and model and model.Parent and stillSelected then
		if merged then
			rebuildArms(model)
		end
		rebuildGhosts(model)
	end

	if commit and model and model.Parent then
		bumpProceduralVersion(model)
	end

	if id then
		ChangeHistoryService:FinishRecording(
			id,
			commit and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel
		)
	end
	insideRecord = false
	if not commit and model and model.Parent and not stillSelected then
		clearGhosts(model)
		clearArms(model)
		clearVertexHandles(model)
	end
end

local function onMouseMove()
	if not mouseRef then
		return
	end
	local origin = mouseRef.Origin.Position
	local direction = mouseRef.UnitRay.Direction
	if dragState then
		updateDrag(origin, direction)
	else
		setHoverTarget(hitTest(origin, direction))
	end
end

local missCount = 0

local function onButton1Down()
	if not mouseRef then
		return
	end
	local origin = mouseRef.Origin.Position
	local direction = mouseRef.UnitRay.Direction
	local target = hitTest(origin, direction)
	if not target then
		missCount += 1
		if missCount >= 2 then
			missCount = 0
			setSelected(nil)
			Selection:Set({})
		end
		return
	end
	missCount = 0
	if target:GetAttribute(GHOST_ATTR) ~= nil then
		setHoverTarget(nil)
		insideRecord = true
		local id = ChangeHistoryService:TryBeginRecording("PolyEdit: Add Vertex", "PolyEdit: Add Vertex")
		local newVert, model = promoteGhostInternal(target)
		if newVert and model then
			setSelected(newVert)
			beginDragOn(newVert, model, id)
		else
			if id then
				ChangeHistoryService:FinishRecording(id, Enum.FinishRecordingOperation.Cancel)
			end
			insideRecord = false
		end
	elseif target:GetAttribute(VERTEX_ATTR) ~= nil then
		setSelected(target)
		startDrag(target)
	end
end

local function onButton1Up()
	if dragState then
		endDrag(true)
	end
end

local function attachMouse()
	if mouseConns.attached then
		return
	end
	mouseConns.attached = true
	mouseRef = pluginRef:GetMouse()
	mouseRef.Icon = ""
	mouseConns.move = mouseRef.Move:Connect(onMouseMove)
	mouseConns.down = mouseRef.Button1Down:Connect(onButton1Down)
	mouseConns.up = mouseRef.Button1Up:Connect(onButton1Up)
end

local function detachMouse()
	if not mouseConns.attached then
		return
	end
	for _, c in mouseConns do
		if typeof(c) == "RBXScriptConnection" then
			c:Disconnect()
		end
	end
	mouseConns = {}
	mouseRef = nil
end

local function activatePlugin()
	if activated or not pluginRef then
		return
	end
	activated = true
	pluginRef:Activate(true)
	attachMouse()
end

local function deactivatePlugin()
	if not activated then
		return
	end
	activated = false
	if dragState then
		endDrag(false)
	end
	setHoverTarget(nil)
	setSelected(nil)
	detachMouse()
	if pluginRef then
		pluginRef:Deactivate()
	end
end

local function updateActivation()
	local shouldBeActive = active and widget and widget.Enabled and next(selectedPolygons) ~= nil
	if shouldBeActive and not activated then
		activatePlugin()
	elseif not shouldBeActive and activated then
		deactivatePlugin()
	end
end

local function activate()
	if active then
		return
	end
	active = true
	scanWorkspace()
	updateActivation()
end

local function deactivate()
	if not active then
		return
	end
	active = false
	selectedPolygons = {}
	local models = {}
	for model in pairs(modelConns) do
		table.insert(models, model)
	end
	for _, model in models do
		clearGhosts(model)
		clearArms(model)
		clearVertexHandles(model)
		detachModel(model)
	end
	updateActivation()
end

local function refreshActiveState()
	if getDataFolder() then
		activate()
	else
		deactivate()
	end
end

local function clearWidget()
	for _, child in widget:GetChildren() do
		child:Destroy()
	end
end

local function buildContainer()
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
	frame.BorderSizePixel = 0
	frame.Parent = widget
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame
	return frame
end

local function makeLabel(parent, text, order)
	local lbl = Instance.new("TextLabel")
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 0, 0)
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.Text = text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextWrapped = true
	lbl.LayoutOrder = order
	lbl.Parent = parent
	return lbl
end

local function makeButton(parent, text, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.AutoButtonColor = true
	btn.LayoutOrder = order
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn
	btn.Parent = parent
	return btn
end

local function refreshUI()
	clearWidget()
	local frame = buildContainer()
	if not getDataFolder() then
		makeLabel(frame, "PolyEdit is not active in this place.", 1)
		makeLabel(
			frame,
			"Enabling adds an empty Folder to ServerStorage to mark the place as PolyEdit-enabled. Nothing else is added.",
			2
		)
		local btn = makeButton(frame, "Enable for this place", 3)
		btn.Activated:Connect(function()
			ensureDataFolder()
		end)
	else
		makeLabel(frame, "PolyEdit is active.", 1)
		local addBtn = makeButton(frame, "New Polygon", 2)
		addBtn.Activated:Connect(function()
			createNewPolygon()
		end)
		local delBtn = makeButton(frame, "Delete Selected Vertex", 3)
		delBtn.Activated:Connect(function()
			if selectedPart and selectedPart:GetAttribute(VERTEX_ATTR) then
				deleteVertex(selectedPart)
			end
		end)
		local resetBtn = makeButton(frame, "Reset to 4 Vertices", 4)
		resetBtn.Activated:Connect(function()
			for model in pairs(selectedPolygons) do
				resetPolygon(model)
			end
		end)
		local gridBtn = makeButton(frame, "Grid Snap: " .. (gridSnapEnabled and "On" or "Off"), 5)
		gridBtn.Activated:Connect(function()
			gridSnapEnabled = not gridSnapEnabled
			gridBtn.Text = "Grid Snap: " .. (gridSnapEnabled and "On" or "Off")
			if pluginRef then
				pluginRef:SetSetting(SETTING_GRID_SNAP, gridSnapEnabled)
			end
		end)
		makeLabel(
			frame,
			"Select a polygon Model to edit it. Drag a vertex to move it; drag onto another vertex to merge. Click a yellow ghost to insert. Click empty space to deselect.",
			6
		)
	end
end

local function applySelection()
	local newSet = {}
	for _, item in Selection:Get() do
		if isPolygon(item) and modelConns[item] then
			newSet[item] = true
		elseif item.ClassName == "ProceduralModel" then
			for _, descendant in item:GetDescendants() do
				if isPolygon(descendant) and modelConns[descendant] then
					newSet[descendant] = true
				end
			end
		end
	end
	missCount = 0
	local changed = {}
	for model in pairs(selectedPolygons) do
		if not newSet[model] then
			changed[model] = true
		end
	end
	for model in pairs(newSet) do
		if not selectedPolygons[model] then
			changed[model] = true
		end
	end
	selectedPolygons = newSet
	for model in pairs(changed) do
		if model.Parent then
			if selectedPolygons[model] then
				addVertexHandles(model)
				rebuildArms(model)
				rebuildGhosts(model)
			else
				clearGhosts(model)
				clearArms(model)
				clearVertexHandles(model)
			end
		end
	end
	if dragState and not selectedPolygons[dragState.model] then
		endDrag(false)
	end
	if hoverTarget then
		local parent = hoverTarget.Parent
		if not parent or not selectedPolygons[parent] then
			setHoverTarget(nil)
		end
	end
	if selectedPart then
		local parent = selectedPart.Parent
		if not parent or not selectedPolygons[parent] then
			setSelected(nil)
		end
	end
	updateActivation()
end

-- ---------------------------------------------------------------------------
-- Modifier watchers
-- ---------------------------------------------------------------------------
-- Tags whose tagged Parts can drive a Landmass regeneration when added,
-- moved, reparented, or have their attributes changed. ADD_HILL is a
-- radial smoothstep bump; ADD_PART is a tilted-plane heightmap stamp
-- inside the part's XZ footprint with linear edge falloff.
local MODIFIER_TAGS = { "ADD_HILL", "ADD_PART" }

local modifierConns: { [Instance]: { RBXScriptConnection } } = {}

-- Per-modifier cache of which PMs it's currently affecting. On any
-- change we recompute, bump the union of (old ∪ new) so a hill that
-- moves out of one landmass's range still triggers it to re-bake
-- without that hill's contribution.
local affectedCache: { [Instance]: { Instance } } = {}

local pendingPMs: { [Instance]: boolean } = {}
local pendingFlush = false

local function bumpVersion(pm: Instance)
	local current = pm:GetAttribute("Version")
	if type(current) == "number" then
		pm:SetAttribute("Version", current + 1)
	else
		pm:SetAttribute("Version", 1)
	end
end

local function flushBumps()
	pendingFlush = false
	local list = pendingPMs
	pendingPMs = {}
	for pm in list do
		if pm.Parent then
			bumpVersion(pm)
		end
	end
end

local function scheduleBumps(pms: { Instance })
	for _, pm in pms do
		pendingPMs[pm] = true
	end
	if pendingFlush then
		return
	end
	pendingFlush = true
	task.defer(flushBumps)
end

-- Compute which PolyEdit-aware PMs a modifier part currently affects.
-- Hills are local-only: a modifier parented under a PM affects only that
-- PM. A modifier not under any PM affects nothing — drop it.
local function computeAffectedPMs(part: Instance): { Instance }
	local out: { Instance } = {}
	if not part:IsA("BasePart") then
		return out
	end

	local ancestor = part.Parent
	while ancestor do
		if ancestor.ClassName == "ProceduralModel" then
			if ancestor:GetAttribute("Guid") ~= nil then
				table.insert(out, ancestor)
			end
			return out
		end
		ancestor = ancestor.Parent
	end
	return out
end

local function refreshModifier(part: Instance)
	local oldAffected = affectedCache[part] or {}
	local newAffected = computeAffectedPMs(part)
	affectedCache[part] = newAffected
	scheduleBumps(oldAffected)
	scheduleBumps(newAffected)
end

local function dropModifier(part: Instance)
	local oldAffected = affectedCache[part]
	affectedCache[part] = nil
	if oldAffected then
		scheduleBumps(oldAffected)
	end
end

local function watchModifier(part: Instance)
	if modifierConns[part] then
		return
	end
	if not part:IsA("BasePart") then
		return
	end
	local conns: { RBXScriptConnection } = {}
	table.insert(
		conns,
		part:GetPropertyChangedSignal("CFrame"):Connect(function()
			refreshModifier(part)
		end)
	)
	table.insert(
		conns,
		part.AttributeChanged:Connect(function()
			refreshModifier(part)
		end)
	)
	table.insert(
		conns,
		part.AncestryChanged:Connect(function()
			refreshModifier(part)
		end)
	)
	modifierConns[part] = conns
end

local function unwatchModifier(part: Instance)
	local conns = modifierConns[part]
	if conns then
		for _, c in conns do
			c:Disconnect()
		end
		modifierConns[part] = nil
	end
end

local function startWatchingModifiers()
	for _, tag in MODIFIER_TAGS do
		for _, part in CollectionService:GetTagged(tag) do
			watchModifier(part)
			refreshModifier(part)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(part)
			watchModifier(part)
			refreshModifier(part)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(part)
			unwatchModifier(part)
			dropModifier(part)
		end)
	end
end

-- Palette watcher: bumping Version on a ProceduralModel is the only way
-- to make a generator re-bake with new colors, but generators don't read
-- ReplicatedStorage.Palettes.* themselves until OnGenerate fires. Without
-- this watcher, changing Palettes.Tree.Foliage in Studio's property pane
-- would silently take no effect until the user manually kicked Trees.
--
-- Each Configuration under ReplicatedStorage.Palettes is named after a
-- generator (Tree, Fence, Landmass, RockCrystal, …). We hook
-- AttributeChanged on each, debounce ~300ms (so dragging the color
-- picker collapses into one kick), and bump Version on every PM whose
-- Generator module shares the Configuration's name.
local PALETTE_DEBOUNCE = 0.3
local palettePending: { [string]: number } = {}

local function kickGenerator(generatorName)
	local count = 0
	for _, d in Workspace:GetDescendants() do
		if d.ClassName == "ProceduralModel" then
			local gen = (d :: any).Generator
			if gen and gen.Name == generatorName then
				bumpVersion(d)
				count += 1
			end
		end
	end
	if count > 0 then
		print(string.format("[PolyEdit] palette change → kicked %d %s ProceduralModel(s)", count, generatorName))
	end
end

local function schedulePaletteKick(generatorName)
	local stamp = os.clock()
	palettePending[generatorName] = stamp
	task.delay(PALETTE_DEBOUNCE, function()
		if palettePending[generatorName] ~= stamp then
			return
		end
		palettePending[generatorName] = nil
		kickGenerator(generatorName)
	end)
end

local function watchPaletteConfig(cfg)
	if not cfg:IsA("Configuration") then
		return
	end
	cfg.AttributeChanged:Connect(function()
		schedulePaletteKick(cfg.Name)
	end)
end

local function startPaletteWatcher()
	local function bind(folder)
		for _, c in folder:GetChildren() do
			watchPaletteConfig(c)
		end
		folder.ChildAdded:Connect(watchPaletteConfig)
	end

	local existing = ReplicatedStorage:FindFirstChild("Palettes")
	if existing and existing:IsA("Folder") then
		bind(existing)
		return
	end

	-- Plugin can load before the Palettes folder is created (or on a
	-- pre-refactor scene). Wait for it instead of giving up so the user
	-- doesn't have to disable + re-enable the plugin to start watching.
	local conn
	conn = ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "Palettes" and child:IsA("Folder") then
			conn:Disconnect()
			bind(child)
		end
	end)
end

-- WorldSettings watcher: SnowAmount (and any other future climate
-- attribute) lives on a single Configuration at
-- ReplicatedStorage.WorldSettings. Any change kicks every PM, since any
-- generator can consume any setting and there's no per-attribute scope
-- mapping. Same 300ms debounce as palettes — coalesces slider drags.
--
-- ProceduralModel merges its existing Generated children with the new
-- bake's targetContainer output rather than fully replacing — meaning a
-- prior bake's "Snow" MeshPart sticks around when the new bake (e.g.
-- SnowAmount=0) emits nothing. Generators can't reach the PM from inside
-- OnGenerate (targetContainer.Parent is nil), so we destroy any stale
-- "Snow" descendants here before bumping Version so the next bake comes
-- up clean.
local STALE_SNOW_NAMES = { "Snow" }
local worldSettingsPending = false
local function scheduleWorldSettingsKick()
	if worldSettingsPending then
		return
	end
	worldSettingsPending = true
	task.delay(PALETTE_DEBOUNCE, function()
		worldSettingsPending = false
		local count = 0
		for _, d in Workspace:GetDescendants() do
			if d.ClassName == "ProceduralModel" then
				for _, name in ipairs(STALE_SNOW_NAMES) do
					for _, descendant in ipairs(d:GetDescendants()) do
						if descendant.Name == name and descendant:IsA("BasePart") then
							descendant:Destroy()
						end
					end
				end
				bumpVersion(d)
				count += 1
			end
		end
		if count > 0 then
			print(string.format("[PolyEdit] WorldSettings change → kicked %d ProceduralModel(s)", count))
		end
	end)
end

local function startWorldSettingsWatcher()
	local function bind(cfg)
		cfg.AttributeChanged:Connect(scheduleWorldSettingsKick)
	end

	local existing = ReplicatedStorage:FindFirstChild("WorldSettings")
	if existing and existing:IsA("Configuration") then
		bind(existing)
		return
	end

	local conn
	conn = ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "WorldSettings" and child:IsA("Configuration") then
			conn:Disconnect()
			bind(child)
		end
	end)
end

function module.start(p, w)
	pluginRef = p
	widget = w
	if pluginRef then
		gridSnapEnabled = pluginRef:GetSetting(SETTING_GRID_SNAP) == true
	end
	refreshUI()
	refreshActiveState()

	Workspace.DescendantAdded:Connect(function(d)
		if not active then
			return
		end
		if d:IsA("Model") and d:GetAttribute(POLY_ATTR) then
			attachModel(d)
			applySelection()
		end
	end)

	widget:GetPropertyChangedSignal("Enabled"):Connect(updateActivation)

	Selection.SelectionChanged:Connect(applySelection)

	local function refreshAfterHistory(action)
		if not action or action:sub(1, 9) ~= "PolyEdit:" then
			return
		end
		if lastInteractivePolygon and lastInteractivePolygon.Parent and #Selection:Get() == 0 then
			Selection:Set({ lastInteractivePolygon })
		end
		for model in pairs(modelConns) do
			if model.Parent and not selectedPolygons[model] then
				clearVertexHandles(model)
				clearArms(model)
				clearGhosts(model)
			end
		end
	end
	ChangeHistoryService.OnUndo:Connect(refreshAfterHistory)
	ChangeHistoryService.OnRedo:Connect(refreshAfterHistory)

	ServerStorage.ChildAdded:Connect(function(c)
		if c.Name == DATA_FOLDER_NAME then
			refreshUI()
			refreshActiveState()
			applySelection()
		end
	end)
	ServerStorage.ChildRemoved:Connect(function(c)
		if c.Name == DATA_FOLDER_NAME then
			refreshUI()
			refreshActiveState()
		end
	end)

	startWatchingModifiers()

	startPaletteWatcher()
	startWorldSettingsWatcher()

	applySelection()
end

return module
