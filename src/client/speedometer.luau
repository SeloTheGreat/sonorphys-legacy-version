--!optimize 2
--!native

local Controller = require("../lib/fastAccessPlayerModule"):GetControls()
local numberGroup = require("../lib/group/numberGroup")
local priorityGroup = require("../lib/group/priorityGroup")
local config = require("../configuration").Movement
local types = require("../types")

--UPVALUES
local prevSpeed = 0
local prevMoveDirection = Vector3.zero
local prevFacingDirection = Vector3.zAxis
local skidSustain = false
local skidSustainedTime = 0

local function clampOvershoot(n: number, nMax: number, nMinMin: number, unitTime: number): number
	return if n <= nMax then math.max(n, nMinMin)
		else math.lerp(n, nMax, unitTime)
end

local function normalize(x: number, xMin: number, xMax: number): number
	return (x - xMin) / (xMax - xMin)
end

--Bi-directional snap
local function snapVectorOnY(normal: Vector3): Vector3
	return normal:Dot(Vector3.yAxis) > 0 and Vector3.yAxis or -Vector3.yAxis
end

--shifts the table forward
local function insertAt(t: {any}, v: any, pos: number)
	local clone = table.clone(t) --idk about cloning
	for i = pos, #t do
		t[i+1] = clone[i]
	end
	t[pos] = v
end

local speedometer = {}

speedometer.MaxSpeed = 1
speedometer.MinSpeed = 0
speedometer.MinMovingSpeed = normalize(config.MinimumMovingSpeed, 0, config.BaseMoveSpeed) --Applies when the player is moving/accelerating

speedometer.SpeedRanges = (function()
	local idle, max = {"Idle", 0}, {"Max", math.huge}
	local ranges = { idle, max }
	
	local _maxSpd = config.BaseMoveSpeed
	for i, v in config.MoveSpeedRanges do
		if i == "Idle" then
			idle[2] = normalize(v, 0, _maxSpd) ; continue
		elseif i == "Max" then
			max[2] = normalize(v, 0, _maxSpd) ; continue
		end
		table.insert(ranges, {i, normalize(v, 0, _maxSpd)})
	end
	
	table.sort(ranges, function(a, b)
		return a[2] < b[2]
	end)
	
	return ranges
end)()

speedometer.AccelerationRate = config.AccelerationRate
speedometer.DecelerationRate = config.DecelerationRate

speedometer.CanAccelAirborne = config.CanAccelerateAirborne

speedometer.AirborneAccelFactor = config.AirborneAccelerationFactor
speedometer.AccelUpAngleTolerance = if config.AccelerationUpAngleTolerance == "COPY" then config.FrictionTolerance else config.AccelerationUpAngleTolerance
speedometer.DecelSharpTurnFactor = config.DecelerationSharpTurnFactor
speedometer.SpeedOvershootCorrectionFactor = config.SpeedOvershootCorrectionFactor
speedometer.SharpTurnSpeedRecovery = config.SpeedRecoveryAfterSharpTurn
speedometer.MaxSkidTime = config.MaxSustainedSkidTime

speedometer.State = "Idle" :: types.SpeedStateEnum
speedometer.Speed = 0

speedometer.SpeedOverride = priorityGroup(nil, 0) :: priorityGroup.PriorityVariable<number?>
speedometer.MoveDirOverride = priorityGroup(nil, 0) :: priorityGroup.PriorityVariable<Vector3?>
speedometer.SustainedSpeed = numberGroup(0) --Added to finalSpeed

