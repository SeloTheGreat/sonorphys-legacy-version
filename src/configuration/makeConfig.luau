--!strict

local function deepCopy(t: {[any]: any})
	local copy = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function reconcile(target: {[any]: any}, template: {[any]: any})
	for k, v in pairs(template) do
		if type(k) == "string" then
			if target[k] == nil then
				if type(v) == "table" then
					target[k] = deepCopy(v)
				else
					target[k] = v
				end
			elseif type(target[k]) == "table" and type(v) == "table" then
				reconcile(target[k], v)
			end
		end
	end
end
--> ↑ snippet from ProfileStore -→ https://github.com/MadStudioRoblox/ProfileStore/blob/main/ProfileStore.luau

local types = require("../types")

local conf = {}
conf.default = {
	Meta = {
		UpdateRate = 1,
		UpdateEvent = "BoundRenderStepped"
	},
	
	EnableDebug = {
		EnableRays = {"Velocity", "RootAxis"},
		RayLineLength = 5,

		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,

		LabelBackgroundTransparency = 1,
		LabelBackgroundColor3 = Color3.new(1,1,1),
		LabelYAxisSize = 20,
		LabelXAxisScale = 1
	},

	LimbParts = {
		CustomPhysicalProperties = PhysicalProperties.new(
			0.7,
			0.3,
			0,
			1,
			100
		)
	},

	Movement = {
		DisabledSpeedStates = { "Skid" },

		MoveSpeedRanges = {
			Mach1 = 34,
			Mach2 = 54
		},

		MinimumMovingSpeed = 16,
		BaseMoveSpeed = 54,
		BaseTurnSpeed = 16,

		CanJump = true,
		MaxJumps = 1,
		JumpPower = "HUMANOID",
		JumpDebounceTime = 0.08,
		FallingOffLedgesConsumesAJump = true,

		SlopeFrictionEnabled = true,
		FrictionTolerance = 0.9,
		MinimumFriction = 0,
		FrictionAngleFactor = 1,
		FrictionRecoveryRate = 8,
		FrictionLossRate = 12,

		MaxAngle = 180,
		UseHumanoidWalkspeed = false,
		UseSimpleSpeedometer = false,
		
		UpDirectionIsAlwaysAligned = false,
		UpDirectionLerpFactor = 10,
		UseMovingDirectionForFacingDirection = false,

		--Acceleration and deceleration rates are multiplied by deltaTime
		--Acceleration/Deceleration Factor affects air and ground acceleration/deceleration
		CanAccelerateAirborne = true,
		
		AccelerationRate = 0.24,
		DecelerationRate = 0.8,
		
		AccelerationUpAngleTolerance = "COPY",
		AirborneAccelerationFactor = 0.5,
		DecelerationSharpTurnFactor = 1.6,
		SpeedOvershootCorrectionFactor = 5,
		SpeedRecoveryAfterSharpTurn = 0.8,

		MaxSustainedSkidTime = 0.08,
	},

	GroundSensor = {
		SearchDistance = "+2",

		IgnoredInstanceDescendants = {},
		CollisionGroup = "Default",
		SnapsToGroundDistance = 0.5
	},

	GroundController = {
		--GroundOffset: "HUMANOID" makes the controller use Humanoid.HipHeight, 2 studs is the height of a roblox r6 rigs leg.
		GroundOffset = 2,
	},

	AirController = {
		-- Increasing this number means that directional inputs will influence the character's moving direction more powerfully
		MoveMaxForce = 1000,
		TurnMaxTorque = 10000
	},
} :: SONORphysConfiguration

function conf.get(sonorphysconf: SONORphysConfiguration?): SONORphysConfiguration
	if not sonorphysconf then
		return conf.default
	end
	
	reconcile(sonorphysconf, conf.default)
	
	return sonorphysconf
end

export type SONORphysConfiguration = {
	Meta: {
		UpdateRate: number,
		UpdateEvent: "BoundRenderStepped"
		|"PreSimulation"
		|"PostSimulation"
		|"PreRender"
		|"PreAnimation"
		|"Heartbeat"
	},

	EnableDebug: {
		EnableRays: { ("Velocity"|"Moving"|"RootAxis")? }|boolean,
		RayLineLength: number?,

		HorizontalAlignment: Enum.HorizontalAlignment?,
		VerticalAlignment: Enum.VerticalAlignment?,

		LabelBackgroundTransparency: number?,
		LabelBackgroundColor3: Color3?,
		LabelYAxisSize: number?,
		LabelXAxisScale: number?
	}|boolean,

	LimbParts: {
		[string]: any?
	},

	Movement: {
		DisabledSpeedStates: {
			types.SpeedStateEnum?
		},

		MoveSpeedRanges: { 
			[string|"Idle"|"Max"]: number
		},

		MinimumMovingSpeed: number,
		BaseMoveSpeed: number,
		BaseTurnSpeed: number,

		CanJump: boolean,
		MaxJumps: number,
		JumpPower: number|"HUMANOID",
		JumpDebounceTime: number,
		FallingOffLedgesConsumesAJump: boolean,

		SlopeFrictionEnabled: boolean,
		FrictionTolerance: number,
		MinimumFriction: number,
		FrictionAngleFactor: number,
		FrictionRecoveryRate: number,
		FrictionLossRate: number,

		MaxAngle: number,

		UseHumanoidWalkspeed: boolean,
		UseSimpleSpeedometer: boolean,

		UpDirectionIsAlwaysAligned: boolean,
		UpDirectionLerpFactor: number,
		UseMovingDirectionForFacingDirection: boolean,

		CanAccelerateAirborne: boolean,

		AccelerationRate: number,
		DecelerationRate: number,

		AccelerationUpAngleTolerance: "COPY"|number,
		AirborneAccelerationFactor: number,
		DecelerationSharpTurnFactor: number,
		SpeedOvershootCorrectionFactor: number, 
		SpeedRecoveryAfterSharpTurn: number,

		MaxSustainedSkidTime: number,
	},

	GroundSensor: {
		SearchDistance: string|number,

		IgnoredInstanceDescendants: { Instance? },
		CollisionGroup: "Default"|string,
		SnapsToGroundDistance: number
	},

	GroundController: {
		GroundOffset: (number|"HUMANOID")?,
		[string]: any?
	},

	AirController: {
		[string]: any?
	},
}

return conf