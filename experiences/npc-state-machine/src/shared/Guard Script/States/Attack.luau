-- Chase and attack the spotted player.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleStateMachine = require(ReplicatedStorage.Shared.SimpleStateMachine)

type State = SimpleStateMachine.State
type Context = SimpleStateMachine.Context

local ATTACK_RANGE = 10
local ATTACK_COOLDOWN = 1

-- Walk directly towards the spotted player and attack if close enough.
local function chaseAndAttack(context: Context)
	local humanoid = context.humanoid :: Humanoid
	local targetCharacter = context.targetPlayer.Character
	if not targetCharacter then
		return
	end

	local targetPosition = targetCharacter:GetPivot().Position
	humanoid:MoveTo(targetPosition)

	local character = context.character :: Model
	local distance = (character:GetPivot().Position - targetPosition).Magnitude

	if distance <= ATTACK_RANGE and os.clock() - context.lastAttackTime >= ATTACK_COOLDOWN then
		local tool = character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("Handle") then
			tool:Activate()
		end
		context.lastAttackTime = os.clock()
	end
end

local function onEnter(context: Context)
	context.lastAttackTime = 0
end

local Attack: State = {
	name = "Attack",
	onEnter = onEnter,
	onStay = chaseAndAttack,
}

return Attack
