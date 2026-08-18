--!strict
-- Turns rich text into a TextLabel one grapheme at a time.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Helper utility that converts custom Markdown into Roblox rich text.
local mder = require(ReplicatedStorage.Utility.mder)

local Typewriter = {}

local currentToken = 0
local typing = false
local currentLabel: TextLabel? = nil

-- Whether a reveal is currently in progress.
function Typewriter.isTyping(): boolean
	return typing
end

-- Reveal text into the label over time, cancelling any in-progress reveal.
-- Returns immediately; the reveal runs on its own task.
function Typewriter.play(label: TextLabel, text: string, charsPerSecond: number)
	currentToken += 1
	local token = currentToken
	typing = true
	currentLabel = label

	-- Render rich text once and reveal graphemes over time. Keep any
	-- `<b>`, `<i>`, `<font>`, etc. tags intact (and invisible) on every frame.
	label.Text = mder.mdToRich(text)
	label.MaxVisibleGraphemes = 0

	local totalGraphemes = utf8.len(label.ContentText) or #label.ContentText
	local interval = 1 / math.max(1, charsPerSecond)
	local accumulator = 0
	local i = 0
	task.spawn(function()
		while i < totalGraphemes do
			local dt = RunService.RenderStepped:Wait()
			-- Re-check after yielding
			if currentToken ~= token then
				return
			end
			accumulator += dt
			while accumulator >= interval and i < totalGraphemes do
				i += 1
				accumulator -= interval
			end
			label.MaxVisibleGraphemes = i
		end
		if currentToken == token then
			label.MaxVisibleGraphemes = -1
			typing = false
		end
	end)
end

-- Immediately reveal the whole current line (the "skip" on the first advance press).
function Typewriter.skip()
	if not typing then
		return
	end
	currentToken += 1
	if currentLabel then
		currentLabel.MaxVisibleGraphemes = -1
	end
	typing = false
end

-- Cancel any in-progress reveal without revealing the rest (e.g. the dialog ended).
function Typewriter.stop()
	currentToken += 1
	typing = false
end

return Typewriter
