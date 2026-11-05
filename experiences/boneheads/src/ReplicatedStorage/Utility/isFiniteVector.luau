local function isFiniteVector(vector: Vector3): boolean
	return vector.X == vector.X
		and vector.Y == vector.Y
		and vector.Z == vector.Z
		and math.abs(vector.X) ~= math.huge
		and math.abs(vector.Y) ~= math.huge
		and math.abs(vector.Z) ~= math.huge
end

return isFiniteVector
