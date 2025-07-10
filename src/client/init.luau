local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local config = require("./configuration")
local mconfig = config.Movement
local replication = require("./_replication")
local types = require("./types")

local sensor = require("@self/groundSensor")
local stateUpdater = require("@self/humanoidState")
local jumpAction = require("@self/jumpAction")
local physics = require("@self/physicsSteps")
local speedometer = require("@self/speedometer")

local characterUtil = require("./lib/characterUtil")
local unhook = require("./lib/unhook")
local functionGroup = require("./lib/group/functionGroup")

local waitingThreads = {}
local _last = os.clock()

local RENDERSTEP_NAME = "Controller.Step"

local controller = {}
controller.vectorSwizzle = require("./lib/swizzler")

controller.character = nil :: Model?
controller.humanoid = nil :: Humanoid?
controller.root = nil :: BasePart?
controller.manager = nil :: types.ControllerManagerHierarchy?

controller.PreUpdate = functionGroup() :: functionGroup.FunctionGroup<number>
controller.PostUpdate = functionGroup() :: functionGroup.FunctionGroup<number>
controller.OnDeath = functionGroup()

controller.jumpAction = jumpAction
controller.physics = physics
controller.speedometer = speedometer
controller.groundSensor = sensor

controller.isLoaded = false

controller.config = {
	BoundEvent = config.Meta.UpdateEvent,
	Rate = config.Meta.UpdateRate,
	FallingOffLedgesConsumesAJump = mconfig.FallingOffLedgesConsumesAJump,
	UseSimpleSpeedometer = mconfig.UseSimpleSpeedometer,
	UseHumanoidWalkspeed = mconfig.UseHumanoidWalkspeed
}

controller._hooks = {}

function controller.initBasicReplication(): RBXScriptConnection
	--Client-Server interactions
	replication.client_callback = function(sender, packet)
		local h = characterUtil.getHumanoid(sender)
		h:ChangeState(packet.State)
		h.Health = if packet.Health then h.MaxHealth else 0
	end

	return replication.ReplicationEvent.OnClientEvent:Connect(replication.client_receive)
end

--Should be called first
--Hooks up connections and initializes variables
function controller.init(): typeof(controller)
	local character, humanoid, root = characterUtil.getComponents()
	local manager = characterUtil.getController()

	controller.humanoid = humanoid
	controller.character = character
	controller.root = root
	controller.manager = manager

	sensor.setParamsToDefault(character, table.unpack(config.GroundSensor.IgnoredInstanceDescendants))

	table.insert(controller._hooks, humanoid.StateChanged:Connect(function(old, new)	
		--Handle jumping
		if new == Enum.HumanoidStateType.Jumping then
			jumpAction.jump(manager, humanoid)
		elseif new == Enum.HumanoidStateType.Landed then
			jumpAction.reset()
		elseif old == Enum.HumanoidStateType.Running and new == Enum.HumanoidStateType.Freefall then
			if controller.config.FallingOffLedgesConsumesAJump then
				jumpAction.JumpCount += 1
			end
		end

		replication.ReplicationEvent:FireServer(replication.uni_encode(humanoid)) --replicate
	end))
	
	table.insert(controller._hooks, UserInputService.JumpRequest:Connect(function()
		jumpAction._requested = true
	end))
	
	table.insert(controller._hooks, humanoid.HealthChanged:Connect(function(health)
		replication.ReplicationEvent:FireServer(replication.uni_encode(humanoid)) --replicate
	end))
	
	table.insert(controller._hooks, root.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			humanoid.Health = 0
		end
	end))

	--main step function
	local bound = controller.config.BoundEvent
	
	if bound == "BoundRenderStepped" then
		RunService:BindToRenderStep(RENDERSTEP_NAME, Enum.RenderPriority.Last.Value, controller.step)
	else
		table.insert(controller._hooks, RunService[bound]:Connect(controller.step))
	end

	--Resume waiting threads
	for i, v in ipairs(waitingThreads) do
		task.spawn(v, controller)
	end
	table.clear(waitingThreads)
	
	controller.isLoaded = true

	return controller
