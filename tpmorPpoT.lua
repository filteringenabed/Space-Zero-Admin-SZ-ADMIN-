-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TextChatService = game:GetService("TextChatService")

-- reallycoolstuff
local GRAVITY_MULTIPLIER = 1.5
local INITIAL_BOOST = 10
local MAX_SPEED = 20
local SIMULATION_RADIUS = 5000
local invertedParts = {}
local connection = nil
local heartbeatConnection = nil
local LocalPlayer = Players.LocalPlayer
local PartsFolder = Instance.new("Folder")
PartsFolder.Parent = Workspace
PartsFolder.Name = "TopPrompt"
local handler = nil
local OrbitConnection = nil
local TeleportTime = 0.2
local AutoStopTime = 3

local SilentSwordkill = {
    Active = false,
    Target = nil,
    OriginalGrip = {},
    OriginalMassless = {},
    Tools = {},
    DeadPlayers = {}
}

local Freeze = {
    Enabled = false,
    Connections = {}
}

local WallHop = {
    Enabled = false,
    Debounce = true,
    RaycastParams = RaycastParams.new()
}

local AntiTripSystem = {
    Enabled = false,
    Connections = {}
}

local AutoRejoin = {
    Enabled = false,
    Connection = nil
}

local FPSCounter = {
    Enabled = false,
    Connection = nil,
    Label = nil
}

local AutoRespawn = {
    Enabled = false,
    Connections = {},
    DeathPosition = nil
}

local FPSCounter = {
    Enabled = false,
    Connection = nil,
    Label = nil
}

local Buff = {
    Enabled = false,
    OriginalProperties = {}
}

local CGod = {
    Enabled = false,
    Connections = {}
}

local Spazz = {
    Enabled = false,
    BodyVelocity = nil
}

local FreeGamepasses = {
    Hooked = false,
    OriginalFunction = nil
}

local Orbit = {
    Active = false,
    Connection = nil,
    Radius = 5,
    Speed = 6,
    Angles = {},
    OriginalPositions = {},
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer
}

local AirWalk = {
    Enabled = false,
    AirPart = nil,
    Connection = nil
}

local AntiTeleport = {
    Enabled = false,
    OriginalFunctions = {}
}

local AntiKick = {
    Enabled = false,
    OriginalFunctions = {}
}

--[[
crx("jsjsjes", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
]]

-- Player references
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Sound effects
local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://177266782" -- Typewriter click
clickSound.Volume = 0.3
clickSound.Parent = SoundService

local errorSound = Instance.new("Sound")
errorSound.SoundId = "rbxassetid://138081500" -- Error beep
errorSound.Volume = 0.4
errorSound.Parent = SoundService

local successSound = Instance.new("Sound")
successSound.SoundId = "rbxassetid://6026984224" -- Success beep
successSound.Volume = 0.4
successSound.Parent = SoundService

-- Command System
local Commands = {}
local CommandOrder = {} -- This will track the order commands were added

-- Type 1: Simple command with description and function
function AddCommand(name, aliases, description, func)
    local commandData = {
        desc = description,
        exec = func,
        hasValue = false,
        hasPlayer = false,
        aliases = type(aliases) == "string" and {aliases} or aliases or {}
    }
    
    -- Add main command
    Commands[name:lower()] = commandData
    table.insert(CommandOrder, name:lower())
    
    -- Add aliases
    for _, alias in ipairs(commandData.aliases) do
        Commands[alias:lower()] = commandData
    end
end

-- Type 2: Command with value input
function AddCommandWithValue(name, valueName, aliases, description, func)
    local commandData = {
        desc = description,
        exec = func,
        hasValue = true,
        valueName = valueName,
        hasPlayer = false,
        aliases = type(aliases) == "string" and {aliases} or aliases or {}
    }
    
    -- Add main command
    Commands[name:lower()] = commandData
    table.insert(CommandOrder, name:lower())
    
    -- Add aliases
    for _, alias in ipairs(commandData.aliases) do
        Commands[alias:lower()] = commandData
    end
end

-- Type 3: Command with player input
function AddCommandWithPlayer(name, aliases, description, func)
    local commandData = {
        desc = description,
        exec = func,
        hasValue = false,
        hasPlayer = true,
        aliases = type(aliases) == "string" and {aliases} or aliases or {}
    }
    
    -- Add main command
    Commands[name:lower()] = commandData
    table.insert(CommandOrder, name:lower())
    
    -- Add aliases
    for _, alias in ipairs(commandData.aliases) do
        Commands[alias:lower()] = commandData
    end
end

-- Type 4: Command with both value and player inputs
function AddCommandWithValueAndPlayer(name, valueName, aliases, description, func)
    local commandData = {
        desc = description,
        exec = func,
        hasValue = true,
        valueName = valueName,
        hasPlayer = true,
        aliases = type(aliases) == "string" and {aliases} or aliases or {}
    }
    
    -- Add main command
    Commands[name:lower()] = commandData
    table.insert(CommandOrder, name:lower())
    
    -- Add aliases
    for _, alias in ipairs(commandData.aliases) do
        Commands[alias:lower()] = commandData
    end
end

-- Alternative simplified command system
function AddCmd(name, description, ...)
    local inputs = {...}
    local hasValue = false
    local valueName = nil
    local hasPlayer = false
    
    for _, input in ipairs(inputs) do
        if input == "value" then
            hasValue = true
            valueName = "value"
        elseif input == "player" then
            hasPlayer = true
        end
    end
    
    return function(func, aliases)
        local commandData = {
            desc = description,
            exec = func,
            hasValue = hasValue,
            valueName = valueName,
            hasPlayer = hasPlayer,
            aliases = type(aliases) == "string" and {aliases} or aliases or {}
        }
        
        -- Add main command
        Commands[name:lower()] = commandData
        table.insert(CommandOrder, name:lower())
        
        -- Add aliases
        for _, alias in ipairs(commandData.aliases) do
            Commands[alias:lower()] = commandData
        end
    end
end

local LocalPlayer = Players.LocalPlayer

-- Command prefix (change this if you want a different prefix)
local COMMAND_PREFIX = "!"

-- Track if we've already processed a message to prevent double execution
local messageProcessed = {}

-- Modified chatbox command handler
local function handleChatMessage(message, speaker)
    -- Only process if the speaker is the local player
    if speaker ~= LocalPlayer then return end
    
    -- Check if message starts with command prefix
    if string.sub(message, 1, 1) == COMMAND_PREFIX then
        -- Create a unique identifier for this message to prevent double processing
        local messageId = speaker.UserId..tostring(message)
        
        -- If we've already processed this message, skip it
        if messageProcessed[messageId] then
            return
        end
        
        -- Mark this message as processed
        messageProcessed[messageId] = true
        
        -- Remove the mark after a short delay (cleanup)
        task.delay(1, function()
            messageProcessed[messageId] = nil
        end)
        
        -- Rest of your existing handleChatMessage function...
        -- Remove the prefix
        local commandText = string.sub(message, 2)
        
        -- Split command and arguments
        local parts = {}
        for part in string.gmatch(commandText, "%S+") do
            table.insert(parts, part:lower())
        end
        
        if #parts == 0 then return end
        
        local command = Commands[parts[1]]
        
        if command then
            -- Check if command expects inputs
            if command.hasValue or command.hasPlayer then
                local playerName, value
                local currentIndex = 2
                
                -- First check for player name if command expects it
                if command.hasPlayer and #parts >= currentIndex then
                    playerName = parts[currentIndex]
                    currentIndex = currentIndex + 1
                end
                
                -- Then check for value if command expects it
                if command.hasValue and #parts >= currentIndex then
                    value = table.concat(parts, " ", currentIndex)
                elseif command.hasValue then
                    speaker:SetAttribute("ChatCommandError", string.format("Missing value for %s.\nUsage: %s%s%s", 
                        parts[1], 
                        parts[1],
                        command.hasPlayer and " <player>" or "",
                        command.hasValue and " <"..(command.valueName or "value")..">" or ""))
                    return
                end
                
                -- Execute command with inputs
                local success, message
                if command.hasPlayer and command.hasValue then
                    success, message = pcall(function() return command.exec(playerName, value) end)
                elseif command.hasPlayer then
                    success, message = pcall(function() return command.exec(playerName) end)
                elseif command.hasValue then
                    success, message = pcall(function() return command.exec(value) end)
                end
                
                if success then
                    if parts[1] ~= "cmds" then
                        successSound:Play()
                        crx(message, 1.1, Color3.fromRGB(0, 255, 0), nil)
                    else
                        -- Handle help command
                        speaker:SetAttribute("ChatCommandResult", message)
                    end
                else
                    errorSound:Play()
                end
            else
                -- Handle regular command without inputs
                local success, message = pcall(command.exec)
                if success then
                    if parts[1] == "cmds" then
                        -- Handle help command
                        speaker:SetAttribute("ChatCommandResult", message)
                    else
                        successSound:Play()
                        crx(message, 1.2, Color3.fromRGB(0, 255, 0), nil)
                    end
                else
                    errorSound:Play()
                end
            end
        else
            errorSound:Play()
            speaker:SetAttribute("ChatCommandError", "Unknown command: " .. parts[1])
        end
    end
end

-- Connect to chat events (both systems but with duplicate prevention)
local chatConnected = false

local function connectChatEvents()
    if chatConnected then return end
    chatConnected = true
    
    if TextChatService then
        -- For new TextChatService system
        TextChatService.OnIncomingMessage = function(message)
            if message.TextSource then
                local speaker = Players:GetPlayerByUserId(message.TextSource.UserId)
                if speaker then
                    handleChatMessage(message.Text, speaker)
                end
            end
        end
    else
        -- Fallback for old chat system
        Players.PlayerChatted:Connect(function(chatType, speaker, message)
            if chatType == Enum.PlayerChatType.All then
                handleChatMessage(message, speaker)
            end
        end)
    end
end

-- Initial connection
connectChatEvents()

-- Reconnect if chat service becomes available later
if not TextChatService then
    game:GetService("ContentProvider"):GetPreloadAsync({game:GetService("TextChatService")})
    game:GetService("TextChatService"):GetPropertyChangedSignal("OnIncomingMessage"):Wait()
    connectChatEvents()
end

-- settings cmds

AddCommand("cmds", nil, "Shows all commands", function() return "Opening cmds window..." end)

-- Add this command to your existing command system
AddCommandWithValue("setprefix", "new_prefix", "setp", "Changes the command prefix", function(newPrefix)
    -- Validate the new prefix
    if type(newPrefix) ~= "string" or #newPrefix ~= 1 then
        errorSound:Play()
        crx("Prefix must be a single character!", 1.5, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Special characters that might cause issues
    local invalidChars = {"e"}
    for _, char in ipairs(invalidChars) do
        if newPrefix == char then
            errorSound:Play()
            crx("Cannot use whitespace as prefix!", 1.5, Color3.fromRGB(255, 0, 0), 138081500)
            return
        end
    end
    
    -- Change the prefix
    local oldPrefix = COMMAND_PREFIX
    COMMAND_PREFIX = newPrefix
    
    -- Play success sound and show confirmation
    successSound:Play()
    crx(string.format("Prefix changed from '%s' to '%s'", oldPrefix, newPrefix), 
        2, Color3.fromRGB(0, 255, 0), 6026984224)
    
    return "Prefix updated"
end)

-- Also add an alias for checking current prefix
AddCommand("prefix", "p", "Shows current command prefix", function()
    return "Current prefix: '"..COMMAND_PREFIX.."'"
end)

AddCommand("reload", nil, "Reloads TopPrompt", function()
    if _G.pcr then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/igfrx/tpmorPpoT/refs/heads/main/tpmorPpoT"))()
    end)
    
    if success then
        _G.pcr = true
        return "TopPrompt Reloaded!"
    else
        crx("Failed To reload!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

-- command 

local function Con()
    game:GetService("StarterGui"):SetCore("DevConsoleVisible",true)
    return "Opening Console."
end

local function enableFlight()

local main = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local dragHandle = Instance.new("Frame")
local title = Instance.new("TextLabel")
local up = Instance.new("TextButton")
local down = Instance.new("TextButton")
local onof = Instance.new("TextButton")
local plus = Instance.new("TextButton")
local speed = Instance.new("TextBox") -- Changed from TextLabel to TextBox
local mine = Instance.new("TextButton")
local closebutton = Instance.new("TextButton")
local mini = Instance.new("TextButton")
local mini2 = Instance.new("TextButton")

-- Main GUI
main.Name = "main"
main.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.ResetOnSpawn = false

-- Main Frame
Frame.Parent = main
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
Frame.Size = UDim2.new(0, 200, 0, 120)
Frame.Active = true
Frame.Draggable = true

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = Frame

-- Add subtle drop shadow
local shadow = Instance.new("UIStroke")
shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
shadow.Color = Color3.fromRGB(60, 60, 60)
shadow.Thickness = 2
shadow.Transparency = 0.7
shadow.Parent = Frame

-- Drag Handle
dragHandle.Name = "DragHandle"
dragHandle.Parent = Frame
dragHandle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dragHandle.BorderSizePixel = 0
dragHandle.Size = UDim2.new(1, 0, 0, 30)
dragHandle.ZIndex = 2

-- Drag handle corners
local dragCorner = Instance.new("UICorner")
dragCorner.CornerRadius = UDim.new(0, 8)
dragCorner.Parent = dragHandle

-- Title
title.Name = "Title"
title.Parent = dragHandle
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 0)
title.Size = UDim2.new(1, -10, 1, 0)
title.Font = Enum.Font.Arcade
title.Text = "FLYGUI"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
closebutton.Name = "Close"
closebutton.Parent = dragHandle
closebutton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
closebutton.BackgroundTransparency = 0.8
closebutton.Position = UDim2.new(1, -30, 0, 2)
closebutton.Size = UDim2.new(0, 26, 0, 26)
closebutton.Font = Enum.Font.Arcade
closebutton.Text = "X"
closebutton.TextColor3 = Color3.fromRGB(255, 0, 0)
closebutton.TextSize = 16
closebutton.ZIndex = 3

-- Close button corner
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closebutton

-- Minimize Button
mini.Name = "minimize"
mini.Parent = dragHandle
mini.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mini.BackgroundTransparency = 0.8
mini.Position = UDim2.new(1, -60, 0, 2)
mini.Size = UDim2.new(0, 26, 0, 26)
mini.Font = Enum.Font.Arcade
mini.Text = "-"
mini.TextColor3 = Color3.fromRGB(0, 255, 0)
mini.TextSize = 20
mini.ZIndex = 3

-- Minimize button corner
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 6)
miniCorner.Parent = mini

-- Restore Button (initially hidden)
mini2.Name = "minimize2"
mini2.Parent = dragHandle
mini2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mini2.BackgroundTransparency = 0.8
mini2.Position = UDim2.new(1, -60, 0, 2)
mini2.Size = UDim2.new(0, 26, 0, 26)
mini2.Font = Enum.Font.Arcade
mini2.Text = "+"
mini2.TextColor3 = Color3.fromRGB(0, 255, 0)
mini2.TextSize = 16
mini2.Visible = false
mini2.ZIndex = 3

-- Restore button corner
local mini2Corner = Instance.new("UICorner")
mini2Corner.CornerRadius = UDim.new(0, 6)
mini2Corner.Parent = mini2

-- Up Button
up.Name = "up"
up.Parent = Frame
up.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
up.Position = UDim2.new(0.05, 0, 0.35, 0)
up.Size = UDim2.new(0.4, 0, 0.25, 0)
up.Font = Enum.Font.Arcade
up.Text = "UP"
up.TextColor3 = Color3.fromRGB(0, 255, 0)
up.TextSize = 14

-- Up button corner and hover effects
local upCorner = Instance.new("UICorner")
upCorner.CornerRadius = UDim.new(0, 6)
upCorner.Parent = up

up.MouseEnter:Connect(function()
    up.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

up.MouseLeave:Connect(function()
    up.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

-- Down Button
down.Name = "down"
down.Parent = Frame
down.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
down.Position = UDim2.new(0.55, 0, 0.35, 0)
down.Size = UDim2.new(0.4, 0, 0.25, 0)
down.Font = Enum.Font.Arcade
down.Text = "DOWN"
down.TextColor3 = Color3.fromRGB(00, 255, 0)
down.TextSize = 14

-- Down button corner and hover effects
local downCorner = Instance.new("UICorner")
downCorner.CornerRadius = UDim.new(0, 6)
downCorner.Parent = down

down.MouseEnter:Connect(function()
    down.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

down.MouseLeave:Connect(function()
    down.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

-- Fly Toggle Button
onof.Name = "onof"
onof.Parent = Frame
onof.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
onof.Position = UDim2.new(0.55, 0, 0.65, 0)
onof.Size = UDim2.new(0.4, 0, 0.25, 0)
onof.Font = Enum.Font.Arcade
onof.Text = "FLY"
onof.TextColor3 = Color3.fromRGB(0, 255, 0)
onof.TextSize = 14

-- Fly button corner and hover effects
local onofCorner = Instance.new("UICorner")
onofCorner.CornerRadius = UDim.new(0, 6)
onofCorner.Parent = onof

onof.MouseEnter:Connect(function()
    onof.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

onof.MouseLeave:Connect(function()
    onof.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

-- Speed Display (now a TextBox for input)
speed.Name = "speed"
speed.Parent = Frame
speed.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
speed.Position = UDim2.new(0.3, 0, 0.65, 0)
speed.Size = UDim2.new(0.2, 0, 0.25, 0)
speed.Font = Enum.Font.Arcade
speed.Text = "1"
speed.PlaceholderText = "Speed"
speed.TextColor3 = Color3.fromRGB(0, 255, 255)
speed.TextSize = 14
speed.ClearTextOnFocus = false
speed.TextScaled = false
speed.TextWrapped = true

-- Speed display corner
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speed

-- Plus Button
plus.Name = "plus"
plus.Parent = Frame
plus.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
plus.Position = UDim2.new(0.05, 0, 0.65, 0)
plus.Size = UDim2.new(0.2, 0, 0.25, 0)
plus.Font = Enum.Font.Arcade
plus.Text = "+"
plus.TextColor3 = Color3.fromRGB(0, 255, 0)
plus.TextSize = 16

-- Plus button corner and hover effects
local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, 6)
plusCorner.Parent = plus

plus.MouseEnter:Connect(function()
    plus.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

plus.MouseLeave:Connect(function()
    plus.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

-- Minus Button
mine.Name = "mine"
mine.Parent = Frame
mine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mine.Position = UDim2.new(0.05, 0, 0.65, 0)
mine.Size = UDim2.new(0.2, 0, 0.25, 0)
mine.Font = Enum.Font.Arcade
mine.Text = "-"
mine.TextColor3 = Color3.fromRGB(0, 255, 0)
mine.TextSize = 16
mine.Visible = false -- Initially hidden since plus is shown first

-- Minus button corner and hover effects
local mineCorner = Instance.new("UICorner")
mineCorner.CornerRadius = UDim.new(0, 6)
mineCorner.Parent = mine

mine.MouseEnter:Connect(function()
    mine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

mine.MouseLeave:Connect(function()
    mine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
end)

-- =============================================
-- IMPROVED DRAGGING IMPLEMENTATION
-- =============================================

local dragging, dragInput, dragStart, startPos

local function update(input)
	if not dragging then return end
	local delta = input.Position - dragStart
	Frame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

local function startDrag(input)
	dragging = true
	dragStart = input.Position
	startPos = Frame.Position

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			dragging = false
		end
	end)
end

for _, element in pairs({dragHandle, title}) do
	element.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startDrag(input)
		end
	end)
end

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		update(input)
	end
end)

-- Set dragInput on InputBegan
dragHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

-- =============================================
-- REST OF THE FUNCTIONALITY
-- =============================================

local speeds = 1
local speaker = game:GetService("Players").LocalPlayer
local chr = game.Players.LocalPlayer.Character
local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
local nowe = false

-- Function to get current speed value
local function getSpeed()
    local num = tonumber(speed.Text)
    if num and num > 0 then
        return num
    else
        speed.Text = "1"
        return 1
    end
end

-- Function to set speed value
local function setSpeed(value)
    speeds = value
    speed.Text = tostring(value)
end

-- Update speed when text changes
speed.FocusLost:Connect(function(enterPressed)
    local num = tonumber(speed.Text)
    if num and num > 0 then
        speeds = num
    else
        speed.Text = tostring(speeds)
    end
end)

onof.MouseButton1Down:connect(function()
    if nowe == true then
        nowe = false
        onof.BackgroundColor3 = Color3.fromRGB(80, 60, 60)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
        speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
    else
        nowe = true
        onof.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
        for i = 1, getSpeed() do
            spawn(function()
                local hb = game:GetService("RunService").Heartbeat             
                tpwalking = true
                local chr = game.Players.LocalPlayer.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
        game.Players.LocalPlayer.Character.Animate.Disabled = true
        local Char = game.Players.LocalPlayer.Character
        local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
        for i,v in next, Hum:GetPlayingAnimationTracks() do
            v:AdjustSpeed(0)
        end
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
        speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
        speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    end
    
    if game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
        local plr = game.Players.LocalPlayer
        local torso = plr.Character.Torso
        local flying = true
        local deb = true
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = getSpeed() * 10 -- Scale the speed
        local speed = 0
        local bg = Instance.new("BodyGyro", torso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = torso.CFrame
        local bv = Instance.new("BodyVelocity", torso)
        bv.velocity = Vector3.new(0,0.1,0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if nowe == true then
            plr.Character.Humanoid.PlatformStand = true
        end
        while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
            game:GetService("RunService").RenderStepped:Wait()
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed+.5+(speed/maxspeed)
                if speed > maxspeed then
                    speed = maxspeed
                end
            elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                speed = speed-1
                if speed < 0 then
                    speed = 0
                end
            end
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
            else
                bv.velocity = Vector3.new(0,0,0)
            end
            bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
        end
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        plr.Character.Humanoid.PlatformStand = false
        game.Players.LocalPlayer.Character.Animate.Disabled = false
        tpwalking = false
    else
        local plr = game.Players.LocalPlayer
        local UpperTorso = plr.Character.UpperTorso
        local flying = true
        local deb = true
        local ctrl = {f = 0, b = 0, l = 0, r = 0}
        local lastctrl = {f = 0, b = 0, l = 0, r = 0}
        local maxspeed = getSpeed() * 10 -- Scale the speed
        local speed = 0
        local bg = Instance.new("BodyGyro", UpperTorso)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = UpperTorso.CFrame
        local bv = Instance.new("BodyVelocity", UpperTorso)
        bv.velocity = Vector3.new(0,0.1,0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        if nowe == true then
            plr.Character.Humanoid.PlatformStand = true
        end
        while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
            wait()
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed+.5+(speed/maxspeed)
                if speed > maxspeed then
                    speed = maxspeed
                end
            elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                speed = speed-1
                if speed < 0 then
                    speed = 0
                end
            end
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
            else
                bv.velocity = Vector3.new(0,0,0)
            end
            bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
        end
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        plr.Character.Humanoid.PlatformStand = false
        game.Players.LocalPlayer.Character.Animate.Disabled = false
        tpwalking = false
    end
end)

local tis
up.MouseButton1Down:connect(function()
    tis = up.MouseEnter:connect(function()
        while tis do
            wait()
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,1,0)
        end
    end)
end)

up.MouseLeave:connect(function()
    if tis then
        tis:Disconnect()
        tis = nil
    end
end)

local dis
down.MouseButton1Down:connect(function()
    dis = down.MouseEnter:connect(function()
        while dis do
            wait()
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,-1,0)
        end
    end)
end)

down.MouseLeave:connect(function()
    if dis then
        dis:Disconnect()
        dis = nil
    end
end)

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.7)
    game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
    game.Players.LocalPlayer.Character.Animate.Disabled = false
end)

plus.MouseButton1Down:connect(function()
    setSpeed(getSpeed() + 1)
    if nowe == true then
        tpwalking = false
        for i = 1, getSpeed() do
            spawn(function()
                local hb = game:GetService("RunService").Heartbeat             
                tpwalking = true
                local chr = game.Players.LocalPlayer.Character
                local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                    if hum.MoveDirection.Magnitude > 0 then
                        chr:TranslateBy(hum.MoveDirection)
                    end
                end
            end)
        end
    end
end)

mine.MouseButton1Down:connect(function()
    if getSpeed() == 1 then
        speed.Text = 'cannot be < 1'
        wait(1)
        speed.Text = tostring(speeds)
    else
        setSpeed(getSpeed() - 1)
        if nowe == true then
            tpwalking = false
            for i = 1, getSpeed() do
                spawn(function()
                    local hb = game:GetService("RunService").Heartbeat             
                    tpwalking = true
                    local chr = game.Players.LocalPlayer.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end
        end
    end
end)

closebutton.MouseButton1Click:Connect(function()
    main:Destroy()
end)

mini.MouseButton1Click:Connect(function()
    up.Visible = false
    down.Visible = false
    onof.Visible = false
    plus.Visible = false
    speed.Visible = false
    mine.Visible = false
    mini.Visible = false
    mini2.Visible = true
    Frame.Size = UDim2.new(0, 200, 0, 30)
    Frame.BackgroundTransparency = 0.5
end)

mini2.MouseButton1Click:Connect(function()
    up.Visible = true
    down.Visible = true
    onof.Visible = true
    plus.Visible = true
    speed.Visible = true
    mine.Visible = true
    mini.Visible = true
    mini2.Visible = false
    Frame.Size = UDim2.new(0, 200, 0, 120)
    Frame.BackgroundTransparency = 0
end)

return "Opened 'FlyGui' Window."
end

local function vfly()

local Flymguiv2 = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local dragHandle = Instance.new("Frame")
local title = Instance.new("TextLabel")
local Speed = Instance.new("TextBox")
local Fly = Instance.new("TextButton")
local Unfly = Instance.new("TextButton")
local Stat2 = Instance.new("TextLabel")
local Close = Instance.new("TextButton")
local Minimize = Instance.new("TextButton")
local Minimize2 = Instance.new("TextButton")
local Speeed = Instance.new("TextLabel")
local ForwardBtn = Instance.new("TextButton")
local BackBtn = Instance.new("TextButton")

-- Properties:
Flymguiv2.Name = "Flym gui v2"
Flymguiv2.Parent = game.CoreGui
Flymguiv2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
Frame.Name = "Frame"
Frame.Parent = Flymguiv2
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.482438415, 0, 0.454874992, 0)
Frame.Size = UDim2.new(0, 200, 0, 180) -- Increased height to accommodate new buttons
Frame.Active = true
Frame.Draggable = false

-- Add rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = Frame

-- Add subtle drop shadow
local shadow = Instance.new("UIStroke")
shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
shadow.Color = Color3.fromRGB(60, 60, 60)
shadow.Thickness = 2
shadow.Transparency = 0.7
shadow.Parent = Frame

-- Drag Handle
dragHandle.Name = "DragHandle"
dragHandle.Parent = Frame
dragHandle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dragHandle.BorderSizePixel = 0
dragHandle.Size = UDim2.new(1, 0, 0, 30)
dragHandle.ZIndex = 2

-- Drag handle corners
local dragCorner = Instance.new("UICorner")
dragCorner.CornerRadius = UDim.new(0, 8)
dragCorner.Parent = dragHandle

-- Title
title.Name = "Title"
title.Parent = dragHandle
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 10, 0, 0)
title.Size = UDim2.new(1, -10, 1, 0)
title.Font = Enum.Font.Arcade
title.Text = "VFLYGUI"
title.TextColor3 = Color3.fromRGB(0, 255, 0)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
Close.Name = "Close"
Close.Parent = dragHandle
Close.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Close.BackgroundTransparency = 0.8
Close.Position = UDim2.new(1, -30, 0, 2)
Close.Size = UDim2.new(0, 26, 0, 26)
Close.Font = Enum.Font.Arcade
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 0, 0)
Close.TextSize = 16
Close.ZIndex = 3

-- Close button corner
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = Close

-- Minimize Button
Minimize.Name = "Minimize"
Minimize.Parent = dragHandle
Minimize.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Minimize.BackgroundTransparency = 0.8
Minimize.Position = UDim2.new(1, -60, 0, 2)
Minimize.Size = UDim2.new(0, 26, 0, 26)
Minimize.Font = Enum.Font.Arcade
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(0, 255, 0)
Minimize.TextSize = 20
Minimize.ZIndex = 3

-- Minimize button corner
local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 6)
miniCorner.Parent = Minimize

-- Restore Button (initially hidden)
Minimize2.Name = "Minimize2"
Minimize2.Parent = dragHandle
Minimize2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Minimize2.BackgroundTransparency = 0.8
Minimize2.Position = UDim2.new(1, -60, 0, 2)
Minimize2.Size = UDim2.new(0, 26, 0, 26)
Minimize2.Font = Enum.Font.Arcade
Minimize2.Text = "+"
Minimize2.TextColor3 = Color3.fromRGB(0, 255, 0)
Minimize2.TextSize = 16
Minimize2.Visible = false
Minimize2.ZIndex = 3

-- Restore button corner
local mini2Corner = Instance.new("UICorner")
mini2Corner.CornerRadius = UDim.new(0, 6)
mini2Corner.Parent = Minimize2

-- Speed Label
Speeed.Name = "Speeed"
Speeed.Parent = Frame
Speeed.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Speeed.BackgroundTransparency = 0.8
Speeed.Position = UDim2.new(0.05, 0, 0.25, 0)
Speeed.Size = UDim2.new(0.4, 0, 0.15, 0)
Speeed.Font = Enum.Font.Arcade
Speeed.Text = "Speed:"
Speeed.TextColor3 = Color3.fromRGB(0, 255, 0)
Speeed.TextSize = 14

-- Speed Label corner
local speedLabelCorner = Instance.new("UICorner")
speedLabelCorner.CornerRadius = UDim.new(0, 6)
speedLabelCorner.Parent = Speeed

-- Speed Input
Speed.Name = "Speed"
Speed.Parent = Frame
Speed.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Speed.BackgroundTransparency = 0.8
Speed.Position = UDim2.new(0.55, 0, 0.25, 0)
Speed.Size = UDim2.new(0.4, 0, 0.15, 0)
Speed.Font = Enum.Font.Arcade
Speed.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
Speed.Text = "20"
Speed.TextColor3 = Color3.fromRGB(0, 255, 255)
Speed.TextSize = 14
Speed.ClearTextOnFocus = false

-- Speed Input corner
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = Speed

-- Status Value (removed the label, kept the value)
Stat2.Name = "Stat2"
Stat2.Parent = Frame
Stat2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Stat2.BackgroundTransparency = 0.8
Stat2.Position = UDim2.new(0.05, 0, 0.45, 0) -- Moved to where the label was
Stat2.Size = UDim2.new(0.9, 0, 0.15, 0) -- Made wider to fill the space
Stat2.Font = Enum.Font.Arcade
Stat2.Text = "Status: Off"
Stat2.TextColor3 = Color3.fromRGB(255, 0, 0)
Stat2.TextSize = 14

-- Status Value corner
local stat2Corner = Instance.new("UICorner")
stat2Corner.CornerRadius = UDim.new(0, 6)
stat2Corner.Parent = Stat2

-- Forward Button
ForwardBtn.Name = "ForwardBtn"
ForwardBtn.Parent = Frame
ForwardBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ForwardBtn.BackgroundTransparency = 0.8
ForwardBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ForwardBtn.Size = UDim2.new(0.4, 0, 0.15, 0)
ForwardBtn.Font = Enum.Font.Arcade
ForwardBtn.Text = "Forward"
ForwardBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
ForwardBtn.TextSize = 14

-- Forward Button corner
local forwardCorner = Instance.new("UICorner")
forwardCorner.CornerRadius = UDim.new(0, 6)
forwardCorner.Parent = ForwardBtn

-- Back Button
BackBtn.Name = "BackBtn"
BackBtn.Parent = Frame
BackBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BackBtn.BackgroundTransparency = 0.8
BackBtn.Position = UDim2.new(0.55, 0, 0.65, 0)
BackBtn.Size = UDim2.new(0.4, 0, 0.15, 0)
BackBtn.Font = Enum.Font.Arcade
BackBtn.Text = "Back"
BackBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
BackBtn.TextSize = 14

-- Back Button corner
local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(0, 6)
backCorner.Parent = BackBtn

-- Fly Button
Fly.Name = "Fly"
Fly.Parent = Frame
Fly.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Fly.BackgroundTransparency = 0.8
Fly.Position = UDim2.new(0.05, 0, 0.85, 0)
Fly.Size = UDim2.new(0.4, 0, 0.15, 0)
Fly.Font = Enum.Font.Arcade
Fly.Text = "Enable"
Fly.TextColor3 = Color3.fromRGB(0, 255, 0)
Fly.TextSize = 15

-- Fly Button corner
local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 6)
flyCorner.Parent = Fly

-- Unfly Button
Unfly.Name = "Unfly"
Unfly.Parent = Frame
Unfly.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Unfly.BackgroundTransparency = 0.8
Unfly.Position = UDim2.new(0.55, 0, 0.85, 0)
Unfly.Size = UDim2.new(0.4, 0, 0.15, 0)
Unfly.Visible = false
Unfly.Font = Enum.Font.Arcade
Unfly.Text = "Disable"
Unfly.TextColor3 = Color3.fromRGB(255, 0, 0)
Unfly.TextSize = 15

-- Unfly Button corner
local unflyCorner = Instance.new("UICorner")
unflyCorner.CornerRadius = UDim.new(0, 6)
unflyCorner.Parent = Unfly

-- Button hover effects
local function setupButtonHover(button)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    end)
end

setupButtonHover(Fly)
setupButtonHover(Unfly)
setupButtonHover(Close)
setupButtonHover(Minimize)
setupButtonHover(Minimize2)
setupButtonHover(ForwardBtn)
setupButtonHover(BackBtn)

-- =============================================
-- DRAGGING IMPLEMENTATION
-- =============================================

local dragging, dragInput, dragStart, startPos

local function update(input)
	if not dragging then return end
	local delta = input.Position - dragStart
	Frame.Position = UDim2.new(
		startPos.X.Scale,
		startPos.X.Offset + delta.X,
		startPos.Y.Scale,
		startPos.Y.Offset + delta.Y
	)
end

local function startDrag(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end

dragHandle.InputBegan:Connect(function(input)
	startDrag(input)
end)

dragHandle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- =============================================
-- FUNCTIONALITY
-- =============================================

-- Function to hide all buttons except the title bar
local function hideButtons()
    Speeed.Visible = false
    Speed.Visible = false
    Stat2.Visible = false
    ForwardBtn.Visible = false
    BackBtn.Visible = false
    Fly.Visible = false
    Unfly.Visible = false
end

-- Function to show all buttons
local function showButtons()
    Speeed.Visible = true
    Speed.Visible = true
    Stat2.Visible = true
    ForwardBtn.Visible = true
    BackBtn.Visible = true
    
    -- Only show the appropriate fly/unfly button based on current state
    if Stat2.Text == "Status: On" then
        Unfly.Visible = true
        Fly.Visible = false
    else
        Fly.Visible = true
        Unfly.Visible = false
    end
end

-- Close button functionality
Close.MouseButton1Click:Connect(function()
	Flymguiv2:Destroy()
end)

-- Minimize button functionality - Fixed to collapse the GUI
Minimize.MouseButton1Click:Connect(function()
	Frame.Size = UDim2.new(0, 200, 0, 30) -- Collapse to just the title bar
	Minimize.Visible = false
	Minimize2.Visible = true
    hideButtons() -- Hide all buttons when collapsed
end)

-- Restore button functionality
Minimize2.MouseButton1Click:Connect(function()
	Frame.Size = UDim2.new(0, 200, 0, 180) -- Restore to original size
	Minimize2.Visible = false
	Minimize.Visible = true
    showButtons() -- Show all buttons when expanded
end)

-- Fly button functionality
Fly.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	Fly.Visible = false
	Stat2.Text = "Status: On"
	Stat2.TextColor3 = Color3.fromRGB(0, 255, 0)
	Unfly.Visible = true
	
	local BV = Instance.new("BodyVelocity", HumanoidRP)
	local BG = Instance.new("BodyGyro", HumanoidRP)
	BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	BV.Velocity = Vector3.new(0, 0, 0)
	
	BG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	BG.D = 5000
	BG.P = 100000
	
	local connection
	connection = game:GetService('RunService').RenderStepped:Connect(function()
		if not BV or not BV.Parent or not BG or not BG.Parent then
			connection:Disconnect()
			return
		end
		BG.CFrame = game.Workspace.CurrentCamera.CFrame
	end)
end)

-- Unfly button functionality
Unfly.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	Fly.Visible = true
	Stat2.Text = "Status: Off"
	Stat2.TextColor3 = Color3.fromRGB(255, 0, 0)
	Unfly.Visible = false
	
	if HumanoidRP:FindFirstChildOfClass("BodyVelocity") then
		HumanoidRP:FindFirstChildOfClass("BodyVelocity"):Destroy()
	end
	if HumanoidRP:FindFirstChildOfClass("BodyGyro") then
		HumanoidRP:FindFirstChildOfClass("BodyGyro"):Destroy()
	end
end)

