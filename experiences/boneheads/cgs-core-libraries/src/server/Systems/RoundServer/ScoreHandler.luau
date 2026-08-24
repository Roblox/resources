-- Copyright (c) 2026 Roblox Corporation
-- SPDX-License-Identifier: MIT

local _scores: { [any]: number } = {}

local ScoreHandler = {}

function ScoreHandler.getScore(source: any): number
	return _scores[source] or 0
end

function ScoreHandler.setScore(source: any, score: number): ()
	_scores[source] = score
end

function ScoreHandler.incrementScore(source: any, amount: number): ()
	assert(amount > 0, "ScoreHandler incrementScore amount must be positive")

	local newScore = ScoreHandler.getScore(source) + amount
	ScoreHandler.setScore(source, newScore)
end

function ScoreHandler.getAllScores(): { [any]: number }
	return _scores
end

function ScoreHandler.resetScores(): ()
	_scores = {}
end

return ScoreHandler
