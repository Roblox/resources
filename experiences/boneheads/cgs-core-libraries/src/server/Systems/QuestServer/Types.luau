-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

export type StepTask =
	{
		mode: "single",
		description: string?,
		isComplete: boolean,
	}
	| {
		mode: "counter",
		description: string?,
		isComplete: boolean,
		progress: number,
		maxProgress: number,
	}
	| {
		mode: "group",
		isComplete: boolean,
		subTasks: { StepTask },
	}

export type Step = {
	getTask: () -> StepTask,
	cleanup: () -> (),
}

export type StepDefinition = {
	name: string,
	start: (player: Player, taskCallback: (StepTask) -> (), completeCallback: () -> ()) -> Step,
}

export type QuestDefinition = {
	name: string,
	description: string,
	unique: boolean,
	steps: { StepDefinition },
	onCompleted: (player: Player) -> (),
}

export type Quest = {
	definition: QuestDefinition,
	id: string,

	isCompleted: boolean,
	cleanup: () -> (),

	getProgress: () -> (number, number),
	onProgressed: (callback: (stepIndex: number, maxSteps: number, task: StepTask) -> ()) -> (),
	getStepDescription: () -> string,
}

return nil
