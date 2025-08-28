--!optimize 2

local swizzle = require("../lib/swizzler")
local speedometer = require("./speedometer")
local config = require("../configuration").Movement
local types = require("../types")

--flatten a vector given vector and normal
--source: https://devforum.roblox.com/t/how-to-prevent-player-getting-stuckglitching-when-pushing-towards-a-wall/2274780/17 
@native local function flattenVectorAgainstNormal(moveVector: Vector3, normal: Vector3): Vector3
	if moveVector == Vector3.zero then
		return Vector3.zero
	end

	local reflected = moveVector - 2 * moveVector:Dot(normal) * normal
	local parallel = moveVector + reflected

	if parallel == Vector3.zero then
		return Vector3.zero
	end

	local _unit = parallel.Unit
	local cropped = _unit:Dot(moveVector) * _unit * moveVector.Magnitude
	return cropped
end

@native local function alignWithAxis(moveVector: Vector3, normal: Vector3, edgecase: Vector3): Vector3
	local divpi, upAngle = math.pi/2, math.acos(normal.Y)
	return if upAngle - 0.1 <= divpi and upAngle + 0.1 >= divpi then edgecase
		elseif upAngle > divpi then Vector3.new(moveVector.X, -moveVector.Y, -moveVector.Z)
		else moveVector
end

local physics = {}
physics.MoveDirOverride = nil :: Vector3?

physics.MaxAngle = config.MaxAngle

physics.UpDirIsAligned = config.UpDirectionIsAlwaysAligned
physics.UpDirLerpFactor = config.UpDirectionLerpFactor
physics.UseMovingDirForFacing = config.UseMovingDirectionForFacingDirection

physics.FrictionEnabled = config.SlopeFrictionEnabled
physics.FrictionAngleFactor = config.FrictionAngleFactor
physics.FrictionRecoveryRate = config.FrictionRecoveryRate
physics.FrictionLossRate = config.FrictionLossRate
physics.MinFriction = config.MinimumFriction
physics.FrictionTolerance = config.FrictionTolerance

--Returns:
--> MovingDirection
--> FacingDirection
--> UpDirection
--> Friction
@native function physics.step(dt: number, manager: types.ControllerManagerHierarchy, humanoid: Humanoid): (Vector3, Vector3, Vector3, number)
	local root: BasePart = manager.RootPart
    
	local hitNormal: Vector3 = manager.GroundSensor.HitNormal
	local isGrounded: boolean = manager.GroundController == manager.ActiveController

	--Moving direction, apply the humanoid move dir
	local moving: Vector3 = swizzle.getApplied(
		physics.MoveDirOverride or humanoid.MoveDirection
	)
	
	--Get up direction
	local upDir = if isGrounded and not physics.UpDirIsAligned
		then manager.UpDirection:Lerp(hitNormal, dt * physics.UpDirLerpFactor)
		else Vector3.yAxis
	
	--Get facing direction
	local facingDir = (moving ~= Vector3.zero)
		and (isGrounded and alignWithAxis(moving, upDir, root.CFrame.LookVector) or moving) --((isGrounded and not physics.UseMovingDirForFacing) and root.AssemblyLinearVelocity.Unit or moving)
		or root.CFrame.LookVector
	
	--Lowers friction if the player is not fast enough for a slope
	local friction = 2
	
	--handle max angle and friction
	local upAngle = math.acos(hitNormal.Y)
	
	if physics.MaxAngle < 180
		and upAngle > math.rad(physics.MaxAngle)
		and moving:Dot(upDir) <= 0
	then
		--modify moving here after setting facing dir bcuz we wanna override
		local oldMoving = moving
		moving = flattenVectorAgainstNormal(moving, Vector3.new(hitNormal.X, 0, hitNormal.Z).Unit)
		facingDir = oldMoving
		friction = 0.9
	else
		--modify friction here
		if physics.FrictionEnabled and isGrounded and speedometer.State ~= "Skid" then --check for skid cuz mh
			local baseMoveSpeed = manager.BaseMoveSpeed
			local spd = baseMoveSpeed * manager.ActiveController.MoveSpeedFactor

			local velocityAngle = math.map(spd,
				0, baseMoveSpeed,
				0, math.pi
			) * physics.FrictionAngleFactor

			if hitNormal:Dot(Vector3.yAxis) < physics.FrictionTolerance and upAngle > velocityAngle then --check if the ground is flat (or below tolerance) and check if we are too slow
				friction = math.lerp(manager.GroundController.Friction,
					math.map(velocityAngle, 0, math.pi, physics.MinFriction, 2), --Map the angle to the friction value he goin
					physics.FrictionLossRate * dt
				)
			else
				friction = math.lerp(manager.GroundController.Friction, 2, physics.FrictionRecoveryRate * dt) --Recover friction
			end
		end
	end
	
	--Return data
	return moving, facingDir, upDir, friction
end

return physics