--Module entry
local speedStates = {
	disabled = (function()
		local t = {}
		for i, v in ipairs(config.DisabledSpeedStates) do
			t[v] = true
		end
		return t
	end)(),
	
	--Order of these tables matter!!
	{
		name = "Idle",
		isApplicable = function(info: types.SpeedometerInfo): boolean
			return speedometer.Speed == speedometer.MinSpeed and info.MovingMagnitude == 0
		end,
		apply = function(info: types.SpeedometerInfo, dt: number): (number, Vector3?)
			return 0, Vector3.zero
		end,
	},

	{
		name = "Skid",
		isApplicable = function(info: types.SpeedometerInfo): boolean
			return info.Grounded and (info.MadeSharpTurn or skidSustain)
		end,
		apply = function(info: types.SpeedometerInfo, dt: number): (number, Vector3?)
			skidSustain = true

			local min = speedometer.MinSpeed

			local spd = math.clamp(info.Speed - ((speedometer.DecelerationRate * speedometer.DecelSharpTurnFactor) * dt),
				min, speedometer.MaxSpeed
			)

			if spd == min then --Reached stop
				if skidSustainedTime >= speedometer.MaxSkidTime then
					prevMoveDirection = Vector3.zero --reset this too!
					speedometer.resetSkid_()

					return prevSpeed * speedometer.SharpTurnSpeedRecovery, nil
				end

				skidSustainedTime += dt --skid stop delay
			end

			return spd, prevFacingDirection
		end,
	},

	{
		name = "Walk",
		isApplicable = function(info: types.SpeedometerInfo): boolean
			return info.MovingMagnitude > 0 and info.MovingMagnitude <= 0.95
		end,
		apply = function(info: types.SpeedometerInfo, dt: number): (number, Vector3?)
			return speedometer.MinMovingSpeed * info.MovingMagnitude, nil
		end,
	},

	{
		name = "Deceleration",
		isApplicable = function(info: types.SpeedometerInfo): boolean
			return info.MovingMagnitude == 0
		end,
		apply = function(info: types.SpeedometerInfo, dt: number): (number, Vector3?)
			local manager = info.Manager
			local upDir = manager.GroundSensor.HitNormal
			local upDirMul = 1 + upDir:Dot(Vector3.yAxis) --get the deceleration factor of the slope
			--knowing if the player is going up or down doesn't matter here
			local spd = math.clamp(info.Speed - ((speedometer.DecelerationRate * upDirMul) * dt),
				speedometer.MinSpeed, speedometer.MaxSpeed
			)

			speedometer.resetSkid_()

			return spd, info.Grounded and prevFacingDirection
		end,
	},

	{
		name = "Acceleration",
		isApplicable = function(info: types.SpeedometerInfo): boolean
			return info.MovingMagnitude > 0.95
		end,
		apply = function(info: types.SpeedometerInfo, dt: number): (number, Vector3?)
			local manager = info.Manager

			local spd = 0

			if speedometer.CanAccelAirborne or info.Grounded then --Accelerate if grounded
				local upDirMul = 1
				local upDir = manager.GroundSensor.HitNormal

				local dotp = upDir:Dot(snapVectorOnY(upDir)) --get the angle of the surface
				if dotp < speedometer.AccelUpAngleTolerance then --check if the ground is flat (or below tolerance)
					local _upDirAngle = math.max(1 - dotp, 0) --get the factor of the slope, former formula: math.max(math.acos(-upDir.Y) / math.pi, minMoving)
					upDirMul = if manager.MovingDirection:Dot(upDir) < 0 then _upDirAngle else 1 + _upDirAngle --decide if the player is going up or down the slope
				end
				
				local add = if info.Speed > speedometer.MaxSpeed
					then 0
					else speedometer.AccelerationRate
						* upDirMul
						* (not info.Grounded and speedometer.AirborneAccelFactor or 1)
						* dt
					
				spd = clampOvershoot(info.Speed + add,
					speedometer.MaxSpeed, speedometer.MinMovingSpeed, speedometer.SpeedOvershootCorrectionFactor * dt
				)
			else
				spd = math.clamp(info.Speed, speedometer.MinMovingSpeed * 1.5, speedometer.MaxSpeed)
			end
			
			speedometer.resetSkid_()
			
			prevFacingDirection = manager.MovingDirection
			--[[prevMoveDirection = if info.MovingMagnitude == 0
				then workspace.CurrentCamera.CFrame:VectorToObjectSpace(manager.RootPart.CFrame.LookVector)
				else moving --Set last moving direction]] --idk this is kinda stupid lol i remvoed it cuz why not lol lol okz<lads
			prevMoveDirection = Controller:GetMoveVector()
			prevSpeed = spd --Set last speed

			return prevSpeed, nil
		end,
	}
} :: {
	[number]: types.SpeedState,
	disabled: {[types.SpeedStateEnum]: boolean?}
}

