*Notice: UNFINISHED - W.I.P.*

# SONORphys - legacy version API

Setup guide:
> Acquire package (currently no package manager support)
>> Through [rbxm file](build/SONORphys.rbxm)
>
>> Through source ([rokit](https://github.com/rojo-rbx/rokit) required)
>> 1. `git clone https://github.com/SeloTheGreat/sonorphys-legacy-version.git`<br>
>> 2. `cd sonorphys-legacy-version`<br>
>> 3. `rokit install` <small>only installs rojo</small><br>
>> 4. `rojo build -o "build/SONORphys.rbxm"` <small>customize this command if you'd like to</small>
>
> Import rbxm into your project
>
> Place it within `ReplicatedStorage`
>
> And u are finished!

# Configuration

## How to make your configuration

Within the [`config`](src/configuration/init.luau) module

```luau
local conf = makeConfig.get {
	... config to provide ...
}

return conf
```

Simple as that

## Config Documentation

```luau
Meta: {
	UpdateRate: number, --[[
		Default: 1
		Desc: Decides how often the controller is stepped; the lower the number, the lower the update rate becomes
	]]
	UpdateEvent: "BoundRenderStepped" --[[
		Default: "BoundRenderStepped"
		Desc: Decises the update event used from 'RunService'
	]]
	|"PreSimulation"
	|"PostSimulation"
	|"PreRender"
	|"PreAnimation"
	|"Heartbeat"
},

EnableDebug: { --OPENS WITH: Alt+C
	EnableRays: { ("Velocity"|"Moving"|"RootAxis")? }|boolean, --[[
		Default: { "Velocity", "RootAxis" }
		Desc: Decides which debug rays are enabled, if set to 'false' no debug ray will be shown
	]]
	RayLineLength: number?, --[[
		Default: 5
		Desc: Length of the debug rays
	]]

	HorizontalAlignment: Enum.HorizontalAlignment?, --[[
		Default: HorizontalAlignment.Left
		Desc: The alignment of the debug ui horizontally
	]]
	VerticalAlignment: Enum.VerticalAlignment?, --[[
		Default: VerticalAlignment.Bottom
		Desc: The alignment of the debug ui vertically
	]]

	LabelBackgroundTransparency: number?, --[[ Default: 1 ]]
	LabelBackgroundColor3: Color3?, --[[ Default: White ]]
	LabelYAxisSize: number?, --[[ Default: 20 ]]
	LabelXAxisScale: number? --[[ Default: 1 ]]
}|boolean, --[[
	Default: table
	Desc: if set to 'false', debug mode will be unaccessable
]]

LimbParts: {
	[string]: any? --[[
		Default: {
			CustomPhysicalProperties = PhysicalProperties(
				elasticity=0,
				elasticityWeight=100
			)
		}
		Desc: Applies the given properties to the characters limb parts, can be left empty
	]]
},

Movement: {
	DisabledSpeedStates: { SpeedStateEnum? }, --[[
		Default: { "Skid" }
		Desc: Speed states that are disabled, these can be later enabled through code
	]]

	MoveSpeedRanges: { [string|"Idle"|"Max"]: number }, --[[
		Default: { Mach1 = 34, Mach2 = 54}
		Desc: Preset machs
	]]

	MinimumMovingSpeed: number, --[[
		Default: 16
		Desc: Minimum moving speed of the speedometer
	]]
	BaseMoveSpeed: number, --[[
		Default: 54
		Desc: Used as the maximum speed in the speedometer
	]]
	BaseTurnSpeed: number, --[[
		Default: 16
		Desc: Angular momentum (spinning)
	]]

	CanJump: boolean, --[[ Default: true ]]
	MaxJumps: number, --[[ Default: 1 ]]
	JumpPower: number|"HUMANOID", --[[
		Default: "HUMANOID"
		Desc: if "HUMANOID", humanoid.JumpPower is used instead
	]]
	JumpDebounceTime: number, --[[
		Default: 0.08
		Desc: Can't be changed after assigment, minimum wait time between each performed jump
	]]
	FallingOffLedgesConsumesAJump: boolean, --[[ Default: true ]]

	SlopeFrictionEnabled: boolean, --[[ Default: true ]]
	FrictionTolerance: number, --[[
		Default: 0.9
		Desc: Value between -1..1, Friction stays still stays 2 even if the surface is slightly tilted (if -1, friction never applies)
	]]
	MinimumFriction: number, --[[ Default: 0 ]]
	FrictionAngleFactor: number, --[[
		Default: 1
		Desc: If the number is bigger than 1, max angle increases. The opposite, max angle lowers, BUT this doesn't offer the same behaviour as MaxAngle
	]]
	FrictionRecoveryRate: number, --[[ Default: 8 ]]
	FrictionLossRate: number, --[[ Default: 12 ]]

	MaxAngle: number, --[[ Default: 180 ]]

	UseHumanoidWalkspeed: boolean, --[[
		Default: false
		Desc: overrides UseSimpleMovement, also disables speedometer (speedometer state also wont be updated), enable for custom speed behaviour,
	]]
	UseSimpleSpeedometer: boolean, --[[
		Default: false
		Desc: disables speedometer, 'BaseMoveSpeed' will be used
	]]

	UpDirectionIsAlwaysAligned: boolean, --[[
		Default: false
		Desc: aligned as with the yAxis <0, 1, 0>
	]]
	UpDirectionLerpFactor: number, --[[ Default: 10 ]]
	UseMovingDirectionForFacingDirection: boolean, --[[ Default: false ]]

	CanAccelerateAirborne: boolean, --[[ Default: true ]]

	AccelerationRate: number, --[[ Default: 0.24 ]]
	DecelerationRate: number, --[[ Default: 0.8 ]]

	AccelerationUpAngleTolerance: "COPY"|number, --[[
		Default: "COPY"
		Desc: the value "COPY" makes this use the friction tolerance value, value between -1..1
	]]
	AirborneAccelerationFactor: number, --[[ Default: 0.5 ]]
	DecelerationSharpTurnFactor: number, --[[
		Default: 1.6
		Desc: used for faster decelerating while skidding, multiplied by the deceleration rate
	]]
	SpeedOvershootCorrectionFactor: number, --[[
		Default: 5
		Desc: affects lerping back to max speed when the speed goes above max speed
	]]
	SpeedRecoveryAfterSharpTurn: number, --[[
		Default: 0.8
		Desc: how much of the speed is kept from the previous acceleration state after skidding
	]]

	MaxSustainedSkidTime: number, --[[
		Default: 0.08
		Desc: the more time, the more skid stop is delayed
	]]
},

GroundSensor: {
	SearchDistance: string|number, --[[
		Default: "+2"
		Desc: Adding a '+' prefix makes it add to the 'GroundOffset'
	]]

	IgnoredInstanceDescendants: { Instance? }, --[[ Default: { } ]]
	CollisionGroup: "Default"|string, --[[ Default: "Default" ]]
	SnapsToGroundDistance: number --[[
		Default: 0.5
		Desc: Can be disabled with setting it to 0
	]]
},

GroundController: {
	GroundOffset: (number|"HUMANOID")?, --[[ Default: 2 ]]
	[string]: any?
},

AirController: {
	[string]: any? --[[
		Default: {
			MoveMaxForce = 1000,
			TurnMaxTorque = 10000
		}
	]]
},
```

# Client

## Client [ Main ]

### Properties

```luau
client.vectorSwizzle
```
Mostly vestigial, returns the [`swizzler`](src/lib/swizzler.luau) object used in mutating the `MovingDirection` of the `ControllerManager`, also has a raw 'swizzle' function

```luau
client.character: Model?
client.humanoid: Humanoid?
client.manager: ControllerManager?
client.root: BasePart?
```
Properties are self explanatory, these properties are set after the client controller is initialized

```luau
client.PreUpdate: FunctionGroup<number>
client.PostUpdate: FunctionGroup<number>
```
`PreUpdate`: Runs before each step, passed in number is the 'deltaTime' argument<br>
`PostUpdate`: Runs after each step is completed, passed in number is the 'deltaTime' argument<br>
[FunctionGroup](API.md#functiongroup)

```luau
client.OnDeath: FunctionGroupa<>
```
Runs each time the character dies, [FunctionGroup](API.md#functiongroup)

```luau
client.isLoaded: boolean
```
Flags whether or not if the client controller is loaded

```luau
client.jumpAction: jumpAction
client.physics: physics
client.speedometer: speedometer
client.groundsensor: sensor
```
[`jumpAction`](API.md#jumpaction) - [`physics`](API.md#physics) - [`speedometer`](API.md#speedometer) - [`groundsensor`](API.md#groundsensor)

```luau
client.config: {
	BoundEvent: @config.Meta.UpdateEvent,
	Rate: @config.Meta.UpdateRate,
	FallingOffLedgesConsumesAJump = @config.Movement.FallingOffLedgesConsumesAJump,
	UseSimpleSpeedometer = config.Movement.UseSimpleSpeedometer,
	UseHumanoidWalkspeed = config.Movement.UseHumanoidWalkspeed
}
```
[`Configuration`](API.md#config-documentation)

### Functions

```luau
client.uninit(): ()
```
Disconnects *internally* bound events and sets the 'character', 'manager', 'humanoid' and 'root' properties to nil

```luau
client.waitUntilLoaded(): typeof(client)
```
Waits until the client controller is fully loaded through `client.init()`, this can be inlined when requiring the module since it returns the client controller, like: `require(SONORphys.client).waitUntilLoaded()`

```luau
client.getCharComponents(): (Model?, Humanoid?, BasePart?, types.ControllerManagerHierarchy?)
```
Utility function. Returns the character, humanoid, root part and manager

```luau
client.getSpeed(): number
```
Returns the current active controllers speed, for example if the `GroundController` is currently active (character is grounded), it will return the [MoveSpeedFactor](https://create.roblox.com/docs/reference/engine/classes/ControllerBase#MoveSpeedFactor) of the `GroundController`

```luau
client.getMoving(): Vector3
```
Returns the moving direction of the `ControllerManager`

```luau
client.isGrounded(): boolean
```
Returns whether the character is on the ground or not

```luau
client.isSlipping(threshold: number?): boolean
```
Returns whether the characters friction is below a certain threshold, if no threshold is given it defaults to 1<br>
`threshold` must be a number between `0` and `2`

```luau
client.step(dt: number): ()
```
*internal ignore* - automatically handled

```luau
client.init(): typeof(client)
```
*internal ignore* - automatically initialized

```luau
client.initBasicReplication(): ()
```
*internal ignore* - automatically initialized

## groundSensor

### Properties

```luau
groundSensor.Params: RaycastParams
```
Can be set with `setParamsToDefault`, the 'RaycastParams' used for checking the ground

```luau
groundSensor.SkipNextSnap: number
```
Skips snapping to the ground for the next `n` times, `n` being the properties value

### Functions

```luau
groundSensor.setParamsToDefault(...: Instance): ()
```
Sets the `Params` property excluding the passed instances

```luau
groundSensor.update(manager: ControllerManager, humanoid: Humanoid): ControllerBase
```
*used internally*

## humanoidState

### Functions

```luau
humanoidState.update(manager: ControllerManager, humanoid: Humanoid): Enum.HumanoidStateType
```
*used internally*

## jumpAction

### Properties

```luau
jumpAction.CanJump: boolean
```
Decides whether the character can jump or not

```luau
jumpAction.CanHoldJump: boolean
```

```luau
jumpAction.JumpPower: number?
```
If `nil`, `Humanoid.JumpPower` is used

```luau
jumpAction.MaxJumps: number
```

```luau
jumpAction.JumpCount: number
```

```luau
jumpAction._requested: boolean
```

### Functions

```luau
jumpAction.jump(manager: ControllerManager, humanoid: Humanoid): ()
```
*handled internally*<br><br>
`Humanoid.JumpHeight` is not supported.<br>
Should be called when the humanoid state type is "Jumping".<br>
Doesn't call `jump.ableToJump()`, this should be called in state handling manually

```luau
jumpAction.reset(): ()
```
Resets the `JumpAction.JumpCount`

```luau
jumpAction.forceJump(manager: ControllerManager, jumpPower: number): ()
```
Forcefully jumps the character

```luau
jumpAction.ableToJump(): boolean
```
Returns whether the character is able to jump

## physics

### Properties

```luau
a
```

### Functions

```luau
a
```

## speedometer

### Properties

```luau
a
```

### Functions

```luau
a
```

# Server

## Server [ Main ]

### Functions

```luau
server.load(character: Model): ControllerManager
```

```luau
server.unload(player: Player): ()
```

```luau
server.init(): ()
```
*handled internally*

```luau
server.uninit(undoControllers: boolean?): ()
```
If `undoControllers` is true, all characters controllers are destroyed

# Types

## FunctionGroup
```luau
type FunctionGroup<T...> = {
	run: (self: @self, T...) -> (),
	add: (self: @self, fn: (T...) -> (), index: any?) -> (any),
	get: (self: @self, index: any) -> (((T...) -> ())?),
	remove: (self: @self, index: any) -> (((T...) -> ())?),
	clear: (self: @self) -> ()
}
```

## SpeedStateEnum
```luau
type SpeedStateEnum = "Idle"
|"Walk"
|"Acceleration"
|"Deceleration"
|"Skid"
```