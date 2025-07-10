local functionGroup = {}
functionGroup.__index = functionGroup

--The tuple is to provide arguments to the callbacks
--Is not yield safe
function functionGroup:run(...: any): ()
	for i, v in self[1] do
		v(...)
	end
end

function functionGroup:add(fn: (...any) -> (), index: any?): (any)
	local l = self[1]
	index = index or table.maxn(l) + 1 
	l[index] = fn
	return index
end

function functionGroup:get(index: any): ((...any) -> ())?
	return self[1][index]
end

--Returns the function
function functionGroup:remove(index: any): ((...any) -> ())?
	local l = self[1]
	local fn = l[index]
	l[index] = nil
	return fn
end

--Clears the table
function functionGroup:clear()
	table.clear(self[1])
end

export type FunctionGroup<T...> = {
	run: (self: FunctionGroup<T...>, T...) -> (),
	add: (self: FunctionGroup<T...>, fn: (T...) -> (), index: any?) -> (any),
	get: (self: FunctionGroup<T...>, index: any) -> (((T...) -> ())?),
	remove: (self: FunctionGroup<T...>, index: any) -> (((T...) -> ())?),
	clear: (self: FunctionGroup<T...>) -> ()
}

--FunctionGroup is not yield safe, use signals instead
return function(): FunctionGroup<>
	return setmetatable({{}}, functionGroup) :: any --i shouldn't do this
end