-- Forward button functionality
ForwardBtn.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	if HumanoidRP:FindFirstChildOfClass("BodyVelocity") then
		HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * tonumber(Speed.Text)
	end
end)

ForwardBtn.MouseButton1Up:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	if HumanoidRP:FindFirstChildOfClass("BodyVelocity") then
		HumanoidRP.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
	end
end)

-- Back button functionality
BackBtn.MouseButton1Click:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	if HumanoidRP:FindFirstChildOfClass("BodyVelocity") then
		HumanoidRP.BodyVelocity.Velocity = game.Workspace.CurrentCamera.CFrame.LookVector * -tonumber(Speed.Text)
	end
end)

BackBtn.MouseButton1Up:Connect(function()
	local HumanoidRP = game.Players.LocalPlayer.Character.HumanoidRootPart
	if HumanoidRP:FindFirstChildOfClass("BodyVelocity") then
		HumanoidRP.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
	end
end)
return "Opened 'VFlyGui' Window."
end

local function plrz()

local player = game.Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "PlayerListGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 2
mainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
mainFrame.Size = UDim2.new(0, 200, 0, 300)
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = mainFrame

-- Drop shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.2
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundTransparency = 1
shadow.Parent = mainFrame
shadow.ZIndex = -1

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
titleBar.BorderSizePixel = 0
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.BackgroundTransparency = 1
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Size = UDim2.new(0.6, 0, 1, 0)
titleText.Font = Enum.Font.Arcade
titleText.Text = "Player List"
titleText.TextColor3 = Color3.fromRGB(0, 255, 0)
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Minimize Button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.BackgroundTransparency = 1
minimizeButton.Position = UDim2.new(0.7, 0, 0, 0)
minimizeButton.Size = UDim2.new(0.15, 0, 1, 0)
minimizeButton.Font = Enum.Font.Arcade
minimizeButton.Text = "_"
minimizeButton.TextColor3 = Color3.fromRGB(0, 255, 0)
minimizeButton.TextSize = 16
minimizeButton.Parent = titleBar

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.BackgroundTransparency = 1
closeButton.Position = UDim2.new(0.85, 0, 0, 0)
closeButton.Size = UDim2.new(0.15, 0, 1, 0)
closeButton.Font = Enum.Font.Arcade
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 0, 0)
closeButton.TextSize = 14
closeButton.Parent = titleBar

-- Button hover effects
local function setupButtonHover(button)
    local originalTextColor = button.TextColor3
    local originalSize = button.Size
    
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(
            button,
            TweenInfo.new(0.2),
            {TextColor3 = Color3.fromRGB(255, 255, 255)}
        )
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(
            button,
            TweenInfo.new(0.2),
            {TextColor3 = originalTextColor}
        )
        tween:Play()
    end)
end

setupButtonHover(minimizeButton)
setupButtonHover(closeButton)

-- Scrolling Frame for Players
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "PlayerScrollFrame"
scrollFrame.BackgroundTransparency = 1
scrollFrame.Position = UDim2.new(0, 0, 0, 30)
scrollFrame.Size = UDim2.new(1, 0, 1, -30)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 5
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

-- Function to update player list
local function updatePlayerList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local playerCount = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        playerCount = playerCount + 1
        
        local playerFrame = Instance.new("Frame")
        playerFrame.Name = plr.Name
        playerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        playerFrame.BackgroundTransparency = 0.5
        playerFrame.Size = UDim2.new(1, -10, 0, 30)
        playerFrame.Position = UDim2.new(0, 5, 0, (playerCount-1) * 35)
        
        -- Animation for when player frame is added
        playerFrame.Size = UDim2.new(0, 0, 0, 30)
        playerFrame.Position = UDim2.new(0.5, 0, 0, (playerCount-1) * 35)
        
        local expandTween = TweenService:Create(
            playerFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 0, (playerCount-1) * 35)}
        )
        expandTween:Play()
        
        local playerCorner = Instance.new("UICorner")
        playerCorner.CornerRadius = UDim.new(0, 4)
        playerCorner.Parent = playerFrame
        
        local username = Instance.new("TextLabel")
        username.Name = "Username"
        username.BackgroundTransparency = 1
        username.Position = UDim2.new(0, 10, 0, 0)
        username.Size = UDim2.new(0.7, 0, 1, 0)
        username.Font = Enum.Font.Arcade
        username.Text = plr.Name
        username.TextColor3 = Color3.fromRGB(0, 170, 220)
        username.TextSize = 12
        username.TextXAlignment = Enum.TextXAlignment.Left
        username.Parent = playerFrame
        
        local copyButton = Instance.new("TextButton")
        copyButton.Name = "CopyButton"
        copyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        copyButton.Position = UDim2.new(0.7, 5, 0.15, 0)
        copyButton.Size = UDim2.new(0.25, 0, 0.7, 0)
        copyButton.Font = Enum.Font.Arcade
        copyButton.Text = "Copy"
        copyButton.TextColor3 = Color3.fromRGB(0, 255, 0)
        copyButton.TextSize = 12
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = copyButton
        
        -- Button hover effect
        copyButton.MouseEnter:Connect(function()
            local tween = TweenService:Create(
                copyButton,
                TweenInfo.new(0.2),
                {BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255)}
            )
            tween:Play()
        end)
        
        copyButton.MouseLeave:Connect(function()
            local tween = TweenService:Create(
                copyButton,
                TweenInfo.new(0.2),
                {BackgroundColor3 = Color3.fromRGB(40, 40, 40), TextColor3 = Color3.fromRGB(200, 200, 200)}
            )
            tween:Play()
        end)
        
        copyButton.MouseButton1Click:Connect(function()
            setclipboard(plr.Name)
            
            -- Animation when copied
            local originalText = copyButton.Text
            local originalSize = copyButton.Size
            
            local tween1 = TweenService:Create(
                copyButton,
                TweenInfo.new(0.1),
                {Size = UDim2.new(0.23, 0, 0.65, 0), Text = "Copied!"}
            )
            
            local tween2 = TweenService:Create(
                copyButton,
                TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1),
                {Size = originalSize}
            )
            
            tween1:Play()
            tween1.Completed:Connect(function()
                tween2:Play()
            end)
            
            wait(1.5)
            copyButton.Text = originalText
        end)
        
        copyButton.Parent = playerFrame
        playerFrame.Parent = scrollFrame
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, playerCount * 35)
end

-- Draggable functionality
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    mainFrame.Position = newPos
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Minimize functionality
local isMinimized = false
minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        local tween = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 200, 0, 30)}
        )
        tween:Play()
        minimizeButton.Text = "+"
    else
        local tween = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 200, 0, 300)}
        )
        tween:Play()
        minimizeButton.Text = "_"
    end
end)

-- Close functionality
closeButton.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 200, 0, 0)}
    )
    tween:Play()
    
    tween.Completed:Connect(function()
        gui:Destroy()
    end)
end)

-- Initial setup
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

gui.Parent = player:WaitForChild("PlayerGui")

return "Playerlist opened!"

end

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Track current character and connections
local currentCharacter = character
local characterAddedConn = nil
local humanoidDiedConn = nil

local function setTransparency(character, transparency)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = transparency
        end
    end
end

local function cleanupInvisibility()
    local invisChair = workspace:FindFirstChild("invischair")
    if invisChair then
        invisChair:Destroy()
    end
end

local function setupCharacter(newCharacter)
    -- Clean up previous character connections
    if humanoidDiedConn then
        humanoidDiedConn:Disconnect()
        humanoidDiedConn = nil
    end
    
    -- Set up new character
    currentCharacter = newCharacter
    
    -- Connect to humanoid's death event
    local humanoid = newCharacter:WaitForChild("Humanoid")
    humanoidDiedConn = humanoid.Died:Connect(function()
        cleanupInvisibility()
    end)
end

-- Initial character setup
setupCharacter(character)

-- Connect to CharacterAdded for respawns
characterAddedConn = player.CharacterAdded:Connect(function(newCharacter)
    cleanupInvisibility()
    setupCharacter(newCharacter)
end)

function invis2()
    if not currentCharacter or not currentCharacter:FindFirstChild("HumanoidRootPart") then
        crx("Invisibility: FAILED!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    
    cleanupInvisibility() -- Clean up any existing invisibility
    
    local savedpos = currentCharacter:WaitForChild("HumanoidRootPart").CFrame
    task.wait()
    currentCharacter:MoveTo(Vector3.new(-25.95, 84, 3537.55))
    task.wait(0.15)

    local seat = Instance.new("Seat")
    seat.Name = "invischair"
    seat.Anchored = false
    seat.CanCollide = false
    seat.Transparency = 1
    seat.Position = Vector3.new(-25.95, 84, 3537.55)
    seat.Parent = workspace

    local weld = Instance.new("Weld", seat)
    weld.Part0 = seat
    weld.Part1 = currentCharacter:FindFirstChild("Torso") or currentCharacter:FindFirstChild("UpperTorso")

    task.wait()
    seat.CFrame = savedpos
    setTransparency(currentCharacter, 0.5)
    return "Invisibility: TRUE"
end

function vis2()
    cleanupInvisibility()
    
    if currentCharacter then
        setTransparency(currentCharacter, 0)
    end
    
    return "Invisibility: FALSE"
end

-- Cleanup when script is destroyed
local function onDestroy()
    cleanupInvisibility()
    if characterAddedConn then
        characterAddedConn:Disconnect()
    end
    if humanoidDiedConn then
        humanoidDiedConn:Disconnect()
    end
end

local localPlayer = Players.LocalPlayer

local function resetCameraSubject()
    if workspace.CurrentCamera and localPlayer.Character then
        local humanoid = localPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
end

local function StartAB()
    local plr = Players.LocalPlayer
    local character = plr.Character or plr.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    local lastPos = hrp.Position
    local targetPos = Vector3.new(0, -80000000, 0)
    local db = false
    local velConn
    
    -- Clean up any existing Gaze parts
    for _, gaze in ipairs(workspace:GetDescendants()) do
        if gaze:IsA("Part") and gaze.Name == "Gaze" and gaze.Transparency == 0.5 then
            workspace.Gaze:Destroy()
        end
    end

    local function createTween(targetCFrame)
        local tweenInfo = TweenInfo.new(TeleportTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        return TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    end

    local function startVelLoop()
        velConn = RunService.Heartbeat:Connect(function()
            hrp.Velocity = Vector3.new(0, 0, 0)
        end)
    end

    local function stopScript()
        if db then return end
        db = true
        
        -- Stop velocity loop
        if velConn then
            velConn:Disconnect()
            velConn = nil
        end
        
        -- Tween back to original position
        local tweenBack = createTween(CFrame.new(lastPos))
        tweenBack:Play()
        tweenBack.Completed:Wait()
        
        -- Reset camera and clean up
        workspace.FallenPartsDestroyHeight = -500
        resetCameraSubject()
        
        for _, gaze in ipairs(workspace:GetDescendants()) do
            if gaze:IsA("Part") and gaze.Name == "Gaze" and gaze.Transparency == 0.5 then
                workspace.Gaze:Destroy()
            end
        end
        
        db = false
    end

    if db then return end
    db = true
    
    -- Store original position
    lastPos = hrp.Position
    
    -- First teleport 20 studs underground
    local undergroundPos = Vector3.new(lastPos.X, lastPos.Y - 20, lastPos.Z)
    local undergroundTween = createTween(CFrame.new(undergroundPos))
    undergroundTween:Play()
    undergroundTween.Completed:Wait()
    
    -- Create Gaze part and set camera
    local part = Instance.new("Part")
    part.Size = Vector3.new(4, 5, 4)
    part.Position = lastPos
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.5
    part.Name = "Gaze"
    part.Parent = game.Workspace
    workspace.CurrentCamera.CameraSubject = part
    
    workspace.FallenPartsDestroyHeight = 0/0
    
    -- Tween to target position
    local tweenToTarget = createTween(CFrame.new(targetPos))
    tweenToTarget:Play()
    tweenToTarget.Completed:Wait()
    
    -- Start velocity loop
    startVelLoop()
    
    -- Schedule automatic stop after AutoStopTime seconds
    delay(AutoStopTime, stopScript)
    
    db = false
    return "AntiBang Executed.."
end

local LocalPlayer = Players.LocalPlayer
local TFlingActive = false
local ModeActive = false
local TFlingCoroutine
local ModeConnection

-- TFling functionality
local function TFling()
    local character = LocalPlayer.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    while TFlingActive do
        RunService.Heartbeat:Wait()
        local velocity = rootPart.Velocity
        rootPart.Velocity = velocity * 999999999999999999999999999999999 + Vector3.new(0, 999999999999999999999999999999999, 0)
        RunService.RenderStepped:Wait()
        rootPart.Velocity = velocity
        RunService.Stepped:Wait()
        rootPart.Velocity = velocity + Vector3.new(0, 0.1, 0)
    end
end

-- Mode functionality
local function DisableCollisions()
    if not LocalPlayer.Character then return end
    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            part.CanCollide = false
        end
    end
end

local function EnableCollisions()
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Control functions
function TFlingOn()
    TFlingActive = true
    TFlingCoroutine = coroutine.create(TFling)
    coroutine.resume(TFlingCoroutine)
    return "Walkfling: TRUE"
end

function TFlingOff()
    TFlingActive = false
    if TFlingCoroutine then
        coroutine.close(TFlingCoroutine)
    end
    return "Walkfling: FALSE"
end

function ModeOn()
    ModeActive = true
    ModeConnection = RunService.Heartbeat:Connect(DisableCollisions)
    return "Noclip Enabled.."
end

function ModeOff()
    ModeActive = false
    if ModeConnection then
        ModeConnection:Disconnect()
    end
    EnableCollisions()
    return "Noclip Disabled.."
end

local function R1()

pcall(function()
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Create the invisible part for attachments
local Folder = Instance.new("Folder", Workspace)
local Part = Instance.new("Part", Folder)
local Attachment1 = Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

-- GUI Implementation
local G2L = {}

-- Create ScreenGui
G2L["ScreenGui_1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
G2L["ScreenGui_1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling

-- Tags
CollectionService:AddTag(G2L["ScreenGui_1"], "main")

-- Main Frame
G2L["Frame_2"] = Instance.new("Frame", G2L["ScreenGui_1"])
G2L["Frame_2"]["BorderSizePixel"] = 0
G2L["Frame_2"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
G2L["Frame_2"]["Size"] = UDim2.new(0, 130, 0, 148)
G2L["Frame_2"]["Position"] = UDim2.new(0, 310, 0, 60)
G2L["Frame_2"]["BackgroundTransparency"] = 0.2

-- Radius TextBox
G2L["RaidusTextBox_3"] = Instance.new("TextBox", G2L["Frame_2"])
G2L["RaidusTextBox_3"]["CursorPosition"] = -1
G2L["RaidusTextBox_3"]["Name"] = "RaidusTextBox"
G2L["RaidusTextBox_3"]["BorderSizePixel"] = 0
G2L["RaidusTextBox_3"]["TextColor3"] = Color3.fromRGB(0, 255, 0)
G2L["RaidusTextBox_3"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
G2L["RaidusTextBox_3"]["PlaceholderText"] = "Radius"
G2L["RaidusTextBox_3"]["Size"] = UDim2.new(0, 100, 0, 20)
G2L["RaidusTextBox_3"]["Position"] = UDim2.new(0, 16, 0, 62)
G2L["RaidusTextBox_3"]["Text"] = "70"
G2L["RaidusTextBox_3"]["TextSize"] = 14
G2L["RaidusTextBox_3"]["Font"] = Enum.Font.Arcade


-- Radius TextBox Corner
G2L["UICorner_4"] = Instance.new("UICorner", G2L["RaidusTextBox_3"])

-- Main Frame Corner
G2L["UICorner_5"] = Instance.new("UICorner", G2L["Frame_2"])

-- Frame for minimize button
G2L["Frame2_6"] = Instance.new("Frame", G2L["Frame_2"])
G2L["Frame2_6"]["BorderSizePixel"] = 0
G2L["Frame2_6"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
G2L["Frame2_6"]["Size"] = UDim2.new(0, 130, 0, 20)
G2L["Frame2_6"]["Name"] = "Frame2"

-- Frame2 Corner
G2L["UICorner_7"] = Instance.new("UICorner", G2L["Frame2_6"])

-- Minimize Button
G2L["MinimiseBtn_8"] = Instance.new("TextButton", G2L["Frame2_6"])
G2L["MinimiseBtn_8"]["BorderSizePixel"] = 0
G2L["MinimiseBtn_8"]["TextSize"] = 11
G2L["MinimiseBtn_8"]["BackgroundColor3"] = Color3.fromRGB(0, 255, 0)
G2L["MinimiseBtn_8"]["BackgroundTransparency"] = 1
G2L["MinimiseBtn_8"]["Size"] = UDim2.new(0, 32, 0, 18)
G2L["MinimiseBtn_8"]["Text"] = "➖"
G2L["MinimiseBtn_8"]["Name"] = "MinimiseBtn"
G2L["MinimiseBtn_8"]["Position"] = UDim2.new(0, 98, 0, 0)

-- Attraction Strength TextBox
G2L["ASTextBox_9"] = Instance.new("TextBox", G2L["Frame_2"])
G2L["ASTextBox_9"]["CursorPosition"] = -1
G2L["ASTextBox_9"]["Name"] = "ASTextBox"
G2L["ASTextBox_9"]["BorderSizePixel"] = 0
G2L["ASTextBox_9"]["TextColor3"] = Color3.fromRGB(0, 255, 0)
G2L["ASTextBox_9"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
G2L["ASTextBox_9"]["PlaceholderText"] = "Speed"
G2L["ASTextBox_9"]["Size"] = UDim2.new(0, 100, 0, 20)
G2L["ASTextBox_9"]["Position"] = UDim2.new(0, 16, 0, 86)
G2L["ASTextBox_9"]["Text"] = "555"
G2L["ASTextBox_9"]["TextSize"] = 14
G2L["ASTextBox_9"]["Font"] = Enum.Font.Arcade


-- AS TextBox Corner
G2L["UICorner_a"] = Instance.new("UICorner", G2L["ASTextBox_9"])

-- Toggle Button
G2L["Toggle_b"] = Instance.new("TextButton", G2L["Frame_2"])
G2L["Toggle_b"]["BorderSizePixel"] = 0
G2L["Toggle_b"]["TextColor3"] = Color3.fromRGB(0, 255, 0)
G2L["Toggle_b"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
G2L["Toggle_b"]["Size"] = UDim2.new(0, 104, 0, 24)
G2L["Toggle_b"]["Text"] = "Ringparts: OFF"
G2L["Toggle_b"]["Name"] = "Toggle"
G2L["Toggle_b"]["Position"] = UDim2.new(0, 14, 0, 30)
G2L["Toggle_b"]["TextSize"] = 12
G2L["Toggle_b"]["Font"] = Enum.Font.Arcade

-- Toggle Button Corner
G2L["UICorner_c"] = Instance.new("UICorner", G2L["Toggle_b"])

-- Title
G2L["Title_d"] = Instance.new("TextLabel", G2L["Frame_2"])
G2L["Title_d"]["BorderSizePixel"] = 0
G2L["Title_d"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
G2L["Title_d"]["TextColor3"] = Color3.fromRGB(0, 255, 0)
G2L["Title_d"]["BackgroundTransparency"] = 1
G2L["Title_d"]["Size"] = UDim2.new(0, 88, 0, 12)
G2L["Title_d"]["Text"] = "RingParts"
G2L["Title_d"]["Name"] = "Title"
G2L["Title_d"]["Position"] = UDim2.new(0, 20, 0, 4)
G2L["Title_d"]["TextSize"] = 14
G2L["Title_d"]["Font"] = Enum.Font.Arcade


-- UI Stroke
G2L["UIStroke_e"] = Instance.new("UIStroke", G2L["Frame_2"])
G2L["UIStroke_e"]["Transparency"] = 0.1
G2L["UIStroke_e"]["Thickness"] = 3
G2L["UIStroke_e"]["Color"] = Color3.fromRGB(0, 0, 0)

-- SuperRing functionality
local radius = tonumber(G2L["RaidusTextBox_3"].Text) or 70
local height = 100
local rotationSpeed = 0.5
local attractionStrength = tonumber(G2L["ASTextBox_9"].Text) or 555
local ringPartsEnabled = false

-- Network part control
if not getgenv().Network then
    getgenv().Network = {
        BaseParts = {},
        Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
    }

    Network.RetainPart = function(Part)
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
            table.insert(Network.BaseParts, Part)
            Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            Part.CanCollide = false
        end
    end

    local function EnablePartControl()
        LocalPlayer.ReplicationFocus = Workspace
        RunService.Heartbeat:Connect(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            for _, Part in pairs(Network.BaseParts) do
                if Part:IsDescendantOf(Workspace) then
                    Part.Velocity = Network.Velocity
                end
            end
        end)
    end

    EnablePartControl()
end

local function ForcePart(v)
    if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
        for _, x in next, v:GetChildren() do
            if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") then
                x:Destroy()
            end
        end
        if v:FindFirstChild("Attachment") then
            v:FindFirstChild("Attachment"):Destroy()
        end
        if v:FindFirstChild("AlignPosition") then
            v:FindFirstChild("AlignPosition"):Destroy()
        end
        if v:FindFirstChild("Torque") then
            v:FindFirstChild("Torque"):Destroy()
        end
        v.CanCollide = false
        local Torque = Instance.new("Torque", v)
        Torque.Torque = Vector3.new(100000, 100000, 100000)
        local AlignPosition = Instance.new("AlignPosition", v)
        local Attachment2 = Instance.new("Attachment", v)
        Torque.Attachment0 = Attachment2
        AlignPosition.MaxForce = 9999999999999999
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = 200
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
    end
end

local function RetainPart(Part)
    if Part:IsA("BasePart") and not Part.Anchored and Part:IsDescendantOf(workspace) then
        if Part.Parent == LocalPlayer.Character or Part:IsDescendantOf(LocalPlayer.Character) then
            return false
        end

        Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        Part.CanCollide = false
        return true
    end
    return false
end

local parts = {}
local function addPart(part)
    if RetainPart(part) then
        if not table.find(parts, part) then
            table.insert(parts, part)
        end
    end
end

local function removePart(part)
    local index = table.find(parts, part)
    if index then
        table.remove(parts, index)
    end
end

for _, part in pairs(workspace:GetDescendants()) do
    addPart(part)
end

workspace.DescendantAdded:Connect(addPart)
workspace.DescendantRemoving:Connect(removePart)

RunService.Heartbeat:Connect(function()
    if not ringPartsEnabled then return end
    
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local tornadoCenter = humanoidRootPart.Position
        for _, part in pairs(parts) do
            if part.Parent and not part.Anchored then
                local pos = part.Position
                local distance = (Vector3.new(pos.X, tornadoCenter.Y, pos.Z) - tornadoCenter).Magnitude
                local angle = math.atan2(pos.Z - tornadoCenter.Z, pos.X - tornadoCenter.X)
                local newAngle = angle + math.rad(rotationSpeed)
                local targetPos = Vector3.new(
                    tornadoCenter.X + math.cos(newAngle) * math.min(radius, distance),
                    tornadoCenter.Y + (height * (math.abs(math.sin((pos.Y - tornadoCenter.Y) / height)))),
                    tornadoCenter.Z + math.sin(newAngle) * math.min(radius, distance)
                )
                local directionToTarget = (targetPos - part.Position).unit
                part.Velocity = directionToTarget * attractionStrength
            end
        end
    end
end)

-- Button functionality
G2L["Toggle_b"].MouseButton1Click:Connect(function()
    ringPartsEnabled = not ringPartsEnabled
    G2L["Toggle_b"].Text = ringPartsEnabled and "Ringparts: ON" or "Ringparts: OFF"
end)

-- Update radius when text changes
G2L["RaidusTextBox_3"].FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newRadius = tonumber(G2L["RaidusTextBox_3"].Text)
        if newRadius then
            radius = math.clamp(newRadius, 1, 1000)
            G2L["RaidusTextBox_3"].Text = tostring(radius)
        else
            G2L["RaidusTextBox_3"].Text = tostring(radius)
        end
    end
end)

-- Update attraction strength when text changes
G2L["ASTextBox_9"].FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local newStrength = tonumber(G2L["ASTextBox_9"].Text)
        if newStrength then
            attractionStrength = math.clamp(newStrength, 1, 10000)
            G2L["ASTextBox_9"].Text = tostring(attractionStrength)
        else
            G2L["ASTextBox_9"].Text = tostring(attractionStrength)
        end
    end
end)

-- Make GUI draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    G2L["Frame_2"].Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

G2L["Frame_2"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = G2L["Frame_2"].Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

G2L["Frame_2"].InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Minimize functionality
local minimized = false
G2L["MinimiseBtn_8"].MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        G2L["Frame_2"].Size = UDim2.new(0, 130, 0, 20)
        G2L["Toggle_b"].Visible = false
        G2L["RaidusTextBox_3"].Visible = false
        G2L["ASTextBox_9"].Visible = false
        G2L["MinimiseBtn_8"].Text = "➕"
    else
        G2L["Frame_2"].Size = UDim2.new(0, 130, 0, 148)
        G2L["Toggle_b"].Visible = true
        G2L["RaidusTextBox_3"].Visible = true
        G2L["ASTextBox_9"].Visible = true
        G2L["MinimiseBtn_8"].Text = "➖"
    end
end)
end)
return "RingParts Loaded.."
end

local VirtualUser = game:GetService('VirtualUser')
local antiAFKConnection = nil

function antiafkon()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
    end
    antiAFKConnection = game:GetService('Players').LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    return "Anti-AFK enabled"
end

function antiafkoff()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
        return "Anti-AFK disabled"
    else
        crx("Anti-AFK is already disabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end

local speaker = Players.LocalPlayer

local antiflingConnection = nil

function Afon()
    if antiflingConnection then
        antiflingConnection:Disconnect()
    end

    antiflingConnection = RunService.Stepped:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= speaker and player.Character then
                for _, v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end
    end)
    return "Anti-Fling enabled" 
end

function Afoff()
    if antiflingConnection then
        antiflingConnection:Disconnect()
        antiflingConnection = nil
    end
    return "Anti-Fling disabled" 
end


local function cleanUpForces(part)
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("BodyForce") or child:IsA("BodyVelocity") then
            child:Destroy()
        end
    end
end

local function applyUpwardForce()
    -- Ensure we can affect distant parts
    sethiddenproperty(player, "SimulationRadius", SIMULATION_RADIUS)
    sethiddenproperty(player, "MaxSimulationRadius", SIMULATION_RADIUS)
    
    for part, data in pairs(invertedParts) do
        if part and part.Parent then
            -- Calculate upward force based on part's mass
            local force = part:GetMass() * Workspace.Gravity * GRAVITY_MULTIPLIER
            
            -- Apply force while respecting max speed
            if part.Velocity.Y < MAX_SPEED then
                part:ApplyImpulse(Vector3.new(0, force * 0.016, 0)) -- 0.016 ≈ 1/60 for frame independence
            end
            
            -- Ensure parts don't get stuck
            if part.Velocity.Y < 5 then
                part.Velocity = Vector3.new(0, 5, 0)
            end
        else
            invertedParts[part] = nil
        end
    end
end

local function invertGravity(part)
    if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(player.Character) then
        if not invertedParts[part] then
            -- Store original state
            invertedParts[part] = {
                CanCollide = part.CanCollide,
                CustomPhysicalProperties = part.CustomPhysicalProperties
            }
            
            -- Clean existing forces
            cleanUpForces(part)
            
            -- Configure part physics
            part.CanCollide = false
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            
            -- Initial gentle push
            part.Velocity = Vector3.new(0, INITIAL_BOOST, 0)
            
            -- Add permanent upward force
            local bodyForce = Instance.new("BodyForce")
            bodyForce.Force = Vector3.new(0, part:GetMass() * Workspace.Gravity * GRAVITY_MULTIPLIER, 0)
            bodyForce.Parent = part
            invertedParts[part].bodyForce = bodyForce
        end
    end
end

local function restoreGravity(part)
    if invertedParts[part] then
        cleanUpForces(part)
        part.CanCollide = invertedParts[part].CanCollide
        part.CustomPhysicalProperties = invertedParts[part].CustomPhysicalProperties
        part.Velocity = Vector3.new(0, 0, 0)
        invertedParts[part] = nil
    end
end

function GravOn()
    -- Set physics range
    sethiddenproperty(player, "SimulationRadius", SIMULATION_RADIUS)
    
    -- Process existing parts
    for _, part in ipairs(Workspace:GetDescendants()) do
        invertGravity(part)
    end
    
    -- Continuous force application
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    heartbeatConnection = RunService.Heartbeat:Connect(applyUpwardForce)
    
    -- Detect new parts
    if connection then connection:Disconnect() end
    connection = Workspace.DescendantAdded:Connect(invertGravity)
    return "Gravity Invert enabled"
end

function GravOff()
    -- Clean up
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    
    for part in pairs(invertedParts) do
        if part.Parent then
            restoreGravity(part)
        end
    end
    
    invertedParts = {}
    if connection then
        connection:Disconnect()
        connection = nil
    end
    return "Gravity Invert disabled"
end

local function CreateTptool()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local backpack = localPlayer.Backpack
    local mouse = localPlayer:GetMouse()
    
    local function isAlive(Player, headCheck)
        local Player = Player or localPlayer
        if Player and Player.Character and ((Player.Character:FindFirstChildOfClass("Humanoid")) and (Player.Character:FindFirstChild("HumanoidRootPart")) and (headCheck and Player.Character:FindFirstChild("Head") or not headCheck)) then
            return true
        else
            return false
        end
    end
    
    local tool = Instance.new("Tool")
    tool.Name = "TPTool"
    tool.Parent = backpack
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
    	if isAlive() then
    		localPlayer.Character.HumanoidRootPart.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
    	end
    end)
    return "Created TpTool.."
    end

-- Black Hole Script Function
local function blackHoleScript()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    Folder = Instance.new("Folder", Workspace)
    local Part = Instance.new("Part", Folder)
    Attachment1 = Instance.new("Attachment", Part)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 1

    if not Network then
        Network = {
            BaseParts = {},
            Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
        }

        Network.RetainPart = function(Part)
            if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
                table.insert(Network.BaseParts, Part)
                Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                Part.CanCollide = false
            end
        end

        local function EnablePartControl()
            LocalPlayer.ReplicationFocus = Workspace
            RunService.Heartbeat:Connect(function()
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                for _, Part in pairs(Network.BaseParts) do
                    if Part:IsDescendantOf(Workspace) then
                        Part.Velocity = Network.Velocity
                    end
                end
            end)
        end

        EnablePartControl()
    end

    local function ForcePart(v)
        if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
            for _, x in next, v:GetChildren() do
                if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") then
                    x:Destroy()
                end
            end
            if v:FindFirstChild("Attachment") then
                v:FindFirstChild("Attachment"):Destroy()
            end
            if v:FindFirstChild("AlignPosition") then
                v:FindFirstChild("AlignPosition"):Destroy()
            end
            if v:FindFirstChild("Torque") then
                v:FindFirstChild("Torque"):Destroy()
            end
            v.CanCollide = false
            local Torque = Instance.new("Torque", v)
            Torque.Torque = Vector3.new(100000, 100000, 100000)
            local AlignPosition = Instance.new("AlignPosition", v)
            local Attachment2 = Instance.new("Attachment", v)
            Torque.Attachment0 = Attachment2
            AlignPosition.MaxForce = 9999999999999999
            AlignPosition.MaxVelocity = math.huge
            AlignPosition.Responsiveness = 200
            AlignPosition.Attachment0 = Attachment2
            AlignPosition.Attachment1 = Attachment1
        end
    end

    blackHoleActive = true

    for _, v in next, Workspace:GetDescendants() do
        ForcePart(v)
    end

    Workspace.DescendantAdded:Connect(function(v)
        if blackHoleActive then
            ForcePart(v)
        end
    end)

    spawn(function()
        while blackHoleActive and RunService.RenderStepped:Wait() do
            Attachment1.WorldCFrame = humanoidRootPart.CFrame
        end
    end)
    return "BlackHole: TRUE"
end

-- Function to disable black hole
local function disableBlackHole()
    blackHoleActive = false
    if Folder then
        Folder:Destroy()
        Folder = nil
    end
    if Network then
        Network.BaseParts = {}
    end
    return "BlackHole: FALSE"
end

-- Commands with aliases
-- == speed loop ==
local SpeedLoop = {
    Enabled = false,
    Value = 16,
    Connection = nil,
    CharConn = nil
}

local function applySpeed()
    local char = Players.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = SpeedLoop.Value end
end

local function startSpeedLoop()
    if SpeedLoop.Connection then SpeedLoop.Connection:Disconnect() end
    SpeedLoop.Connection = RunService.Heartbeat:Connect(function()
        if not SpeedLoop.Enabled then
            SpeedLoop.Connection:Disconnect()
            SpeedLoop.Connection = nil
            return
        end
        applySpeed()
    end)
end

AddCommandWithValue("walkspeed", "speed", "ws", "Sets your speed (16 Default)", function(speed)
    speed = tonumber(speed)
    if not speed then crx("Invalid speed!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) return end
    SpeedLoop.Value = speed
    SpeedLoop.Enabled = true
    applySpeed()
    startSpeedLoop()
    if SpeedLoop.CharConn then SpeedLoop.CharConn:Disconnect() end
    SpeedLoop.CharConn = Players.LocalPlayer.CharacterAdded:Connect(function()
        if not SpeedLoop.Enabled then return end
        task.wait(0.5)
        applySpeed()
    end)
    return "WalkSpeed set to\n" .. speed
end)

AddCommand("stopspeed", {"sps"}, "Stops speed loop & resets to 16", function()
    SpeedLoop.Enabled = false
    if SpeedLoop.Connection then SpeedLoop.Connection:Disconnect() SpeedLoop.Connection = nil end
    if SpeedLoop.CharConn then SpeedLoop.CharConn:Disconnect() SpeedLoop.CharConn = nil end
    local char = Players.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    return "Speed stopped, reset to 16"
end)

local LocalPlayer = Players.LocalPlayer

local tpwalking = false
local speeds = 1

local function getCharacter()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    return character, humanoid, rootPart
end

local function TpWalk()
    local _, humanoid, rootPart = getCharacter()
    tpwalking = true

    while tpwalking and humanoid.Health > 0 do
        RunService.Heartbeat:Wait()

        if humanoid.MoveDirection.Magnitude > 0 then
            local moveDirection = humanoid.MoveDirection.Unit
            local velocity = moveDirection * speeds * 50
            rootPart.CFrame = rootPart.CFrame + velocity * RunService.Heartbeat:Wait()
        end
    end
end

-- Command: tpwalk <value>
AddCommandWithValue("tpwalk", "speed", "tpw", "More safer walkspeed", function(speed)
    speed = tonumber(speed)
    if not speed then
        crx("Invalid speed!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    speeds = speed
    if not tpwalking then
        task.spawn(TpWalk)
    end
    return "Tpwalk set to\n" .. speeds
end)

-- Command: stoptpwalk
AddCommand("stoptpwalk", "untpw", "Stops Tpwalk", function()
    tpwalking = false
    return "Tpwalk stopped."
end)

local player = Players.LocalPlayer
local loopaatConnection = nil

function loopaat2()
	if loopaatConnection then return end -- already looping

	loopaatConnection = RunService.Heartbeat:Connect(function()
		local backpack = player:FindFirstChildOfClass("Backpack")
		local character = player.Character
		if not backpack or not character then return end

		local tools = {}
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(tools, item)
			end
		end

		if #tools > 0 then
			local randomTool = tools[math.random(1, #tools)]
			randomTool.Parent = character
			task.wait(0.005)
			pcall(function()
				randomTool:Activate()
			end)
			task.wait(0.005)
			randomTool.Parent = backpack
		end
	end)
   return "LoopAAT Enabled"
end

function unloopaat1()
	if loopaatConnection then
		loopaatConnection:Disconnect()
		loopaatConnection = nil
	end
   return "LoopAAT Disabled"
end

local Player = Players.LocalPlayer

local function GetPlayer(Name)
    Name = Name:lower()
    for _, x in next, Players:GetPlayers() do
        if x ~= Player then
            if x.Name:lower():match("^" .. Name) or x.DisplayName:lower():match("^" .. Name) then
                return x
            end
        end
    end
    return nil
end

local function SkidFling(TargetPlayer)
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter and TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if not Character or not Humanoid or not RootPart then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end

    if not TCharacter or not THumanoid then
        crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) 
        return
    end

    if THumanoid.Sit then
        crx("Target is Sitting!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end

    -- Save original position
    local OldPos = RootPart.CFrame
    local OldFPDH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0

    -- Set camera subject
    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    else
        workspace.CurrentCamera.CameraSubject = THumanoid
    end

    -- Create velocity
    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local function FPos(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function SFBasePart(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0

        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100

                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                        
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                    task.wait()

                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
    end

    -- Choose which part to fling
    if TRootPart and THead then
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart and not THead then
        SFBasePart(TRootPart)
    elseif not TRootPart and THead then
        SFBasePart(THead)
    elseif not TRootPart and not THead and Accessory and Handle then
        SFBasePart(Handle)
    else
        BV:Destroy()
        workspace.FallenPartsDestroyHeight = OldFPDH
        crx("Target is missing?", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    -- Clean up
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid

    -- Return to original position
    repeat
        RootPart.CFrame = OldPos * CFrame.new(0, .5, 0)
        Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, .5, 0))
        Humanoid:ChangeState("GettingUp")
        for _, x in ipairs(Character:GetChildren()) do
            if x:IsA("BasePart") then
                x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
            end
        end
        task.wait()
    until (RootPart.Position - OldPos.p).Magnitude < 25
    
    workspace.FallenPartsDestroyHeight = OldFPDH
    return "Flinged " .. TargetPlayer.Name
end

local function credits()
    crx("Script made by hmmm5650! :D", 3, Color3.fromRGB(0, 255, 255), 12221831)
end

local function error()
    crx("Error!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
end

local function good()
    return "Success!"
end

local function meh()
    crx("Notification!", 3, Color3.fromRGB(50, 50, 50), 12221831)
end

local function plrd()

-- Create main screen GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerRadar"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Detect if on mobile
local isMobile = UserInputService.TouchEnabled

-- Main frame (smaller for mobile)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "RadarFrame"
mainFrame.Size = isMobile and UDim2.new(0, 150, 0, 180) or UDim2.new(0, 200, 0, 200)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Corner for rounded edges
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title bar for dragging
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 24)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(1, -30, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Player Radar"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamMedium
titleText.TextSize = 14
titleText.Parent = titleBar

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -24, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.GothamBold
closeTextSize = isMobile and 12 or 14
closeButton.TextSize = closeTextSize
closeButton.Parent = titleBar

-- Radar display area
local radarDisplay = Instance.new("Frame")
radarDisplay.Name = "RadarDisplay"
radarDisplay.Size = UDim2.new(1, -10, 0, isMobile and 100 or 120)
radarDisplay.Position = UDim2.new(0, 5, 0, 29)
radarDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
radarDisplay.BorderSizePixel = 0
radarDisplay.Parent = mainFrame

local radarCorner = Instance.new("UICorner")
radarCorner.CornerRadius = UDim.new(0, 6)
radarCorner.Parent = radarDisplay

-- Radar center point (player position)
local centerPoint = Instance.new("Frame")
centerPoint.Name = "CenterPoint"
centerPoint.Size = UDim2.new(0, 6, 0, 6)
centerPoint.AnchorPoint = Vector2.new(0.5, 0.5)
centerPoint.Position = UDim2.new(0.5, 0, 0.5, 0)
centerPoint.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
centerPoint.BorderSizePixel = 0
centerPoint.ZIndex = 2
centerPoint.Parent = radarDisplay

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(1, 0)
centerCorner.Parent = centerPoint

-- Distance indicator frame
local distanceFrame = Instance.new("Frame")
distanceFrame.Name = "DistanceFrame"
distanceFrame.Size = UDim2.new(1, -10, 0, isMobile and 40 or 30)
distanceFrame.Position = UDim2.new(0, 5, 0, isMobile and 134 or 154)
distanceFrame.BackgroundTransparency = 1
distanceFrame.Parent = mainFrame

-- Distance title
local distanceTitle = Instance.new("TextLabel")
distanceTitle.Name = "DistanceTitle"
distanceTitle.Size = UDim2.new(1, 0, 0, 15)
distanceTitle.Position = UDim2.new(0, 0, 0, 0)
distanceTitle.BackgroundTransparency = 1
distanceTitle.Text = "CLOSEST PLAYER:"
distanceTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
distanceTitle.TextXAlignment = Enum.TextXAlignment.Left
distanceTitle.Font = Enum.Font.Gotham
distanceTitle.TextSize = isMobile and 10 or 12
distanceTitle.Parent = distanceFrame

-- Distance value
local distanceValue = Instance.new("TextLabel")
distanceValue.Name = "DistanceValue"
distanceValue.Size = UDim2.new(1, 0, 0, isMobile and 20 or 15)
distanceValue.Position = UDim2.new(0, 0, 0, 15)
distanceValue.BackgroundTransparency = 1
distanceValue.Text = "0 studs"
distanceValue.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceValue.TextXAlignment = Enum.TextXAlignment.Left
distanceValue.Font = Enum.Font.GothamBold
distanceValue.TextSize = isMobile and 14 or 16
distanceValue.Parent = distanceFrame

-- Direction indicator
local directionFrame = Instance.new("Frame")
directionFrame.Name = "DirectionFrame"
directionFrame.Size = UDim2.new(0, 20, 0, 20)
directionFrame.Position = UDim2.new(1, -25, 0, 15)
directionFrame.BackgroundTransparency = 1
directionFrame.Parent = distanceFrame

local directionArrow = Instance.new("ImageLabel")
directionArrow.Name = "DirectionArrow"
directionArrow.Size = UDim2.new(1, 0, 1, 0)
directionArrow.BackgroundTransparency = 1
directionArrow.Image = "rbxassetid://10709790937" -- Arrow icon
directionArrow.Parent = directionFrame

-- Make the GUI draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- Radar functionality
local blips = {} -- Store player blips
local closestDistance = math.huge
local closestPlayer = nil

-- Function to create or update player blips
local function updateBlip(player, position, isLocalPlayer)
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	if not blips[player] then
		local blip = Instance.new("Frame")
		blip.Name = player.Name
		blip.Size = UDim2.new(0, 8, 0, 8)
		blip.AnchorPoint = Vector2.new(0.5, 0.5)
		blip.BackgroundColor3 = isLocalPlayer and Color3.fromRGB(0, 162, 255) or Color3.fromRGB(255, 50, 50)
		blip.BorderSizePixel = 0
		blip.ZIndex = 2
		blip.Parent = radarDisplay
		
		local blipCorner = Instance.new("UICorner")
		blipCorner.CornerRadius = UDim.new(1, 0)
		blipCorner.Parent = blip
		
		-- Player name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(0, 60, 0, 12)
		nameLabel.Position = UDim2.new(0, -25, 0, -15)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = player.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = isMobile and 8 or 10
		nameLabel.Visible = false
		nameLabel.Parent = blip
		
		blips[player] = {blip = blip, label = nameLabel}
	end
	
	-- Update blip position in radar
	local blipData = blips[player]
	local blip = blipData.blip
	local nameLabel = blipData.label
	
	-- Calculate position relative to local player
	local localPlayer = Players.LocalPlayer
	local localCharacter = localPlayer.Character
	if localCharacter then
		local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
		if localRoot then
			-- Calculate direction and distance
			local direction = (humanoidRootPart.Position - localRoot.Position) * Vector3.new(1, 0, 1)
			local distance = direction.Magnitude
			
			-- Update closest player info
			if distance > 0 and distance < closestDistance then
				closestDistance = distance
				closestPlayer = player
			end
			
			-- Normalize and scale for radar display
			local maxDistance = 50 -- Radar range
			local scale = math.min(distance / maxDistance, 1)
			local normalizedDirection = direction.Unit
			
			-- Convert to radar coordinates (0,0 is center)
			local radarX = normalizedDirection.X * scale * (radarDisplay.AbsoluteSize.X / 2)
			local radarY = normalizedDirection.Z * scale * (radarDisplay.AbsoluteSize.Y / 2)
			
			-- Update blip position
			blip.Position = UDim2.new(0.5, radarX, 0.5, radarY)
			
			-- Adjust size based on distance (closer = bigger)
			local size = math.max(6, 10 - (distance / maxDistance) * 4)
			blip.Size = UDim2.new(0, size, 0, size)
			
			-- Update name label position and show if close enough
			if distance < 20 then
				nameLabel.Visible = true
				nameLabel.Position = UDim2.new(0, -25, 0, -15)
			else
				nameLabel.Visible = false
			end
			
			-- Update direction arrow for closest player
			if player == closestPlayer then
				local angle = math.atan2(normalizedDirection.Z, normalizedDirection.X)
				directionArrow.Rotation = math.deg(angle) + 90
			end
		end
	end
end

-- Function to remove blips when players leave
local function removeBlip(player)
	if blips[player] then
		blips[player].blip:Destroy()
		blips[player].label:Destroy()
		blips[player] = nil
		
		if player == closestPlayer then
			closestDistance = math.huge
			closestPlayer = nil
			distanceValue.Text = "No players nearby"
			directionArrow.Visible = false
		end
	end
end

-- Set up player connections
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		if player == Players.LocalPlayer then
			-- Don't create a blip for local player (we have the center point)
			return
		end
		updateBlip(player, character:WaitForChild("HumanoidRootPart").Position, false)
	end)
	
	if player.Character then
		if player == Players.LocalPlayer then
			-- Don't create a blip for local player
			return
		end
		updateBlip(player, player.Character:WaitForChild("HumanoidRootPart").Position, false)
	end
end)

Players.PlayerRemoving:Connect(removeBlip)

-- Update radar continuously
local radarUpdateConnection
radarUpdateConnection = RunService.RenderStepped:Connect(function()
	-- Reset closest distance each frame
	closestDistance = math.huge
	closestPlayer = nil
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer and player.Character then
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				updateBlip(player, humanoidRootPart.Position, false)
			end
		end
	end
	
	-- Update distance display
	if closestPlayer then
		distanceValue.Text = math.floor(closestDistance) .. " studs"
		directionArrow.Visible = true
	else
		distanceValue.Text = "No players nearby"
		directionArrow.Visible = false
	end
end)

-- Clean up when GUI is removed
screenGui.Destroying:Connect(function()
	if radarUpdateConnection then
		radarUpdateConnection:Disconnect()
	end
end)
return "Player Radar loaded!."
end

local function sl()

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FakeShiftlockUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "ShiftlockToggle"
button.Size = UDim2.new(0, 130, 0, 50)
button.Position = UDim2.new(0.5, -65, 1, -90)
button.AnchorPoint = Vector2.new(0.5, 1)
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.BackgroundTransparency = 0.1
button.TextColor3 = Color3.fromRGB(0, 255, 0)
button.Font = Enum.Font.Arcade
button.TextSize = 15
button.Text = "Shiftlock: OFF"
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(0, 0, 0)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = button

-- crosshair
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.Size = UDim2.new(0, 6, 0, 6)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
crosshair.BackgroundTransparency = 0
crosshair.Visible = false
crosshair.ZIndex = 10
crosshair.Parent = screenGui

local crossCorner = Instance.new("UICorner")
crossCorner.CornerRadius = UDim.new(1, 0)
crossCorner.Parent = crosshair

-- draggable with tween smoothing
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
	local delta = input.Position - dragStart
	local newPos = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
	TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = newPos}):Play()
end

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = button.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

button.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateDrag(input)
	end
end)

-- shiftlock system
local shiftlockEnabled = false
local connection

local function setShiftlock(state)
	shiftlockEnabled = state

	-- always clear old connection
	if connection then
		connection:Disconnect()
		connection = nil
	end

	if shiftlockEnabled then
		button.Text = "Shiftlock: ON"
		crosshair.Visible = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		connection = RunService.RenderStepped:Connect(function()
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local camCF = camera.CFrame
				root.CFrame = CFrame.new(root.Position, Vector3.new(
					camCF.LookVector.X + root.Position.X,
					root.Position.Y,
					camCF.LookVector.Z + root.Position.Z
				))
			end
		end)
	else
		button.Text = "Shiftlock: OFF"
		crosshair.Visible = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

button.MouseButton1Click:Connect(function()
	setShiftlock(not shiftlockEnabled)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		setShiftlock(not shiftlockEnabled)
	end
end)

-- respawn safety
player.CharacterAdded:Connect(function()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	if shiftlockEnabled then
		task.wait(0.2)
		setShiftlock(true)
	else
		crosshair.Visible = false
	end
end)
return "FakeShiftlock Loaded"
end

local function cmdl()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local cg = cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")

-- Get HD Admin prefix
local function getPrefix()
    return Players.LocalPlayer.PlayerGui:WaitForChild("HDAdminGUIs")
        :WaitForChild("MainFrame"):WaitForChild("Pages")
        :WaitForChild("Settings"):WaitForChild("Custom")
        :WaitForChild("AE1 Prefix"):WaitForChild("SettingValue")
        :WaitForChild("TextBox").Text
end

-- GUI Setup
local sGui = Instance.new("ScreenGui")
sGui.Name = "CmdBar3"
sGui.ResetOnSpawn = false
sGui.Parent = cg

-- Main command bar
local cmdBar = Instance.new("Frame")
cmdBar.Size = UDim2.new(0, 400, 0, 36)
cmdBar.Position = UDim2.new(0.5, -200, 0, 10)
cmdBar.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
cmdBar.BorderSizePixel = 0
cmdBar.Parent = sGui

local cmdBarCorner = Instance.new("UICorner", cmdBar)
cmdBarCorner.CornerRadius = UDim.new(0, 6)

local cmdBarStroke = Instance.new("UIStroke", cmdBar)
cmdBarStroke.Thickness = 1
cmdBarStroke.Color = Color3.fromRGB(60, 70, 75)

-- Add a drag handle at the top of the command bar
local dragHandle = Instance.new("Frame")
dragHandle.Size = UDim2.new(1, 0, 0, 36) -- Increased height to cover the entire bar for better dragging
dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.BackgroundTransparency = 1
dragHandle.BorderSizePixel = 0
dragHandle.ZIndex = 10
dragHandle.Parent = cmdBar

-- Command input
local cmdInput = Instance.new("TextBox")
cmdInput.Size = UDim2.new(0.7, -10, 0.8, 0)
cmdInput.Position = UDim2.new(0.01, 0, 0.1, 0)
cmdInput.PlaceholderText = "Enter command (e.g., ;fly ;invis)"
cmdInput.Text = ""
cmdInput.ClearTextOnFocus = false
cmdInput.TextColor3 = Color3.new(0.9, 0.9, 0.9)
cmdInput.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
cmdInput.Font = Enum.Font.Gotham
cmdInput.TextSize = 14
cmdInput.TextXAlignment = Enum.TextXAlignment.Left
cmdInput.Parent = cmdBar

local inputCorner = Instance.new("UICorner", cmdInput)
inputCorner.CornerRadius = UDim.new(0, 4)

-- Execute button
local executeBtn = Instance.new("TextButton")
executeBtn.Size = UDim2.new(0.28, -5, 0.8, 0)
executeBtn.Position = UDim2.new(0.71, 0, 0.1, 0)
executeBtn.Text = "Execute"
executeBtn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
executeBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
executeBtn.Font = Enum.Font.GothamBold
executeBtn.TextSize = 14
executeBtn.Parent = cmdBar

local executeCorner = Instance.new("UICorner", executeBtn)
executeCorner.CornerRadius = UDim.new(0, 4)

-- Dropdown arrow for targets
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(0, 20, 0, 20)
dropdownBtn.Position = UDim2.new(0.98, -20, 0.5, -10)
dropdownBtn.Text = "▼"
dropdownBtn.TextColor3 = Color3.new(0.7, 0.7, 0.7)
dropdownBtn.BackgroundTransparency = 1
dropdownBtn.Font = Enum.Font.GothamBold
dropdownBtn.TextSize = 12
dropdownBtn.Parent = cmdBar

-- Targets panel (initially hidden)
local targetsPanel = Instance.new("Frame")
targetsPanel.Size = UDim2.new(0, 380, 0, 150)
targetsPanel.Position = UDim2.new(0.5, -190, 0, 40)
targetsPanel.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
targetsPanel.BorderSizePixel = 0
targetsPanel.Visible = false
targetsPanel.Parent = sGui

local targetsCorner = Instance.new("UICorner", targetsPanel)
targetsCorner.CornerRadius = UDim.new(0, 6)

local targetsStroke = Instance.new("UIStroke", targetsPanel)
targetsStroke.Thickness = 1
targetsStroke.Color = Color3.fromRGB(60, 70, 75)

-- Player list
local scroll = Instance.new("ScrollingFrame", targetsPanel)
scroll.Size = UDim2.new(0.95, 0, 0.7, 0)
scroll.Position = UDim2.new(0.025, 0, 0.15, 0)
scroll.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.Parent = targetsPanel

local scrollCorner = Instance.new("UICorner", scroll)
scrollCorner.CornerRadius = UDim.new(0, 4)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Selection buttons
local allBtn = Instance.new("TextButton", targetsPanel)
allBtn.Size = UDim2.new(0.3, -5, 0, 20)
allBtn.Position = UDim2.new(0.025, 0, 0.05, 0)
allBtn.Text = "All"
allBtn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
allBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
allBtn.Font = Enum.Font.Gotham
allBtn.TextSize = 12
allBtn.Parent = targetsPanel

local othersBtn = Instance.new("TextButton", targetsPanel)
othersBtn.Size = UDim2.new(0.3, -5, 0, 20)
othersBtn.Position = UDim2.new(0.35, 0, 0.05, 0)
othersBtn.Text = "Others"
othersBtn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
othersBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
othersBtn.Font = Enum.Font.Gotham
othersBtn.TextSize = 12
othersBtn.Parent = targetsPanel

local clearBtn = Instance.new("TextButton", targetsPanel)
clearBtn.Size = UDim2.new(0.3, -5, 0, 20)
clearBtn.Position = UDim2.new(0.675, 0, 0.05, 0)
clearBtn.Text = "Clear"
clearBtn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
clearBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
clearBtn.Font = Enum.Font.Gotham
clearBtn.TextSize = 12
clearBtn.Parent = targetsPanel

-- Loop controls
local loopToggle = Instance.new("TextButton", targetsPanel)
loopToggle.Size = UDim2.new(0.4, -5, 0, 20)
loopToggle.Position = UDim2.new(0.025, 0, 0.9, -20)
loopToggle.Text = "Loop: Off"
loopToggle.TextColor3 = Color3.new(0.9, 0.9, 0.9)
loopToggle.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
loopToggle.Font = Enum.Font.Gotham
loopToggle.TextSize = 12
loopToggle.Parent = targetsPanel

local delayInput = Instance.new("TextBox", targetsPanel)
delayInput.Size = UDim2.new(0.2, 0, 0, 20)
delayInput.Position = UDim2.new(0.45, 0, 0.9, -20)
delayInput.PlaceholderText = "Delay: 1s"
delayInput.Text = "1"
delayInput.TextColor3 = Color3.new(0.9, 0.9, 0.9)
delayInput.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
delayInput.Font = Enum.Font.Gotham
delayInput.TextSize = 12
delayInput.Parent = targetsPanel

local delayCorner = Instance.new("UICorner", delayInput)
delayCorner.CornerRadius = UDim.new(0, 4)

-- Close button
local closeBtn = Instance.new("TextButton", targetsPanel)
closeBtn.Size = UDim2.new(0.3, -5, 0, 20)
closeBtn.Position = UDim2.new(0.675, 0, 0.9, -20)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 80)
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 12
closeBtn.Parent = targetsPanel

-- Selected targets storage
local selectedTargets = {}
local looping = false

-- Function to create player checkbox
local function createCheckbox(player)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 20)
    container.BackgroundTransparency = 1
    container.Name = player.Name
    
    local checkbox = Instance.new("ImageButton")
    checkbox.Size = UDim2.new(0, 16, 0, 16)
    checkbox.Position = UDim2.new(0, 0, 0.5, -8)
    checkbox.BackgroundColor3 = Color3.fromRGB(40, 45, 50)
    checkbox.BorderSizePixel = 0
    checkbox.Image = ""
    checkbox.Parent = container
    
    local cbStroke = Instance.new("UIStroke", checkbox)
    cbStroke.Thickness = 1
    cbStroke.Color = Color3.fromRGB(70, 80, 80)
    
    local cbCorner = Instance.new("UICorner", checkbox)
    cbCorner.CornerRadius = UDim.new(0, 3)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = player == localPlayer and player.Name .. " (you)" or player.Name
    nameLabel.Position = UDim2.new(0, 22, 0, 0)
    nameLabel.Size = UDim2.new(1, -22, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextSize = 12
    nameLabel.Parent = container
    
    local function updateCheckboxVisual()
        local isSelected = selectedTargets[player.Name] == true
        checkbox.BackgroundColor3 = isSelected and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(40, 45, 50)
    end
    
    updateCheckboxVisual()
    
    checkbox.MouseButton1Click:Connect(function()
        selectedTargets[player.Name] = not selectedTargets[player.Name]
        updateCheckboxVisual()
    end)
    
    container.Parent = scroll
end

-- Function to refresh player list
local function refreshPlayerList()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "UIListLayout" then
            child:Destroy()
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        createCheckbox(player)
    end
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 22)
end

-- Player events
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function(player)
    selectedTargets[player.Name] = nil
    local existing = scroll:FindFirstChild(player.Name)
    if existing then
        existing:Destroy()
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 22)
end)

-- Execute command function
local function executeCommand()
    local commandText = cmdInput.Text
    if commandText == "" then return end
    
    -- Split commands by semicolon
    local commands = {}
    for cmd in commandText:gmatch("[^;]+") do
        table.insert(commands, cmd:match("^%s*(.-)%s*$")) -- Trim whitespace
    end
    
    -- Execute each command
    for _, cmd in ipairs(commands) do
        if cmd ~= "" then
            local fired = false
            
            -- Check if any targets are selected
            for name, isSelected in pairs(selectedTargets) do
                if isSelected then
                    local fullCmd = getPrefix() .. cmd .. " " .. name
                    ReplicatedStorage:WaitForChild("HDAdminClient"):WaitForChild("Signals"):WaitForChild("RequestCommand"):InvokeServer(fullCmd)
                    fired = true
                end
            end
            
            -- If no targets selected, execute on self
            if not fired then
                local fullCmd = getPrefix() .. cmd
                ReplicatedStorage:WaitForChild("HDAdminClient"):WaitForChild("Signals"):WaitForChild("RequestCommand"):InvokeServer(fullCmd)
            end
        end
    end
end

-- Toggle targets panel
dropdownBtn.MouseButton1Click:Connect(function()
    targetsPanel.Visible = not targetsPanel.Visible
    if targetsPanel.Visible then
        refreshPlayerList()
    end
end)

-- Close targets panel
closeBtn.MouseButton1Click:Connect(function()
    targetsPanel.Visible = false
end)

-- Selection buttons
allBtn.MouseButton1Click:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        selectedTargets[player.Name] = true
    end
    refreshPlayerList()
end)

othersBtn.MouseButton1Click:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        selectedTargets[player.Name] = player ~= localPlayer
    end
    refreshPlayerList()
end)

clearBtn.MouseButton1Click:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        selectedTargets[player.Name] = false
    end
    refreshPlayerList()
end)

-- Execute command
executeBtn.MouseButton1Click:Connect(executeCommand)

-- Execute on Enter key
cmdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        executeCommand()
    end
end)

