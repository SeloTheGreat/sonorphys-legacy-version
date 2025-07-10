--Module by: TheMisterShowerMan
--Devforum: https://devforum.roblox.com/t/debounce-module/1941502

local Debounce = {}
Debounce.__index = Debounce

function Debounce.new(cooldown: number, instantlyReady: boolean?)
	local self = setmetatable({}, Debounce)
	
	instantlyReady = instantlyReady == nil or instantlyReady

	self.cooldown = cooldown
	self.PreviousDebounceReset = instantlyReady and os.clock() - cooldown or os.clock()

	return self
end

-- Wraps a function with a debounce, internally calling reset and is ready before the function is called
function Debounce.wrap(func: (...any) -> (...any), cooldown: number, instantlyReady: boolean?): (...any) -> (...any)
	local debounce = Debounce.new(cooldown, instantlyReady)
	return function(...)
		if debounce:IsReady() then
			debounce:Reset()
			return func(...)
		end
	end
end

-- Same as Debounce.Wrap but only resets the debounce when the given function returns true
function Debounce.smartWrap(func: (...any) -> (boolean), cooldown: number, instantlyReady: boolean?): (...any) -> ()
	local debounce = Debounce.new(cooldown, instantlyReady)
	return function(...)
		if debounce:IsReady() then
			local success = func(...)
			if success then
				debounce:Reset()
			end
		end
	end
end

-- Checks if the remaining time to the next available debounce is 0
function Debounce:IsReady(): boolean
	return self:GetRemainingTime() == 0
end

-- Gets the remaining time to next debounce
function Debounce:GetRemainingTime(): number
	return math.max(self.PreviousDebounceReset + self.cooldown - os.clock(), 0)
end

-- Restarts the debounce timer
function Debounce:Reset()
	self.PreviousDebounceReset = os.clock()
end

return Debounce