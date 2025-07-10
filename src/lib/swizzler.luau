--Doesn't respect .Enabled or any other external properties
--The <code>mode</code> argument functions as basic swizzling*
--*: the string must be strictly 3 characters long only including the component names of the object and the character: "_"
local function swizzle(vec: Vector3|vector, mode: string): Vector3
	local mx, my, mz = ("c1c1c1"):unpack(mode)
	return Vector3.new(
		mx == "_" and 0 or vec[mx],
		my == "_" and 0 or vec[my],
		mz == "_" and 0 or vec[mz]
	)
end

local apply = swizzle

local move = {}
move.Enabled = false
move.AppliedMode = "XYZ"

--Returns based on the current apply function and <code>AppliedMode</code> property, also respects the <code>Enabled</code> property
--The <code>AppliedMode</code> property functions as basic swizzling*
--*: the string must be strictly 3 characters long only including the characters: "X", "Y", "Z", "_"
function move.getApplied(vec: Vector3): Vector3
	return if move.Enabled then apply(vec, move.AppliedMode) else vec
end

move.swizzle = swizzle

--Sets the apply function used by the .getApplied function to the given function
--If no argument is given, the apply function is set to the default .swizzle function
function move.setApplyFunction(applier: ((vec: Vector3|vector, mode: string) -> (Vector3))?)
	apply = applier or swizzle
end

return move