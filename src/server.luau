local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local configuration = require("./configuration")
local replication = require("./_replication")
local charUtil = require("./lib/characterUtil")
local unhook = require("./lib/unhook")

local deathThreads = {} --muheehehehe >:]

local function getHipHeight(humanoid: Humanoid): number
	return if configuration.GroundController.GroundOffset == "HUMANOID" then humanoid.HipHeight
		else configuration.GroundController.GroundOffset
end

local function getSearchDistance(dist: string|number, humanoid: Humanoid): number	
	if type(dist) == "string" then
		if dist:sub(1, 1) == "+" then
			return getHipHeight(humanoid) + tonumber(dist:sub(2, -1))
		else
			return tonumber(dist)
		end
	else
		return dist
	end
end

local function createControllerManager(root: BasePart): ControllerManager
	local ControllerManager = Instance.new("ControllerManager")

	ControllerManager.RootPart = root

	ControllerManager.BaseMoveSpeed = configuration.Movement.BaseMoveSpeed
	ControllerManager.BaseTurnSpeed = configuration.Movement.BaseTurnSpeed
	ControllerManager.FacingDirection = root.CFrame.LookVector

	return ControllerManager
end

local function createGroundSensor(humanoid: Humanoid): ControllerPartSensor
	local groundSensor = Instance.new("ControllerPartSensor")
	groundSensor.Name = "GroundSensor"

	groundSensor.SensorMode = Enum.SensorMode.Floor
	groundSensor.UpdateType = Enum.SensorUpdateType.Manual
	groundSensor.SearchDistance = getSearchDistance(configuration.GroundSensor.SearchDistance, humanoid)
	
	return groundSensor
end

local function createControllers(humanoid: Humanoid): (GroundController, AirController)
	local groundController = Instance.new("GroundController")
	groundController.BalanceRigidityEnabled = true -- Keeps the character upright on the ground.
	
	for i, v in configuration.GroundController do
		groundController[i] = v
	end
	groundController.GroundOffset = getHipHeight(humanoid) --Override
	groundController.MoveSpeedFactor = 0 --This is handled by Speedometer
	
	local airController = Instance.new("AirController")
	airController.MaintainLinearMomentum = true 
	-- Setting this to true means that the character will keep its linear momentum given a directional input in the air. 
	airController.MaintainAngularMomentum = false
	-- Seting this to true means that the character will keep its angular momentum given a directional input. If you input A or D in the air, the character will keep on spinning around till it hits the ground.
	airController.BalanceRigidityEnabled = true
	
	for i, v in configuration.AirController do
		airController[i] = v
	end
	
	airController.MoveSpeedFactor = 0 --This is also handled by Speedometer

	return groundController, airController
end

local server = {}
server._hooks = {}

--Initiates the humanoid controller on the given character
function server.load(character: Model): ControllerManager
	assert(RunService:IsServer(), "Not in server")
	
	local humanoid, root, plr = charUtil.getComponentsFromCharacter(character)
	
	humanoid.EvaluateStateMachine = false --Stop default state machine
	
	wait() -- ensure post-load Humanoid computations are complete (such as hip height)
	
	humanoid:SetAttribute("FloorMaterial", Enum.Material.SmoothPlastic)
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
	
	local controllerManager = createControllerManager(root)
	
	local groundSensor = createGroundSensor(humanoid)
	local groundController, airController = createControllers(humanoid)
	
	groundSensor.Parent = groundController
	
	groundController.Parent = controllerManager
	airController.Parent = controllerManager
	
	--Assign sensors
	controllerManager.GroundSensor = groundSensor
	
	controllerManager.ActiveController = groundController
	controllerManager.Parent = character
	
	for i, v in ipairs(character:GetChildren()) do
		if v:IsA("BasePart") and humanoid:GetLimb(v) ~= Enum.Limb.Unknown then
			v:SetNetworkOwner(plr)
			for prop, conf in configuration.LimbParts do
				v[prop] = conf
			end
		end
	end
	
	return controllerManager
end

--Destroys the humanoid controller on the given player
function server.unload(player: Player)
	assert(RunService:IsServer(), "Not in server")
	
	local character, humanoid = charUtil.getComponents(player)

	humanoid.EvaluateStateMachine = true

	local controller = character:FindFirstChildOfClass("ControllerManager")
	if controller then
		controller:Destroy()
	end
end

--Creates neccessary connections, should be called first, and not called again
function server.init()
	assert(RunService:IsServer(), "Not in server")
	
	for i, v in ipairs(Players:GetPlayers()) do
		server.load(charUtil.getCharacter(v))
		v.CharacterAdded:Connect(server.load)
	end
	
	table.insert(server._hooks, Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(server.load)
	end))
	
	--replication handlers
	replication.server_callback = function(player, packet)
		if packet.State == Enum.HumanoidStateType.Dead and not deathThreads[player.UserId] then
			deathThreads[player.UserId] = task.delay(Players.RespawnTime, function()
				player:LoadCharacter()
				deathThreads[player.UserId] = nil
			end)
		end
	end
	
	table.insert(server._hooks,
		replication.ReplicationEvent.OnServerEvent:Connect(replication.server_receive)
	)
end

--Disconnects connections, can destroy controllers if wanted to
function server.uninit(undoControllers: boolean?)
	assert(RunService:IsServer(), "Not in server")
	
	unhook(server._hooks)
	
	if not undoControllers then return end
	
	for i, v in ipairs(Players:GetPlayers()) do
		server.unload(v)
	end
end

return server
