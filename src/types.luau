export type SpeedStateEnum = "Idle"|"Walk"|"Acceleration"|"Deceleration"|"Skid"

export type SpeedometerInfo = {
	Manager: ControllerManager,
	Speed: number,
	MadeSharpTurn: boolean,
	MovingMagnitude: number,
	Grounded: boolean
}

export type SpeedState = {
	name: SpeedStateEnum,
	apply: (info: SpeedometerInfo, dt: number) -> (number, Vector3?),
	isApplicable: (info: SpeedometerInfo) -> (boolean),
}

export type ControllerManagerHierarchy = ControllerManager & {
	AirController: AirController,
	GroundController: GroundController & {
		GroundSensor: ControllerPartSensor
	}
}

export type ReplicationPacket = {
	Health: number,
	State: Enum.HumanoidStateType
}

return nil
