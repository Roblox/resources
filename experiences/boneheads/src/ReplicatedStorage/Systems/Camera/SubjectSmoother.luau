-- Critically-damped smoothing (TweenService:SmoothDamp) of a Vector3 or CFrame
-- sampled from server-authority sim state, which steps at the sim tick and snaps
-- on reconciliation. zeroVelocity must match the value type (Vector3.zero / CFrame.identity).

local TweenService = game:GetService("TweenService")

local RELEASE_DISTANCE = 0.05

export type Smoothable = Vector3 | CFrame

export type SubjectSmoother = {
	update: (target: Smoothable, delta: number) -> Smoothable,
	reset: () -> (),
}

local function positionOf(value: Smoothable): Vector3
	return if typeof(value) == "CFrame" then value.Position else value
end

-- snapDistance: jumps beyond this snap instead of gliding (respawns/teleports).
-- engageDistance: 0 = always smooth (kills tick stepping); >0 = divergence-gated —
-- follow exactly during normal motion, glide only once a correction jumps past it.
local function createSubjectSmoother(
	smoothTime: number,
	zeroVelocity: Smoothable,
	snapDistance: number,
	engageDistance: number?
): SubjectSmoother
	local engage = engageDistance or 0
	local isCFrame = typeof(zeroVelocity) == "CFrame"
	local current: Smoothable? = nil
	local previousTarget: Smoothable? = nil
	local velocity: Smoothable = zeroVelocity
	local residual: Smoothable = zeroVelocity
	local previousTargetVelocity = Vector3.zero

	local function combine(target: Smoothable, offset: Smoothable): Smoothable
		if isCFrame then
			return (offset :: CFrame) * (target :: CFrame)
		end
		return (target :: Vector3) + (offset :: Vector3)
	end

	local function residualBetween(value: Smoothable, target: Smoothable): Smoothable
		if isCFrame then
			return (value :: CFrame) * (target :: CFrame):Inverse()
		end
		return (value :: Vector3) - (target :: Vector3)
	end

	local function update(target: Smoothable, delta: number): Smoothable
		local currentValue = current
		if not currentValue then
			current = target
			previousTarget = target
			return target
		end

		if engage <= 0 then
			if (positionOf(target) - positionOf(currentValue)).Magnitude > snapDistance then
				current = target
				velocity = zeroVelocity
				return target
			end
			local smoothed, newVelocity =
				TweenService:SmoothDamp(currentValue, target, velocity, smoothTime, math.huge, delta)
			current = smoothed
			velocity = newVelocity
			return smoothed
		end

		local lastTarget = previousTarget or currentValue
		local previousPosition = positionOf(lastTarget)
		local targetPosition = positionOf(target)
		local deviation = (targetPosition - (previousPosition + previousTargetVelocity * delta)).Magnitude
		previousTarget = target
		if deviation > snapDistance then
			current = target
			velocity = zeroVelocity
			residual = zeroVelocity
			previousTargetVelocity = Vector3.zero
			return target
		end
		previousTargetVelocity = if delta > 0 then (targetPosition - previousPosition) / delta else Vector3.zero

		if deviation > engage then
			residual = residualBetween(currentValue, target)
		end

		local decayed, newVelocity =
			TweenService:SmoothDamp(residual, zeroVelocity, velocity, smoothTime, math.huge, delta)
		if positionOf(decayed).Magnitude <= RELEASE_DISTANCE then
			decayed = zeroVelocity
			newVelocity = zeroVelocity
		end
		residual = decayed
		velocity = newVelocity

		local result = combine(target, residual)
		current = result
		return result
	end

	local function reset()
		current = nil
		previousTarget = nil
		velocity = zeroVelocity
		residual = zeroVelocity
		previousTargetVelocity = Vector3.zero
	end

	return {
		update = update,
		reset = reset,
	}
end

return createSubjectSmoother
