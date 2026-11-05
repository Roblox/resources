export type SoundDefinition = {
	name: string,
	assetId: string,
	volume: number,
	rollOffMinDistance: number,
	rollOffMaxDistance: number,
	looped: boolean,
}

export type PlayOptions = {
	volume: number?,
	rollOffMinDistance: number?,
	rollOffMaxDistance: number?,
	looped: boolean?,
}

export type SoundHandle = {
	stop: () -> (),
}

return nil
