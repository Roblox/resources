local function setTorchEnabled(parent: Instance, enabled: boolean)
	for _, descendant in parent:GetDescendants() do
		if descendant:IsA("ParticleEmitter") or descendant:IsA("PointLight") then
			descendant.Enabled = enabled
		end
	end
end

return setTorchEnabled
