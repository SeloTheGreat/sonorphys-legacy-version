local priorityVariable = {}
priorityVariable.__index = priorityVariable

function priorityVariable:result(): (any, number)
	local highest, val = self[1], self[2]
	local index = table.maxn(self[3])
	if index > highest then
		highest, val = index, self[3][index]
	end
	return val, highest
end

function priorityVariable:add(n: any, pri: number|"default")
	if pri == "default" then
		self[2] = n
		return
	end
	local l = self[3]
	l[pri] = n
end

function priorityVariable:get(pri: number|"default"): any?
	if pri == "default" then
		return self[2]
	end
	return self[3][pri]
end

--Returns the number
function priorityVariable:remove(pri: any): any?
	local l = self[3]

	local n = l[pri]
	l[pri] = nil
	return n
end

--Clears the table
function priorityVariable:clear()
	table.clear(self[3])
end

export type PriorityVariable<T = any> = {
	result: (self: PriorityVariable<T>) -> (T, number),
	add: (self: PriorityVariable<T>, value: T, priority: number|"default") -> (),
	get: (self: PriorityVariable<T>, priority: number|"default") -> (T?),
	remove: (self: PriorityVariable<T>, priority: number) -> (T?),
	clear: (self: PriorityVariable<T>) -> ()
}

return function<T>(default: T, defaultsPriority: number): PriorityVariable<T>
	return setmetatable({defaultsPriority, default, {}}, priorityVariable) :: any
end
