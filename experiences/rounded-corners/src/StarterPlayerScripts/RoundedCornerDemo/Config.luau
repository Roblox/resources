-- Options for the demo. See README.md.
return {
	-- Image for the PNG-shadow column in scene 2. Empty = bake an identical 800x800 shadow at
	-- runtime into an EditableImage. To use an uploaded image instead, set this to
	-- "rbxassetid://<id>".
	ShadowImage = "",

	-- Design resolution of the stage. Everything is laid out in these units and uniformly scaled
	-- to fit the window, so captures look identical at any size. Capture at 1920x1080 or 1600x900.
	StageSize = Vector2.new(1600, 900),

	-- Show the caption bar on start (toggle with H).
	ShowCaptions = true,

	-- First scene to open.
	StartScene = 1,
}
