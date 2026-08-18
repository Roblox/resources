--!strict
-- Uses pattern matching to convert Markdown to rich text.
-- Doesn't conform to CommonMark or any other specification. Uses
-- Slack conventions for bold and italic and !! for higlighting.
-- Probably has some bugs, but works well enough for short strings.

local mder = {}

mder.mdToRich = function(text: string)
	-- Bold: *text*
	text = text:gsub("%*([^*]+)%*", "<b>%1</b>")

	-- Underline: __text__, must come before italics
	text = text:gsub("__([^_]+)__", "<u>%1</u>")

	-- Italic: _text_
	text = text:gsub("_([^*]+)_", "<i>%1</i>")

	-- Inline code: `text`
	text = text:gsub("`([^`]+)`", '<font face="Code">%1</font>')

	-- Superscript: ^text^
	text = text:gsub("%^([^`]+)%^", "<sup>%1</sup>")

	-- Strikethrough: ~text~
	text = text:gsub("~([^`]+)~", "<s>%1</s>")

	-- Highlight: !!text!!
	text = text:gsub("!!([^`]+)!!", '<mark color="#009966" transparency="0">%1</mark>')

	return text
end

return mder
