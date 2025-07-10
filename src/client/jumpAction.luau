local debounce = require("../lib/debounce")
local config = require("../configuration").Movement

local jumpDebounce = debounce.new(config.JumpDebounceTime, true)

local jump = {}
jump.CanJump = config.CanJump

jump.JumpPower = if config.JumpPower == "HUMANOID" then nil else config.JumpPower :: number?
jump.MaxJumps = config.MaxJumps
jump.JumpCount = 0

jump._requested = false

--<code>Humanoid.JumpHeight</code> is not supported
--Should be called when the humanoid state type is "Jumping"
--Doesn't call <code>jump.ableToJump()</code>, this should be called in state handling manually
function jump.jump(manager: ControllerManager, humanoid: Humanoid)
	jump.forceJump(manager, jump.JumpPower or humanoid.JumpPower)
	
	jump.JumpCount += 1
	jumpDebounce:Reset()
end

--Resets the jump count
function jump.reset()
	jump.JumpCount = 0
end

--Jumps the player regardless of any external logic
function jump.forceJump(manager: ControllerManager, jumpPower: number)
	local root = manager.RootPart
	
	local velocity = root.AssemblyLinearVelocity
	local jumpingDir = manager.UpDirection * jumpPower
	
	root.AssemblyLinearVelocity = Vector3.new(
		velocity.X + jumpingDir.X,
		jumpingDir.Y,
		velocity.Z + jumpingDir.Z
	)

	--floor receives equal and opposite force
	--TAG:UNNECESSARY
	local groundSensor = manager.GroundSensor
	local floor = groundSensor.SensedPart
	if floor then
		floor:ApplyImpulseAtPosition(-jumpingDir, groundSensor.HitFrame.Position)
	end
end

function jump.forceJumpUp(manager: ControllerManager, jumpPower: number)
	local jumpDir = Vector3.new(0, jumpPower, 0)
	
	manager.RootPart.AssemblyLinearVelocity = jumpDir

	--floor receives equal and opposite force
	--TAG:UNNECESSARY
	local groundSensor = manager.GroundSensor
	local floor = groundSensor.SensedPart
	if floor then
		floor:ApplyImpulseAtPosition(-jumpDir, groundSensor.HitFrame.Position)
	end
end

function jump.ableToJump(): boolean
	local req, count = jump._requested, jump.JumpCount
	jump._requested = false
	return (if count > 0 then req else true)
		and count < jump.MaxJumps
		and jumpDebounce:IsReady()
		and jump.CanJump
end

return jump