local SPEEDOMETER_INFO: types.SpeedometerInfo = {
	Manager = nil,
	MadeSharpTurn = false,
	Grounded = true,
	Speed = 1,
	MovingMagnitude = 0
}

--Returns a number to set MoveSpeedFactor on controllers to
--Only mutates the properties "Speed" and "State"
--Changes acceleration based on UpDirection
function speedometer.step(dt: number, manager: types.ControllerManagerHierarchy): (number, Vector3?)
	--[[Override!
	do
		local spdOverride, moveOverride = speedometer.SpeedOverride, speedometer.MoveDirOverride
		if spdOverride or moveOverride then
			speedometer.Speed = spdOverride
			speedometer.State = basicState(spdOverride, speedometer.MinSpeed)
			
			prevMoveDirection = moveOverride or manager.MovingDirection
			prevFacingDirection = manager.FacingDirection
			prevSpeed = spdOverride or speedometer.Speed
			
			skidSustain = false
			skidSustainedTime = 0
			
			return prevSpeed, prevMoveDirection
		end
	end]] --got rid of it :/

	local moveVector = Controller:GetMoveVector()
	SPEEDOMETER_INFO.Manager,
		SPEEDOMETER_INFO.MadeSharpTurn,
		SPEEDOMETER_INFO.Grounded,
		SPEEDOMETER_INFO.Speed,
		SPEEDOMETER_INFO.MovingMagnitude =
			manager,
			prevMoveDirection:Dot(moveVector) < -0.5 and speedometer.Speed > speedometer.MinMovingSpeed,
			manager.ActiveController == (manager.GroundController :: GroundController),
			speedometer.Speed,
			moveVector.Magnitude

	local disabled = speedStates.disabled
	for i, v in ipairs(speedStates) do
		if disabled[v.name] then continue end
		if v.isApplicable(SPEEDOMETER_INFO) then
			local spd, move = v.apply(SPEEDOMETER_INFO, dt)

			speedometer.Speed = spd
			speedometer.State = v.name
			
            --TODO: possibly change this to always be sustained
			local sustained = v.name == "Acceleration" and speedometer.SustainedSpeed:sum() or 0
			--this is dumb because the name implies it is always added but im a dumnb gay idiot --IM NOT GAY WTF?!?!? --nevermind i am
			
			return speedometer.SpeedOverride:result() or (spd + sustained), speedometer.MoveDirOverride:result() or move
		end
	end
	
	return speedometer.SpeedOverride:result() or speedometer.MinMovingSpeed, speedometer.MoveDirOverride:result()
end

--Uses the SpeedRanges table property
--if no speed is given, the .Speed property is used
function speedometer.getMach(normalized_speed: number?): string
	normalized_speed = normalized_speed or speedometer.Speed
	local ranges = speedometer.SpeedRanges
	
	for i, v in ipairs(ranges) do
		if normalized_speed <= v[2] then
			return v[1]
		end
	end

    return ranges[1][1]
end

--<code>value</code> must either be a normalized number or nil
--if nil, the mach state with the given name is deleted
function speedometer.setMach(name: string, value: number?)
	if not value then
		for i, v in ipairs(speedometer.SpeedRanges) do
			if v[1] == name then
				table.remove(speedometer.SpeedRanges, i)
				return
			end
		end
	end

	for i, v in ipairs(speedometer.SpeedRanges) do
		if value == v[2] then
			v.name = name
			return
		elseif value < v[2] then
			insertAt(speedometer.SpeedRanges, {name, value}, i)
			return
		end
	end
end

--Normalizes given number based on max and min speed
function speedometer.normalize(speed: number): number
	return normalize(speed, 0, config.BaseMoveSpeed)
end

function speedometer.setSpeedStateEnabled(speedState: types.SpeedStateEnum, enabled: boolean)
	speedStates.disabled[speedState] = (not enabled) or nil
end

--idk you dont need to use tihs
function speedometer.resetSkid_()
	skidSustain = false --reset ← ↓
	skidSustainedTime = 0
end

return speedometer
