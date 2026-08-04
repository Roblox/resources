local CollectionService = game:GetService("CollectionService")

local BOUNCE_PAD_TAG = "BouncePad"
local DEFAULT_BOUNCE_IMPULSE = 300

local function setupBouncePad(bouncePad: Instance)
	if not bouncePad:IsA("BasePart") then
		-- If the bounce pad is not a BasePart, we cannot set its velocity
		return
	end

	-- Set the bounce pad's velocity based on its BounceImpulse attribute
	local impulse = bouncePad:GetAttribute("BounceImpulse") or DEFAULT_BOUNCE_IMPULSE

	bouncePad.Anchored = true
	bouncePad.AssemblyLinearVelocity = bouncePad.CFrame:VectorToWorldSpace(Vector3.yAxis * impulse)

	-- Hide the bounce indicator if it exists
	local bounceIndicator = bouncePad:FindFirstChildWhichIsA("SurfaceGui")
	if bounceIndicator then
		bounceIndicator.Enabled = false
	end
end

-- Setup all existing bounce pads
for _, bouncePad in CollectionService:GetTagged(BOUNCE_PAD_TAG) do
	setupBouncePad(bouncePad)
end

-- Setup new bounce pads as they are added
CollectionService:GetInstanceAddedSignal(BOUNCE_PAD_TAG):Connect(setupBouncePad)
