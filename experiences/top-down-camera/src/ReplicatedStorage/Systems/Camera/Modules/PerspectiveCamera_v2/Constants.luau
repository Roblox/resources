return {
	CAMERA_OFFSET = Vector3.new(10, 16, 16),
	ROTATION_STEP = math.rad(90), -- per E/Q press; 90° = classic 4-way iso, 45° for 8-way.
	ROTATION_SPEED = 8, -- Lerp factor; higher = snappier, ~6–10 feels good.
}