-- Loop functionality
loopToggle.MouseButton1Click:Connect(function()
    looping = not looping
    if looping then
        loopToggle.Text = "Loop: On"
        loopToggle.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
        
        task.spawn(function()
            while looping do
                executeCommand()
                local delay = tonumber(delayInput.Text) or 1
                task.wait(delay)
            end
        end)
    else
        loopToggle.Text = "Loop: Off"
        loopToggle.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    end
end)

-- Make command bar draggable using the drag handle
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    cmdBar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    
    -- Also update the targets panel position relative to the command bar
    if targetsPanel.Visible then
        targetsPanel.Position = UDim2.new(0.5, -190, 0, cmdBar.Position.Y.Offset + 36)
    end
end

-- Handle both mouse and touch input for dragging
local function onInputBegan(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = cmdBar.Position
        
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                connection:Disconnect()
            end
        end)
    end
end

local function onInputChanged(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        update(input)
    end
end

dragHandle.InputBegan:Connect(onInputBegan)
dragHandle.InputChanged:Connect(onInputChanged)

-- Also handle input changes through UserInputService for better mobile support
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        update(input)
    end
end)

-- Initial setup
refreshPlayerList()
return "Cmdbar3 Loaded!."
end

local ftiLoopRunning = false
local ftiLoopConnection

local function fti()
    local lp = Players.LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()

    local function fireTouch(part)
        if not part:IsA("BasePart") then return end
        for _, ti in ipairs(part:GetChildren()) do
            if ti:IsA("TouchTransmitter") then
                for _, myPart in ipairs(char:GetDescendants()) do
                    if myPart:IsA("BasePart") then
                        firetouchinterest(myPart, part, 0)
                        task.wait()
                        firetouchinterest(myPart, part, 1)
                    end
                end
            end
        end
    end

    for _, v in ipairs(workspace:GetDescendants()) do
        fireTouch(v)
    end
    return "Fired all TouchInterests"
end

local function ftiloop()
    if ftiLoopRunning then
        return "FTI loop is already running"
    end
    
    ftiLoopRunning = true
    
    ftiLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local success, err = pcall(function()
            fti()
        end)
        
        if not success then
            
        end
        
        task.wait(0.01) -- 0.01 second interval
    end)
    
    return "FTI loop started"
end

local function unftiloop()
    if not ftiLoopRunning then
        return "FTI loop is not running"
    end
    
    if ftiLoopConnection then
        ftiLoopConnection:Disconnect()
        ftiLoopConnection = nil
    end
    
    ftiLoopRunning = false
    return "FTI loop stopped"
end

local cdLoopRunning = false
local cdLoopConnection

