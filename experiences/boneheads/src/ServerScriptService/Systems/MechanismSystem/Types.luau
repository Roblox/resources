export type MechanismDefinition = {
	name: string,
	onStart: (model: Model, inputs: { Model }) -> (),
	onUpdate: (model: Model, inputs: { Model }) -> (),
	onStop: ((model: Model) -> ())?,
}

return nil
