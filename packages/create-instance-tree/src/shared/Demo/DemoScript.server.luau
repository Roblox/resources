--[[
	Creates instances with given properties based on the given tree data table.
	This streamlines the tedious process of calling Instance.new and setting each property by creating a table of properties and a ClassName instead.
--]]

local Workspace = game:GetService("Workspace")
local createInstanceTree = require(script.Parent.Parent.createInstanceTree)

-- Creates a neon green sphere
local sphere = createInstanceTree({
	className = "Part",
	properties = {
		Name = "Sphere",
		Size = Vector3.new(10, 10, 10),
		Position = Vector3.new(-10, 10, -10),
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = Color3.new(0, 1, 0),
		Anchored = true,
	},
})

-- Creates a Model that resembles the Studio Model icon
local modelIconModel = createInstanceTree({
	className = "Model",
	properties = {
		Name = "ModelIcon",
	},
	children = {
		{
			className = "Part",
			properties = {
				Name = "BluePart",
				Size = Vector3.new(4, 4, 4),
				Color = Color3.new(0, 0, 1),
				Position = Vector3.new(10, 4, -10),
				Anchored = true,
				TopSurface = Enum.SurfaceType.Smooth,
				BottomSurface = Enum.SurfaceType.Smooth,
			},
		},
		{
			className = "Part",
			properties = {
				Name = "RedPart",
				Size = Vector3.new(4, 4, 4),
				Color = Color3.new(1, 0, 0),
				Position = Vector3.new(14, 4, -10),
				Anchored = true,
				TopSurface = Enum.SurfaceType.Smooth,
				BottomSurface = Enum.SurfaceType.Smooth,
			},
		},
		{
			className = "Part",
			properties = {
				Name = "YellowPart",
				Size = Vector3.new(4, 4, 4),
				Color = Color3.new(1, 1, 0),
				Position = Vector3.new(12, 8, -10),
				Anchored = true,
				TopSurface = Enum.SurfaceType.Smooth,
				BottomSurface = Enum.SurfaceType.Smooth,
			},
		},
	},
})

sphere.Parent = Workspace
modelIconModel.Parent = Workspace