local function fireClickDetectors()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if not humanoid then
        crx("No HRP!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    
    local firedCount = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local success, err = pcall(function()
                fireclickdetector(obj, humanoid)
            end)
            
            if success then
                firedCount += 1
            else
                crx("ERROR!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
            end
        end
    end
    
    return "Fired " .. firedCount .. " ClickDetectors"
end

local function cdloop()
    if cdLoopRunning then
        return "ClickDetector loop is already running"
    end
    
    cdLoopRunning = true
    
    cdLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local success, err = pcall(function()
            fireClickDetectors()
        end)
        
        if not success then
            crx("ERROR!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        end
        
        task.wait(0.01) -- 0.01 second interval
    end)
    
    return "ClickDetector loop started"
end

local function uncdloop()
    if not cdLoopRunning then
        return "ClickDetector loop is not running"
    end
    
    if cdLoopConnection then
        cdLoopConnection:Disconnect()
        cdLoopConnection = nil
    end
    
    cdLoopRunning = false
    return "ClickDetector loop stopped"
end

local ppLoopRunning = false
local ppLoopConnection

local function fireProximityPrompts()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart then
        crx("No HRP!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    
    local firedCount = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local success, err = pcall(function()
                -- Fire the ProximityPrompt
                fireproximityprompt(obj)
            end)
            
            if success then
                firedCount += 1
            else
                crx("ERROR!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
            end
        end
    end
    
    return "Fired " .. firedCount .. " ProximityPrompts"
end

local function pploop()
    if ppLoopRunning then
        return "ProximityPrompt loop is already running"
    end
    
    ppLoopRunning = true
    print("ProximityPrompt loop started (0.01s interval)")
    
    ppLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local success, err = pcall(function()
            fireProximityPrompts()
        end)
        
        if not success then
            warn("Error in ProximityPrompt loop: " .. tostring(err))
        end
        
        task.wait(0.1)
    end)
    
    return "ProximityPrompt loop started"
end

local function unpploop()
    if not ppLoopRunning then
        return "ProximityPrompt loop is not running"
    end
    
    if ppLoopConnection then
        ppLoopConnection:Disconnect()
        ppLoopConnection = nil
    end
    
    ppLoopRunning = false
    return "ProximityPrompt loop stopped"
end

local function pmg()

local player = game.Players.LocalPlayer;
local playerGui = player:FindFirstChild("PlayerGui");

local re = game:GetService("Workspace");
local sandbox = function(var, func)
	local env = getfenv(func);
	local newenv = setmetatable({}, {__index=function(self, k)
		if (k == "script") then
			return var;
		else
			return env[k];
		end
	end});
	setfenv(func, newenv);
	return func;
end;
cors = {};
local _Name = "Telekinesis";
local uis = game:GetService("UserInputService");
local _Ins, _CF_new, _VTR_new = Instance.new, CFrame.new, Vector3.new;
mas = _Ins("Model", game:GetService("Lighting"));
local con = getfenv().sethiddenproperty;
Tool0 = _Ins("Tool");
Part1 = _Ins("Part");
Script2 = _Ins("Script");
local light = _Ins("Highlight", Tool0);
light.FillTransparency = 1;
light.OutlineColor = Color3.new(0, 255, 0);
LocalScript3 = _Ins("LocalScript");
re = game:GetService("RunService");
Tool0.Name = _Name;
Tool0.Parent = mas;
Tool0.Grip = _CF_new(0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1);
Tool0.GripPos = _VTR_new(0, 0, 1);
Part1.Name = "Handle";
Part1.Parent = Tool0;
local changed = "Changed";
Part1.CFrame = _CF_new(-3.5, 5.30000019, -3.5, 1, 0, 0, 0, -1, 0, 0, 0, -1);
Part1.Orientation = _VTR_new(0, 180, 180);
Part1.Position = _VTR_new(-3.5, 5.300000190734863, -3.5);
Part1.Rotation = _VTR_new(-180, 0, 0);
Part1.Color = Color3.new(0.972549, 0.972549, 0.972549);
Part1.Transparency = 1;
local cam = re.RenderStepped;
local w = wait;
Part1.Size = _VTR_new(1, 1, 1);
Part1.BottomSurface = Enum.SurfaceType.Smooth;
Part1.BrickColor = BrickColor.new("Institutional white");
Part1.Locked = true;
local speed = 55;
local mb = uis.TouchEnabled;
Part1.TopSurface = Enum.SurfaceType.Smooth;
Part1.brickColor = BrickColor.new("Institutional white");
Script2.Name = "LineConnect";
Script2.Parent = Tool0;
light.Adornee = nil;
local Sound = _Ins("Sound", game.Workspace);
Sound.SoundId = "rbxassetid://755341345";
Sound:Play();
cam:Connect(function()
	if con then
		con(game:GetService("Players").LocalPlayer, changed, speed);
	end
end);
table.insert(cors, sandbox(Script2, function()
	w();
	local check = script.Part2;
	local part1 = script.Part1.Value;
	local part2 = script.Part2.Value;
	local parent = script.Par.Value;
	local color = script.Color;
	local line = _Ins("Part");
	line.TopSurface = 0;
	line.BottomSurface = 0;
	line.Reflectance = 0.5;
	line.Name = "Laser";
	line.Locked = true;
	line.CanCollide = false;
	line.Anchored = true;
	line.formFactor = 0;
	line.Size = _VTR_new(1, 1, 1);
	local mesh = _Ins("BlockMesh");
	mesh.Parent = line;
	while true do
		if (check.Value == nil) then
			break;
		end
		if ((part1 == nil) or (part2 == nil) or (parent == nil)) then
			break;
		end
		if ((part1.Parent == nil) or (part2.Parent == nil)) then
			break;
		end
		if (parent.Parent == nil) then
			break;
		end
		local lv = _CF_new(part1.Position, part2.Position);
		local dist = (part1.Position - part2.Position).magnitude;
		line.Parent = parent;
		line.BrickColor = color.Value.BrickColor;
		line.Reflectance = color.Value.Reflectance;
		line.Transparency = color.Value.Transparency;
		line.CFrame = _CF_new(part1.Position + (lv.lookVectordist / 2));
		line.CFrame = _CF_new(line.Position, part2.Position);
		mesh.Scale = _VTR_new(0.25, 0.25, dist);
		w();
	end
	line:remove();
	script:remove();
end));
changed = "SimulationRadius";
Script2.Disabled = true;
LocalScript3.Name = "MainScript";
LocalScript3.Parent = Tool0;
local pointLight = _Ins("PointLight", Part1);
pointLight.Color = Color3.new(0, 255, 0);
pointLight.Range = 30;
pointLight.Brightness = 2;
table.insert(cors, sandbox(LocalScript3, function()
	w();
	tool = script.Parent;
	lineconnect = tool.LineConnect;
	object = nil;
	mousedown = false;
	found = false;
	BP = _Ins("BodyPosition");
	BP.maxForce = _VTR_new(math.huge, math.huge, math.huge);
	BP.P = BP.P * 3;
	dist = 1000;
	point = _Ins("Part");
	point.Locked = true;
	point.Anchored = true;
	point.formFactor = 0;
	point.Shape = 0;
	point.BrickColor = BrickColor.Blue();
	point.Size = _VTR_new(0, 0, 0);
	point.CanCollide = false;
	local mesh = _Ins("SpecialMesh");
	mesh.MeshType = "Sphere";
	mesh.Scale = _VTR_new(0.7, 0.7, 0.7);
	mesh.Parent = point;
	handle = tool.Handle;
	front = tool.Handle;
	color = tool.Handle;
	objval = nil;
	local hooked = false;
	local hookBP = BP:clone();
	hookBP.maxForce = _VTR_new(30000, 30000, 30000);
	local equipSound = Instance.new("Sound");
	equipSound.SoundId = "rbxassetid://8717291772";
	equipSound.Volume = 1;
	equipSound.Parent = tool.Handle;
	local tapSound = Instance.new("Sound");
	tapSound.SoundId = "rbxassetid://7496207231";
	tapSound.Volume = 1;
	tapSound.Parent = tool.Handle;
	local function enableNoclip()
		local character = player.Character;
		if character then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false;
				end
			end
		end
	end
	local function disableNoclip()
		local character = player.Character;
		if character then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true;
				end
			end
		end
	end
	local function onEquipped(mouse)
		equipSound:Play();
		enableNoclip();
		keymouse = mouse;
	end
	tool.Unequipped:Connect(function()
		mousedown = false;
		disableNoclip();
	end);
	tool.Equipped:Connect(onEquipped);
	local onButton1Down = function(mouse)
		if (mousedown == true) then
			return;
		end
		mousedown = true;
		tapSound:Play();
		coroutine.resume(coroutine.create(function()
			local p = point:clone();
			p.Parent = tool;
			LineConnect(front, p, workspace);
			while mousedown == true do
				p.Parent = tool;
				if (object == nil) then
					if (mouse.Target == nil) then
						local lv = _CF_new(front.Position, mouse.Hit.p);
						p.CFrame = _CF_new(front.Position + (lv.lookVector * dist));
					else
						p.CFrame = _CF_new(mouse.Hit.p);
					end
				else
					LineConnect(front, object, workspace);
					break;
				end
				w();
			end
			p:remove();
		end));
		while mousedown == true do
			if (mouse.Target ~= nil) then
				local t = mouse.Target;
				if (t.Anchored == false) then
					object = t;
					light.Adornee = object;
					dist = (object.Position - front.Position).magnitude;
					break;
				end
			end
			w();
		end
		while mousedown == true do
			if (object.Parent == nil) then
				break;
			end
			local lv = _CF_new(front.Position, mouse.Hit.p);
			BP.Parent = object;
			BP.position = front.Position + (lv.lookVector * dist);
			w();
		end
		BP:remove();
		object = nil;
		objval.Value = nil;
		light.Adornee = nil;
	end;
	local onKeyDown = function(key, mouse)
		local key = key:lower();
		local yesh = false;
		if (key == "q") then
			if (dist >= 5) then
				dist = dist - 5;
			end
		end
		if (key == "u") then
			if (dist ~= 1) then
				BX = _Ins("BodyGyro");
				BX.MaxTorque = _VTR_new(math.huge, 0, math.huge);
				BX.CFrame = BX.CFrame * CFrame.Angles(0, math.rad(45), 0);
				BX.D = 0;
				BX.Parent = object;
			end
		end
		if (key == "p") then
			if (dist ~= 1) then
				BX = _Ins("BodyVelocity");
				BX.maxForce = _VTR_new(0, math.huge, 0);
				BX.velocity = _VTR_new(0, 1, 0);
				BX.Parent = object;
			end
		end
		if (key == "l") then
			if (object == nil) then
				return;
			end
			for _, v in pairs(object:children()) do
				if (v.className == "BodyGyro") then
					return nil;
				end
			end
			BG = _Ins("BodyGyro");
			BG.maxTorque = _VTR_new(math.huge, math.huge, math.huge);
			BG.cframe = _CF_new(object.CFrame.p);
			BG.Parent = object;
			repeat
				w();
			until object.CFrame == _CF_new(object.CFrame.p) 
			BG.Parent = nil;
			if (object == nil) then
				return;
			end
			for _, v in pairs(object:children()) do
				if (v.className == "BodyGyro") then
					v.Parent = nil;
				end
			end
			object.Velocity = _VTR_new(0, 0, 0);
			object.RotVelocity = _VTR_new(0, 0, 0);
		end
		if (key == "y") then
			if (dist ~= 500) then
				dist = 500;
			end
		end
		if (key == "j") then
			if (dist ~= 5000) then
				dist = 5000;
			end
		end
		if (key == "e") then
			dist = dist + 5;
		end
		if (key == "x") then
			if (dist ~= 15) then
				dist = 15;
			end
		end
	end;
	local onEquipped = function(mouse)
		equipSound:Play();
		enableNoclip();
		keymouse = mouse;
		local char = tool.Parent;
		human = char.Humanoid;
		human.Changed:connect(function()
			if (human.Health == 0) then
				mousedown = false;
				BP:remove();
				point:remove();
				tool:remove();
			end
		end);
		mouse.Button1Down:connect(function()
			onButton1Down(mouse);
		end);
		mouse.KeyDown:connect(function(key)
			onKeyDown(key, mouse);
		end);
		if mb then
			uis.TouchLongPress:Connect(function()
				onKeyDown("y", mouse);
			end);
			uis.TouchEnded:Connect(function()
				mousedown = false;
			end);
		else
			mouse.Button1Up:connect(function()
				mousedown = false;
			end);
		end
	end;
	tool.Equipped:connect(onEquipped);
	tool.Unequipped:connect(function()
		mousedown = false;
		disableNoclip();
	end);
end));
for i, v in pairs(mas:GetChildren()) do
	v.Parent = game:GetService("Players").LocalPlayer.Backpack;
	pcall(function()
		v:MakeJoints();
	end);
end
mas:Destroy();
for i, v in pairs(cors) do
	spawn(function()
		pcall(v);
	end);
end
return "TelekinesisTool Created!"
end

function CreateFlingGun()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        warn("Backpack not found!")
        return
    end
    
    -- Remove existing tool if any
    local existingTool = backpack:FindFirstChild("FlingGun")
    if existingTool then
        existingTool:Destroy()
    end
    
    -- Create the FlingGun
    local tool = Instance.new("Tool")
    tool.Name = "FlingGun"
    tool.ToolTip = "FlingGun - Click players to fling them"
    tool.RequiresHandle = true
    tool.Parent = backpack
    
    -- Create tool handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 2, 1)
    handle.BrickColor = BrickColor.new("Bright blue")
    handle.Material = Enum.Material.Neon
    handle.Parent = tool
    
    -- Create mesh
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://135128080" -- Gun mesh
    mesh.TextureId = "rbxassetid://94242778"
    mesh.Scale = Vector3.new(0.5, 0.5, 0.5)
    mesh.Parent = handle
    
    -- Create shoot sound
    local shootSound = Instance.new("Sound")
    shootSound.SoundId = "rbxassetid://7026894166"
    shootSound.Volume = 1
    shootSound.Parent = handle
    
    -- Create highlight for target
    local highlight = Instance.new("Highlight")
    highlight.Name = "TargetHighlight"
    highlight.Enabled = false
    highlight.FillColor = Color3.fromRGB(255, 255, 0) -- Yellow
    highlight.OutlineColor = Color3.fromRGB(255, 200, 0)
    highlight.FillTransparency = 0.5
    highlight.Parent = tool
    
    -- Animation track
    local animationTrack = nil
    
    -- Store original transparency values
    local originalTransparency = {}
    local invisibleTimer = 0
    local maxInvisibleTime = 3 -- 5 seconds max invisibility
    local invisibilityCheck = nil
    
    -- Function to make player invisible
    local function makeInvisible()
        local character = player.Character
        if not character then return end
        
        -- Stop any existing invisibility check
        if invisibilityCheck then
            invisibilityCheck:Disconnect()
            invisibilityCheck = nil
        end
        
        originalTransparency = {}
        
        -- Make all parts transparent
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalTransparency[part] = part.Transparency
                part.Transparency = 1
            elseif part:IsA("Decal") or part:IsA("Texture") then
                originalTransparency[part] = part.Transparency
                part.Transparency = 1
            end
        end
        
        -- Hide accessories
        for _, accessory in ipairs(character:GetChildren()) do
            if accessory:IsA("Accessory") and accessory:FindFirstChild("Handle") then
                originalTransparency[accessory.Handle] = accessory.Handle.Transparency
                accessory.Handle.Transparency = 1
            end
        end
        
        -- Start invisibility timer
        invisibleTimer = 0
        invisibilityCheck = game:GetService("RunService").Heartbeat:Connect(function(dt)
            invisibleTimer = invisibleTimer + dt
            
            -- Auto make visible if invisible for too long
            if invisibleTimer >= maxInvisibleTime then
                makeVisible()
                if invisibilityCheck then
                    invisibilityCheck:Disconnect()
                    invisibilityCheck = nil
                end
            end
        end)
    end
    
    -- Function to make player visible again
    local function makeVisible()
        local character = player.Character
        if not character then return end
        
        -- Stop invisibility check
        if invisibilityCheck then
            invisibilityCheck:Disconnect()
            invisibilityCheck = nil
        end
        
        -- Restore original transparency
        for object, transparency in pairs(originalTransparency) do
            if object and object.Parent then
                object.Transparency = transparency
            end
        end
        
        originalTransparency = {}
        invisibleTimer = 0
    end
    
    -- Visual effects function (always shows)
    local function createVisualEffects()
        -- Muzzle flash
        local flash = Instance.new("Part")
        flash.Size = Vector3.new(0.5, 0.5, 0.5)
        flash.BrickColor = BrickColor.new("Bright yellow")
        flash.Material = Enum.Material.Neon
        flash.Anchored = true
        flash.CanCollide = false
        flash.CFrame = handle.CFrame * CFrame.new(0, 0, -1)
        flash.Parent = workspace
        
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 10
        pointLight.Range = 15
        pointLight.Color = Color3.fromRGB(255, 255, 0)
        pointLight.Parent = flash
        
        game:GetService("TweenService"):Create(flash, TweenInfo.new(0.3), {Size = Vector3.new(0, 0, 0)}):Play()
        game:GetService("TweenService"):Create(pointLight, TweenInfo.new(0.3), {Brightness = 0}):Play()
        game:GetService("Debris"):AddItem(flash, 0.4)
        
        -- Camera effects
        local camera = workspace.CurrentCamera
        local originalCFrame = camera.CFrame
        
        -- Camera shake
        local shakeIntensity = 0.5
        for i = 1, 10 do
            camera.CFrame = originalCFrame * CFrame.new(
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity)
            )
            task.wait(0.01)
        end
        camera.CFrame = originalCFrame
        
        -- Camera FOV effect
        local originalFOV = camera.FieldOfView
        camera.FieldOfView = originalFOV + 10
        game:GetService("TweenService"):Create(camera, TweenInfo.new(0.3), {FieldOfView = originalFOV}):Play()
    end
    
    -- Tool equipped event
    tool.Equipped:Connect(function()
        -- Play equip sound
        local equipSound = Instance.new("Sound")
        equipSound.SoundId = "rbxassetid://7026893899"
        equipSound.Volume = 0.5
        equipSound.Parent = handle
        equipSound:Play()
        game:GetService("Debris"):AddItem(equipSound, 2)
        
        -- Load animation
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://94242777"
                animationTrack = animator:LoadAnimation(animation)
                animationTrack:Play()
            end
        end
    end)
    
    -- Tool unequipped event
    tool.Unequipped:Connect(function()
        if animationTrack then
            animationTrack:Stop()
            animationTrack = nil
        end
        highlight.Enabled = false
        highlight.Adornee = nil
        makeVisible() -- Ensure player becomes visible again
    end)
    
    -- Tool activated event (shooting)
    tool.Activated:Connect(function()
        -- Play shoot sound
        shootSound:Play()
        
        -- Always show visual effects, even if not targeting player
        createVisualEffects()
        
        -- Get mouse target
        local mouse = player:GetMouse()
        local target = mouse.Target
        local targetPlayer = nil
        
        -- Find if target is a player
        if target then
            local model = target:FindFirstAncestorOfClass("Model")
            if model then
                targetPlayer = game.Players:GetPlayerFromCharacter(model)
            end
        end
        
        if targetPlayer and targetPlayer ~= player then
            -- Make player invisible
            makeInvisible()
            
            -- Highlight target
            highlight.Adornee = targetPlayer.Character
            highlight.Enabled = true
            
            -- Execute fling on target
            SkidFling(targetPlayer)
            
            -- Remove highlight and make visible after shorter delay
            task.delay(1, function()
                highlight.Enabled = false
                highlight.Adornee = nil
                makeVisible() -- Make player visible again after fling process
            end)
        else
            -- Play empty click sound for missed shot
            local clickSound = Instance.new("Sound")
            clickSound.SoundId = "rbxassetid://131147845"
            clickSound.Volume = 0.3
            clickSound.Parent = handle
            clickSound:Play()
            game:GetService("Debris"):AddItem(clickSound, 2)
        end
    end)
    
    -- Mouse movement (target highlighting)
    local mouse = player:GetMouse()
    mouse.Move:Connect(function()
        if tool.Parent == player.Character then
            local target = mouse.Target
            local targetPlayer = nil
            
            if target then
                local model = target:FindFirstAncestorOfClass("Model")
                if model then
                    targetPlayer = game.Players:GetPlayerFromCharacter(model)
                end
            end
            
            if targetPlayer and targetPlayer ~= player then
                highlight.Adornee = targetPlayer.Character
                highlight.Enabled = true
            else
                highlight.Enabled = false
                highlight.Adornee = nil
            end
        end
    end)
    
    -- Auto cleanup if character is lost
    game.Players.LocalPlayer.CharacterRemoving:Connect(function()
        makeVisible() -- Ensure visibility is restored
        if invisibilityCheck then
            invisibilityCheck:Disconnect()
            invisibilityCheck = nil
        end
    end)
    
    return tool
end

-- BToolPunch Tool Creation Function
function CreateBToolPunch()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        warn("Backpack not found!")
        return
    end
    
    -- Remove existing tool if any
    local existingTool = backpack:FindFirstChild("BToolPunch")
    if existingTool then
        existingTool:Destroy()
    end
    
    -- Create the BToolPunch
    local tool = Instance.new("Tool")
    tool.Name = "BToolPunch"
    tool.ToolTip = "BToolPunch - Punch players to kill"
    tool.RequiresHandle = false
    tool.Parent = backpack
    
    -- Create punch sound
    local punchSound = Instance.new("Sound")
    punchSound.SoundId = "rbxassetid://1033173157" -- Punch sound
    punchSound.Volume = 0.7
    punchSound.Parent = handle
    
    -- Animation track
    local animationTrack = nil
    
    -- Cooldown state
    local cooldown = false
    local punchRange = 10 -- Studs range
    
    -- Function to execute bkill on target
    local function ExecuteBkill(targetPlayer)
        local character = player.Character
        if not character then return false end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end

        -- Find Building Tools
        local btools = player:FindFirstChild("Backpack") and 
                      player.Backpack:FindFirstChild("Building Tools") or
                      character:FindFirstChild("Building Tools")
        
        if not btools then 
            warn("Building Tools not found!")
            return false 
        end

        local syncAPI = btools:FindFirstChild("SyncAPI")
        local serverEndpoint = syncAPI and syncAPI:FindFirstChild("ServerEndpoint")
        if not serverEndpoint then 
            warn("ServerEndpoint not found!")
            return false 
        end

        -- Execute kill on target
        if targetPlayer and targetPlayer.Character then
            local torso = targetPlayer.Character:FindFirstChild("Torso") or 
                         targetPlayer.Character:FindFirstChild("UpperTorso")
            if torso then
                pcall(function()
                    serverEndpoint:InvokeServer("Remove", {torso})
                end)
                return true
            end
        end
        return false
    end
    
    -- Function to check if target is in range
    local function isTargetInRange(targetCharacter)
        local character = player.Character
        if not character or not targetCharacter then return false end
        
        local localRoot = character:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        
        if not localRoot or not targetRoot then return false end
        
        local distance = (localRoot.Position - targetRoot.Position).Magnitude
        return distance <= punchRange
    end
    
    -- Tool equipped event
    tool.Equipped:Connect(function()
        -- Load punch animation
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://204062532" -- Punch animation
                animationTrack = animator:LoadAnimation(animation)
            end
        end
    end)
    
    -- Tool unequipped event
    tool.Unequipped:Connect(function()
        if animationTrack then
            animationTrack:Stop()
            animationTrack = nil
        end
        cooldown = false
    end)
    
    -- Tool activated event (punching)
    tool.Activated:Connect(function()
        if cooldown then return end
        cooldown = true
        
        -- Play punch sound
        punchSound:Play()
        
        -- Play punch animation
        if animationTrack then
            animationTrack:Stop()
            animationTrack:Play()
        end
        
        -- Find closest player in range
        local closestPlayer = nil
        local closestDistance = punchRange + 1
        
        for _, targetPlayer in ipairs(game.Players:GetPlayers()) do
            if targetPlayer ~= player and targetPlayer.Character then
                if isTargetInRange(targetPlayer.Character) then
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetRoot and localRoot then
                        local distance = (localRoot.Position - targetRoot.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = targetPlayer
                        end
                    end
                end
            end
        end
        
        if closestPlayer then
            -- Execute bkill on closest player
            local success = ExecuteBkill(closestPlayer)
            if success then
                warn("Punched " .. closestPlayer.Name)
            else
                warn("Failed to punch " .. closestPlayer.Name)
            end
        else
            warn("No player in punching range!")
        end
        
        -- Cooldown
        task.wait(0.5)
        cooldown = false
    end)
    
    -- Visual range indicator (optional)
    local rangeSphere = Instance.new("Part")
    rangeSphere.Name = "RangeIndicator"
    rangeSphere.Size = Vector3.new(punchRange * 2, 0.1, punchRange * 2)
    rangeSphere.Transparency = 1
    rangeSphere.BrickColor = BrickColor.new("Bright orange")
    rangeSphere.Material = Enum.Material.Neon
    rangeSphere.Anchored = true
    rangeSphere.CanCollide = false
    rangeSphere.Parent = tool
    rangeSphere.Visible = false
    
    -- Show range when equipped
    tool.Equipped:Connect(function()
        rangeSphere.Visible = true
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rangeSphere.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
            end
        end
    end)
    
    tool.Unequipped:Connect(function()
        rangeSphere.Visible = false
    end)
    
    -- Update range indicator position
    game:GetService("RunService").Heartbeat:Connect(function()
        if rangeSphere.Visible and player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rangeSphere.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)
            end
        end
    end)
    
    return tool
end

-- BtoolGun Tool Creation Function
function CreateBtoolGun()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        warn("Backpack not found!")
        return
    end
    
    -- Remove existing tool if any
    local existingTool = backpack:FindFirstChild("BtoolGun")
    if existingTool then
        existingTool:Destroy()
    end
    
    -- Create the BToolGun
    local tool = Instance.new("Tool")
    tool.Name = "BtoolGun"
    tool.ToolTip = "BtoolGun - Click players to kill them"
    tool.RequiresHandle = true
    tool.Parent = backpack
    
    -- Create tool handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 2, 1)
    handle.BrickColor = BrickColor.new("Bright blue")
    handle.Material = Enum.Material.Neon
    handle.Parent = tool
    
    -- Create mesh
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://94242777" -- Gun mesh
    mesh.TextureId = "rbxassetid://94242778"
    mesh.Scale = Vector3.new(0.5, 0.5, 0.5)
    mesh.Parent = handle
    
    -- Create shoot sound
    local shootSound = Instance.new("Sound")
    shootSound.SoundId = "rbxassetid://7026894166"
    shootSound.Volume = 1
    shootSound.Parent = handle
    
    -- Create highlight for target
    local highlight = Instance.new("Highlight")
    highlight.Name = "TargetHighlight"
    highlight.Enabled = false
    highlight.FillColor = Color3.fromRGB(255, 255, 0) -- Yellow
    highlight.OutlineColor = Color3.fromRGB(255, 200, 0)
    highlight.FillTransparency = 0.5
    highlight.Parent = tool
    
    -- Animation track
    local animationTrack = nil
    
    -- Cooldown state
    local cooldown = false
    
    -- Function to execute bkill on target
    local function ExecuteBkill(targetPlayer)
        local character = player.Character
        if not character then return false end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return false end

        -- Find Building Tools
        local btools = player:FindFirstChild("Backpack") and 
                      player.Backpack:FindFirstChild("Building Tools") or
                      character:FindFirstChild("Building Tools")
        
        if not btools then return false end

        local syncAPI = btools:FindFirstChild("SyncAPI")
        local serverEndpoint = syncAPI and syncAPI:FindFirstChild("ServerEndpoint")
        if not serverEndpoint then return false end

        -- Execute kill on target
        if targetPlayer and targetPlayer.Character then
            local torso = targetPlayer.Character:FindFirstChild("Torso") or 
                         targetPlayer.Character:FindFirstChild("UpperTorso")
            if torso then
                pcall(function()
                    serverEndpoint:InvokeServer("Remove", {torso})
                end)
                return true
            end
        end
        return false
    end
    
    -- Visual effects function (always shows)
    local function createVisualEffects()
        -- Muzzle flash
        local flash = Instance.new("Part")
        flash.Size = Vector3.new(0.5, 0.5, 0.5)
        flash.BrickColor = BrickColor.new("Bright yellow")
        flash.Material = Enum.Material.Neon
        flash.Anchored = true
        flash.CanCollide = false
        flash.CFrame = handle.CFrame * CFrame.new(0, 0, -1)
        flash.Parent = workspace
        
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 10
        pointLight.Range = 15
        pointLight.Color = Color3.fromRGB(255, 255, 0)
        pointLight.Parent = flash
        
        game:GetService("TweenService"):Create(flash, TweenInfo.new(0.3), {Size = Vector3.new(0, 0, 0)}):Play()
        game:GetService("TweenService"):Create(pointLight, TweenInfo.new(0.3), {Brightness = 0}):Play()
        game:GetService("Debris"):AddItem(flash, 0.4)
        
        -- Camera effects
        local camera = workspace.CurrentCamera
        local originalCFrame = camera.CFrame
        
        -- Camera shake
        local shakeIntensity = 0.5
        for i = 1, 10 do
            camera.CFrame = originalCFrame * CFrame.new(
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity)
            )
            task.wait(0.01) -- Faster shake
        end
        camera.CFrame = originalCFrame
        
        -- Camera blur (simulated with FOV change)
        local originalFOV = camera.FieldOfView
        camera.FieldOfView = originalFOV + 10
        game:GetService("TweenService"):Create(camera, TweenInfo.new(0.3), {FieldOfView = originalFOV}):Play() -- Faster blur recovery
    end
    
    -- Tool equipped event
    tool.Equipped:Connect(function()
        -- Play equip sound
        local equipSound = Instance.new("Sound")
        equipSound.SoundId = "rbxassetid://7026893899"
        equipSound.Volume = 0.5
        equipSound.Parent = handle
        equipSound:Play()
        game:GetService("Debris"):AddItem(equipSound, 2)
        
        -- Load animation
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://94242777"
                animationTrack = animator:LoadAnimation(animation)
                animationTrack:Play()
            end
        end
    end)
    
    -- Tool unequipped event
    tool.Unequipped:Connect(function()
        if animationTrack then
            animationTrack:Stop()
            animationTrack = nil
        end
        highlight.Enabled = false
        highlight.Adornee = nil
        cooldown = false
    end)
    
    -- Tool activated event (shooting)
    tool.Activated:Connect(function()
        if cooldown then return end
        cooldown = true
        
        -- Play shoot sound
        shootSound:Play()
        
        -- Always show visual effects, even if not targeting player
        createVisualEffects()
        
        -- Get mouse target
        local mouse = player:GetMouse()
        local target = mouse.Target
        local targetPlayer = nil
        
        -- Find if target is a player
        if target then
            local model = target:FindFirstAncestorOfClass("Model")
            if model then
                targetPlayer = game.Players:GetPlayerFromCharacter(model)
            end
        end
        
        if targetPlayer and targetPlayer ~= player then
            -- Highlight target
            highlight.Adornee = targetPlayer.Character
            highlight.Enabled = true
            
            -- Execute bkill on target (ONCE)
            ExecuteBkill(targetPlayer)
            
            -- Remove highlight after shorter delay
            task.delay(1, function() -- Faster cooldown (1 second instead of 2)
                highlight.Enabled = false
                highlight.Adornee = nil
                cooldown = false
            end)
        else
            -- Play empty click sound for missed shot
            local clickSound = Instance.new("Sound")
            clickSound.SoundId = "rbxassetid://131147845"
            clickSound.Volume = 0.3
            clickSound.Parent = handle
            clickSound:Play()
            game:GetService("Debris"):AddItem(clickSound, 2)
            
            cooldown = false
        end
    end)
    
    -- Mouse movement (target highlighting)
    local mouse = player:GetMouse()
    mouse.Move:Connect(function()
        if tool.Parent == player.Character then
            local target = mouse.Target
            local targetPlayer = nil
            
            if target then
                local model = target:FindFirstAncestorOfClass("Model")
                if model then
                    targetPlayer = game.Players:GetPlayerFromCharacter(model)
                end
            end
            
            if targetPlayer and targetPlayer ~= player then
                highlight.Adornee = targetPlayer.Character
                highlight.Enabled = true
            else
                highlight.Enabled = false
                highlight.Adornee = nil
            end
        end
    end)
    
    return tool
end

-- NPCGun Function (Fixed with Visual Effects)
function CreateNpcGun()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        warn("Backpack not found!")
        return
    end
    
    -- Remove existing tool if any
    local existingTool = backpack:FindFirstChild("NPCGun")
    if existingTool then
        existingTool:Destroy()
    end
    
    -- Create the NPCGun
    local tool = Instance.new("Tool")
    tool.Name = "NPCGun"
    tool.ToolTip = "NPCGun - Click NPCs to kill them"
    tool.RequiresHandle = true
    tool.Parent = backpack
    
    -- Create tool handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 2, 1)
    handle.BrickColor = BrickColor.new("Bright red")
    handle.Material = Enum.Material.Neon
    handle.Parent = tool
    
    -- Create mesh (same as BToolGun)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://94242777"
    mesh.TextureId = "rbxassetid://94242778"
    mesh.Scale = Vector3.new(0.5, 0.5, 0.5)
    mesh.Parent = handle
    
    -- Create shoot sound (same as BToolGun)
    local shootSound = Instance.new("Sound")
    shootSound.SoundId = "rbxassetid://7026894166"
    shootSound.Volume = 1
    shootSound.Parent = handle
    
    -- Create highlight for target (same as BToolGun)
    local highlight = Instance.new("Highlight")
    highlight.Name = "TargetHighlight"
    highlight.Enabled = false
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.Parent = tool
    
    -- Animation track (same as BToolGun)
    local animationTrack = nil
    
    -- Cooldown state
    local cooldown = false
    
    -- Visual effects function (same as BToolGun)
    local function createVisualEffects()
        -- Muzzle flash
        local flash = Instance.new("Part")
        flash.Size = Vector3.new(0.5, 0.5, 0.5)
        flash.BrickColor = BrickColor.new("Bright yellow")
        flash.Material = Enum.Material.Neon
        flash.Anchored = true
        flash.CanCollide = false
        flash.CFrame = handle.CFrame * CFrame.new(0, 0, -1)
        flash.Parent = workspace
        
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 10
        pointLight.Range = 15
        pointLight.Color = Color3.fromRGB(255, 255, 0)
        pointLight.Parent = flash
        
        game:GetService("TweenService"):Create(flash, TweenInfo.new(0.3), {Size = Vector3.new(0, 0, 0)}):Play()
        game:GetService("TweenService"):Create(pointLight, TweenInfo.new(0.3), {Brightness = 0}):Play()
        game:GetService("Debris"):AddItem(flash, 0.4)
        
        -- Camera effects
        local camera = workspace.CurrentCamera
        local originalCFrame = camera.CFrame
        
        -- Camera shake
        local shakeIntensity = 0.5
        for i = 1, 10 do
            camera.CFrame = originalCFrame * CFrame.new(
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity)
            )
            task.wait(0.01)
        end
        camera.CFrame = originalCFrame
        
        -- Camera FOV effect
        local originalFOV = camera.FieldOfView
        camera.FieldOfView = originalFOV + 10
        game:GetService("TweenService"):Create(camera, TweenInfo.new(0.3), {FieldOfView = originalFOV}):Play()
    end
    
    -- Tool equipped event (same as BToolGun)
    tool.Equipped:Connect(function()
        -- Play equip sound
        local equipSound = Instance.new("Sound")
        equipSound.SoundId = "rbxassetid://7026893899"
        equipSound.Volume = 0.5
        equipSound.Parent = handle
        equipSound:Play()
        game:GetService("Debris"):AddItem(equipSound, 2)
        
        -- Load animation (same as BToolGun)
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://94242777"
                animationTrack = animator:LoadAnimation(animation)
                animationTrack:Play()
            end
        end
    end)
    
    -- Tool unequipped event (same as BToolGun)
    tool.Unequipped:Connect(function()
        if animationTrack then
            animationTrack:Stop()
            animationTrack = nil
        end
        highlight.Enabled = false
        highlight.Adornee = nil
        cooldown = false
    end)
    
    -- Tool activated event (shooting)
    tool.Activated:Connect(function()
        if cooldown then return end
        cooldown = true
        
        -- Play shoot sound
        shootSound:Play()
        
        -- Always show visual effects (same as BToolGun)
        createVisualEffects()
        
        -- Get mouse target
        local mouse = player:GetMouse()
        local target = mouse.Target
        local targetNPC = nil
        
        -- Find if target is an NPC
        if target then
            local model = target:FindFirstAncestorOfClass("Model")
            if model then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if humanoid and not game.Players:GetPlayerFromCharacter(model) then
                    targetNPC = model
                end
            end
        end
        
        if targetNPC then
            -- Highlight target
            highlight.Adornee = targetNPC
            highlight.Enabled = true
            
            -- Kill the NPC
            local humanoid = targetNPC:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
            
            -- Remove highlight after delay
            task.delay(1, function()
                highlight.Enabled = false
                highlight.Adornee = nil
                cooldown = false
            end)
        else
            -- Play empty click sound for missed shot (same as BToolGun)
            local clickSound = Instance.new("Sound")
            clickSound.SoundId = "rbxassetid://131147845"
            clickSound.Volume = 0.3
            clickSound.Parent = handle
            clickSound:Play()
            game:GetService("Debris"):AddItem(clickSound, 2)
            
            cooldown = false
        end
    end)
    
    -- Mouse movement (target highlighting) - Same as BToolGun
    local mouse = player:GetMouse()
    mouse.Move:Connect(function()
        if tool.Parent == player.Character then
            local target = mouse.Target
            local targetNPC = nil
            
            if target then
                local model = target:FindFirstAncestorOfClass("Model")
                if model then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    if humanoid and not game.Players:GetPlayerFromCharacter(model) then
                        targetNPC = model
                    end
                end
            end
            
            if targetNPC then
                highlight.Adornee = targetNPC
                highlight.Enabled = true
            else
                highlight.Enabled = false
                highlight.Adornee = nil
            end
        end
    end)
    
    return tool
end

