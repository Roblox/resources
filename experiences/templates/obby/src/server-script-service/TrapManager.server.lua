local CollectionService = game:GetService("CollectionService")

local TRAP_PART_TAG = "TrapPart"

local function onTrapTouched(hit: BasePart)
	if hit and hit.Parent then
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end

local function setupTrapPart(trapPart: Instance)
	if not trapPart:IsA("BasePart") then
		-- If the trap part is not a BasePart, we cannot connect the Touched event
		return
	end

	-- Connect the Touched event to handle when a player touches the trap
	trapPart.Touched:Connect(onTrapTouched)
end

-- Connect the trap touched event for each existing trap part
for _, trapPart in CollectionService:GetTagged(TRAP_PART_TAG) do
	setupTrapPart(trapPart)
end

-- Connect the trap touched event for new trap parts as they are added
CollectionService:GetInstanceAddedSignal(TRAP_PART_TAG):Connect(setupTrapPart)
