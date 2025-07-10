local numberGroup = {}
numberGroup.__index = numberGroup

function numberGroup:sum(): (number)
	local sum = self[1]
	for i, v in self[2] do
		sum += v
	end
	return sum
end

function numberGroup:add(n: number, index: any?): (any)
	if index == "origin" then
		self[1] = n
		return index
	end
	local l = self[2]
	
	index = index or table.maxn(l) + 1
	l[index] = n
	return index
end

function numberGroup:get(index: any): number?
	if index == "origin" then
		return self[1]
	end
	return self[2][index]
end

--Returns the number
function numberGroup:remove(index: any): number?
	local l = self[2]
	local n = l[index]
	l[index] = nil
	return n
end

--Clears the table
function numberGroup:clear()
	table.clear(self[2])
end

export type NumberGroup = {
	sum: (self: NumberGroup) -> (number),
	add: (self: NumberGroup, value: number, id: any?|"origin") -> (any),
	get: (self: NumberGroup, id: any|"origin") -> (number?),
	remove: (self: NumberGroup, id: any) -> (number?),
	clear: (self: NumberGroup) -> ()
}

return function(original: number): NumberGroup
	return setmetatable({original, {}}, numberGroup) :: any
end