-- SwordGun Function with Silent Swordkill Integration
function CreateSwordGun()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        warn("Backpack not found!")
        return
    end
    
    -- Remove existing tool if any
    local existingTool = backpack:FindFirstChild("SwordGun")
    if existingTool then
        existingTool:Destroy()
    end
    
    -- Create the SwordGun
    local tool = Instance.new("Tool")
    tool.Name = "SwordGun"
    tool.ToolTip = "SwordGun - click on players to kill them"
    tool.RequiresHandle = true
    tool.Parent = backpack
    
    -- Create tool handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 2, 1)
    handle.BrickColor = BrickColor.new("Bright green")
    handle.Material = Enum.Material.Neon
    handle.Parent = tool
    
    -- Create mesh
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://94242777"
    mesh.TextureId = "rbxassetid://94242778"
    mesh.Scale = Vector3.new(0.5, 0.5, 0.5)
    mesh.Parent = handle
    
    -- Create shoot sound
    local shootSound = Instance.new("Sound")
    shootSound.SoundId = "rbxassetid://7026894166"
    shootSound.Volume = 1
    shootSound.Parent = handle
    
    -- Create highlight for target (IMPROVED)
    local highlight = Instance.new("Highlight")
    highlight.Name = "TargetHighlight"
    highlight.Enabled = false
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = tool
    
    -- Animation track
    local animationTrack = nil
    
    -- Sword detection functions
    local SWORD_NAMES = {
        "sword", "foil", "blade", "katana", "saber", "rapier", "cutlass", "dagger",
        "knife", "longsword", "shortsword", "scimitar", "falchion", "broadsword"
    }

    local function isSword(toolObj)
        if not toolObj then return false end
        local toolName = toolObj.Name:lower()
        for _, name in ipairs(SWORD_NAMES) do
            if toolName:find(name) then
                return true
            end
        end
        return false
    end

    local function findSword()
        local character = player.Character
        if not character then return nil end
        
        -- Check character first
        for _, toolObj in ipairs(character:GetChildren()) do
            if toolObj:IsA("Tool") and isSword(toolObj) then
                return toolObj
            end
        end
        
        -- Check backpack
        if backpack then
            for _, toolObj in ipairs(backpack:GetChildren()) do
                if toolObj:IsA("Tool") and isSword(toolObj) then
                    return toolObj
                end
            end
        end
        
        return nil
    end

    -- Silent swordkill system
    local swordkillActive = false
    local swordkillTarget = nil
    local originalGrip = nil
    local originalMassless = nil

    -- Function to disable tool animations
    local function disableToolAnim()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        end
    end

    -- Function to enable tool animations
    local function enableToolAnim()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        end
    end

    -- Function to stop sounds in object
    local function stopSoundsInObject(obj)
        if not obj then return end
        for _, sound in ipairs(obj:GetDescendants()) do
            if sound:IsA("Sound") then
                sound:Stop()
            end
        end
    end

    -- Function to touch parts (silent version)
    local function silentTouch(part1, part2)
        if part1 and part2 then
            firetouchinterest(part1, part2, 0)
            task.wait()
            firetouchinterest(part1, part2, 1)
        end
    end

    local function forceEquipSword(sword)
        if not sword then return nil end
        
        -- Store original properties
        originalGrip = sword.Grip
        originalMassless = sword.Handle.Massless
        
        -- Make sword invisible and silent
        sword.Handle.Massless = true
        sword.Grip = CFrame.new(0, 5774, 0)
        stopSoundsInObject(sword)
        
        -- Equip the sword
        sword.Parent = player.Character
        task.wait(0.1)
        return sword
    end

    local function restoreSwordProperties(sword)
        if sword and sword.Parent then
            sword.Grip = originalGrip
            sword.Handle.Massless = originalMassless
            stopSoundsInObject(sword)
        end
    end

    local function reEquipSwordGun()
        task.wait(0.5)
        local character = player.Character
        if character and tool and tool.Parent == backpack then
            tool.Parent = character
        end
    end

    local function startSilentSwordKill(targetPlayer)
        swordkillActive = true
        swordkillTarget = targetPlayer
        
        -- Find sword
        local sword = findSword()
        if not sword then
            warn("No sword found for silent swordkill!")
            reEquipSwordGun()
            return
        end
        
        -- Force equip sword with silent properties
        sword = forceEquipSword(sword)
        if not sword then 
            reEquipSwordGun()
            return
        end
        
        -- Disable animations for complete silence
        disableToolAnim()
        
        -- Start silent kill process
        coroutine.wrap(function()
            while swordkillActive and swordkillTarget and swordkillTarget.Character do
                local targetCharacter = swordkillTarget.Character
                local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    -- Silent touch the target's parts
                    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
                    if targetRoot and sword.Handle then
                        silentTouch(targetRoot, sword.Handle)
                    end
                    
                    -- Touch other body parts for reliability
                    for _, part in ipairs(targetCharacter:GetChildren()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            silentTouch(part, sword.Handle)
                        end
                    end
                else
                    -- Target died, stop swordkill
                    swordkillActive = false
                    break
                end
                
                task.wait(0.1)
            end
            
            -- Cleanup and re-equip SwordGun
            enableToolAnim()
            restoreSwordProperties(sword)
            
            -- Unequip sword
            if sword and sword.Parent == player.Character then
                sword.Parent = backpack
            end
            
            swordkillActive = false
            swordkillTarget = nil
            
            if highlight then
                highlight.Enabled = false
                highlight.Adornee = nil
            end
            
            -- Re-equip SwordGun after target dies
            reEquipSwordGun()
        end)()
    end

    -- Death listener
    local function setupDeathListener(targetPlayer)
        if targetPlayer.Character then
            local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Died:Connect(function()
                    if swordkillTarget == targetPlayer then
                        swordkillActive = false
                        enableToolAnim()
                        swordkillTarget = nil
                    end
                end)
            end
        end
        
        targetPlayer.CharacterAdded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(function()
                if swordkillTarget == targetPlayer then
                    swordkillActive = false
                    enableToolAnim()
                    swordkillTarget = nil
                end
            end)
        end)
    end

    -- Visual effects function
    local function createVisualEffects()
        -- Muzzle flash
        local flash = Instance.new("Part")
        flash.Size = Vector3.new(0.5, 0.5, 0.5)
        flash.BrickColor = BrickColor.new("Bright yellow")
        flash.Material = Enum.Material.Neon
        flash.Anchored = true
        flash.CanCollide = false
        flash.CFrame = handle.CFrame * CFrame.new(0, 0, -1)
        flash.Parent = workspace
        
        local pointLight = Instance.new("PointLight")
        pointLight.Brightness = 10
        pointLight.Range = 15
        pointLight.Color = Color3.fromRGB(255, 255, 0)
        pointLight.Parent = flash
        
        game:GetService("TweenService"):Create(flash, TweenInfo.new(0.3), {Size = Vector3.new(0, 0, 0)}):Play()
        game:GetService("TweenService"):Create(pointLight, TweenInfo.new(0.3), {Brightness = 0}):Play()
        game:GetService("Debris"):AddItem(flash, 0.4)
        
        -- Camera effects
        local camera = workspace.CurrentCamera
        local originalCFrame = camera.CFrame
        
        -- Camera shake
        local shakeIntensity = 0.5
        for i = 1, 10 do
            camera.CFrame = originalCFrame * CFrame.new(
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity),
                math.random(-shakeIntensity, shakeIntensity)
            )
            task.wait(0.01)
        end
        camera.CFrame = originalCFrame
        
        -- Camera FOV effect
        local originalFOV = camera.FieldOfView
        camera.FieldOfView = originalFOV + 10
        game:GetService("TweenService"):Create(camera, TweenInfo.new(0.3), {FieldOfView = originalFOV}):Play()
    end
    
    -- Cooldown state
    local cooldown = false
    
    -- Improved targeting function
    local function getTargetPlayer()
        local mouse = player:GetMouse()
        local target = mouse.Target
        local targetPlayer = nil
        
        if mouse.Target then
            local model = mouse.Target:FindFirstAncestorOfClass("Model")
            if model then
                targetPlayer = game.Players:GetPlayerFromCharacter(model)
            end
        end
        
        if not targetPlayer then
            local characters = workspace:GetChildren()
            for _, char in ipairs(characters) do
                if char:IsA("Model") then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if hum and root then
                        local distance = (mouse.Hit.Position - root.Position).Magnitude
                        if distance < 10 then
                            targetPlayer = game.Players:GetPlayerFromCharacter(char)
                            if targetPlayer then break end
                        end
                    end
                end
            end
        end
        
        return targetPlayer
    end

    -- Tool equipped event
    tool.Equipped:Connect(function()
        local equipSound = Instance.new("Sound")
        equipSound.SoundId = "rbxassetid://7026893899"
        equipSound.Volume = 0.5
        equipSound.Parent = handle
        equipSound:Play()
        game:GetService("Debris"):AddItem(equipSound, 2)
        
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local animation = Instance.new("Animation")
                animation.AnimationId = "rbxassetid://94242777"
                animationTrack = animator:LoadAnimation(animation)
                animationTrack:Play()
            end
        end
    end)

    -- Tool unequipped event
    tool.Unequipped:Connect(function()
        if animationTrack then
            animationTrack:Stop()
            animationTrack = nil
        end
        highlight.Enabled = false
        highlight.Adornee = nil
        cooldown = false
        
        if swordkillActive then
            swordkillActive = false
            enableToolAnim()
        end
    end)

    -- Tool activated event
    tool.Activated:Connect(function()
        if cooldown or swordkillActive then return end
        cooldown = true
        
        shootSound:Play()
        createVisualEffects()
        
        local targetPlayer = getTargetPlayer()
        
        if targetPlayer and targetPlayer ~= player then
            swordkillTarget = targetPlayer
            highlight.Adornee = targetPlayer.Character
            highlight.Enabled = true
            
            setupDeathListener(targetPlayer)
            tool.Parent = backpack
            startSilentSwordKill(targetPlayer)
        else
            local clickSound = Instance.new("Sound")
            clickSound.SoundId = "rbxassetid://131147845"
            clickSound.Volume = 0.3
            clickSound.Parent = handle
            clickSound:Play()
            game:GetService("Debris"):AddItem(clickSound, 2)
        end
        
        cooldown = false
    end)

    -- Mouse movement
    local mouse = player:GetMouse()
    mouse.Move:Connect(function()
        if tool.Parent == player.Character then
            local targetPlayer = getTargetPlayer()
            
            if targetPlayer and targetPlayer ~= player then
                highlight.Adornee = targetPlayer.Character
                highlight.Enabled = true
            else
                highlight.Enabled = false
                highlight.Adornee = nil
            end
        end
    end)
    
    return tool
end

local function Vcban()
    game:GetService("VoiceChatService"):joinVoice()
    return "Removed VCBan.."
end

local originalPos = nil

