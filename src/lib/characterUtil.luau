local Players = game:GetService("Players")

local function waitForChildOfClass(parent: Instance, childClass: string): Instance
	local _child = parent:FindFirstChildOfClass(childClass)
	if _child then
		return _child
	end
	local running = coroutine.running()
	local conn
	conn = parent.ChildAdded:Connect(function(child)
		if child.ClassName == childClass then
			conn:Disconnect()
			task.spawn(running, child)
		end
	end)
	return coroutine.yield()
end

local function waitForChanged(inst: Instance, property: string): any
	local running = coroutine.running()
	local conn
	conn = inst.Changed:Connect(function(prop)
		if prop == property and inst[prop] ~= nil then
			conn:Disconnect()
			task.spawn(running, inst[prop])
		end
	end)
	return coroutine.yield()
end

local playerUtil = {}

--May yield
--if no player is given, local player is used
function playerUtil.sustained(player: Player?): ({char: Model, hum: Humanoid, root: BasePart}, RBXScriptConnection)
	player = player or Players.LocalPlayer
	
	local t = {char = nil, hum = nil, root = nil}
	
	local function onCharacterAdded(character)
		local humanoid = waitForChildOfClass(character, "Humanoid")
		t.char, t.hum, t.root = character, humanoid, (humanoid.RootPart or waitForChanged(humanoid, "RootPart"))
	end
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	local con = player.CharacterAdded:Connect(onCharacterAdded)
	
	return t, con
end

--May yield
--if no player is given, local player is used
--Returns the character, humanoid and root part
function playerUtil.getComponents(player: Player?): (Model, Humanoid, BasePart)
	player = player or Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = waitForChildOfClass(character, "Humanoid")
	
	return character, humanoid, (humanoid.RootPart or waitForChanged(humanoid, "RootPart"))
end

--May yield
--Returns the humanoid, root part and the player
function playerUtil.getComponentsFromCharacter(character: Model): (Humanoid, BasePart, Player)
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = waitForChildOfClass(character, "Humanoid")
	local rootPart = humanoid.RootPart or waitForChanged(humanoid, "RootPart")

	return humanoid, rootPart, player
end

--May yield
--if no player is given, local player is used
--returns controller and character
function playerUtil.getController(player: Player?): (ControllerManager, Model)
	player = player or Players.LocalPlayer
	local character = playerUtil.getCharacter(player)
	return waitForChildOfClass(character, "ControllerManager") :: ControllerManager, character
end

--May yield
--if no player is given, local player is used
--returns character
function playerUtil.getCharacter(player: Player?): Model
	player = player or Players.LocalPlayer
	return player.Character or player.CharacterAdded:Wait()
end

--May yield
--if no player is given, local player is used
--returns humanoid and character
function playerUtil.getHumanoid(player: Player?): (Humanoid, Model)
	player = player or Players.LocalPlayer
	local character = playerUtil.getCharacter(player)
	return waitForChildOfClass(character, "Humanoid") :: Humanoid, character
end

--May yield
--if no player is given, local player is used
--returns root part and character
function playerUtil.getRoot(player: Player?): (BasePart, Model)
	player = player or Players.LocalPlayer
	local character = playerUtil.getCharacter(player) 
	return character:WaitForChild("HumanoidRootPart") :: BasePart, character
end

--[[--May yield
--if no player is given, local player is used
--returns character controller
function playerUtil.getCharacterController(player: Player?): types.CharacterController
	player = player or Players.LocalPlayer
	return require(playerUtil.getCharacter(player):WaitForChild("Scripts"):WaitForChild("CharacterController"))
end]]

return playerUtil