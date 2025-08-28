local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local config = require("../configuration")
local rep = require("../_replication")
local client = require("../client")

rep.ReplicationEvent = script.Parent.Parent._replication:WaitForChild("Replication")

client.initBasicReplication()

Players.LocalPlayer.CharacterAdded:Connect(client.init)
Players.LocalPlayer.CharacterRemoving:Connect(client.uninit)

if Players.LocalPlayer.Character then
	client.init()
end

if config.EnableDebug then
	local Gizmo
	local debugConfig = config.EnableDebug
	
	if debugConfig.EnableRays and #debugConfig.EnableRays > 0 then
		--make gizmo lib
		Gizmo = {}
		
		local Terrain = workspace:FindFirstChildOfClass('Terrain')

		local AdornmentProperties = {
			-- Used for lines, rays ...
			Cylinder = {
				Color3 = Color3.new(100, 100, 100), -- have to set it to a value >1 otherwise it wont be white if AlwaysOnTop is true.
				AlwaysOnTop = true,
				Adornee = Terrain,
				Radius = 0.04,
				ZIndex = 1
			},

			-- Used for showing direction of rays and arrows
			Cone = {
				Color3 = Color3.new(100, 100, 100), -- have to set it to a value >1 otherwise it wont be white if AlwaysOnTop is true.
				AlwaysOnTop = true,
				Adornee = Terrain,
				Height = 0.3,
				Radius = 0.07,
				ZIndex = 1
			}
		}

		local ActiveGizmos = {}

		local AdornmentHolders = Terrain:FindFirstChild('Gizmo - AdornmentHolders')
		if not AdornmentHolders then
			AdornmentHolders = Instance.new('Folder')
			AdornmentHolders.Name = 'Gizmo - AdornmentHolders'
			AdornmentHolders.Parent = Terrain
		end

		local function CreateBase(AdornmentClass, ID)
			if ActiveGizmos[ID] then
				ActiveGizmos[ID]:Destroy()
			end

			local Object = Instance.new(AdornmentClass .. 'HandleAdornment')

			for Name, Value in next, AdornmentProperties[AdornmentClass] do
				Object[Name] = Value
			end

			Object.Parent = AdornmentHolders

			ActiveGizmos[ID] = Object

			return Object
		end

		function Gizmo:DrawLine(Start, End, Offset, Color, ID)
			local Line = CreateBase('Cylinder', ID)

			local Distance = (Start - End).Magnitude
			Offset = Offset or 0

			Line.Height = Distance - Offset
			Line.CFrame = CFrame.lookAt(Start, End) * CFrame.new(0, 0, 0.5 * (Offset - Distance))

			if Color then
				Line.Color3 = Color
			end
			return Line
		end
		function Gizmo:DrawCone(CFrame, Color, ID)
			local Cone = CreateBase('Cone', ID)

			Cone.CFrame = CFrame
			if Color then
				Cone.Color3 = Color
			end
			return Cone
		end

		function Gizmo:DrawArrow(Start, End, Color, ID)
			local ConeHeight = AdornmentProperties.Cone.Height

			local Distance = (Start - End).Magnitude

			local Line = Gizmo:DrawLine(Start, End, ConeHeight, Color, ID)
			local Cone = Gizmo:DrawCone(CFrame.lookAt(Start, End) * CFrame.new(0, 0, -Distance + ConeHeight), Color, ID .. "#Cone")

			return Line, Cone
		end

		function Gizmo:DrawRay(Start, Direction, Color, ID)
			return Gizmo:DrawArrow(Start, Start + Direction, Color, ID)
		end
		
		function Gizmo:Clear()
			for i, v in ActiveGizmos do
				v:Destroy()
			end
			table.clear(ActiveGizmos)
		end
	end
	
	local screen = Instance.new("ScreenGui")
	local list = Instance.new("Frame") do
		screen.Name = "Debug"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
		
		list.ZIndex = 10000
		list.Size = UDim2.fromScale(0.5, 1)
		list.BackgroundTransparency = 1
		list.Parent = screen
		
		if debugConfig.HorizontalAlignment == Enum.HorizontalAlignment.Right then
			list.Position = UDim2.fromScale(0.5, 0)
		elseif debugConfig.HorizontalAlignment == Enum.HorizontalAlignment.Center then
			list.Position = UDim2.fromScale(0.25, 0)
		end
		
		local layout = Instance.new("UIListLayout")
		layout.VerticalAlignment = debugConfig.VerticalAlignment or Enum.VerticalAlignment.Bottom
		layout.HorizontalAlignment = debugConfig.HorizontalAlignment or Enum.HorizontalAlignment.Left
		layout.Parent = list
	end
	
	local templateLabel = Instance.new("TextLabel") do
		templateLabel.BackgroundTransparency = debugConfig.LabelBackgroundTransparency or 1
		templateLabel.BackgroundColor3 = debugConfig.LabelBackgroundColor3 or Color3.new(1,1,1)
		templateLabel.Size = UDim2.new(debugConfig.LabelXAxisScale or 1, 0, 0, debugConfig.LabelYAxisSize or 20)
		templateLabel.TextColor3 = Color3.new(1,1,1)
		templateLabel.TextScaled = true
		templateLabel.TextStrokeTransparency = 0
		templateLabel.TextXAlignment = Enum.TextXAlignment:FromName(debugConfig.HorizontalAlignment.Name) or Enum.TextXAlignment.Left
	end
	
	local labels = {
		Friction = {templateLabel:Clone(), function()
			return string.format("%.3f",client.manager.GroundController.Friction)
		end,},
		Speed = {templateLabel:Clone(), function()
			return string.format("%.3f", client.getSpeed())
		end},
		Mach = {templateLabel:Clone(), function()
			return client.speedometer.getMach(client.getSpeed())
		end,},
		State = {templateLabel:Clone(), function()
			return client.humanoid:GetState().Name
		end,},
		SpeedState = {templateLabel:Clone(), function()
			return client.speedometer.State
		end,},
		JumpCount = {templateLabel:Clone(), function()
			return client.jumpAction.JumpCount
		end,},
		Walkspeed = {templateLabel:Clone(), function()
			return math.round(client.getSpeed() * client.manager.BaseMoveSpeed)
		end},
		Velocity = {templateLabel:Clone(), function()
			local vel = client.root.AssemblyLinearVelocity
			return string.format("%.1f, %.1f, %.1f", vel.X, vel.Y, vel.Z)
		end,},
		--add more here if u would like to :D
	}
	
	for i, v in labels do
		v[1].Parent = list
		v[1].Text = i .. ": ?"
	end
	
	local name = "ui_update"
	
	local function iter()
		for i, v in labels do
			v[1].Text = i .. ": " .. v[2]()
		end
		
		if debugConfig.EnableRays then
			local length = debugConfig.RayLineLength or 5
			local root = client.root
			local rootcf = root.CFrame
			
			for i, v in ipairs(debugConfig.EnableRays) do
				if v == "Moving" then
					Gizmo:DrawArrow(root.Position,
						root.Position + (client.getMoving() * length),
						Color3.new(1, 1, 0), "moving"
					)
				elseif v == "Velocity" then
					Gizmo:DrawArrow(root.Position,
						root.Position + (root.AssemblyLinearVelocity.Unit * (length + 2)),
						Color3.new(0, 1, 1), "velocity"
					)
				elseif v == "RootAxis" then
					Gizmo:DrawArrow(root.Position,
						root.Position + (rootcf.LookVector * length),
						Color3.new(0,1,0), "look"
					)
					Gizmo:DrawArrow(root.Position,
						root.Position + (rootcf.RightVector * length),
						Color3.new(1,0,0), "right"
					)
					Gizmo:DrawArrow(root.Position,
						root.Position + (rootcf.UpVector * length),
						Color3.new(0,0,1), "up"
					)
				end
			end
		end
	end
	
	UserInputService.InputBegan:Connect(function(obj)
		if obj.KeyCode == Enum.KeyCode.C and obj:IsModifierKeyDown(Enum.ModifierKey.Alt) then
			if not client.isLoaded then
				warn("Client controller has not yet loaded to enable the debug ui")
				return
			end
			if client.PostUpdate:get(name) then
				list.Visible = false
				client.PostUpdate:remove(name)
				Gizmo:Clear()
			else
				client.PostUpdate:add(iter, name)
				list.Visible = true
			end
		end
	end)
	
	list.Visible = false
	
	screen.Parent = Players.LocalPlayer.PlayerGui
end