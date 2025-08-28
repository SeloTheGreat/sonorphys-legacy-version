--!nocheck

local makeConf = require("@self/makeConfig")

local config = makeConf.get {	
	LimbParts = {
		EnableFluidForces = false
	},

	Movement = {
		MoveSpeedRanges = {
			Mach1 = 30,
			Mach2 = 80,
			Mach3 = 120,
			Mach4 = 200
		},

		MinimumMovingSpeed = 30,
		BaseMoveSpeed = 120,
		BaseTurnSpeed = 12,
	}
}

return config