local config = require("../configuration").GroundSensor
local types = require("../types")

assert(config.SnapsToGroundDistance >= 0, "CharacterController configuration: Movement.SnapsToGroundDistance needs to be either 0 or more")

local function defaultParams(...: Instance?)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.IgnoreWater = true
	p.RespectCanCollide = true
	p.FilterDescendantsInstances = {...}
	p.CollisionGroup = config.CollisionGroup or "Default"
	return p
end

local sensormodule = {}
sensormodule.Params = defaultParams()
sensormodule.SkipNextSnap = 0

--Updates the ground sensor of the given manager
--Returned <code>ControllerBase</code> is to be set to the managers active controller
function sensormodule.update(manager: types.ControllerManagerHierarchy, humanoid: Humanoid): ControllerBase
	local sensor = manager.GroundSensor :: ControllerPartSensor
	local root = manager.RootPart

	local dir = (-manager.UpDirection) * (sensor.SearchDistance + config.SnapsToGroundDistance)
	local result =
		workspace:Raycast(root.Position, dir, sensormodule.Params) --using raycast for now cuz it saves performance
		--workspace:Blockcast(root.CFrame, Vector3.new(0.5, 1, 0.5), dir, sensormodule.Params)

	if result and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
		local normal = result.Normal
		
		sensor.SensedPart = result.Instance
		sensor.HitNormal = normal
		sensor.HitFrame = CFrame.new(result.Position)

		if result.Distance > sensor.SearchDistance
			and normal:Dot(Vector3.yAxis) > 0
			and humanoid.Jump == false
		then --Makes player stick to surfaces below 90 degrees
			if sensormodule.SkipNextSnap == 0 then
				root.AssemblyLinearVelocity -= Vector3.yAxis * (result.Distance * 10)
			else
				sensormodule.SkipNextSnap -= 1
				return manager.AirController
			end
		end

		return manager.GroundController
	else
		sensor.SensedPart = nil
		
		return manager.AirController
	end
end

--Calls the local defaultParams function with the given instances and sets it to the params
function sensormodule.setParamsToDefault(...: Instance)
	sensormodule.Params = defaultParams(...)
end

return sensormodule
