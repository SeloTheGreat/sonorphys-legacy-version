local jumpAction = require("./jumpAction")
local groundSensor = require("./groundSensor")
local types = require("../types")

local S_FREEFALL = Enum.HumanoidStateType.Freefall
local S_RUNNING = Enum.HumanoidStateType.Running

local state = {}

--Returns <code>Enum.HumanoidStateType.Dead</code> if the humanoid health is zero
--Returns the state that should be set to the new state
function state.update(manager: types.ControllerManagerHierarchy, humanoid: Humanoid): Enum.HumanoidStateType
	local old = humanoid:GetState()
	local new = manager.ActiveController == manager.GroundController and S_RUNNING or S_FREEFALL

	--Handle death
	if humanoid.Health == 0 then
		return Enum.HumanoidStateType.Dead
	end

	--Handle in-between states (jump and land)
	if humanoid.Jump and jumpAction.ableToJump() then --Supports normal roblox behaviour
		return Enum.HumanoidStateType.Jumping
	end
	
	if old == S_FREEFALL and new == S_RUNNING then
		return Enum.HumanoidStateType.Landed
	end

	--main states
	return new
end

return state