local function re()
crx("Resetting Character\nPlease Wait", 1.1, Color3.fromRGB(0, 255, 0), nil)
    originalPos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
    
    local h = game.Players.LocalPlayer.Character.HumanoidRootPart
    local cam = workspace.CurrentCamera

    if replicatesignal then
        replicatesignal(game.Players.LocalPlayer.ConnectDiedSignalBackend)
    else
        crx("Unable to do FastRespawn\nExecutor may not be supported!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        game.Players.LocalPlayer.Character.Head:Destroy()
    end

    wait(game.Players.RespawnTime - .165)
    game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(15)

    wait(0.5)
    
    -- Teleport back to the saved position if it exists
    if originalPos then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = originalPos
        workspace.CurrentCamera = cam
    end
end

local function res()
    game.Players.LocalPlayer.Character.Head:Destroy()
    return "Resetting Character.."
end

local player = Players.LocalPlayer

local function sit()
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.Sit = true
        return "Sitting.."
    else
        crx("Failed to sit!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end

local function fpsb()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/hm5650/Optiz/refs/heads/main/Optiz.lua'))()()
    return "AntiLag Started"
end

local function DAT()
    -- Get the player's character and backpack
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        crx("Backpack not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Get all tools in the backpack
    local tools = {}
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
        end
    end
    
    -- Drop each tool
    for _, tool in ipairs(tools) do
        -- Equip the tool first (necessary to drop it)
        tool.Parent = character
        task.wait(0.1) -- Small delay to ensure tool is equipped
        
        -- Drop the tool
        tool.Parent = workspace
        tool:FindFirstChild("Handle").Anchored = false -- Ensure it can fall
    end
    
    return "Dropped:\n" .. #tools .. " tools"
end


-- Bypass System
local function InitializeBypass()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "FireServer" then
            return nil
        end
        return old(self, ...)
    end)
    
    for _, v in next, getconnections(game:GetService("ScriptContext").Error) do 
        v:Disable()
    end
    
    for _, v in next, getconnections(game:GetService("LogService").MessageOut) do 
        v:Disable()
    end
end

-- Network Ownership
local function SetupNetwork()
    settings().Physics.AllowSleep = false
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
    
    if not getgenv().NetworkBypass then
        getgenv().NetworkBypass = true
        local old
        old = hookmetamethod(game, "__index", newcclosure(function(self, idx)
            if idx == "NetworkOwnershipRule" then
                return Enum.NetworkOwnership.Manual
            end
            return old(self, idx)
        end))
    end
end

-- Main Destroyer System
local BasePartHandler = {}
BasePartHandler.__index = BasePartHandler

function BasePartHandler.new()
    local self = setmetatable({}, BasePartHandler)
    self.Connections = {}
    self.TargetParts = {}
    return self
end

function BasePartHandler:SetupPart(part)
    if part:IsA("BasePart") and not part.Anchored then
        if not part:IsDescendantOf(LocalPlayer.Character) then
            -- Setup part physics
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            
            -- Create constraints
            local attachment = Instance.new("Attachment")
            attachment.Parent = part
            
            local alignPosition = Instance.new("AlignPosition")
            alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
            alignPosition.Attachment0 = attachment
            alignPosition.MaxForce = 999999999999999
            alignPosition.MaxVelocity = math.huge
            alignPosition.Responsiveness = 200
            alignPosition.Parent = part
            
            local gyro = Instance.new("BodyGyro")
            gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            gyro.P = 100000
            gyro.Parent = part
            
            -- Add to control list
            table.insert(self.TargetParts, {
                Part = part,
                Attachment = attachment,
                AlignPosition = alignPosition,
                Gyro = gyro
            })
        end
    end
end

function BasePartHandler:Start()
    -- Setup all existing parts
    for _, v in ipairs(Workspace:GetDescendants()) do
        self:SetupPart(v)
    end
    
    -- Monitor new parts
    table.insert(self.Connections, Workspace.DescendantAdded:Connect(function(v)
        self:SetupPart(v)
    end))
    
    -- Main control loop
    table.insert(self.Connections, RunService.Heartbeat:Connect(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        sethiddenproperty(LocalPlayer, "MaxSimulationRadius", math.huge)
        
        for _, targetData in ipairs(self.TargetParts) do
            pcall(function()
                local part = targetData.Part
                if part and part.Parent then
                    -- Get random player as target (excluding local player)
                    local potentialTargets = {}
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            table.insert(potentialTargets, player)
                        end
                    end
                    
                    if #potentialTargets > 0 then
                        local randomPlayer = potentialTargets[math.random(1, #potentialTargets)]
                        local targetPos = randomPlayer.Character.HumanoidRootPart.Position
                        
                        -- Crazy movement
                        targetData.AlignPosition.Position = targetPos
                        targetData.Gyro.CFrame = CFrame.new(targetPos) * CFrame.Angles(
                            math.rad(math.random(-360, 360)),
                            math.rad(math.random(-360, 360)),
                            math.rad(math.random(-360, 360))
                        )
                        
                        -- Add force
                        part.Velocity = Vector3.new(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500))
                        part.RotVelocity = Vector3.new(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500))
                    end
                end
            end)
        end
    end))
end

function BasePartHandler:Stop()
    -- Disconnect all connections
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    
    -- Clean up parts
    for _, targetData in ipairs(self.TargetParts) do
        pcall(function()
            if targetData.Part and targetData.Part.Parent then
                targetData.AlignPosition:Destroy()
                targetData.Gyro:Destroy()
                targetData.Attachment:Destroy()
                targetData.Part.CustomPhysicalProperties = nil
            end
        end)
    end
    
    -- Clear tables
    self.Connections = {}
    self.TargetParts = {}
end

-- Initialize everything
local function StartDestroyer()
    InitializeBypass()
    SetupNetwork()
    
    handler = BasePartHandler.new()
    handler:Start()
    
    -- Anti kick & crash
    spawn(function()
        while wait() do
            if LocalPlayer.Character then
                for _, connection in ipairs(getconnections(LocalPlayer.Character.DescendantAdded)) do
                    connection:Disable()
                end
            end
            game:GetService("NetworkClient"):SetOutgoingKBPSLimit(math.huge)
        end
    end)
    return "Tpuaall Started"
end

-- Function to stop the destroyer
local function stopdestroyer()
    if handler then
        handler:Stop()
        handler = nil
        return "Tpuaall stopped"
    else
        return "No active Tpua to stop"
    end
end

AddCommand("respawn", {"res"}, "Respawns your character", res)
AddCommand("reset", {"re"}, "FastResets Your character", re)
AddCommand("fly", {"f"}, "Opens FLYGUI", function() return enableFlight() end)
AddCommand("vehiclefly", {"vfly", "vf"}, "Opens VEHICLEFLYGUI", vfly)
AddCommand("shiftlock", {"sl"}, "Gives you shiftlock", sl)
AddCommand("noclip", {"nc"}, "Walk thru walls", ModeOn)
AddCommand("clip", {"noc"}, "Stops Noclip", ModeOff)

-- Freeze/Anchor command
AddCommand("freeze", {"anchor", "fr"}, "Freezes/anchors your character completely", function()
    if Freeze.Enabled then
        return "You are already frozen! Use 'thaw' or 'unanchor' to unfreeze."
    end
    
    Freeze.Enabled = true
    local character = game.Players.LocalPlayer.Character
    if not character then return "Character not found" end
    
    -- Clear any existing connections first
    if Freeze.Connections.characterDescendantAdded then
        Freeze.Connections.characterDescendantAdded:Disconnect()
        Freeze.Connections.characterDescendantAdded = nil
    end
    
    -- Anchor all base parts
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
        end
    end
    
    -- Stop all movement by zeroing velocities
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end
    
    -- Connect to new parts being added
    Freeze.Connections.characterDescendantAdded = character.DescendantAdded:Connect(function(descendant)
        if Freeze.Enabled and descendant:IsA("BasePart") then
            descendant.Anchored = true
        end
    end)
    
    return "Frozen!"
end)

-- Unfreeze/Unanchor command
AddCommand("thaw", {"unanchor", "unfr"}, "Unfreezes/unanchors your character", function()
    if not Freeze.Enabled then
        return "You are not frozen!"
    end
    
    Freeze.Enabled = false
    local character = game.Players.LocalPlayer.Character
    if not character then return "Character not found" end
    
    -- Disconnect the descendant added connection FIRST
    if Freeze.Connections.characterDescendantAdded then
        Freeze.Connections.characterDescendantAdded:Disconnect()
        Freeze.Connections.characterDescendantAdded = nil
    end
    
    -- Unanchor all base parts
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
        end
    end
    
    -- Return to normal state
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    return "Unfrozen!"
end)

-- Automatic handling for character respawns (fixed)
if not Freeze.Connections.characterAdded then
    Freeze.Connections.characterAdded = game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
        if Freeze.Enabled then
            task.wait(0.5) -- Wait for character to fully load
            
            -- Clear any old connections
            if Freeze.Connections.characterDescendantAdded then
                Freeze.Connections.characterDescendantAdded:Disconnect()
                Freeze.Connections.characterDescendantAdded = nil
            end
            
            -- Anchor new character
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                end
            end
            
            -- Reconnect descendant added for new character
            Freeze.Connections.characterDescendantAdded = character.DescendantAdded:Connect(function(descendant)
                if Freeze.Enabled and descendant:IsA("BasePart") then
                    descendant.Anchored = true
                end
            end)
        end
    end)
end

-- Cleanup when script stops
game:GetService("UserInputService").WindowFocused:Connect(function()
    if not Freeze.Enabled then
        for _, connection in pairs(Freeze.Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        Freeze.Connections = {}
    end
end)

-- List of sword names to look for
local SWORD_NAMES = {
    "sword", "foil", "blade", "katana", "saber", "rapier", "cutlass", "dagger",
    "knife", "longsword", "shortsword", "scimitar", "falchion", "broadsword"
}

-- Function to check if a tool is a sword
local function isSword(tool)
    if not tool then return false end
    local toolName = tool.Name:lower()
    for _, name in ipairs(SWORD_NAMES) do
        if toolName:find(name) then
            return true
        end
    end
    return false
end

-- Function to find a sword in player's inventory
local function findSword()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return nil end
    
    -- Check character first
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and isSword(tool) then
            return tool
        end
    end
    
    -- Check backpack
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and isSword(tool) then
                return tool
            end
        end
    end
    
    return nil
end

-- Function to disable tool animations
local function disableToolAnim()
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    end
end

-- Function to enable tool animations
local function enableToolAnim()
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
    end
end

-- Function to stop sounds in object
local function stopSoundsInObject(obj)
    if not obj then return end
    for _, sound in ipairs(obj:GetDescendants()) do
        if sound:IsA("Sound") then
            sound:Stop()
        end
    end
end

-- Function to touch parts (silent version)
local function silentTouch(part1, part2)
    if part1 and part2 then
        firetouchinterest(part1, part2, 0)
        task.wait()
        firetouchinterest(part1, part2, 1)
    end
end

-- Function to setup death listener for a player
local function setupDeathListener(player)
    if SilentSwordkill.DeadPlayers[player] then return end
    
    local function onCharacterAdded(character)
        if not SilentSwordkill.Active then return end
        
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            SilentSwordkill.DeadPlayers[player] = nil -- Player respawned
            humanoid.Died:Connect(function()
                SilentSwordkill.DeadPlayers[player] = true
            end)
        end
    end
    
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                SilentSwordkill.DeadPlayers[player] = true
            end)
        end
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
end

AddCommandWithPlayer("swordkill", {"skill"}, "Kill players with swords [TOOL]", function(name)
    if SilentSwordkill.Active then
        crx("swordkill is already active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    SilentSwordkill.Active = true
    SilentSwordkill.DeadPlayers = {}
    
    -- Set target
    if not name or name == "all" then
        SilentSwordkill.Target = "all"
        -- Setup death listeners for all players
        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= player then
                setupDeathListener(target)
            end
        end
    else
        local target = GetPlayer(name)
        if not target then 
            crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
            SilentSwordkill.Active = false
            return
        end
        if typeof(target) == "table" then target = target[1] end
        SilentSwordkill.Target = target.Name
        setupDeathListener(target)
    end
    
    -- Check if we have a sword first
    local sword = findSword()
    if not sword then
        crx("No sword found in inventory!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        SilentSwordkill.Active = false
        return
    end
    
    -- Disable animations
    disableToolAnim()
    
    -- Start silent kill loop
    coroutine.wrap(function()
        while SilentSwordkill.Active do
            local character = player.Character
            if not character then 
                task.wait(0.1) 
                continue 
            end
            
            -- Find a sword (only use swords, not any tool)
            local sword = findSword()
            if not sword then 
                crx("Sword not found anymore!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
                SilentSwordkill.Active = false
                break
            end
            
            -- Store original properties if not already stored
            if not SilentSwordkill.OriginalGrip[sword] then
                SilentSwordkill.OriginalGrip[sword] = sword.Grip
                SilentSwordkill.OriginalMassless[sword] = sword.Handle.Massless
                SilentSwordkill.Tools[sword] = true
                
                -- Make sword invisible and silent
                sword.Handle.Massless = true
                sword.Grip = CFrame.new(0, 5774, 0) -- Move sword far away visually
                stopSoundsInObject(sword)
            end
            
            -- Equip sword silently if not already equipped
            if sword.Parent ~= character then
                sword.Parent = character
            end
            
            if SilentSwordkill.Target == "all" then
                -- Kill all players except yourself
                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= player and target.Character and not SilentSwordkill.DeadPlayers[target] then
                        local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            -- Silent touch the target's parts
                            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                            if targetRoot and sword.Handle then
                                silentTouch(targetRoot, sword.Handle)
                            end
                            
                            -- Touch other body parts for reliability
                            for _, part in ipairs(target.Character:GetChildren()) do
                                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                    silentTouch(part, sword.Handle)
                                end
                            end
                        end
                    elseif SilentSwordkill.DeadPlayers[target] then
                        -- Player is dead, do nothing (loop continues for others)
                    end
                end
            else
                -- Kill specific target
                local target = Players:FindFirstChild(SilentSwordkill.Target)
                if target and target.Character and not SilentSwordkill.DeadPlayers[target] then
                    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        -- Silent touch the target's parts
                        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        if targetRoot and sword.Handle then
                            silentTouch(targetRoot, sword.Handle)
                        end
                        
                        -- Touch other body parts for reliability
                        for _, part in ipairs(target.Character:GetChildren()) do
                            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                silentTouch(part, sword.Handle)
                            end
                        end
                    end
                elseif target and SilentSwordkill.DeadPlayers[target] then
                    -- Target is dead, do nothing (loop continues)
                end
            end
            
            task.wait(0.1)
        end
        
        -- Cleanup when loop ends
        enableToolAnim()
        
        -- Restore all sword properties
        for sword, _ in pairs(SilentSwordkill.Tools) do
            if sword and sword.Parent then
                sword.Grip = SilentSwordkill.OriginalGrip[sword]
                sword.Handle.Massless = SilentSwordkill.OriginalMassless[sword]
                stopSoundsInObject(sword)
            end
        end
        
        -- Unequip all tools
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:UnequipTools()
            end
        end
        
        -- Clear stored data
        SilentSwordkill.OriginalGrip = {}
        SilentSwordkill.OriginalMassless = {}
        SilentSwordkill.Tools = {}
        SilentSwordkill.DeadPlayers = {}
    end)()
    
    return "Swordkilled " .. (SilentSwordkill.Target == "all" and "all players" or "target: " .. SilentSwordkill.Target)
end)

AddCommand("unswordkill", {"unskill"}, "Stops silent swordkill loop", function()
    if not SilentSwordkill.Active then
        crx("swordkill wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    SilentSwordkill.Active = false
    return "swordkill stopped"
end)

-- Setup player tracking
game:GetService("Players").PlayerAdded:Connect(function(player)
    if SilentSwordkill.Active and SilentSwordkill.Target == "all" then
        setupDeathListener(player)
    end
end)

-- Auto cleanup
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    if SilentSwordkill.Active then
        SilentSwordkill.Active = false
        enableToolAnim()
        
        -- Restore all sword properties
        for sword, _ in pairs(SilentSwordkill.Tools) do
            if sword and sword.Parent then
                sword.Grip = SilentSwordkill.OriginalGrip[sword]
                sword.Handle.Massless = SilentSwordkill.OriginalMassless[sword]
                stopSoundsInObject(sword)
            end
        end
        
        SilentSwordkill.OriginalGrip = {}
        SilentSwordkill.OriginalMassless = {}
        SilentSwordkill.Tools = {}
        SilentSwordkill.DeadPlayers = {}
    end
end)

local Bkill = {
    Active = false,
    TargetAll = false,
    Players = game:GetService("Players"),
    LocalPlayer = game:GetService("Players").LocalPlayer
}

-- Main killing function
local function ExecuteBkill()
    while Bkill.Active do
        local character = Bkill.LocalPlayer.Character
        if not character then task.wait(0.1) continue end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then task.wait(0.1) continue end

        -- Find Building Tools
        local btools = Bkill.LocalPlayer:FindFirstChild("Backpack") and 
                      Bkill.LocalPlayer.Backpack:FindFirstChild("Building Tools") or
                      character:FindFirstChild("Btools")
        
        if not btools then 
            task.wait(0.1)
            continue 
        end

        local syncAPI = btools:FindFirstChild("SyncAPI")
        local serverEndpoint = syncAPI and syncAPI:FindFirstChild("ServerEndpoint")
        if not serverEndpoint then task.wait(0.1) continue end

        -- Determine targets
        local targets = {}
        if Bkill.TargetAll then
            -- Get all players except yourself
            for _, player in ipairs(Bkill.Players:GetPlayers()) do
                if player ~= Bkill.LocalPlayer then
                    table.insert(targets, player)
                end
            end
        else
            -- Get current target (if specified)
            if Bkill.CurrentTarget then
                table.insert(targets, Bkill.CurrentTarget)
            end
        end

        -- Execute kill on targets
        for _, target in ipairs(targets) do
            if target and target.Character then
                local torso = target.Character:FindFirstChild("Torso") or 
                             target.Character:FindFirstChild("UpperTorso")
                if torso then
                    pcall(function()
                        serverEndpoint:InvokeServer("Remove", {torso})
                    end)
                end
            end
        end

        task.wait(0.1)
    end
end

-- Command to start killing (all or specific player)
AddCommandWithPlayer("btoolkill", {"bkill"}, "Deletes parts of target player(s) using Building Tools", function(name)
    if Bkill.Active then
        crx("Bkill already active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    Bkill.Active = true
    Bkill.CurrentTarget = GetPlayer(name) -- nil if "all" is used
    
    -- Check if targeting all players
    if not name or string.lower(name) == "all" then
        Bkill.TargetAll = true
        coroutine.wrap(ExecuteBkill)()
        return "Bkilling all players"
    else
        Bkill.TargetAll = false
        if not Bkill.CurrentTarget then
            Bkill.Active = false
            crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        end
        coroutine.wrap(ExecuteBkill)()
        return "Bkilling "..Bkill.CurrentTarget.Name
    end
end)

-- Command to stop killing
AddCommand("unbtoolkill", {"unbkill"}, "Stops the bkill process", function()
    if not Bkill.Active then
        crx("Bkill isn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    
    Bkill.Active = false
    Bkill.TargetAll = false
    Bkill.CurrentTarget = nil
    return "Bkill stopped"
end)

AddCommand("flinggun", {"fgun"}, "Cool gun flings people", function()
CreateFlingGun()
return "Created FlingGun"
end)

AddCommand("npcgun", {"ngun"}, "Cool gun kills npc", function()
CreateNpcGun()
return "Created NpcGun"
end)

AddCommand("swordgun", {"sgun"}, "Cooler gun kills players with sword [TOOL]", function()
CreateSwordGun()
return "Created SwordGun"
end)

AddCommand("btoolgun", {"bgun"}, "Coolller gun that kills people with btools [TOOL]", function()
CreateBtoolGun()
return "Created BtoolGun"
end)

AddCommand("guns", nil, "gives u all da guns [TOOL]", function()
CreateFlingGun()
CreateNpcGun()
CreateSwordGun()
CreateBtoolGun()
return "Created all guns"
end)

AddCommand("btoolpunch", {"bpunch", "bfist"}, "Cool punch tool that kills people with btools [TOOL]", function()
    CreateBToolPunch()
    return "Created BtoolPunch"
end)

AddCommandWithPlayer("clientkill", {"ckill"}, "Kills players on the client (CLIENT)", function(name)
    local targets = {}
    local localPlayer = game.Players.LocalPlayer
    
    -- Check if targeting all players
    if not name or string.lower(name) == "all" then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(targets, player)
            end
        end
    else
        -- Target specific player
        local target = GetPlayer(name)
        if not target then return "Player not found" end
        if target == localPlayer then return "Cannot neckkill yourself" end
        table.insert(targets, target)
    end
    
    if #targets == 0 then
        return "No valid targets found"
    end
    
    local count = 0
    
    for _, target in ipairs(targets) do
        local character = target.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        
        if humanoid and head and torso then
            -- Method 1: Try to find and destroy neck joint
            pcall(function() 
                local neck = head:FindFirstChild("Neck") or head:FindFirstChild("NeckRigAttachment")
                if neck then neck:Destroy() end
            end)
            
            -- Method 2: Try remote events
            local remotes = {
                game.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents"),
                game.ReplicatedStorage:FindFirstChild("SayMessageRequest"),
                game.ReplicatedStorage:FindFirstChild("Health"),
                game.ReplicatedStorage:FindFirstChild("Damage"),
                game.ReplicatedStorage:FindFirstChild("Kill"),
                game.ReplicatedStorage:FindFirstChild("BreakJoints"),
                game.ReplicatedStorage:FindFirstChild("Remotes"),
                game.ReplicatedStorage:FindFirstChild("RemoteEvents"),
                game.ReplicatedStorage:FindFirstChild("RemoteFunctions"),
                game.Workspace:FindFirstChild("Remote"),
                game.Workspace:FindFirstChild("Events"),
            }
            
            for _, remote in ipairs(remotes) do
                if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
                    pcall(function()
                        if remote:IsA("RemoteEvent") then
                            remote:FireServer("BreakNeck", target, character)
                            remote:FireServer("Kill", target, "NeckBreak")
                        elseif remote:IsA("RemoteFunction") then
                            remote:InvokeServer("BreakNeck", target)
                        end
                    end)
                end
            end
            
            -- Method 3: Direct damage
            pcall(function()
                humanoid:TakeDamage(math.huge)
                humanoid.Health = 0
            end)
            
            -- Method 4: Break joints
            pcall(function()
                head:BreakJoints()
                torso:BreakJoints()
            end)
            
            count = count + 1
        end
    end
    
    if string.lower(name) == "all" then
        return "Killed " .. count .. " players"
    else
        return "Killed " .. targets[1].Name
    end
end)

AddCommand("walkfling", {"wf"}, "Starts Touchfling", TFlingOn)
AddCommand("unwalkfling", {"unwf"}, "Stops Touchfling", TFlingOff)

local FlingCommand = {
    OriginalTransparency = {},
    InvisibleTimer = 0,
    MaxInvisibleTime = 10, -- 5 seconds max invisibility
    InvisibilityCheck = nil
}

AddCommandWithPlayer("fling", {"throw"}, "Fling a player or all players", function(name)
    local player = game.Players.LocalPlayer
    local character = player.Character
    name = name:lower()

    -- Function to make player invisible
    local function makeInvisible()
        if not character then return end
        
        -- Stop any existing invisibility check
        if FlingCommand.InvisibilityCheck then
            FlingCommand.InvisibilityCheck:Disconnect()
            FlingCommand.InvisibilityCheck = nil
        end
        
        FlingCommand.OriginalTransparency = {}
        
        -- Make all parts transparent
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                FlingCommand.OriginalTransparency[part] = part.Transparency
                part.Transparency = 1
            elseif part:IsA("Decal") or part:IsA("Texture") then
                FlingCommand.OriginalTransparency[part] = part.Transparency
                part.Transparency = 1
            end
        end
        
        -- Hide accessories
        for _, accessory in ipairs(character:GetChildren()) do
            if accessory:IsA("Accessory") and accessory:FindFirstChild("Handle") then
                FlingCommand.OriginalTransparency[accessory.Handle] = accessory.Handle.Transparency
                accessory.Handle.Transparency = 1
            end
        end
        
        -- Start invisibility timer
        FlingCommand.InvisibleTimer = 0
        FlingCommand.InvisibilityCheck = game:GetService("RunService").Heartbeat:Connect(function(dt)
            FlingCommand.InvisibleTimer = FlingCommand.InvisibleTimer + dt
            
            -- Auto make visible if invisible for too long
            if FlingCommand.InvisibleTimer >= FlingCommand.MaxInvisibleTime then
                makeVisible()
                if FlingCommand.InvisibilityCheck then
                    FlingCommand.InvisibilityCheck:Disconnect()
                    FlingCommand.InvisibilityCheck = nil
                end
            end
        end)
    end

    -- Function to make player visible again
    local function makeVisible()
        if not character then return end
        
        -- Stop invisibility check
        if FlingCommand.InvisibilityCheck then
            FlingCommand.InvisibilityCheck:Disconnect()
            FlingCommand.InvisibilityCheck = nil
        end
        
        -- Restore original transparency
        for object, transparency in pairs(FlingCommand.OriginalTransparency) do
            if object and object.Parent then
                object.Transparency = transparency
            end
        end
        
        FlingCommand.OriginalTransparency = {}
        FlingCommand.InvisibleTimer = 0
    end

    -- Make player invisible before flinging
    makeInvisible()

    if name == "all" then
        local count = 0
        for _, targetPlayer in ipairs(game.Players:GetPlayers()) do
            if targetPlayer ~= player then
                SkidFling(targetPlayer)
                count = count + 1
                task.wait(0.3) -- small delay so it doesn't break physics
            end
        end
        
        -- Make visible after all flings complete (with safety timer)
        task.delay(2, function()
            makeVisible()
        end)
        
        return "Flinged "..count.." players"
    else
        local target = GetPlayer(name)
        if not target then 
            crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
            makeVisible() -- Make visible again if target not found
            return
        end
        
        SkidFling(target)
        
        -- Make visible after fling completes (with safety timer)
        task.delay(2, function()
            makeVisible()
        end)
        
        return "Flinged "..target.Name
    end
end)

-- Auto cleanup in case of errors or character removal
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    -- Make visible again if character is removed
    local function restoreVisibility()
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character then
            for object, transparency in pairs(FlingCommand.OriginalTransparency) do
                if object and object.Parent then
                    object.Transparency = transparency
                end
            end
        end
        FlingCommand.OriginalTransparency = {}
    end
    
    restoreVisibility()
    
    if FlingCommand.InvisibilityCheck then
        FlingCommand.InvisibilityCheck:Disconnect()
        FlingCommand.InvisibilityCheck = nil
    end
    FlingCommand.InvisibleTimer = 0
end)

-- Additional safety: Auto visible if command somehow gets stuck
task.spawn(function()
    while true do
        task.wait(1)
        if FlingCommand.InvisibleTimer > 0 and FlingCommand.InvisibleTimer >= FlingCommand.MaxInvisibleTime then
            local player = game.Players.LocalPlayer
            local character = player.Character
            if character then
                for object, transparency in pairs(FlingCommand.OriginalTransparency) do
                    if object and object.Parent then
                        object.Transparency = transparency
                    end
                end
                FlingCommand.OriginalTransparency = {}
            end
            FlingCommand.InvisibleTimer = 0
            if FlingCommand.InvisibilityCheck then
                FlingCommand.InvisibilityCheck:Disconnect()
                FlingCommand.InvisibilityCheck = nil
            end
        end
    end
end)

AddCommand("Invisible", {"invis"}, "Hides you [R6 RECOMMENDED]", invis2)
AddCommand("visible", {"vis"}, "Shows you", vis2)
AddCommand("antibang", {"ab"}, "use when banged", StartAB)
AddCommand("antifling", {"af"}, "Prevents exploiter flings", Afon)
AddCommand("unantifling", {"unaf"}, "Vulnerable to exploiter flings", Afoff)
AddCommand("antiafk", {"aafk"}, "Prevents idle kick", antiafkon)
AddCommand("unantiafk", {"unaafk"}, "Stops Anti-Afk", antiafkoff)
AddCommand("antilag", {"nolag"}, "Makes your frames smoother", fpsb)

-- Universal Artificial Gravity Commands
AddCommandWithValue("setuagrav", "amount", {"sug"}, "Sets unanchored gravity", function(value)
    local gravityValue = tonumber(value)
    if not gravityValue then
        crx("Invalid gravity value!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end

    sethiddenproperty(game.Players.LocalPlayer, "SimulationRadius", 5000)
    sethiddenproperty(game.Players.LocalPlayer, "MaxSimulationRadius", 5000)

    if _G.CustomGravityForces then
        for part, force in pairs(_G.CustomGravityForces) do
            if part and part.Parent then force:Destroy() end
        end
    end

    _G.CustomGravityForces = {}
    local changed, partsProcessed = 0, 0
    local maxPartsPerFrame = 100
    local partsToProcess = {}

    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored then
            table.insert(partsToProcess, part)
        end
    end

    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local processed = 0
        while processed < maxPartsPerFrame and partsProcessed < #partsToProcess do
            partsProcessed = partsProcessed + 1
            local part = partsToProcess[partsProcessed]

            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("BodyForce") and child.Name == "CustomGravityForce" then
                    child:Destroy()
                end
            end

            local bodyForce = Instance.new("BodyForce")
            bodyForce.Name = "CustomGravityForce"

            if gravityValue == 0 then
                bodyForce.Force = Vector3.new(0, part:GetMass() * workspace.Gravity, 0)
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotationalVelocity = Vector3.new(0, 0, 0)
            else
                bodyForce.Force = Vector3.new(0, part:GetMass() * workspace.Gravity * (gravityValue - 1), 0)
            end

            bodyForce.Parent = part
            _G.CustomGravityForces[part] = bodyForce
            changed = changed + 1
            processed = processed + 1
        end

        if partsProcessed >= #partsToProcess then
            connection:Disconnect()
            return string.format("Applied gravity to %d parts (Multiplier: %.2f)", changed, gravityValue)
        end
    end)

    return string.format("Processing %d parts with gravity multiplier %.2f...", #partsToProcess, gravityValue)
end)

AddCommand("resetuagrav", {"rsug"}, "Resets unanchored Gravity", function()
    if not _G.CustomGravityForces then
        return "No custom gravity forces to remove"
    end

    local restored, processed = 0, 0
    local maxPerFrame, totalToProcess = 100, 0
    for _ in pairs(_G.CustomGravityForces) do totalToProcess = totalToProcess + 1 end

    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        local batch = 0
        for part, force in pairs(_G.CustomGravityForces) do
            if part and part.Parent then force:Destroy() end
            _G.CustomGravityForces[part] = nil
            restored = restored + 1
            processed = processed + 1
            batch = batch + 1

            if batch >= maxPerFrame then break end
        end

        if processed >= totalToProcess then
            connection:Disconnect()
            _G.CustomGravityForces = nil
            return string.format("Removed custom gravity from %d parts", restored)
        end
    end)

    return string.format("Resetting gravity forces... (%d parts)", totalToProcess)
end)



AddCommand("buff", {}, "Easier to move unanchored parts", function()
    if Buff.Enabled then
        crx("Buff is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Buff.Enabled = true
    local character = game.Players.LocalPlayer.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Store original properties and apply buff
    Buff.OriginalProperties = {}
    local partsModified = 0
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Store original properties
            Buff.OriginalProperties[part] = part.CustomPhysicalProperties
            
            -- Apply buff properties (massive weight for easy movement)
            part.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0.5, 0.5)
            partsModified = partsModified + 1
        end
    end
    
    -- Listen for new parts being added to character
    if Buff.Connections then
        for _, connection in pairs(Buff.Connections) do
            connection:Disconnect()
        end
    end
    
    Buff.Connections = {}
    Buff.Connections.descendantAdded = character.DescendantAdded:Connect(function(descendant)
        if Buff.Enabled and descendant:IsA("BasePart") then
            Buff.OriginalProperties[descendant] = descendant.CustomPhysicalProperties
            descendant.CustomPhysicalProperties = PhysicalProperties.new(math.huge, 0.5, 0.5)
        end
    end)
    
    return "Buff enabled"
end)

AddCommand("unbuff", {}, "Disables the buff command", function()
    if not Buff.Enabled then
        crx("Buff wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Buff.Enabled = false
    local partsRestored = 0
    local character = game.Players.LocalPlayer.Character
    
    -- Restore original properties
    for part, originalProps in pairs(Buff.OriginalProperties) do
        if part and part.Parent then
            part.CustomPhysicalProperties = originalProps
            partsRestored = partsRestored + 1
        end
    end
    
    -- Disconnect connections
    if Buff.Connections then
        for _, connection in pairs(Buff.Connections) do
            connection:Disconnect()
        end
        Buff.Connections = {}
    end
    
    Buff.OriginalProperties = {}
    
    return "Buff disabled"
end)

-- Auto cleanup on character respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if Buff.Enabled then
        Buff.Enabled = false
        Buff.OriginalProperties = {}
        if Buff.Connections then
            for _, connection in pairs(Buff.Connections) do
                connection:Disconnect()
            end
            Buff.Connections = {}
        end
    end
end)

AddCommand("cgod", {"cgod"}, "Sets your health to inf (CLIENT)", function()
    if CGod.Enabled then
        crx("CGod is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    CGod.Enabled = true
    local player = game.Players.LocalPlayer
    
    -- Function to set health to math.huge
    local function setGodMode(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Health = math.huge
        humanoid.MaxHealth = math.huge
        
        -- Prevent health from being reduced
        if CGod.Connections.healthChanged then
            CGod.Connections.healthChanged:Disconnect()
        end
        
        CGod.Connections.healthChanged = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if CGod.Enabled and humanoid.Health < math.huge then
                humanoid.Health = math.huge
            end
        end)
    end
    
    -- Apply to current character
    if player.Character then
        setGodMode(player.Character)
    end
    
    -- Apply to new characters
    if CGod.Connections.characterAdded then
        CGod.Connections.characterAdded:Disconnect()
    end
    
    CGod.Connections.characterAdded = player.CharacterAdded:Connect(function(character)
        if CGod.Enabled then
            setGodMode(character)
        end
    end)
    
    return "ClientGod enabled"
end)

AddCommand("unclientgod", {"uncgod"}, "Disables ClientGod mode", function()
    if not CGod.Enabled then
        crx("ClientGod wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    CGod.Enabled = false
    
    -- Disconnect connections
    for _, connection in pairs(CGod.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    CGod.Connections = {}
    
    -- Restore normal health if possible
    local character = game.Players.LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end
    
    return "ClientGod disabled"
end)

local PartAttachTool = {
    Tool = nil,
    Welds = {},
    Connection = nil
}

AddCommand("partattachtool", {"pat"}, "Creates a PartAttachTool that welds parts to itself (click to weld)", function()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    
    if not backpack then
        crx("Backpack not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Remove existing tool if any
    if PartAttachTool.Tool then
        PartAttachTool.Tool:Destroy()
        PartAttachTool.Tool = nil
    end
    
    -- Clear any existing welds
    for _, weld in pairs(PartAttachTool.Welds) do
        if weld then
            weld:Destroy()
        end
    end
    PartAttachTool.Welds = {}
    
    if PartAttachTool.Connection then
        PartAttachTool.Connection:Disconnect()
        PartAttachTool.Connection = nil
    end
    
    -- Create the tool with a handle
    local tool = Instance.new("Tool")
    tool.Name = "PartAttachTool"
    tool.ToolTip = "Click on unanchored parts to weld to this tool"
    tool.RequiresHandle = true
    tool.Parent = backpack
    
    -- Create tool handle
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Transparency = 1  -- Invisible handle
    handle.CanCollide = false
    handle.Parent = tool
    
    -- Create selection box for visual feedback
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Name = "PartSelection"
    selectionBox.Adornee = nil
    selectionBox.Color3 = Color3.new(0, 1, 0) -- Green
    selectionBox.LineThickness = 0.05
    selectionBox.Parent = tool
    
    -- Tool activated event (when clicked on a part)
    tool.Activated:Connect(function()
        local mouse = player:GetMouse()
        local targetPart = mouse.Target
        
        if targetPart and targetPart:IsA("BasePart") and not targetPart.Anchored then
            -- Remove any existing weld for this part
            if PartAttachTool.Welds[targetPart] then
                PartAttachTool.Welds[targetPart]:Destroy()
                PartAttachTool.Welds[targetPart] = nil
            end
            
            -- Create weld between tool handle and target part
            local weld = Instance.new("Weld")
            weld.Name = "ToolAttachment"
            weld.Part0 = handle
            weld.Part1 = targetPart
            weld.C0 = CFrame.new() -- Identity offset
            weld.C1 = handle.CFrame:ToObjectSpace(targetPart.CFrame)
            weld.Parent = handle
            
            -- Store the weld
            PartAttachTool.Welds[targetPart] = weld
            
            -- Show visual feedback
            selectionBox.Adornee = targetPart
            
            return "Welded " .. targetPart.Name .. " to tool"
        else
            return "Target must be an unanchored part!"
        end
    end)
    
    -- Tool unequipped event (remove all welds)
    tool.Unequipped:Connect(function()
        -- Remove all welds
        for part, weld in pairs(PartAttachTool.Welds) do
            if weld then
                weld:Destroy()
            end
        end
        PartAttachTool.Welds = {}
        selectionBox.Adornee = nil
    end)
    
    -- Cleanup when tool is removed
    tool.Destroying:Connect(function()
        for part, weld in pairs(PartAttachTool.Welds) do
            if weld then
                weld:Destroy()
            end
        end
        PartAttachTool.Welds = {}
        PartAttachTool.Tool = nil
    end)
    
    PartAttachTool.Tool = tool
    return "PartAttachTool Created!"
end)

-- Auto cleanup when player leaves
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    if PartAttachTool.Tool then
        PartAttachTool.Tool:Destroy()
        PartAttachTool.Tool = nil
    end
    
    for part, weld in pairs(PartAttachTool.Welds) do
        if weld then
            weld:Destroy()
        end
    end
    PartAttachTool.Welds = {}
end)

-- AntiTrip System (FIXED)


AddCommand("antitrip", {"at"}, "Prevents sitting and tripping", function()
    if AntiTripSystem.Enabled then
        crx("AntiTrip is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AntiTripSystem.Enabled = true
    local player = game.Players.LocalPlayer
    
    local function monitorHumanoid(humanoid)
        if AntiTripSystem.Connections.heartbeat then
            AntiTripSystem.Connections.heartbeat:Disconnect()
        end
        
        AntiTripSystem.Connections.heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
            if not AntiTripSystem.Enabled or not humanoid or not humanoid.Parent then
                AntiTripSystem.Connections.heartbeat:Disconnect()
                return
            end
            
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.Seated or
               state == Enum.HumanoidStateType.FallingDown or
               state == Enum.HumanoidStateType.Ragdoll then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            
            if humanoid.Sit then
                humanoid.Sit = false
            end
        end)
    end
    
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            monitorHumanoid(humanoid)
        end
    end
    
    if AntiTripSystem.Connections.characterAdded then
        AntiTripSystem.Connections.characterAdded:Disconnect()
    end
    
    AntiTripSystem.Connections.characterAdded = player.CharacterAdded:Connect(function(character)
        if AntiTripSystem.Enabled then
            local humanoid = character:WaitForChild("Humanoid")
            monitorHumanoid(humanoid)
        end
    end)
    
    return "AntiTrip enabled!"
end)

AddCommand("unantitrip", {"unat"}, "Allows sitting and tripping again", function()
    if not AntiTripSystem.Enabled then
        crx("AntiTrip wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AntiTripSystem.Enabled = false
    
    for _, connection in pairs(AntiTripSystem.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    AntiTripSystem.Connections = {}
    
    return "AntiTrip disabled"
end)

AddCommand("autorejoin", {"autorj", "arj"}, "Automatically rejoins if you get kicked", function()
    if AutoRejoin.Enabled then
        crx("AutoRejoin is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AutoRejoin.Enabled = true
    
    -- Create connection to detect kick messages
    if AutoRejoin.Connection then
        AutoRejoin.Connection:Disconnect()
    end
    
    AutoRejoin.Connection = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        if AutoRejoin.Enabled then
            -- Rejoin the same server
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end
    end)
    
    return "AutoRejoin enabled"
end)

AddCommand("unautorejoin", {"unautorj", "unarj"}, "Disables AutoRejoin", function()
    if not AutoRejoin.Enabled then
        crx("AutoRejoin wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AutoRejoin.Enabled = false
    
    -- Disconnect the connection
    if AutoRejoin.Connection then
        AutoRejoin.Connection:Disconnect()
        AutoRejoin.Connection = nil
    end
    
    return "AutoRejoin disabled"
end)


AddCommand("autorespawn", {"autore"}, "Automatically teleports you back to your death location", function()
    if AutoRespawn.Enabled then
        crx("AutoRespawn is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AutoRespawn.Enabled = true
    local player = game.Players.LocalPlayer
    
    -- Function to handle respawn teleport
    local function setupRespawn(character)
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Store death position
        if AutoRespawn.Connections.died then
            AutoRespawn.Connections.died:Disconnect()
        end
        
        AutoRespawn.Connections.died = humanoid.Died:Connect(function()
            if AutoRespawn.Enabled then
                AutoRespawn.DeathPosition = rootPart.CFrame
            end
        end)
    end
    
    -- Function to teleport to death position
    local function teleportToDeathPosition(newCharacter)
        if AutoRespawn.Enabled and AutoRespawn.DeathPosition then
            local newRoot = newCharacter:WaitForChild("HumanoidRootPart")
            newRoot.CFrame = AutoRespawn.DeathPosition
            AutoRespawn.DeathPosition = nil -- Clear after use
        end
    end
    
    -- Setup current character
    if player.Character then
        setupRespawn(player.Character)
    end
    
    -- Setup character added connection
    if AutoRespawn.Connections.characterAdded then
        AutoRespawn.Connections.characterAdded:Disconnect()
    end
    
    AutoRespawn.Connections.characterAdded = player.CharacterAdded:Connect(function(character)
        if AutoRespawn.Enabled then
            -- Wait for character to fully load
            character:WaitForChild("Humanoid")
            character:WaitForChild("HumanoidRootPart")
            
            -- Teleport to death position if available
            teleportToDeathPosition(character)
            
            -- Setup respawn for the new character
            setupRespawn(character)
        end
    end)
    
    return "AutoRespawn enabled"
end)

AddCommand("unautorespawn", {"unautore"}, "Disables AutoRespawn", function()
    if not AutoRespawn.Enabled then
        crx("AutoRespawn wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AutoRespawn.Enabled = false
    AutoRespawn.DeathPosition = nil
    
    -- Disconnect all connections
    for _, connection in pairs(AutoRespawn.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    AutoRespawn.Connections = {}
    
    return "AutoRespawn disabled"
end)

-- FPS Commandslll

-- Alternative simpler FPS command that always works
AddCommand("showfps", {"sfps"}, "Shows FPS counter", function()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove any existing FPS counters
    local oldGui = playerGui:FindFirstChild("SimpleFPSCounter")
    if oldGui then
        oldGui:Destroy()
    end
    
    -- Create simple FPS counter
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SimpleFPSCounter"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSCounter"
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = Color3.new(0, 1, 0)
    fpsLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    fpsLabel.BackgroundTransparency = 0.5
    fpsLabel.Size = UDim2.new(0, 80, 0, 25)
    fpsLabel.Position = UDim2.new(0, 70, 0, 50)
    fpsLabel.Font = Enum.Font.Arcade
    fpsLabel.TextSize = 16
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = screenGui
    
    -- FPS calculation
    local lastTime = tick()
    local frames = 0
    local connection
    
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        frames = frames + 1
        local currentTime = tick()
        if currentTime - lastTime >= 1 then
            fpsLabel.Text = "FPS: " .. math.floor(frames)
            frames = 0
            lastTime = currentTime
        end
    end)
    
    -- Make it draggable
    local dragging = false
    local dragInput, dragStart, startPos
    
    fpsLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = fpsLabel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    fpsLabel.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            fpsLabel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    return "FPS counter shown"
end)

AddCommand("hidefps", {"hfps"}, "Hides FPS counter", function()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local oldGui = playerGui:FindFirstChild("SimpleFPSCounter")
    if oldGui then
        oldGui:Destroy()
    end
    
    -- Also disable the toggle version
    if FPSCounter.Enabled then
        if FPSCounter.Connection then
            FPSCounter.Connection:Disconnect()
            FPSCounter.Connection = nil
        end
        if FPSCounter.Label then
            FPSCounter.Label:Destroy()
            FPSCounter.Label = nil
        end
        FPSCounter.Enabled = false
    end
    
    return "FPS counter hidden"
end)

-- AntiKick System

AddCommand("antikick", {"ak"}, "Prevents (client) scripts from kicking you", function()
    if AntiKick.Enabled then
        crx("AntiKick is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AntiKick.Enabled = true
    
    if hookfunction then
        -- Hook LocalPlayer.Kick methods
        local kickMethods = {game.Players.LocalPlayer.Kick, game.Players.LocalPlayer.kick}
        
        for _, kickFunc in ipairs(kickMethods) do
            if type(kickFunc) == "function" then
                AntiKick.OriginalFunctions[kickFunc] = hookfunction(kickFunc, function(...)
                    if not AntiKick.Enabled then
                        return AntiKick.OriginalFunctions[kickFunc](...)
                    end
                    -- Block the kick if AntiKick is enabled
                    return nil
                end)
            end
        end
        
        return "AntiKick enabled"
    else
        crx("Unsupported Executor - Missing hookfunction", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
end)

AddCommand("unantikick", {"unak"}, "Disables AntiKick", function()
    if not AntiKick.Enabled then
        crx("AntiKick wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AntiKick.Enabled = false
    
    -- Restore original functions
    if hookfunction then
        for func, original in pairs(AntiKick.OriginalFunctions) do
            if type(func) == "function" and type(original) == "function" then
                hookfunction(func, original)
            end
        end
        AntiKick.OriginalFunctions = {}
    end
    
    return "AntiKick disabled"
end)

-- AntiTeleport System


AddCommand("antiteleport", {"ant"}, "Prevents you from getting teleported to other games", function()
    if AntiTeleport.Enabled then
        crx("AntiTeleport is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AntiTeleport.Enabled = true
    
    if hookfunction then
        local ts = game:GetService("TeleportService")
        local http = game:GetService("HttpService")
        
        -- Hook teleport functions
        local teleportFunctions = {
            ts.TeleportToPlaceInstance,
            ts.TeleportToPrivateServer,
            ts.Teleport,
            ts.TeleportToPlace,
            ts.TeleportToGame
        }
        
        -- Also check HttpService for teleport methods
        if http.TeleportToPlaceInstance then
            table.insert(teleportFunctions, http.TeleportToPlaceInstance)
        end
        
        for _, teleportFunc in ipairs(teleportFunctions) do
            if type(teleportFunc) == "function" then
                AntiTeleport.OriginalFunctions[teleportFunc] = hookfunction(teleportFunc, function(...)
                    if not AntiTeleport.Enabled then
                        return AntiTeleport.OriginalFunctions[teleportFunc](...)
                    end
                    -- Block the teleport if AntiTeleport is enabled
                    return nil
                end)
            end
        end
        
        return "AntiTeleport enabled"
    else
        crx("Unsupported Executor - Missing hookfunction", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
end)

AddCommand("unantiteleport", {"unant"}, "Disables AntiTeleport", function()
    if not AntiTeleport.Enabled then
        crx("AntiTeleport wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AntiTeleport.Enabled = false
    
    -- Restore original functions
    if hookfunction then
        for func, original in pairs(AntiTeleport.OriginalFunctions) do
            if type(func) == "function" and type(original) == "function" then
                hookfunction(func, original)
            end
        end
        AntiTeleport.OriginalFunctions = {}
    end
    
    return "AntiTeleport disabled"
end)

-- Save/Load Tools
AddCommand("savetools", {"st"}, "Drops all your tools in the sky, type LoadTools to get them back", function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        crx("HumanoidRootPart not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local oldPosition = rootPart.CFrame
    rootPart.CFrame = CFrame.new(0, 9e9, 0)
    
    task.wait(1)
    
    -- Drop tools from backpack
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.CanBeDropped then
                tool.Parent = character
                tool.Parent = workspace
            end
        end
    end
    
    -- Drop tools from character
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.CanBeDropped then
            tool.Parent = workspace
        end
    end
    
    task.wait(0.5)
    rootPart.CFrame = oldPosition
    
    return "Tools saved in the sky - Use loadtools to retrieve them"
end)

AddCommand("loadtools", {"lt"}, "Receives all the tools you've saved", function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not humanoid then
        crx("Humanoid not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local toolsCollected = 0
    for _, tool in ipairs(workspace:GetChildren()) do
        if tool:IsA("Tool") then
            humanoid:EquipTool(tool)
            toolsCollected = toolsCollected + 1
        end
    end
    
    return "Collected " .. toolsCollected .. " tools from workspace"
end)

-- AirWalk System

AddCommand("airwalk", {"aw"}, "Allows you to walk on air; jump to go up", function()
    if AirWalk.Enabled then
        crx("AirWalk is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AirWalk.Enabled = true
    local character = game.Players.LocalPlayer.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        crx("HumanoidRootPart not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Create air platform
    AirWalk.AirPart = Instance.new("Part")
    AirWalk.AirPart.Transparency = 1
    AirWalk.AirPart.Size = Vector3.new(7, 2, 3)
    AirWalk.AirPart.Parent = workspace
    AirWalk.AirPart.CanCollide = true
    AirWalk.AirPart.Anchored = true
    AirWalk.AirPart.Name = "AirWalkPlatform_" .. tostring(math.random(10000, 99999))
    
    -- Update platform position
    if AirWalk.Connection then
        AirWalk.Connection:Disconnect()
    end
    
    AirWalk.Connection = game:GetService("RunService").Heartbeat:Connect(function()
        if AirWalk.Enabled and AirWalk.AirPart and rootPart and rootPart.Parent then
            AirWalk.AirPart.CFrame = rootPart.CFrame + Vector3.new(0, -4, 0)
        else
            AirWalk.Connection:Disconnect()
        end
    end)
    
    return "AirWalk enabled"
end)

AddCommand("unairwalk", {"unaw"}, "Disables the airwalk command", function()
    if not AirWalk.Enabled then
        crx("AirWalk wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    AirWalk.Enabled = false
    
    if AirWalk.AirPart then
        AirWalk.AirPart:Destroy()
        AirWalk.AirPart = nil
    end
    
    if AirWalk.Connection then
        AirWalk.Connection:Disconnect()
        AirWalk.Connection = nil
    end
    
    return "AirWalk disabled"
end)

local Climb = {
    Enabled = false,
    ClimbPart = nil,
    Connection = nil
}

AddCommand("climb", {"truss"}, "Allows you to climb in the air", function()
    if Climb.Enabled then
        crx("Climb is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Climb.Enabled = true
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        crx("HumanoidRootPart not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Remove old climb part if exists
    if Climb.ClimbPart then
        Climb.ClimbPart:Destroy()
        Climb.ClimbPart = nil
    end
    
    -- Create new climb part
    Climb.ClimbPart = Instance.new("TrussPart")
    Climb.ClimbPart.Transparency = 1
    Climb.ClimbPart.Size = Vector3.new(2, 10, 2)
    Climb.ClimbPart.Parent = workspace
    Climb.ClimbPart.CanCollide = true
    Climb.ClimbPart.Name = "ClimbPart_" .. tostring(math.random(10000, 99999))
    
    -- Update climb part position
    if Climb.Connection then
        Climb.Connection:Disconnect()
    end
    
    Climb.Connection = game:GetService("RunService").Heartbeat:Connect(function()
        if Climb.Enabled and Climb.ClimbPart and rootPart and rootPart.Parent then
            Climb.ClimbPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -1.5)
        else
            Climb.Connection:Disconnect()
        end
    end)
    
    return "Climb enabled"
end)

AddCommand("unclimb", {"untruss"}, "Disables the climb command", function()
    if not Climb.Enabled then
        crx("Climb wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Climb.Enabled = false
    
    if Climb.ClimbPart then
        Climb.ClimbPart:Destroy()
        Climb.ClimbPart = nil
    end
    
    if Climb.Connection then
        Climb.Connection:Disconnect()
        Climb.Connection = nil
    end
    
    return "Climb disabled"
end)

-- Auto cleanup
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    if Climb.ClimbPart then
        Climb.ClimbPart:Destroy()
        Climb.ClimbPart = nil
    end
    Climb.Enabled = false
    if Climb.Connection then
        Climb.Connection:Disconnect()
        Climb.Connection = nil
    end
end)

-- Show/Hide Invisible Parts
local ShowHide = {
    HiddenParts = {},
    Active = false
}

AddCommand("showwalls", {"swalls"}, "Reveals all invisible parts ingame", function()
    if ShowHide.Active then
        crx("Show is already active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    ShowHide.Active = true
    ShowHide.HiddenParts = {}
    local revealed = 0
    
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency == 1 and part.Name ~= "HumanoidRootPart" then
            table.insert(ShowHide.HiddenParts, part)
            part.Transparency = 0
            revealed = revealed + 1
        end
    end
    
    return "Showing " .. revealed .. " invisible walls"
end)

AddCommand("hidewalls", {"hwalls"}, "Hides all previously shown parts", function()
    if not ShowHide.Active then
        crx("Show wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    ShowHide.Active = false
    local hidden = 0
    
    for _, part in ipairs(ShowHide.HiddenParts) do
        if part and part.Parent then
            part.Transparency = 1
            hidden = hidden + 1
        end
    end
    
    ShowHide.HiddenParts = {}
    return "Hidden " .. hidden .. " previously shown walls"
end)

-- Set Spawn Location
local SpawnSystem = {
    Enabled = false,
    SpawnLocation = nil,
    Connection = nil
}

AddCommand("setspawn", {"ss"}, "Sets your new spawn location", function()
    local character = game.Players.LocalPlayer.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        crx("HumanoidRootPart not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    SpawnSystem.Enabled = true
    SpawnSystem.SpawnLocation = rootPart.CFrame
    
    -- Disconnect previous connection
    if SpawnSystem.Connection then
        SpawnSystem.Connection:Disconnect()
    end
    
    -- Connect to character respawns
    SpawnSystem.Connection = game.Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if SpawnSystem.Enabled and SpawnSystem.SpawnLocation then
            local newRoot = newCharacter:WaitForChild("HumanoidRootPart")
            newRoot.CFrame = SpawnSystem.SpawnLocation
        end
    end)
    
    return "Spawnpoint set at current location"
end)

AddCommand("unsetspawn", {"unss"}, "Deletes the spawn location you've saved", function()
    if not SpawnSystem.Enabled then
        crx("No spawnpoint was set!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    SpawnSystem.Enabled = false
    SpawnSystem.SpawnLocation = nil
    
    if SpawnSystem.Connection then
        SpawnSystem.Connection:Disconnect()
        SpawnSystem.Connection = nil
    end
    
    return "Spawnpoint removed"
end)

AddCommandWithPlayer("scare", {"boo"}, "Tps behind a target and tps you back somehow scares them lol", function(name)
    local target = GetPlayer(name)
    if not target then
        crx("Player not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local targetCharacter = target.Character
    if not targetCharacter then
        crx("Target has no character!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local localRoot = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if not targetRoot or not localRoot or not humanoid then
        crx("Required parts not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Store original position
    local originalPosition = localRoot.CFrame
    local originalAnimationSpeed = humanoid.WalkSpeed
    
    -- Load and play scary animation
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        crx("Animaton not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://429703734"
    
    local animationTrack = animator:LoadAnimation(animation)
    animationTrack:Play()
    animationTrack:AdjustSpeed(3) -- 3x speed
    
    -- Calculate position behind target (2 studs away)
    local targetCFrame = targetRoot.CFrame
    local behindPosition = targetCFrame * CFrame.new(0, 0, 3) -- 2 studs behind
    
    -- Teleport behind target
    localRoot.CFrame = behindPosition
    
    -- Wait 0.5 seconds
    task.wait(0.5)
    
    -- Teleport back to original position
    localRoot.CFrame = originalPosition
    
    -- Reset animation speed to normal
    animationTrack:AdjustSpeed(1)
    
    -- Stop animation after a brief moment
    task.wait(0.2)
    animationTrack:Stop()
    
    return "Scared " .. target.Name .. "!"
end)

AddCommand("telekinesis", {"kineis", "tele"}, "Move any unanchored parts [UPDATED]", pmg)

AddCommand("spazz", {"sillyspin"}, "silly spin :p", function()
    if Spazz.Enabled then
        crx("Spazz is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Spazz.Enabled = true
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        crx("HumanoidRootPart not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Remove existing BodyVelocity if any
    if Spazz.BodyVelocity then
        Spazz.BodyVelocity:Destroy()
        Spazz.BodyVelocity = nil
    end
    
    -- Apply initial rotation
    rootPart.CFrame = rootPart.CFrame * CFrame.Angles(-0.3, 0, 0)
    
    -- Create BodyAngularVelocity for spinning
    Spazz.BodyVelocity = Instance.new("BodyAngularVelocity")
    Spazz.BodyVelocity.P = 200000
    Spazz.BodyVelocity.AngularVelocity = Vector3.new(0, 15, 0)
    Spazz.BodyVelocity.MaxTorque = Vector3.new(200000, 200000, 200000)
    Spazz.BodyVelocity.Parent = rootPart
    
    return "Spazz enabled"
end)

AddCommand("unspazz", {"unsillyspin"}, "Disables Spazz", function()
    if not Spazz.Enabled then
        crx("Spazz wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Spazz.Enabled = false
    
    -- Remove BodyVelocity
    if Spazz.BodyVelocity then
        Spazz.BodyVelocity:Destroy()
        Spazz.BodyVelocity = nil
    end
    
    return "Spazz disabled"
end)

-- Auto cleanup on character respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    if Spazz.Enabled then
        Spazz.Enabled = false
        if Spazz.BodyVelocity then
            Spazz.BodyVelocity:Destroy()
            Spazz.BodyVelocity = nil
        end
    end
end)

-- Auto cleanup when character is destroyed
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    if Spazz.BodyVelocity then
        Spazz.BodyVelocity:Destroy()
        Spazz.BodyVelocity = nil
    end
    Spazz.Enabled = false
end)

AddCommand("freegamepass", {"freegp", "fgp"}, "Pretends you own every gamepass and fires purchase signals", function()
    if FreeGamepasses.Hooked then
        crx("FreeGamepasses is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local marketplaceService = game:GetService("MarketplaceService")
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    
    local signalsFired = 0
    
    -- Hook UserOwnsGamePassAsync if possible
    if hookfunction then
        FreeGamepasses.OriginalFunction = hookfunction(
            marketplaceService.UserOwnsGamePassAsync,
            function(...)
                return true -- Always return true (you own the gamepass)
            end
        )
        FreeGamepasses.Hooked = true
    else
        crx("Hookfunction not available - Gamepass ownership won't be faked", 1.1, Color3.fromRGB(255, 165, 0), 138081500)
    end
    
    -- Try to get developer products and fire signals
    pcall(function()
        local success, products = pcall(function()
            return marketplaceService:GetDeveloperProductsAsync():GetCurrentPage()
        end)
        
        if success and products then
            for _, product in ipairs(products) do
                if product.ProductId then
                    pcall(function()
                        marketplaceService:SignalPromptProductPurchaseFinished(localPlayer.UserId, product.ProductId, true)
                        signalsFired = signalsFired + 1
                    end)
                end
            end
        end
    end)
    
    -- Also try to fire signals for known gamepass types
    pcall(function()
        -- Common gamepass IDs (you can add more specific ones)
        local commonPasses = {100, 200, 300, 400, 500, 1000, 2000, 5000}
        for _, passId in ipairs(commonPasses) do
            pcall(function()
                marketplaceService:SignalPromptProductPurchaseFinished(localPlayer.UserId, passId, true)
                signalsFired = signalsFired + 1
            end)
        end
    end)
    
    return "Free Gamepasses enabled - " .. signalsFired .. " purchase signals fired"
end)

AddCommand("unfreegamepass", {"unfreegp", "unfgp"}, "Disables free gamepasses hook", function()
    if not FreeGamepasses.Hooked then
        crx("FreeGamepasses wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Restore original function if hooked
    if hookfunction and FreeGamepasses.OriginalFunction then
        hookfunction(game:GetService("MarketplaceService").UserOwnsGamePassAsync, FreeGamepasses.OriginalFunction)
    end
    
    FreeGamepasses.Hooked = false
    FreeGamepasses.OriginalFunction = nil
    
    return "Free Gamepasses disabled"
end)

-- NPC Control Commands
AddCommand("killnpcs", {"knpc"}, "Kills all NPCs", function()
    local killed = 0
    local players = game:GetService("Players")
    
    -- Get all NPCs (non-player characters with humanoids)
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:FindFirstChildOfClass("Humanoid") and not players:GetPlayerFromCharacter(npc) then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            humanoid.Health = 0
            killed = killed + 1
        end
    end
    
    return "Killed " .. killed .. " NPCs"
end)

AddCommand("flingnpcs", {"fnpc"}, "Flings all NPCs", function()
    local flung = 0
    local players = game:GetService("Players")
    
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:FindFirstChildOfClass("Humanoid") and not players:GetPlayerFromCharacter(npc) then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            humanoid.HipHeight = 1024
            flung = flung + 1
        end
    end
    
    return "Flung " .. flung .. " NPCs"
end)

AddCommand("voidnpcs", {"vnpc"}, "Voids all NPCs", function()
    local voided = 0
    local players = game:GetService("Players")
    
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:FindFirstChildOfClass("Humanoid") and not players:GetPlayerFromCharacter(npc) then
            local humanoid = npc:FindFirstChildOfClass("Humanoid")
            humanoid.HipHeight = -1024
            voided = voided + 1
        end
    end
    
    return "Voided " .. voided .. " NPCs"
end)

AddCommand("bringnpcs", {"bnpc"}, "Brings all NPCs to you", function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        crx("HumanoidRootPart not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local brought = 0
    local players = game:GetService("Players")
    
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:FindFirstChildOfClass("Humanoid") and not players:GetPlayerFromCharacter(npc) then
            local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc:FindFirstChild("UpperTorso")
            if root then
                root.CFrame = rootPart.CFrame
                brought = brought + 1
            end
        end
    end
    
    return "Brought " .. brought .. " NPCs to your position"
end)

-- Advanced NPC Control with better detection
AddCommand("freezenpcs", {"frnpc"}, "Freezes all NPCs in place", function()
    local frozen = 0
    local players = game:GetService("Players")
    
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:FindFirstChildOfClass("Humanoid") and not players:GetPlayerFromCharacter(npc) then
            for _, part in ipairs(npc:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                end
            end
            frozen = frozen + 1
        end
    end
    
    return "Froze " .. frozen .. " NPCs"
end)

AddCommand("unnpcs", {"unpc"}, "Removes all NPCs from the game", function()
    local removed = 0
    local players = game:GetService("Players")
    
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:FindFirstChildOfClass("Humanoid") and not players:GetPlayerFromCharacter(npc) then
            npc:Destroy()
            removed = removed + 1
        end
    end
    
    return "Removed " .. removed .. " NPCs from the game"
end)

AddCommand("invertgrav", {"igrav"}, "Inverts UnachoredParts Gravity", GravOn)
AddCommand("uninvertgrav", {"unigrav"}, "Stopps Inverting UnachoredParts Gravity", GravOff)

AddCommand("partmover", {"pm"}, "Move any UnachoredParts like Btools", function()
    if _G.pcr then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://pastefy.app/Vcuyg09O/raw"))()
    end)
    
    if success then
        _G.pcr = true
        return "PartMover Loaded!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)



AddCommand("blackhole", {"bh"}, "Sucks UnachoredParts", blackHoleScript)
AddCommand("unblackhole", {"unbh"}, "stops sucking UnachoredParts", disableBlackHole)
AddCommand("ringparts", "rp", "Loads The Ringparts Gui", R1)
AddCommand("tpuaall", "bpall", "Tps unachored to everyone", StartDestroyer)
AddCommand("untpuaall", "unbpall", "Stops Tpuaall", stopdestroyer)

local LocalPlayer = Players.LocalPlayer

-- Blackhole system (only initialized when needed)
local Blackhole = {
    Active = false,
    Attachment1 = nil,
    Folder = nil,
    AnchorPart = nil,
    HumanoidRootPart = nil,
    Connections = {},
    ModifiedParts = {}
}

-- Network optimization (only initialized when needed)
local Network = {
    Initialized = false,
    BaseParts = {},
    Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424),
    HeartbeatConnection = nil
}

-- Initialize network system (only when first needed)
local function InitializeNetwork()
    if not Network.Initialized then
        Network.HeartbeatConnection = RunService.Heartbeat:Connect(function()
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
            for _, part in pairs(Network.BaseParts) do
                if part and part:IsDescendantOf(Workspace) then
                    part.Velocity = Network.Velocity
                end
            end
        end)
        Network.Initialized = true
    end
end

-- Retain part in network system
local function RetainPart(part)
    if part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
        table.insert(Network.BaseParts, part)
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        part.CanCollide = false
    end
end

-- Create hidden anchor part (only when needed)
local function CreateAttachmentPart()
    if not Blackhole.Folder then
        Blackhole.Folder = Instance.new("Folder")
        Blackhole.Folder.Name = "BlackholeSystem"
        Blackhole.Folder.Parent = Workspace
        
        Blackhole.AnchorPart = Instance.new("Part")
        Blackhole.AnchorPart.Name = "BlackholeAnchor"
        Blackhole.AnchorPart.Anchored = true
        Blackhole.AnchorPart.CanCollide = false
        Blackhole.AnchorPart.Transparency = 1
        Blackhole.AnchorPart.Size = Vector3.new(0.1, 0.1, 0.1)
        Blackhole.AnchorPart.Parent = Blackhole.Folder
        
        Blackhole.Attachment1 = Instance.new("Attachment")
        Blackhole.Attachment1.Name = "BlackholeAttachment"
        Blackhole.Attachment1.Parent = Blackhole.AnchorPart
    end
end

-- Clean up a modified part
local function CleanPart(part)
    if part and part:IsA("BasePart") then
        -- Restore original properties if we stored them
        if Blackhole.ModifiedParts[part] then
            local original = Blackhole.ModifiedParts[part]
            part.CanCollide = original.CanCollide
            part.CustomPhysicalProperties = original.CustomPhysicalProperties
            Blackhole.ModifiedParts[part] = nil
        end
        
        -- Remove created instances
        for _, child in ipairs(part:GetChildren()) do
            if child.Name == "BlackholeAttachment" or 
               child.Name == "BlackholeAlignPosition" or
               child.Name == "BlackholeTorque" then
                child:Destroy()
            end
        end
    end
end

-- Function to "blackhole" parts
local function ForcePart(part)
    if part:IsA("BasePart") and not part.Anchored and
       not part.Parent:FindFirstChildOfClass("Humanoid") and
       not part.Parent:FindFirstChild("Head") and
       part.Name ~= "Handle" then
        
        -- Store original properties
        if not Blackhole.ModifiedParts[part] then
            Blackhole.ModifiedParts[part] = {
                CanCollide = part.CanCollide,
                CustomPhysicalProperties = part.CustomPhysicalProperties
            }
        end
        
        -- Clean up existing movers
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("BodyMover") or child:IsA("RocketPropulsion") then
                child:Destroy()
            end
        end
        
        part.CanCollide = false
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        
        -- Create new attachment if needed
        if not part:FindFirstChild("BlackholeAttachment") then
            local attachment = Instance.new("Attachment")
            attachment.Name = "BlackholeAttachment"
            attachment.Parent = part
            
            local torque = Instance.new("Torque")
            torque.Name = "BlackholeTorque"
            torque.Torque = Vector3.new(100000, 100000, 100000)
            torque.Attachment0 = attachment
            torque.Parent = part
            
            local alignPos = Instance.new("AlignPosition")
            alignPos.Name = "BlackholeAlignPosition"
            alignPos.MaxForce = math.huge
            alignPos.MaxVelocity = math.huge
            alignPos.Responsiveness = 200
            alignPos.Attachment0 = attachment
            alignPos.Attachment1 = Blackhole.Attachment1
            alignPos.Parent = part
        end
        
        RetainPart(part)
    end
end

-- Start bringing parts
local function StartBringParts(target)
    InitializeNetwork()
    CreateAttachmentPart()
    
    local character = target.Character or target.CharacterAdded:Wait()
    Blackhole.HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    Blackhole.Active = true
    
    -- Process existing parts
    for _, part in ipairs(Workspace:GetDescendants()) do
        ForcePart(part)
    end
    
    -- Connect to new parts
    Blackhole.Connections.DescendantAdded = Workspace.DescendantAdded:Connect(function(part)
        if Blackhole.Active then
            ForcePart(part)
        end
    end)
    
    -- Update position loop
    Blackhole.Connections.RenderStepped = RunService.RenderStepped:Connect(function()
        if Blackhole.Active and Blackhole.Attachment1 and Blackhole.HumanoidRootPart then
            Blackhole.Attachment1.WorldCFrame = Blackhole.HumanoidRootPart.CFrame
        end
    end)
    
    return "Tpua\n" .. target.Name
end

-- Stop bringing parts (full cleanup)
local function StopBringParts()
    Blackhole.Active = false
    
    -- Disconnect all connections
    for name, connection in pairs(Blackhole.Connections) do
        if connection then
            connection:Disconnect()
        end
        Blackhole.Connections[name] = nil
    end
    
    -- Clean up modified parts
    for part, _ in pairs(Blackhole.ModifiedParts) do
        if part then
            CleanPart(part)
        end
    end
    Blackhole.ModifiedParts = {}
    
    -- Clean up anchor system
    if Blackhole.Folder then
        Blackhole.Folder:Destroy()
        Blackhole.Folder = nil
        Blackhole.Attachment1 = nil
        Blackhole.AnchorPart = nil
    end
    
    -- Clear network parts (but keep network system running)
    Network.BaseParts = {}
    
    return "Stopped Tpua"
end

-- Commands
AddCommandWithPlayer("tpua", "bp", "Tps unanchored to player", function(name)
    local target = GetPlayer(name)
    if not target then crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    return StartBringParts(target)
end)

AddCommand("untpua", "unbp", "Stops Tpua", function()
    return StopBringParts()
end)

AddCommand("tornado", {"td"}, "Loads Tornado Gui", function()
    if _G.td then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hm5650/TornadoGuiIg/refs/heads/main/Srrylolitsobfuscatednomorestealing"))()
    end)
    
    if success then
        _G.td = true
        return "TornadoGui Loaded!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("players", {"plrs"}, "Opens the players list", plrz)

AddCommand("brick", {"brk"}, "Loads Brick Unachored Abuser", function()
    if _G.pcr then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
       loadstring(game:HttpGet("https://raw.githubusercontent.com/hm5650/Brick/refs/heads/main/Brick.lua"))()
    end)
    
    if success then
        _G.pcr = true
        return "PartController Loaded!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("playerradar", {"radar", "gps"}, "Shows an Player Radar", plrd)
AddCommand("console", {"cn"}, "Opens Console", Con)

AddCommand("numeroware", {"nware", "nhub"}, "sussy :-)", function()
    if _G.nware then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/hm5650/Killerfish/refs/heads/main/KFW"))()
    end)
    
    if success then
        _G.nware = true
        return "Numero Loaded!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("explorer", {"dex"}, "Opens DexExplorer", function()
    if _G.dex then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
    end)
    
    if success then
        _G.dex = true
        return "DexExplorer Loaded"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("quirkycmd", {"qcmd"}, "really cool adminpanle1!!1 [Req, Remotes]", function()
    if _G.qc then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://gist.github.com/someunknowndude/38cecea5be9d75cb743eac8b1eaf6758/raw"))()
    end)
    
    if success then
        _G.qc = true
        return "QuirkyCmd Loaded"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("wallwalk", {"ww"}, "Enables wall walking (Rejoin to fully disable)", function()
    if _G.WallWalkExecuted then
        return "WallWalk is already active!"
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/igfrx/tpmorPpoT/refs/heads/main/WallWalk"))()
    end)
    
    if success then
        _G.WallWalkExecuted = true
        return "WallWalk Started!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("f3x", {"fex"}, "Gives you btools [CLIENT]", function()
    if _G.fex then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:GetObjects("rbxassetid://6695644299")[1].Source)()
    end)
    
    if success then
        _G.fex = true
        return "Gear Found!\nF3X loaded!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("f3xpanel", {"fexp"}, "Loads Btools panel [TOOL]", function()
    if _G.fexp then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/SkireScripts/F3X-Panel/main/Main.lua"))()
    end)
    
    if success then
        _G.fexp = true
        return "F3xpanel Loaded!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommand("sit", nil, "Makes you sit", sit)
AddCommand("cmdbar3", {"cb3"}, "Cmdbar3 for HD Admin", cmdl)
AddCommand("touchinterest", {"fti"}, "Fires All TouchInterest", fti)
AddCommand("looptouchinterest", {"loopfti", "lfti"}, "Loop Fires All TouchInterest", ftiloop)
AddCommand("unlooptouchinterest", {"unloopfti"}, "Stops loop Fires All TouchInterest", unftiloop)
AddCommand("clickdetectors", {"cds"}, "Fires All ClickDetectors", fireClickDetectors)
AddCommand("loopclickd", {"loopcds", "lcds"}, "Loop Fires All ClickDetectors", cdloop)
AddCommand("unloopclickd", {"unloopcds", "unlcds"}, "Stops Loop Fires All ClickDetectors", uncdloop)
AddCommand("interacts", {"prop", "int"}, "Fires All ProximityPrompts", fireProximityPrompts)
AddCommand("loopInteracts", {"loopprop", "lint"}, "Loop Fires All ProximityPrompts", pploop)
AddCommand("unloopInteracts", {"unloopprop", "unlint"}, "Stops Loop Fires All ProximityPrompts", pploop)

local CartControl = {
    Active = false,
    Connections = {}
}

AddCommand("fastcarts", {"fastc"}, "Increases cart speed, making them go forward", function()
    if CartControl.Active then
        crx("Cart control is already active! Use 'stopcarts' first.", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    CartControl.Active = true
    CartControl.Mode = "fast"
    local cartsControlled = 0
    
    -- Find all cart models
    for _, cart in ipairs(workspace:GetDescendants()) do
        if cart:IsA("Model") then
            local button = cart:FindFirstChild("Up")
            local clickDetector = button and button:FindFirstChildOfClass("ClickDetector")
            
            if button and button:IsA("BasePart") and clickDetector then
                cartsControlled = cartsControlled + 1
                
                -- Start rapid clicking
                coroutine.wrap(function()
                    while CartControl.Active and CartControl.Mode == "fast" and button and clickDetector and button.Parent do
                        fireclickdetector(clickDetector)
                        task.wait(0.05)
                    end
                end)()
            end
        end
    end
    
    if cartsControlled == 0 then
        CartControl.Active = false
        crx("No carts with 'Up' buttons found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    return "Speeding up " .. cartsControlled .. " carts"
end)

AddCommand("slowcarts", {"slowc"}, "Decreases cart speed, making them go backwards", function()
    if CartControl.Active then
        crx("Cart control is already active! Use 'stopcarts' first.", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    CartControl.Active = true
    CartControl.Mode = "slow"
    local cartsControlled = 0
    
    -- Find all cart models
    for _, cart in ipairs(workspace:GetDescendants()) do
        if cart:IsA("Model") then
            local button = cart:FindFirstChild("Down")
            local clickDetector = button and button:FindFirstChildOfClass("ClickDetector")
            
            if button and button:IsA("BasePart") and clickDetector then
                cartsControlled = cartsControlled + 1
                
                -- Start rapid clicking
                coroutine.wrap(function()
                    while CartControl.Active and CartControl.Mode == "slow" and button and clickDetector and button.Parent do
                        fireclickdetector(clickDetector)
                        task.wait(0.05)
                    end
                end)()
            end
        end
    end
    
    if cartsControlled == 0 then
        CartControl.Active = false
        crx("No carts with 'Down' buttons found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    return "Slowing down " .. cartsControlled .. " carts"
end)

local Killbrick = {
    Enabled = false,
    Player = game.Players.LocalPlayer
}

-- Function to apply/remove killbrick effect
local function ApplyKillbrickEffect()
    while Killbrick.Enabled and task.wait(0.1) do
        local character = Killbrick.Player.Character
        if not character then continue end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then continue end
        
        -- Get parts within radius and make them non-touchable
        local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 10)
        for _, part in ipairs(parts) do
            -- Skip parts that belong to the local player's character
            if part:IsDescendantOf(character) then
                continue
            end
            
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end
    end
end

-- Command to toggle killbrick
AddCommand("triggerbricks", {"tbs"}, "Toggle TriggerBricks (removes fti to parts)", function()
    Killbrick.Enabled = not Killbrick.Enabled
    
    if Killbrick.Enabled then
        -- Start the effect
        coroutine.wrap(ApplyKillbrickEffect)()
        return "TriggerBricks: FALSE"
    else
        return "TriggerBricks: TRUE"
    end
end)

AddCommand("dropalltools", {"dat"}, "Drops all your tools", DAT)
AddCommand("unvcban", {"vban"}, "Removes VoiceChat Ban", Vcban)

AddCommand("toolcontrol", {"tc"}, "Control any tool! [TOOL]", function()
    if _G.pcr then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/v0c0n1337/scripts/refs/heads/main/FE%20Tool%20control.txt"))()
    end)
    
    if success then
        _G.pcr = true
        return "Toolcontrol Loaded!\nPlease hold any tool"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

-- stuffness

local Fan = {
    Enabled = false,
    Connection = nil,
    TargetPlayer = nil,
    SpinAngle = 0
}

AddCommandWithPlayer("sillyorbit", nil, "Make a player dizzy", function(name)
    if Fan.Enabled then
        crx("sillyorbit is already active! Use 'unsillyorbit' to stop.", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local targetPlayer = GetPlayer(name)
    if not targetPlayer then
        crx("Player not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Fan.Enabled = true
    Fan.TargetPlayer = targetPlayer
    Fan.SpinAngle = 0
    
    local localPlayer = game.Players.LocalPlayer
    local character = localPlayer.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        crx("HumanoidRootPart not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    -- Disconnect previous connection if any
    if Fan.Connection then
        Fan.Connection:Disconnect()
        Fan.Connection = nil
    end
    
    -- Start fan orbit and spin
    Fan.Connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not Fan.Enabled or not Fan.TargetPlayer or not Fan.TargetPlayer.Character then
            if Fan.Connection then
                Fan.Connection:Disconnect()
                Fan.Connection = nil
            end
            return
        end
        
        local targetCharacter = Fan.TargetPlayer.Character
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        local localCharacter = localPlayer.Character
        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        
        if not targetRoot or not localRoot then
            return
        end
        
        -- Update spin angle
        Fan.SpinAngle = Fan.SpinAngle + (10 * dt) -- Spin speed
        
        -- Orbit calculations
        local orbitRadius = 5 -- Distance from target
        local orbitHeight = 2 -- Height above target
        
        -- Calculate orbit position
        local orbitX = math.cos(Fan.SpinAngle) * orbitRadius
        local orbitZ = math.sin(Fan.SpinAngle) * orbitRadius
        local orbitOffset = Vector3.new(orbitX, orbitHeight, orbitZ)
        
        -- Set position (orbit around target)
        localRoot.CFrame = CFrame.new(targetRoot.Position + orbitOffset, targetRoot.Position)
        
        -- Apply horizontal spinning (fan rotation)
        localRoot.CFrame = localRoot.CFrame * CFrame.Angles(0, Fan.SpinAngle * 2, 0)
    end)
    
    return "sillyorbit enabled " .. targetPlayer.Name
end)

AddCommand("unsillyorbit", nil, "Stops the haha orbit", function()
    if not Fan.Enabled then
        crx("Fan wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    Fan.Enabled = false
    Fan.TargetPlayer = nil
    Fan.SpinAngle = 0
    
    if Fan.Connection then
        Fan.Connection:Disconnect()
        Fan.Connection = nil
    end
    
    return "sillyorbit disabled"
end)

-- Auto cleanup
game.Players.LocalPlayer.CharacterRemoving:Connect(function()
    if Fan.Enabled then
        Fan.Enabled = false
        Fan.TargetPlayer = nil
        if Fan.Connection then
            Fan.Connection:Disconnect()
            Fan.Connection = nil
        end
    end
end)

-- Save original position of a player
local function SaveOriginalPosition(player)
    if not player.Character then return end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        Orbit.OriginalPositions[player] = rootPart.CFrame
    end
end

-- Restore original position of a player
local function RestoreOriginalPosition(player)
    if Orbit.OriginalPositions[player] and player.Character then
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = Orbit.OriginalPositions[player]
        end
    end
    Orbit.OriginalPositions[player] = nil
end

-- Orbit a specific player
local function OrbitPlayer(player, angle)
    if not player.Character then return end
    
    local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
    local localRoot = Orbit.LocalPlayer.Character and Orbit.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if targetRoot and localRoot then
        local x = math.cos(angle) * Orbit.Radius
        local z = math.sin(angle) * Orbit.Radius
        local position = localRoot.Position + Vector3.new(x, 0, z)
        
        targetRoot.CFrame = CFrame.new(position)
        targetRoot.Velocity = Vector3.new(0, 0, 0)
        targetRoot.RotVelocity = Vector3.new(0, 0, 0)
    end
end

-- Start orbiting
local function StartOrbit(target)
    if Orbit.Connection then
        Orbit.Connection:Disconnect()
    end
    
    Orbit.Connection = Orbit.RunService.Heartbeat:Connect(function()
        if not Orbit.Active then return end
        
        if target == "all" then
            -- Orbit all players
            for _, player in ipairs(Orbit.Players:GetPlayers()) do
                if player ~= Orbit.LocalPlayer then
                    if Orbit.Angles[player] == nil then
                        Orbit.Angles[player] = 0
                        SaveOriginalPosition(player)
                    end
                    
                    Orbit.Angles[player] = Orbit.Angles[player] + Orbit.Speed * 0.01
                    OrbitPlayer(player, Orbit.Angles[player])
                end
            end
        else
            -- Orbit specific player
            if Orbit.Angles[target] == nil then
                Orbit.Angles[target] = 0
                SaveOriginalPosition(target)
            end
            
            Orbit.Angles[target] = Orbit.Angles[target] + Orbit.Speed * 0.01
            OrbitPlayer(target, Orbit.Angles[target])
        end
    end)
end

-- Stop orbiting and clean up
local function StopOrbit()
    Orbit.Active = false
    
    if Orbit.Connection then
        Orbit.Connection:Disconnect()
        Orbit.Connection = nil
    end
    
    -- Restore all players to original positions
    for player, _ in pairs(Orbit.OriginalPositions) do
        RestoreOriginalPosition(player)
    end
    
    -- Clear tables
    Orbit.Angles = {}
    Orbit.OriginalPositions = {}
end

-- Main orbit command (handles both specific player and "all")
AddCommandWithPlayer("plrorbit", {"porb"}, "Makes player(s) orbit around you. Use 'all' for everyone", function(name)
    if Orbit.Active then
        StopOrbit()
    end
    
    -- Check if targeting all players
    if not name or string.lower(name) == "all" then
        Orbit.Active = true
        StartOrbit("all")
        return "All players are now orbiting you"
    else
        local target = GetPlayer(name)
        if not target then
            return "Player not found!"
        end
        
        Orbit.Active = true
        StartOrbit(target)
        return target.Name .. " is now orbiting you"
    end
end)

-- Stop orbit command
AddCommand("unplrorbit", {"unporb"}, "Stops all orbiting and restores players", function()
    if not Orbit.Active then
        return "Orbit wasn't active"
    end
    
    StopOrbit()
    return "Stopped orbiting"
end)

-- WallHop System Variables
local WallHop = {
    Enabled = false,
    Debounce = true,
    RaycastParams = RaycastParams.new()
}

-- Initialize raycast parameters
WallHop.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

-- Precise wall detection function
local function GetWallRaycastResult()
    local character = Players.LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    WallHop.RaycastParams.FilterDescendantsInstances = {character}

    local directions = {
        rootPart.CFrame.LookVector,
        -rootPart.CFrame.LookVector,
        rootPart.CFrame.RightVector,
        -rootPart.CFrame.RightVector
    }
    local detectionDistance = 2
    local closestHit = nil
    local minDistance = detectionDistance + 1

    for _, direction in pairs(directions) do
        local ray = Workspace:Raycast(
            rootPart.Position,
            direction * detectionDistance,
            WallHop.RaycastParams
        )
        if ray and ray.Instance then
            if ray.Distance < minDistance then
                minDistance = ray.Distance
                closestHit = ray
            end
        end
    end
    return closestHit
end

AddCommandWithPlayer("orbit", nil, "Orbit around a player", function(name)
    -- Stop existing orbit if any
    if OrbitConnection then
        OrbitConnection:Disconnect()
        OrbitConnection = nil
    end

    -- Validate player
    local targetPlayer = GetPlayer(name)
    if not targetPlayer then
        return "Player not found."
    end

    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

    -- If target has no character
    local TargetChar = targetPlayer.Character
    if not TargetChar or not TargetChar:FindFirstChild("HumanoidRootPart") then
        return "Target player has no character."
    end

    -- Orbit settings
    local radius = 10
    local speed = 2
    local angle = 0

    -- Start orbiting
    OrbitConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        -- Check if target character still exists
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            OrbitConnection:Disconnect()
            OrbitConnection = nil
            return
        end

        -- Check if local character still exists
        if not Character or not Character.Parent or not HumanoidRootPart or not HumanoidRootPart.Parent then
            OrbitConnection:Disconnect()
            OrbitConnection = nil
            return
        end

        angle = angle + speed * dt
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")

        -- Calculate orbit position
        local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        HumanoidRootPart.CFrame = CFrame.new(targetHRP.Position + offset, targetHRP.Position)
    end)

    return "Started orbiting " .. targetPlayer.Name
end)

AddCommand("unorbit", nil, "Stop orbiting", function()
    if OrbitConnection then
        OrbitConnection:Disconnect()
        OrbitConnection = nil
        return "Stopped orbiting."
    else
        return "You are not orbiting anyone."
    end
end)

-- Core WallHop functionality
local function SetupWallHop()
    UserInputService.JumpRequest:Connect(function()
        if not WallHop.Enabled or not WallHop.Debounce then return end

        local player = Players.LocalPlayer
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera

        if not (humanoid and rootPart and camera) then return end

        local wallRayResult = GetWallRaycastResult()

        if wallRayResult then
            WallHop.Debounce = false

            -- Calculate directions
            local wallNormal = wallRayResult.Normal
            local horizontalWallNormal = Vector3.new(wallNormal.X, 0, wallNormal.Z).Unit
            if horizontalWallNormal.Magnitude < 0.1 then
                horizontalWallNormal = (rootPart.CFrame.LookVector * Vector3.new(1,0,1)).Unit
                if horizontalWallNormal.Magnitude < 0.1 then 
                    horizontalWallNormal = Vector3.new(0,0,-1) 
                end
            end
            
            local baseDirection = horizontalWallNormal
            local cameraLook = camera.CFrame.LookVector
            local horizontalCameraLook = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
            if horizontalCameraLook.Magnitude < 0.1 then 
                horizontalCameraLook = baseDirection 
            end

            -- Calculate rotation
            local maxAngle = math.rad(40)
            local dot = math.clamp(baseDirection:Dot(horizontalCameraLook), -1, 1)
            local angle = math.acos(dot)
            local cross = baseDirection:Cross(horizontalCameraLook)
            local rotationSign = math.sign(cross.Y)
            if rotationSign == 0 then angle = 0 end
            local actualAngle = math.min(angle, maxAngle)
            local adjustment = CFrame.Angles(0, actualAngle * rotationSign, 0)
            local targetDirection = adjustment * baseDirection

            -- Apply initial rotation
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + targetDirection)
            RunService.Heartbeat:Wait()

            -- Execute jump
            local didJump = false
            if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                didJump = true
            end

            -- Rotate back towards wall
            if didJump then
                rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + -baseDirection)
            end

            -- Cooldown
            task.wait(0.15)
            WallHop.Debounce = true
        end
    end)
end

-- Commands
AddCommand("autowallhop", {"awh"}, "Enables automatic wall hopping", function()
    if WallHop.Enabled then
        return "AutoWallHop is already enabled"
    end
    
    WallHop.Enabled = true
    SetupWallHop()
    return "AutoWallHop enabled"
end)

AddCommand("unautowallhop", {"unawh"}, "Disables automatic wall hopping", function()
    if not WallHop.Enabled then
        return "AutoWallHop wasn't active"
    end
    
    WallHop.Enabled = false
    return "AutoWallHop disabled"
end)


-- Hitbox command
local originalSizes = {} -- Stores original sizes of HRPs
local hitboxEnabled = false
local currentSize = 0
local connections = {} -- Stores player connections to clean up later

-- Function to apply hitbox to a character
local function applyHitbox(character, player)
    -- Skip if this is the local player
    if player == game.Players.LocalPlayer then
        return
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Store original size if we haven't already
        if not originalSizes[player] then
            originalSizes[player] = hrp.Size
        end
        
        if hitboxEnabled then
            -- Apply hitbox size
            hrp.Size = Vector3.new(currentSize, currentSize, currentSize)
            hrp.Transparency = 0.9
            hrp.Material = Enum.Material.Neon
            hrp.Color = Color3.fromRGB(255, 0, 0) -- Red color for visibility
        else
            -- Reset to original size
            hrp.Size = originalSizes[player]
            hrp.Transparency = 0
            hrp.Material = Enum.Material.Plastic
            hrp.Color = Color3.fromRGB(13, 105, 172) -- Default blue color
        end
    end
end

-- Function to handle character added events
local function setupPlayer(player)
    -- Skip if this is the local player
    if player == game.Players.LocalPlayer then
        return
    end
    
    -- Clean up any existing connection for this player
    if connections[player] then
        connections[player]:Disconnect()
        connections[player] = nil
    end
    
    -- Set up new connection
    connections[player] = player.CharacterAdded:Connect(function(character)
        -- Wait for the character to fully load
        character:WaitForChild("HumanoidRootPart")
        applyHitbox(character, player)
    end)
    
    -- Apply to existing character if it exists
    if player.Character then
        player.Character:WaitForChild("HumanoidRootPart")
        applyHitbox(player.Character, player)
    end
end

-- Cleanup function
local function cleanup()
    hitboxEnabled = false
    currentSize = 0
    
    -- Disconnect all player connections
    for player, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Reset all hitboxes
    for player, originalSize in pairs(originalSizes) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = originalSize
                hrp.Transparency = 0
                hrp.Material = Enum.Material.Plastic
                hrp.Color = Color3.fromRGB(13, 105, 172)
            end
        end
    end
    
    originalSizes = {}
end

local NoFallDamage = {
    Enabled = false,
    Connections = {}
}

AddCommand("nofalldamage", {"nfd"}, "Prevents all fall damage", function()
    if NoFallDamage.Enabled then
        crx("NoFallDamage is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    NoFallDamage.Enabled = true
    local player = game.Players.LocalPlayer
    
    -- Function to setup fall damage protection for a character
    local function setupCharacter(character)
        local humanoid = character:WaitForChild("Humanoid")
        
        -- Store original state
        NoFallDamage.OriginalStates = NoFallDamage.OriginalStates or {}
        NoFallDamage.OriginalStates[humanoid] = {
            UseJumpPower = humanoid.UseJumpPower,
            JumpPower = humanoid.JumpPower,
            JumpHeight = humanoid.JumpHeight
        }
        
        -- Prevent fall damage by making character float before hitting ground
        if NoFallDamage.Connections.falling then
            NoFallDamage.Connections.falling:Disconnect()
        end
        
        NoFallDamage.Connections.falling = humanoid.StateChanged:Connect(function(oldState, newState)
            if NoFallDamage.Enabled and newState == Enum.HumanoidStateType.Freefall then
                -- When falling, reduce velocity before hitting ground
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart and rootPart.Velocity.Y < -50 then -- Only if falling fast
                    rootPart.Velocity = Vector3.new(rootPart.Velocity.X, -25, rootPart.Velocity.Z)
                end
            end
        end)
        
        -- Alternative method: Modify physics properties to reduce fall damage
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end
    
    -- Setup current character
    if player.Character then
        setupCharacter(player.Character)
    end
    
    -- Setup for new characters
    if NoFallDamage.Connections.characterAdded then
        NoFallDamage.Connections.characterAdded:Disconnect()
    end
    
    NoFallDamage.Connections.characterAdded = player.CharacterAdded:Connect(function(character)
        if NoFallDamage.Enabled then
            setupCharacter(character)
        end
    end)
    
    return "NoFallDamage enabled"
end)

AddCommand("unnofalldamage", {"unnfd"}, "Allows fall damage again", function()
    if not NoFallDamage.Enabled then
        crx("NoFallDamage wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    
    NoFallDamage.Enabled = false
    
    -- Restore original states
    if NoFallDamage.OriginalStates then
        for humanoid, states in pairs(NoFallDamage.OriginalStates) do
            if humanoid and humanoid.Parent then
                humanoid.UseJumpPower = states.UseJumpPower
                humanoid.JumpPower = states.JumpPower
                humanoid.JumpHeight = states.JumpHeight
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            end
        end
        NoFallDamage.OriginalStates = {}
    end
    
    -- Disconnect all connections
    for _, connection in pairs(NoFallDamage.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    NoFallDamage.Connections = {}
    
    return "NoFallDamage disabled"
end)

-- Main command
AddCommandWithValue("hitbox", "amount", {"reach", "hb"}, "Changes other players hitbox size (0 to reset)", function(size)
    local sizeNum = tonumber(size)
    if not sizeNum then crx("Invalid amount!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    -- Clean up if resetting
    if sizeNum == 0 then
        cleanup()
        return "Hitboxes reset to normal"
    end
    
    -- Set new state
    hitboxEnabled = true
    currentSize = sizeNum
    
    -- Setup existing players
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            setupPlayer(player)
        end
    end
    
    -- Setup future players
    if not connections.playerAdded then
        connections.playerAdded = game:GetService("Players").PlayerAdded:Connect(function(player)
            setupPlayer(player)
        end)
    end
    
    return "Hitbox size set to "..sizeNum
end)

-- Reapply hitboxes when local player respawns (to ensure they persist)
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if hitboxEnabled then
        -- Wait a moment for other players to load
        wait(1)
        -- Reapply hitboxes to all players
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                applyHitbox(player.Character, player)
            end
        end
    end
end)

-- Clean up when script ends
game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(cleanup)

-- == jump loop ==
local JumpLoop = {
    Enabled = false,
    Value = 50,
    Connection = nil,
    CharConn = nil
}

local function detectAndApplyJump(hum, val)
    if not hum or not hum.Parent then return end
    if hum.UseJumpPower then
        hum.JumpPower = val
    else
        hum.JumpHeight = val
    end
end

local function startJumpLoop()
    if JumpLoop.Connection then JumpLoop.Connection:Disconnect() end
    JumpLoop.Connection = RunService.Heartbeat:Connect(function()
        if not JumpLoop.Enabled then
            JumpLoop.Connection:Disconnect()
            JumpLoop.Connection = nil
            return
        end
        local char = Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then detectAndApplyJump(hum, JumpLoop.Value) end
        end
    end)
end

AddCommandWithValue("jumppower", "amount", "jp", "Sets jump power/height (auto-detect)", function(power)
    local num = tonumber(power)
    if not num then crx("Invalid amount!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) return end
    JumpLoop.Value = num
    JumpLoop.Enabled = true
    local char = Players.LocalPlayer.Character
    local jtype = "JumpPower"
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if not hum.UseJumpPower then jtype = "JumpHeight" end
            detectAndApplyJump(hum, num)
        end
    end
    startJumpLoop()
    if JumpLoop.CharConn then JumpLoop.CharConn:Disconnect() end
    JumpLoop.CharConn = Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
        if not JumpLoop.Enabled then return end
        task.wait(0.5)
        local hum = newChar:FindFirstChildOfClass("Humanoid")
        if hum then detectAndApplyJump(hum, JumpLoop.Value) end
    end)
    return "Jump " .. jtype .. " set to
" .. num
end)

AddCommand("stopjump", {"sjp"}, "Stops jump loop", function()
    JumpLoop.Enabled = false
    if JumpLoop.Connection then JumpLoop.Connection:Disconnect() JumpLoop.Connection = nil end
    if JumpLoop.CharConn then JumpLoop.CharConn:Disconnect() JumpLoop.CharConn = nil end
    return "Jump loop stopped"
end)

-- == infjump ==
local InfJump = {
    Enabled = false,
    Connection = nil,
    CharConn = nil
}

local function setupInfJump(char)
    local hum = char:WaitForChild("Humanoid")
    if InfJump.Connection then InfJump.Connection:Disconnect() end
    InfJump.Connection = hum.StateChanged:Connect(function(_, new)
        if not InfJump.Enabled then return end
        if new == Enum.HumanoidStateType.Freefall or
           new == Enum.HumanoidStateType.Jumping then
            task.wait(0.3)
            if InfJump.Enabled then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

AddCommand("infjump", {"ij"}, "Infinite jump (cooldown kayak Roblox asli)", function()
    if InfJump.Enabled then
        crx("InfJump already active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    InfJump.Enabled = true
    local char = Players.LocalPlayer.Character
    if char then setupInfJump(char) end
    if InfJump.CharConn then InfJump.CharConn:Disconnect() end
    InfJump.CharConn = Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
        if not InfJump.Enabled then return end
        task.wait(0.5)
        setupInfJump(newChar)
    end)
    return "InfJump enabled"
end)

AddCommand("uninfjump", {"unij"}, "Stops infinite jump", function()
    if not InfJump.Enabled then
        crx("InfJump wasn't active!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
        return
    end
    InfJump.Enabled = false
    if InfJump.Connection then InfJump.Connection:Disconnect() InfJump.Connection = nil end
    if InfJump.CharConn then InfJump.CharConn:Disconnect() InfJump.CharConn = nil end
    return "InfJump disabled"
end)

AddCommandWithValue("gravity", "value", "grav", "Sets workspace gravity", function(value)
    local num = tonumber(value)
    if not num then crx("Invalid value!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    workspace.Gravity = num
    return "Gravity set to\n"..num
end)

AddCommandWithValue("hipheight", "amount", "hh", "Sets your hip height", function(height)
    local num = tonumber(height)
    if not num then crx("Invalid amount!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HipHeight = num
        return "Hip height set to\n"..num
    end
    crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
end)

local spinning = nil -- connection holder

AddCommandWithValue("spin", "speed", nil, "Spin your character at the given speed", function(value)
    local speed = tonumber(value)
    if not speed then
        crx("Invalid speed!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    local character = game.Players.LocalPlayer.Character
    if not character then
        crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        crx("HRP not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    -- Stop previous spin if active
    if spinning then
        spinning:Disconnect()
        spinning = nil
    end

    -- Start new spin loop
    spinning = RunService.Heartbeat:Connect(function(dt)
        if character and character.Parent and hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(speed), 0)
        end
    end)

    return "Spinning at\n" .. speed
end)

AddCommand("unspin", nil, "Stop spinning your character", function()
    if spinning then
        spinning:Disconnect()
        spinning = nil
        return "Spin stopped"
    else
        return "Stopped spinning"
    end
end)

local joinLogsEnabled = false
local joinLogsConnection

AddCommand("joinlogs", "jlogs", "Toggle join logs on/off", function()
    joinLogsEnabled = not joinLogsEnabled

    if joinLogsEnabled then
        crx("Join Logs Enabled", 1.5, Color3.fromRGB(0, 255, 0), nil)

        joinLogsConnection = game.Players.PlayerAdded:Connect(function(player)
            crx(player.Name .. " joined the game", 2, Color3.fromRGB(255, 255, 0), nil)
        end)
    else
        crx("Join Logs Disabled", 1.5, Color3.fromRGB(255, 0, 0), nil)

        if joinLogsConnection then
            joinLogsConnection:Disconnect()
            joinLogsConnection = nil
        end
    end
end)

AddCommand("ping", nil, "Show your current ping", function()
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    return "Ping: " .. ping .. "ms"
end)

-- Fullbright command
local fullbrightEnabled = false
local originalLighting

AddCommand("fullbright", {"fb"}, "Toggles fullbright mode", function()
    fullbrightEnabled = not fullbrightEnabled
    local lighting = game:GetService("Lighting")
    
    if fullbrightEnabled then
        originalLighting = {
            Ambient = lighting.Ambient,
            Brightness = lighting.Brightness,
            GlobalShadows = lighting.GlobalShadows
        }
        
        lighting.Ambient = Color3.new(1,1,1)
        lighting.Brightness = 1
        lighting.GlobalShadows = false
        
        return "Fullbright enabled"
    else
        if originalLighting then
            lighting.Ambient = originalLighting.Ambient
            lighting.Brightness = originalLighting.Brightness
            lighting.GlobalShadows = originalLighting.GlobalShadows
        end
        
        return "Fullbright disabled"
    end
end)

-- Rejoin command
AddCommand("rejoin", {"rj"}, "Rejoins the same game", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
    return "Rejoining game..."
end)

-- Server Hop command
AddCommand("serverhop", {"sh"}, "Joins a random server", function()
    local Http = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    
    local servers = Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    
    for _, server in ipairs(servers.data) do
        if server.playing < server.maxPlayers and server.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
            return "Server hopping..."
        end
    end
    
    crx("No available servers!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
end)

AddCommand("serverinfo", {"si"}, "Shows sum serverinfo", function()
    if _G.sk then
        return
    end
    
    -- Execute the wallwalk script
    local success, errorMessage = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/igfrx/tpmorPpoT/refs/heads/main/serveridk.lua"))()
    end)
    
    if success then
        _G.sk = true
        return "Opened 'Serverinfo' window!"
    else
        crx("Failed To Load!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

-- Copy Position command
AddCommand("copypos", {"cp"}, "Copies your current position to clipboard", function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then crx("HRP not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    local position = hrp.Position
    local text = string.format("Vector3.new(%d, %d, %d)", position.X, position.Y, position.Z)
    
    setclipboard(text)
    return "copied to clipboard:\n"..text
end)

-- Size command
AddCommandWithValue("size", "amount", "scale", "Scales your character size", function(scale)
    local num = tonumber(scale)
    if not num or num <= 0 or num > 10 then crx("Invalid amount!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    local character = game.Players.LocalPlayer.Character
    if not character then crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Size = part.Size * num
        end
    end
    
    return "scaled to\n"..num.."x"
end)

AddCommand("dance", "d", "Makes your character dance", function()
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then crx("Humanoid not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    -- Load dance animation
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://35654637" -- Default dance animation
    
    local track = humanoid:LoadAnimation(animation)
    track:Play()
    return "Dancing!"
end)

AddCommand("undance", "und", "Stops dancing", function()
    local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then crx("Humanoid not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    return "Stopped dancing :("
end)

AddCommand("day", nil, "Sets time to day [CLIENT]", function()
    game:GetService("Lighting").ClockTime = 14
    return "Time set to day"
end)

AddCommand("night", nil, "Sets time to night [CLIENT]", function()
    game:GetService("Lighting").ClockTime = 2
    return "Time set to night"
end)

AddCommandWithValue("time", "value", nil, "Sets the time (0-24) [CLIENT]", function(value)
    local num = tonumber(value)
    if not num or num < 0 or num > 24 then
        crx("Invalid time! (0-24)", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    game:GetService("Lighting").ClockTime = num
    return "Time set to "..num
end)

-- Enable fakelag with adjustable delay
AddCommandWithValue("fakelag", "delay", "flag", "Makes you look  like you have Lag", function(delay)
    local waitTime = tonumber(delay)
    if not waitTime or waitTime <= 0 then
        return "Usage: fakelag [delay]\nExample: fakelag 0.1"
    end

    -- Disable existing fakelag if active
    if _G.FakeLagEnabled then
        _G.FakeLagEnabled = false
        if _G.FakeLagThread then
            task.cancel(_G.FakeLagThread)
            _G.FakeLagThread = nil
        end
        -- Unanchor character when disabling
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = false
        end
    end

    -- Enable new fakelag
    _G.FakeLagEnabled = true
    _G.FakeLagWaitTime = waitTime

    _G.FakeLagThread = task.spawn(function()
        local player = game.Players.LocalPlayer
        while _G.FakeLagEnabled and task.wait(waitTime) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                -- Freeze character for 0.4 seconds (adjustable)
                char.HumanoidRootPart.Anchored = true
                task.wait(0.4)
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Anchored = false
                end
            end
        end
    end)

    return "Fakelag enabled\n(delay: " .. waitTime .. "s)"
end)

-- Disable fakelag
AddCommand("unfakelag", "unflag", "Disables fakelag", function()
    if _G.FakeLagEnabled then
        _G.FakeLagEnabled = false
        if _G.FakeLagThread then
            task.cancel(_G.FakeLagThread)
            _G.FakeLagThread = nil
        end
        -- Unanchor character
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = false
        end
        return "Fakelag disabled"
    else
        crx("Fakelag was never enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
end)

AddCommandWithValue("animspeed", "value", "as", "Sets animation speed (1 = default)", function(value)
    local speed = tonumber(value)
    if not speed or speed <= 0 or speed > 10 then
        crx("Invalid value!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    -- Start a loop to continuously apply speed
    if character:FindFirstChild("AnimationSpeedLoop") then
        character.AnimationSpeedLoop:Destroy() -- Remove old loop if it exists
    end

    local loopMarker = Instance.new("BoolValue")
    loopMarker.Name = "AnimationSpeedLoop"
    loopMarker.Parent = character

    task.spawn(function()
        while loopMarker.Parent do
            task.wait()
            local humanoid = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
            if not humanoid then continue end

            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(speed)
            end
        end
    end)

    return "animspeed set to\n" .. speed
end)

-- Set max camera zoom only (does NOT change min zoom)
AddCommandWithValue("zoom", "value", "z", "Sets max camera zoom distance", function(value)
    local num = tonumber(value)
    if not num or num < 0 then
        crx("Invalid value!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end

    local player = game.Players.LocalPlayer
    player.CameraMaxZoomDistance = num

    return "Zoom set to\n" .. num
end)

-- Reset zoom to Roblox defaults (min stays at default 0.5, max at 128)
AddCommand("resetzoom", {"rz"}, "Reset zoom distance to default", function()
    local player = game.Players.LocalPlayer
    player.CameraMaxZoomDistance = 128

    return "Zoom reset to default"
end)

-- Set camera field of view
AddCommandWithValue("fov", "value", nil, "Sets camera Field of View", function(value)
    local num = tonumber(value)
    if not num or num < 1 or num > 120 then
        return "FOV must be between 1 and 120"
    end

    workspace.CurrentCamera.FieldOfView = num
    return "FOV set to\n" .. num
end)

-- Helper: Find a player by partial username or display name
local function FindPlayer(name)
    name = name:lower()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Name:lower():sub(1, #name) == name or player.DisplayName:lower():sub(1, #name) == name then
            return player
        end
    end
    return nil
end



local currentViewConnection -- to disconnect old connections
local currentViewedPlayer -- to track which player is being viewed

AddCommandWithPlayer("view", nil, "View a player", function(name)
    local targetPlayer = FindPlayer(name)
    if not targetPlayer then
        crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    
    -- If already viewing this player, stop viewing
    if currentViewedPlayer == targetPlayer then
        if currentViewConnection then
            currentViewConnection:Disconnect()
            currentViewConnection = nil
        end
        currentViewedPlayer = nil
        return "Stopped viewing\n" .. targetPlayer.Name
    end
    
    local function updateView(character)
        if not character then return end
        
        -- Wait for humanoid to exist (might not be immediately available after respawn)
        local humanoid = character:WaitForChild("Humanoid", 5) or character:FindFirstChildWhichIsA("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        elseif hrp then
            workspace.CurrentCamera.CameraSubject = hrp
        end
    end

    -- Disconnect previous connection if viewing another player
    if currentViewConnection then
        currentViewConnection:Disconnect()
        currentViewConnection = nil
    end

    -- Update view immediately
    updateView(targetPlayer.Character)

    -- Listen for respawn
    currentViewConnection = targetPlayer.CharacterAdded:Connect(updateView)
    currentViewedPlayer = targetPlayer

    return "Viewing\n" .. targetPlayer.Name
end)

AddCommand("unview", nil, "Reset camera back to yourself", function()
    -- Clear viewing state
    if currentViewConnection then
        currentViewConnection:Disconnect()
        currentViewConnection = nil
    end
    currentViewedPlayer = nil
    
    -- Reset to local player
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    local humanoid = character:WaitForChild("Humanoid", 5) or character:FindFirstChildWhichIsA("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if humanoid then
        workspace.CurrentCamera.CameraSubject = humanoid
    elseif hrp then
        workspace.CurrentCamera.CameraSubject = hrp
    end

    return "Stopped viewing"
end)

-- Fixed version of the goto command
AddCommandWithPlayer("goto", {"tp"}, "Teleport to a player", function(name)
    local targetPlayer = FindPlayer(name)
    if not targetPlayer then crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end

    local character = game.Players.LocalPlayer.Character
    if not character then crx("Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then crx("HRP not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end

    local targetCharacter = targetPlayer.Character
    if not targetCharacter then crx("Target not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end

    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHRP then crx("Target's Character not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end

    -- Offset behind the target
    local offset = CFrame.new(0, 0, 5)
    humanoidRootPart.CFrame = targetHRP.CFrame * offset

    return "Teleported to\n" .. targetPlayer.Name
end)

AddCommand("teleporttool", {"tptool"}, "Click any where to teleport", CreateTptool)

-- Activate all tools command
AddCommand("aat", {"activatealltools"}, "Activates all tools in your inventory", function()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if not backpack and not character then crx("Backpack or Tools not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    local tools = {}
    
    -- Get tools from backpack
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    -- Get tools from character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(tools, item)
            end
        end
    end
    
    if #tools == 0 then crx("Tools not found!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    -- Equip and activate all tools
    for _, tool in ipairs(tools) do
        if character then
            tool.Parent = character
            if tool:FindFirstChild("Activate") then
                tool.Activate:Fire()
            end
        end
    end
    
    return "Activated "..#tools.." tools"
end)

AddCommand("loopaat", {"laat"}, "activate all tools but it's looped", loopaat2)
AddCommand("unloopaat", {"unlaat"}, "Stops Loopaat", unloopaat1)

local AutoUse = {
    Enabled = false,
    Connection = nil,
    UseCooldown = 0.01 -- 10ms between uses
}

-- AutoUse command
AddCommand("autouse", "au", "Automatically uses the selected tool every 0.01 seconds", function()
    if AutoUse.Enabled then
        crx("AutoUse is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    
    AutoUse.Enabled = true
    local player = game.Players.LocalPlayer
    
    -- Start the auto-use loop
    AutoUse.Connection = game:GetService("RunService").Heartbeat:Connect(function()
        if not AutoUse.Enabled then return end
        
        -- Get the currently selected tool
        local character = player.Character
        local backpack = player:FindFirstChild("Backpack")
        
        if not character or not backpack then return end
        
        -- Check for selected tool in backpack or character
        local selectedTool = nil
        local selectedSlot = player:GetAttribute("SelectedSlot") or player:FindFirstChild("SelectedSlot")
        
        if selectedSlot then
            local slotNumber = tonumber(tostring(selectedSlot)) or 1
            selectedTool = backpack:FindFirstChild(tostring(slotNumber)) or character:FindFirstChild(tostring(slotNumber))
        else
            -- Fallback: try to find any equipped tool
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") then
                    selectedTool = tool
                    break
                end
            end
        end
        
        -- Use the tool if found
        if selectedTool and selectedTool:IsA("Tool") then
            -- Activate the tool
            pcall(function()
                selectedTool:Activate()
            end)
        end
        
        -- Respect the cooldown
        task.wait(AutoUse.UseCooldown)
    end)
    
    return "AutoUse enabled - Automatically using selected tool every 0.01s"
end)

-- Stop AutoUse command
AddCommand("unautouse", "unau", "Stops automatically using tools", function()
    if not AutoUse.Enabled then
        crx("AutoUse was never enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500)
    end
    
    AutoUse.Enabled = false
    if AutoUse.Connection then
        AutoUse.Connection:Disconnect()
        AutoUse.Connection = nil
    end
    
    return "AutoUse disabled"
end)

-- ESP command
local espEnabled = false
local espObjects = {}

local function createESP(player)
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    -- Set color based on team
    if player.Team then
        if player.Team == game.Players.LocalPlayer.Team then
            highlight.FillColor = Color3.fromRGB(0, 0, 255) -- Blue for teammates
            highlight.OutlineColor = Color3.fromRGB(0, 0, 200)
        else
            highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red for enemies
            highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
        end
    else
        highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green for neutral
        highlight.OutlineColor = Color3.fromRGB(0, 200, 0)
    end
    
    highlight.Parent = character
    
    -- Distance label
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Distance"
    billboard.Adornee = character:WaitForChild("Head") or character:WaitForChild("HumanoidRootPart")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    
    local label = Instance.new("TextLabel")
    label.Name = "ESP_Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = billboard
    
    billboard.Parent = character
    
    -- Store for cleanup
    espObjects[player] = {highlight, billboard}
    
    -- Update distance
    game:GetService("RunService").Heartbeat:Connect(function()
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if not game.Players.LocalPlayer.Character or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        
        local distance = (character.HumanoidRootPart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        label.Text = string.format("%s [%d studs]", player.Name, math.floor(distance))
    end)
end

local function removeESP(player)
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            if obj then
                obj:Destroy()
            end
        end
        espObjects[player] = nil
    end
end

AddCommand("esp", nil, "Highlights all players with distance", function()
    if espEnabled then crx("ESP is already enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    espEnabled = true
    
    -- ESP existing players
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            createESP(player)
        end
    end
    
    -- ESP new players
    game.Players.PlayerAdded:Connect(function(player)
        if espEnabled then
            player.CharacterAdded:Connect(function(character)
                if espEnabled then
                    createESP(player)
                end
            end)
        end
    end)
    
    -- Handle character respawns
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            player.CharacterAdded:Connect(function(character)
                if espEnabled then
                    createESP(player)
                end
            end)
        end
    end
    
    return "ESP enabled"
end)

AddCommand("unesp", nil, "Removes all ESP highlights", function()
    if not espEnabled then crx("ESP was never enabled!", 1.1, Color3.fromRGB(255, 0, 0), 138081500) end
    
    espEnabled = false
    
    for player, objects in pairs(espObjects) do
        for _, obj in ipairs(objects) do
            if obj then
                obj:Destroy()
            end
        end
    end
    
    espObjects = {}
    return "ESP disabled"
end)

-- Xray command
local xrayEnabled = false
local originalTransparencies = {}

local function enableXray()
    if xrayEnabled then return end
    
    xrayEnabled = true
    
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            originalTransparencies[part] = part.Transparency
            part.Transparency = 0.5
            part.LocalTransparencyModifier = 0.5
        end
    end
    
    -- Handle new parts
    workspace.DescendantAdded:Connect(function(part)
        if xrayEnabled and part:IsA("BasePart") and part.Transparency < 1 then
            originalTransparencies[part] = part.Transparency
            part.Transparency = 0.5
            part.LocalTransparencyModifier = 0.5
        end
    end)
end

local function disableXray()
    if not xrayEnabled then return end
    
    xrayEnabled = false
    
    for part, transparency in pairs(originalTransparencies) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
            part.LocalTransparencyModifier = 0
        end
    end
    
    originalTransparencies = {}
end

AddCommand("xray", nil, "See through walls", function()
    enableXray()
    return "Xray enabled"
end)

AddCommand("unxray", nil, "Disables xray", function()
    disableXray()
    return "Xray disabled"
end)

AddCommand("credits", {"c"}, "Shows the owner of the script", credits)
AddCommand("sucess", {"good"}, "Shows an success notification", good)
AddCommand("error", {"bad"}, "Shows an error notification", error)
AddCommand("notification", {"notify"}, "Shows an normal notification", meh)

-- Function to destroy existing TopPrompt GUI if it exists
local function destroyExistingTopPrompt()
    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local existingGui = playerGui:FindFirstChild("TopPrompt")
        if existingGui then
            existingGui:Destroy()
        end
    end
end

-- Player references
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local function initializeMainGUI()
    -- Destroy any existing TopPrompt GUI first
    destroyExistingTopPrompt()
    
    -- Rest of your existing GUI initialization code...
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create or get existing main GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TopPrompt"
    ScreenGui.DisplayOrder = 99999
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = playerGui

    -- Mobile detection
    local function isMobile()
        return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
    end


local currentNotification = nil

-- Function to create or get the ScreenGui
local function getScreenGui()
    local player = game:GetService("Players").LocalPlayer
    while not player do
        player = game:GetService("Players").LocalPlayer
        wait()
    end
    
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = playerGui:FindFirstChild("NotificationGui")
    
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "NotificationGui"
        gui.DisplayOrder = 999999
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = playerGui
        
        -- Ensure GUI is properly initialized
        gui:GetPropertyChangedSignal("Enabled"):Connect(function()
            if not gui.Enabled then
                gui.Enabled = true
            end
        end)
    end
    
    -- Make sure GUI is enabled
    if not gui.Enabled then
        gui.Enabled = true
    end
    
    return gui
end

function crx(message, duration, rateColor, soundId)
    -- Validate input
    if not message or type(message) ~= "string" then
        warn("Notification error: Invalid message")
        return
    end
    
    -- Default values
    duration = duration or 2
    rateColor = rateColor or Color3.fromRGB(0, 170, 255)
    
    -- Get the ScreenGui (will create if doesn't exist)
    local screenGui = getScreenGui()
    
    -- Destroy previous notification if it exists
    if currentNotification and currentNotification.Parent then
        local oldNotify = currentNotification
        currentNotification = nil
        
        -- Smoothly fade out old notification
        local fadeOut = game:GetService("TweenService"):Create(oldNotify, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 30)
        })
        fadeOut:Play()
        
        fadeOut.Completed:Connect(function()
            if oldNotify and oldNotify.Parent then
                oldNotify:Destroy()
            end
        end)
    end
    
    -- Play sound immediately if soundId is provided
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(soundId)
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
    
    -- Create notification frame
    local notify = Instance.new("Frame")
    notify.Name = "Notification"
    notify.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notify.BackgroundTransparency = 0.3
    notify.BorderSizePixel = 0
    notify.Size = UDim2.new(0, 0, 0, 30)
    notify.Position = UDim2.new(0, 20, 0, 69)
    notify.ZIndex = 10
    notify.ClipsDescendants = true -- Prevent overflow
    notify.Parent = screenGui
    
    -- Store the current notification
    currentNotification = notify
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notify
    
    -- Add subtle shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.ZIndex = 9
    shadow.Parent = notify
    
    -- Add accent bar
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.BackgroundColor3 = rateColor
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 3, 0.7, 0)
    accent.Position = UDim2.new(0, 5, 0.13, 0)
    accent.ZIndex = 11
    accent.Parent = notify
    
    -- Round accent corners
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent
    
    -- Add modern text label
    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.Text = ""
    label.Font = Enum.Font.Arcade
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = false
    label.ClipsDescendants = true
    label.Parent = notify
    
    -- Smooth expand animation
    local expand = game:GetService("TweenService"):Create(notify, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
        Size = UDim2.new(0, 250, 0, 30)
    })
    expand:Play()
    
    -- Typewriter effect
    local displayText = ""
    local fullText = tostring(message)
    local typingSpeed = 0.0001
    
    -- Use a coroutine for the typing effect
    coroutine.wrap(function()
        for i = 1, #fullText do
            if not (notify and notify.Parent) then break end
            
            displayText = string.sub(fullText, 1, i)
            label.Text = displayText
            
            if string.sub(fullText, i, i) ~= " " and clickSound then
                clickSound:Play()
            end
            
            wait(typingSpeed)
        end
    end)()
    
    -- Auto-close after delay
    task.delay(duration, function()
        if not (notify and notify.Parent) then return end
        
        local fadeOut = game:GetService("TweenService"):Create(notify, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 30)
        })
        fadeOut:Play()
        
        local textFade = game:GetService("TweenService"):Create(label, TweenInfo.new(0.2), {
            TextTransparency = 1
        })
        textFade:Play()
        
        local accentFade = game:GetService("TweenService"):Create(accent, TweenInfo.new(0.2), {
            BackgroundTransparency = 1
        })
        accentFade:Play()
        
        fadeOut.Completed:Connect(function()
            if notify and notify.Parent then
                notify:Destroy()
                if currentNotification == notify then
                    currentNotification = nil
                end
            end
        end)
    end)
    
    return notify
end

    local MainFrame = ScreenGui:FindFirstChild("MainFrame")
    

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.BorderSizePixel = 0
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BackgroundTransparency = 0.2
    
    -- Set position based on device type
    if isMobile() then
        MainFrame.Position = UDim2.new(0, 20, 0, 2)
    else
        MainFrame.Position = UDim2.new(0.5, -73, 1, -50)
    end
    
    MainFrame.Size = UDim2.new(0, 146, 0, 44)
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = MainFrame
    
    local Arrow = Instance.new("TextLabel")
    Arrow.Name = "Arrow"
    Arrow.Text = ">"
    Arrow.Font = Enum.Font.Arcade
    Arrow.TextSize = 40
    Arrow.TextColor3 = Color3.fromRGB(0, 255, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Size = UDim2.new(0, 56, 0, 50)
    Arrow.Position = UDim2.new(0, 0, 0, -6)
    Arrow.Parent = MainFrame

    -- Blinking arrow animation
    local arrowBlink = TweenService:Create(Arrow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        TextTransparency = 0.5
    })
    arrowBlink:Play()

    local InputBox = Instance.new("TextBox")
    InputBox.Name = "InputBox"
    InputBox.PlaceholderText = "..."
    InputBox.Font = Enum.Font.Arcade
    InputBox.TextSize = 25
    InputBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    InputBox.PlaceholderColor3 = Color3.fromRGB(0, 255, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.Size = UDim2.new(0, 102, 0, 44)
    InputBox.Position = UDim2.new(0, 40, 0, 0)
    InputBox.TextTruncate = Enum.TextTruncate.AtEnd  -- This prevents overflow
    InputBox.ClipsDescendants = true  -- Ensures text doesn't render outside the box
    InputBox.Parent = MainFrame

    -- Input box focus animations
    InputBox.Focused:Connect(function()
        clickSound:Play()
        local focusTween = TweenService:Create(InputBox, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(0, 255, 255),
            PlaceholderColor3 = Color3.fromRGB(0, 255, 255)
        })
        focusTween:Play()
    end)

    InputBox.FocusLost:Connect(function()
        local unfocusTween = TweenService:Create(InputBox, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(0, 255, 0),
            PlaceholderColor3 = Color3.fromRGB(0, 255, 0)
        })
        unfocusTween:Play()
    end)

    -- (version label dihapus)

    -- == drag cmdbar ==
    local cmdDragging = false
    local cmdDragInput, cmdDragStart, cmdDragStartPos

    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            if input.Target == InputBox then return end
            cmdDragging = true
            cmdDragStart = input.Position
            cmdDragStartPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    cmdDragging = false
                end
            end)
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            cmdDragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == cmdDragInput and cmdDragging then
            local delta = input.Position - cmdDragStart
            MainFrame.Position = UDim2.new(
                cmdDragStartPos.X.Scale, cmdDragStartPos.X.Offset + delta.X,
                cmdDragStartPos.Y.Scale, cmdDragStartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Initial boot animation
    MainFrame.Size = UDim2.new(0, 0, 0, 44)
    MainFrame.BackgroundTransparency = 1
    Arrow.TextTransparency = 1
    InputBox.TextTransparency = 1

    local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
        Size = UDim2.new(0, 146, 0, 44),
        BackgroundTransparency = 0.2
    })
    openTween:Play()

    openTween.Completed:Connect(function()
        clickSound:Play()
        TweenService:Create(Arrow, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        TweenService:Create(InputBox, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    end)

    -- Enhanced Help GUI with animations
    local function createHelpWindow()
        -- Create main frame with initial transparency
        local helpFrame = Instance.new("Frame")
        helpFrame.Name = "HelpFrame"
        helpFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        helpFrame.BackgroundTransparency = 1
        helpFrame.BorderSizePixel = 0
        helpFrame.Size = UDim2.new(0.2, 0, 0.3, 0) -- Updated size
        helpFrame.Position = UDim2.new(0, 170, 0, -44) -- Updated position
        helpFrame.Parent = ScreenGui
        
        local helpCorner = Instance.new("UICorner")
        helpCorner.CornerRadius = UDim.new(0, 12)
        helpCorner.Parent = helpFrame
        
        -- Title bar with fade-in effect
        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        titleBar.BackgroundTransparency = 1
        titleBar.Size = UDim2.new(1, 0, 0, 30)
        titleBar.Position = UDim2.new(0, 0, 0, 0)
        titleBar.Parent = helpFrame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 12)
        titleCorner.Parent = titleBar
        
        local titleText = Instance.new("TextLabel")
        titleText.Name = "TitleText"
        titleText.Text = "Commands :-)"
        titleText.Font = Enum.Font.Arcade
        titleText.TextSize = 18
        titleText.TextColor3 = Color3.fromRGB(0, 255, 0)
        titleText.TextTransparency = 1
        titleText.BackgroundTransparency = 1
        titleText.Size = UDim2.new(1, -40, 1, 0)
        titleText.Position = UDim2.new(0, 10, 0, 0)
        titleText.TextXAlignment = Enum.TextXAlignment.Left
        titleText.Parent = titleBar
        
        -- Close button with hover effect
        local closeButton = Instance.new("TextButton")
        closeButton.Name = "CloseButton"
        closeButton.Text = "X"
        closeButton.Font = Enum.Font.Arcade
        closeButton.TextSize = 18
        closeButton.TextColor3 = Color3.fromRGB(255, 0, 0)
        closeButton.TextTransparency = 1
        closeButton.BackgroundTransparency = 1
        closeButton.Size = UDim2.new(0, 30, 1, 0)
        closeButton.Position = UDim2.new(1, -30, 0, 0)
        closeButton.Parent = titleBar
        
        closeButton.MouseButton1Click:Connect(function()
            clickSound:Play()
            -- Close animation
            local closeAnim = TweenService:Create(helpFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            })
            closeAnim:Play()
            closeAnim.Completed:Connect(function()
                helpFrame:Destroy()
            end)
        end)
        
        -- Hover effects for close button
        closeButton.MouseEnter:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(255, 100, 100)
            }):Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(255, 0, 0)
            }):Play()
        end)
        
        -- Scrolling frame for commands
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Name = "ScrollFrame"
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.Size = UDim2.new(1, -20, 1, -40)
        scrollFrame.Position = UDim2.new(0, 10, 0, 40)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollFrame.ScrollBarThickness = 5
        scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 0)
        scrollFrame.ScrollBarImageTransparency = 1
        scrollFrame.Parent = helpFrame
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10) -- Increased padding between commands
        layout.Parent = scrollFrame
        
        -- Add commands to help window with sequential animations
        local commandFrames = {}
        for _, cmd in ipairs(CommandOrder) do
            local data = Commands[cmd]
            local commandFrame = Instance.new("Frame")
            commandFrame.BackgroundTransparency = 1
            commandFrame.Size = UDim2.new(1, 0, 0, 0) -- Height will be automatic
            commandFrame.AutomaticSize = Enum.AutomaticSize.Y
            commandFrame.Parent = scrollFrame
            
            -- Create a string that shows the command and its aliases
            local aliasesText = ""
            if #data.aliases > 0 then
                aliasesText = " (" .. table.concat(data.aliases, "/") .. ")"
            end
            
            -- Command name with parameters and aliases
            local cmdText = Instance.new("TextLabel")
            cmdText.Name = "CmdText"
            if data.hasValue and data.hasPlayer then
                cmdText.Text = cmd .. aliasesText .. " <player> <" .. (data.valueName or "value") .. ">"
            elseif data.hasValue then
                cmdText.Text = cmd .. aliasesText .. " <" .. (data.valueName or "value") .. ">"
            elseif data.hasPlayer then
                cmdText.Text = cmd .. aliasesText .. " <player>"
            else
                cmdText.Text = cmd .. aliasesText
            end
            cmdText.Font = Enum.Font.Arcade
            cmdText.TextSize = 13
            cmdText.TextColor3 = Color3.fromRGB(0, 255, 255)
            cmdText.TextTransparency = 1
            cmdText.BackgroundTransparency = 1
            cmdText.TextXAlignment = Enum.TextXAlignment.Left
            cmdText.AutomaticSize = Enum.AutomaticSize.Y
            cmdText.Size = UDim2.new(1, 0, 0, 0)
            cmdText.Parent = commandFrame
            
            -- Description text (on new line)
            local descText = Instance.new("TextLabel")
            descText.Name = "DescText"
            descText.Text = data.desc
            descText.Font = Enum.Font.Arcade
            descText.TextSize = 14
            descText.TextColor3 = Color3.fromRGB(0, 255, 0)
            descText.TextTransparency = 1
            descText.BackgroundTransparency = 1
            descText.TextXAlignment = Enum.TextXAlignment.Left
            descText.TextWrapped = true -- Allow text to wrap
            descText.AutomaticSize = Enum.AutomaticSize.Y
            descText.Size = UDim2.new(1, 0, 0, 0)
            descText.Position = UDim2.new(0, 0, 0, 20) -- Position below command text
            descText.Parent = commandFrame
            
            table.insert(commandFrames, commandFrame)
        end
        
        -- Window open animation
        helpFrame.BackgroundTransparency = 1
        helpFrame.Size = UDim2.new(0, 10, 0, 10)
        
        local openAnim = TweenService:Create(helpFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.2,
            Size = UDim2.new(0.3, 0, 0.5, 0), -- Updated target size
            Position = UDim2.new(0, 170, 0, -44) -- Updated target position
        })
        openAnim:Play()
        
        openAnim.Completed:Connect(function()
            -- Fade in title bar
            TweenService:Create(titleBar, TweenInfo.new(0.3), {
                BackgroundTransparency = 0
            }):Play()
            
            -- Fade in title text
            TweenService:Create(titleText, TweenInfo.new(0.3), {
                TextTransparency = 0
            }):Play()
            
            -- Fade in close button
            TweenService:Create(closeButton, TweenInfo.new(0.3), {
                TextTransparency = 0
            }):Play()
            
            -- Fade in scrollbar
            TweenService:Create(scrollFrame, TweenInfo.new(0.3), {
                ScrollBarImageTransparency = 0.5
            }):Play()
            
            -- Sequential fade in for command entries
            for i, frame in ipairs(commandFrames) do
                task.spawn(function()
                    task.wait(i * 0.05)
                    -- Fade in command text
                    TweenService:Create(frame:FindFirstChild("CmdText"), TweenInfo.new(0.3), {
                        TextTransparency = 0
                    }):Play()
                    
                    -- Fade in description text
                    TweenService:Create(frame:FindFirstChild("DescText"), TweenInfo.new(0.3), {
                        TextTransparency = 0
                    }):Play()
                    
                    -- Add subtle hover effect for each command
                    frame.MouseEnter:Connect(function()
                        TweenService:Create(frame:FindFirstChild("CmdText"), TweenInfo.new(0.2), {
                            TextColor3 = Color3.fromRGB(0, 255, 255),
                            TextSize = 13
                        }):Play()
                    end)
                    
                    frame.MouseLeave:Connect(function()
                        TweenService:Create(frame:FindFirstChild("CmdText"), TweenInfo.new(0.2), {
                            TextColor3 = Color3.fromRGB(0, 255, 200),
                            TextSize = 13
                        }):Play()
                    end)
                end)
            end
        end)
        
        -- Make window draggable
        local dragging
        local dragInput
        local dragStart
        local startPos
        
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = helpFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                helpFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                              startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        return helpFrame
    end

    -- Command handler
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            clickSound:Play()
            
            -- Arrow flicker animation when Enter is pressed
            local flickerTween1 = TweenService:Create(Arrow, TweenInfo.new(0.1), {
                TextTransparency = 0.8
            })
            local flickerTween2 = TweenService:Create(Arrow, TweenInfo.new(0.1), {
                TextTransparency = 0
            })
            
            flickerTween1:Play()
            flickerTween1.Completed:Connect(function()
                flickerTween2:Play()
            end)
            
            local fullCommand = InputBox.Text
            InputBox.Text = ""
            
            -- Split command and arguments
            local parts = {}
            for part in string.gmatch(fullCommand, "%S+") do
                table.insert(parts, part:lower())
            end
            
            if #parts == 0 then return end
            
            local commandText = parts[1]
            local command = Commands[commandText]
            
            if command then
                -- Check if command expects inputs
                if command.hasValue or command.hasPlayer then
                    local playerName, value
                    local currentIndex = 2
                    
                    -- First check for player name if command expects it
                    if command.hasPlayer and #parts >= currentIndex then
                        playerName = parts[currentIndex]
                        currentIndex = currentIndex + 1
                    end
                    
                    -- Then check for value if command expects it
                    if command.hasValue and #parts >= currentIndex then
                        value = table.concat(parts, " ", currentIndex)
                    elseif command.hasValue then
                        errorSound:Play()
                        crx(string.format("Missing value for %s.\nUsage: %s%s%s", 
                            commandText, 
                            commandText,
                            command.hasPlayer and " <player>" or "",
                            command.hasValue and " <"..(command.valueName or "value")..">" or ""), 
                            3, Color3.fromRGB(255, 0, 0))
                        return
                    end
                    
                    -- Execute command with inputs
                    local success, message
                    if command.hasPlayer and command.hasValue then
                        success, message = pcall(function() return command.exec(playerName, value) end)
                    elseif command.hasPlayer then
                        success, message = pcall(function() return command.exec(playerName) end)
                    elseif command.hasValue then
                        success, message = pcall(function() return command.exec(value) end)
                    end
                    
                    if success then
                        if commandText ~= "cmds" then
                            successSound:Play()
                            crx(message, 1.1, Color3.fromRGB(0, 255, 0), nil)
                            
                            -- On PC, hide the GUI after command execution
                            if not isMobile() then
                                local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                                    Size = UDim2.new(0, 0, 0, 44),
                                    BackgroundTransparency = 1
                                })
                                closeTween:Play()
                                closeTween.Completed:Connect(function()
                                    ScreenGui.Enabled = false
                                end)
                            end
                        else
                            createHelpWindow()
                        end
                    else
                        errorSound:Play()
                    end
                else
                    -- Handle regular command without inputs
                    local success, message = pcall(command.exec)
                    if success then
                        if commandText == "cmds" then
                            createHelpWindow()
                        else
                            successSound:Play()
                            crx(message, 1.2, Color3.fromRGB(0, 255, 0), nil)
                            
                            -- On PC, hide the GUI after command execution
                            if not isMobile() then
                                local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                                    Size = UDim2.new(0, 0, 0, 44),
                                    BackgroundTransparency = 1
                                })
                                closeTween:Play()
                                closeTween.Completed:Connect(function()
                                    ScreenGui.Enabled = false
                                end)
                            end
                        end
                    else
                        errorSound:Play()
                    end
                end
            else
                errorSound:Play()
                crx("Unknown command:\n" .. commandText, 1.1, Color3.fromRGB(255, 0, 0), nil)
            end
        end
    end)

    -- Toggle GUI visibility with RightShift (with animation) - only on PC
    if not isMobile() then
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == Enum.KeyCode.RightShift and not gameProcessed then
                clickSound:Play()
                if ScreenGui.Enabled then
                    -- Close animation
                    local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, 0, 0, 44),
                        BackgroundTransparency = 1
                    })
                    closeTween:Play()
                    closeTween.Completed:Connect(function()
                        ScreenGui.Enabled = false
                    end)
                else
                    -- Open animation
                    ScreenGui.Enabled = true
                    MainFrame.Size = UDim2.new(0, 0, 0, 44)
                    local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, 146, 0, 44),
                        BackgroundTransparency = 0.2
                    })
                    openTween:Play()
                    
                    -- Focus the input box
                    task.wait(0.3)
                    InputBox:CaptureFocus()
                end
            end
        end)
    end
end

-- Initialize and handle respawns
local mainGUI = initializeMainGUI()
crx("'235' Cmds Loaded!\nType 'cmds' for commands :D", 3, Color3.fromRGB(0, 255, 255), 12221831)

Players.LocalPlayer.CharacterAdded:Connect(function()
    if ScreenGui and not ScreenGui.Parent then
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            ScreenGui.Parent = playerGui
        else
            playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
            ScreenGui.Parent = playerGui
        end
    end
end)