end

--Unhooks the controller and sets character values to nil
function controller.uninit()
	if controller.config.BoundEvent == "BoundRenderStepped" then
		RunService:UnbindFromRenderStep(RENDERSTEP_NAME)
	end
	unhook(controller._hooks)

	controller.isLoaded = false

	sensor.setParamsToDefault()
	controller.character, controller.humanoid, controller.root, controller.manager =
		nil, nil, nil, nil
end

--Ran every RenderStepped
function controller.step(dt: number)
	local _conf = controller.config
	
	if _conf.Rate < 1 then
		local newTime = os.clock()
		local elapsed = newTime - _last
		if elapsed < dt / _conf.Rate then
			return
		end
		dt = elapsed --set delta time to the actual elapsed time
		_last = newTime
	end
	
	local manager = controller.manager
	local hum = controller.humanoid

	debug.profilebegin("Controller:PreUpdate")

	controller.PreUpdate:run(dt)

	debug.profileend()
	debug.profilebegin("Controller:Step")

	manager.ActiveController = sensor.update(manager, hum) --update controller

	local newState = stateUpdater.update(manager, hum)
	hum:ChangeState(newState) --update state

	local groundController = manager.GroundController --cache i guess

	manager.MovingDirection, manager.FacingDirection, manager.UpDirection, groundController.Friction
		= physics.step(dt, manager, hum) --update physics

	if _conf.UseHumanoidWalkspeed then
		manager.BaseMoveSpeed = hum.WalkSpeed
		
		if manager.MovingDirection == Vector3.zero then
			manager.AirController.MoveSpeedFactor, groundController.MoveSpeedFactor = 0, 0
		else
			manager.AirController.MoveSpeedFactor, groundController.MoveSpeedFactor = 1, 1
		end
	elseif _conf.UseSimpleSpeedometer then
		if manager.MovingDirection == Vector3.zero then
			manager.AirController.MoveSpeedFactor, groundController.MoveSpeedFactor = 0, 0
		else
			manager.AirController.MoveSpeedFactor, groundController.MoveSpeedFactor = 1, 1
		end
	else
		local speedfactor, override = speedometer.step(dt, manager) --update speed and related

		physics.MoveDirOverride = override
		manager.AirController.MoveSpeedFactor, groundController.MoveSpeedFactor
			= speedfactor, speedfactor
	end

	debug.profileend()
	debug.profilebegin("Controller:PostUpdate")

	controller.PostUpdate:run(dt)

	debug.profileend()

	if newState == Enum.HumanoidStateType.Dead then
		replication.ReplicationEvent:FireServer(replication.uni_encode(hum))
		controller.OnDeath:run()
		controller.uninit()
	end
	--Got rid of frame by frame replication, this used to be an unreliable remote event
	--replication.ReplicationEvent:FireServer(replication.uni_encode(hum)) --update state for other players
end

--Yields the thread until controller initalizes
function controller.waitUntilLoaded(): typeof(controller)
	if controller.isLoaded then
		return controller
	end
	table.insert(waitingThreads, coroutine.running())
	return coroutine.yield()
end

--Returns the character, humanoid, root part and manager
function controller.getCharComponents(): (Model?, Humanoid?, BasePart?, types.ControllerManagerHierarchy?)
	return controller.character, controller.humanoid, controller.root, controller.manager
end

--Returns active controllers speed
function controller.getSpeed(): number
	return controller.manager.ActiveController.MoveSpeedFactor
end

function controller.getMoving(): Vector3
	return controller.manager.MovingDirection
end

function controller.isGrounded(): boolean
	local manager = controller.manager
	return manager.ActiveController == manager.GroundController
end

--if threshold is nil, 1 is used as it instead
function controller.isSlipping(threshold: number?): boolean
	return controller.manager.GroundController.Friction < (threshold or 1)
end

return controller