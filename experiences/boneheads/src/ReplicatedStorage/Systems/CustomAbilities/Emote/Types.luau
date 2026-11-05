export type Element = {
	id: string,
	assetIds: { string },
	label: string?,
	image: string?,
}

export type Config = {
	elements: { Element },
	parent: Instance?,
	onSelected: ((emoteIndex: number) -> ())?,
	onDismissed: (() -> ())?,
	onHighlightChanged: ((id: string?) -> ())?,
}

export type EmoteMenu = {
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	getSelectedId: () -> string?,
	setElements: (elements: { Element }) -> (),
	destroy: () -> (),
}

return nil
