local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🐰 Doors ESP Ultimate | RabbitCore",
   LoadingTitle = "🐰 Loading Ultimate ESP System...",
   LoadingSubtitle = "by RabbitCore | Final Optimized Edition",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "DoorsESP_RabbitCore_Ultimate"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false
})



local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera



local Config = {
    ESP = {
        Enabled = false,
        MaxDistance = 150,
        UpdateRate = 0.1,
        ScanBatchSize = 10,  -- Further reduced for ultimate smoothness
        ScanYield = 0.05,    -- Increased yield to eliminate all micro-freezes
        Keys = true,
        NextDoors = true,
        NormalDoors = true,
        Items = true,
        Coins = true,
        Books = true,
        Levers = true,
        Generators = true,
        Breakers = true,
        HidingSpots = true,
        Entities = true,
        GoldChests = true,
        Lockpicks = true
    },
    Tracers = {
        Enabled = false,
        UpdateRate = 0.05,
        Thickness = 2
    },
    Entities = {
        AlertEnabled = true,
        AlertDuration = 6,
        AlertAnimationSpeed = 1,
        Rush = true,
        Ambush = true,
        Eyes = true,
        Screech = true,
        Halt = true,
        Seek = true,
        Figure = true,
        A60 = true,
        A90 = true,
        A120 = true
    },
    Visual = {
        NoDark = false,
        NoFog = false,
        Brightness = 2,
        FullBright = false,
        AntiLag = true
    },
    Colors = {
        Keys = Color3.fromRGB(255, 215, 0),
        NextDoors = Color3.fromRGB(0, 255, 127),
        NormalDoors = Color3.fromRGB(255, 140, 0),
        Items = Color3.fromRGB(0, 191, 255),
        Coins = Color3.fromRGB(255, 255, 0),
        Books = Color3.fromRGB(186, 85, 211),
        Levers = Color3.fromRGB(255, 140, 0),
        Generators = Color3.fromRGB(255, 69, 0),
        Breakers = Color3.fromRGB(255, 0, 0),
        HidingSpots = Color3.fromRGB(144, 238, 144),
        Entities = Color3.fromRGB(255, 0, 0),
        GoldChests = Color3.fromRGB(255, 215, 0),
        Lockpicks = Color3.fromRGB(192, 192, 192)
    }
}



local ESPCache = {}
local TracerCache = {}
local ProcessedObjects = {}
local DetectedEntities = {}
local AlertGUI = nil
local LastESPUpdate = 0
local LastTracerUpdate = 0
local OriginalLighting = {}
local Connections = {}
local FullBrightFolder = nil
local ScanQueue = {}
local ProcessingQueue = false

-- ========================================
-- OBJECT DETECTION (FIXED & OPTIMIZED)
-- ========================================

local function IsNextDoor(doorModel)
    if not doorModel or doorModel.Name ~= "Door" then return false end
    
    -- Check for Lock (locked doors are next doors)
    if doorModel:FindFirstChild("Lock") then
        return true
    end
    
    -- Check parent name is a number (room number)
    if doorModel.Parent and tonumber(doorModel.Parent.Name) then
        return true
    end
    
    -- Check if door is in CurrentRooms
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms and doorModel:IsDescendantOf(currentRooms) then
        return true
    end
    
    return false
end

local function IsKey(object)
    -- Check exact name
    if object.Name == "KeyObtain" then return true end
    
    -- Check if it's a model with KeyObtain
    if object:IsA("Model") and object.Name == "KeyObtain" then return true end
    
    -- Check if parent is KeyObtain
    if object.Parent and object.Parent.Name == "KeyObtain" then return true end
    
    -- Check for key mesh/handle
    if object:FindFirstChild("Handle") and object.Name:lower():find("key") then return true end
    
    return false
end

local ObjectPatterns = {
    Keys = {
        Check = IsKey
    },
    NextDoors = {
        Check = function(obj) 
            return obj:IsA("Model") and obj.Name == "Door" and IsNextDoor(obj)
        end
    },
    NormalDoors = {
        Check = function(obj)
            return obj:IsA("Model") and obj.Name == "Door" and not IsNextDoor(obj)
        end
    },
    Items = {
        Names = {"Lockpick", "FlashlightModel", "Lighter", "Candle", "CrucifixModel", "Scanner", "Shears", "Vitamins", "SkeletonKey"}
    },
    Coins = {
        Names = {"GoldPile"}
    },
    Books = {
        Names = {"LibraryHintPaper", "LiveHintBook", "LiveBreakerPolePickup"}
    },
    Levers = {
        Names = {"LeverForGate"}
    },
    Generators = {
        Names = {"GeneratorMain"}
    },
    Breakers = {
        Check = function(obj)
            return obj:IsA("Model") and (obj:FindFirstChild("Breakers") or obj:FindFirstChild("BreakerBox") or obj.Name == "ElectricalRoom")
        end
    },
    HidingSpots = {
        Check = function(obj)
            if not obj:IsA("Model") then return false end
            local name = obj.Name
            return name == "Wardrobe" or name == "Bed" or obj:FindFirstChild("HiddenPlayer") or obj:FindFirstChild("HidePrompt")
        end
    },
    GoldChests = {
        Names = {"ChestBox", "Toolbox"}
    },
    Lockpicks = {
        Names = {"Lockpick"}
    }
}



local EntityPatterns = {
    Rush = {"RushMoving", "RushNew"},
    Ambush = {"AmbushMoving", "AmbushNew"},
    Eyes = {"Eyes", "Lookman"},
    Screech = {"Screech"},
    Halt = {"Halt"},
    Seek = {"Seek_Arm", "SeekRig"},
    Figure = {"FigureRagdoll", "FigureRig"},
    A60 = {"A60"},
    A90 = {"A90"},
    A120 = {"A120"}
}

-- ========================================
-- ENTITY ALERT DESIGNS (ENHANCED WITH UNIQUE ANIMATIONS & DESIGNS)
-- ========================================

local EntityAlerts = {
    Rush = {
        Title = "⚠️ RUSH INCOMING",
        Message = "🚪 HIDE IN THE NEAREST CLOSET NOW! RUSH IS SPEEDING THROUGH THE ROOMS!",
        Color = Color3.fromRGB(220, 20, 60),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 20, 60)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(178, 34, 34)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 20, 60))
        },
        Icon = "⚠️",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Shake",
        ParticleType = "Burst",  -- Unique: Explosive burst particles
        FlashIntensity = 0.7,
        ExtraEffect = function(gui)
            -- Unique: Screen shake with red tint
            TweenService:Create(gui.FlashOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {BackgroundTransparency = 0.3}):Play()
            task.wait(0.3)
            TweenService:Create(gui.FlashOverlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        end
    },
    Ambush = {
        Title = "⚡ AMBUSH DETECTED",
        Message = "🔄 AMBUSH IS BOUNCING BACK! HIDE, EXIT, AND REPEAT TO SURVIVE!",
        Color = Color3.fromRGB(30, 144, 255),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 144, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 191, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 144, 255))
        },
        Icon = "⚡",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Pulse",
        ParticleType = "Swirl",  -- Unique: Swirling particles for rebound effect
        FlashIntensity = 0.5,
        ExtraEffect = function(gui)
            -- Unique: Bouncing icon animation
            local icon = gui.IconContainer
            TweenService:Create(icon, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 3), {Position = UDim2.new(0, 30, 0.5, -70)}):Play()
        end
    },
    Eyes = {
        Title = "👁️ EYES SPAWNED",
        Message = "👀 THE EYES ARE WATCHING! LOOK AWAY OR FACE INSTANT DAMAGE!",
        Color = Color3.fromRGB(138, 43, 226),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(148, 0, 211)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
        },
        Icon = "👁️",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Wave",
        ParticleType = "EyesBlink",  -- Unique: Blinking eye particles
        FlashIntensity = 0.6,
        ExtraEffect = function(gui)
            -- Unique: Blinking icon
            task.spawn(function()
                for i = 1, 5 do
                    gui.Icon.TextTransparency = 1
                    task.wait(0.2)
                    gui.Icon.TextTransparency = 0
                    task.wait(0.2)
                end
            end)
        end
    },
    Screech = {
        Title = "😱 SCREECH NEARBY",
        Message = "🔦 SCREECH IS LURKING! LOOK UP AND FLASH YOUR LIGHT TO SCARE IT AWAY!",
        Color = Color3.fromRGB(40, 40, 40),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 60, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
        },
        Icon = "😱",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Shake",
        ParticleType = "Scatter",  -- Unique: Scattering dark particles
        FlashIntensity = 0.8,
        ExtraEffect = function(gui)
            -- Unique: Sudden jump scare shake
            AnimateAlertShake(gui.Frame, 1, 10)
        end
    },
    Halt = {
        Title = "🚫 HALT CORRIDOR",
        Message = "⚠️ HALT IS BLOCKING THE WAY! WATCH FOR 'TURN AROUND' AND OBEY!",
        Color = Color3.fromRGB(70, 130, 180),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 130, 180)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 149, 237)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 130, 180))
        },
        Icon = "🚫",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Pulse",
        ParticleType = "Barrier",  -- Unique: Barrier-like particles
        FlashIntensity = 0.4,
        ExtraEffect = function(gui)
            -- Unique: Rotating barrier lines
            TweenService:Create(gui.WarningLine1, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
        end
    },
    Seek = {
        Title = "🔥 SEEK CHASE",
        Message = "🏃 SEEK IS PURSUING! RUN THROUGH THE CORRIDOR AND DODGE THE FIRE!",
        Color = Color3.fromRGB(255, 69, 0),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 69, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 69, 0))
        },
        Icon = "🔥",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Shake",
        ParticleType = "Flame",  -- Unique: Flame particles rising
        FlashIntensity = 0.9,
        ExtraEffect = function(gui)
            -- Unique: Flaming border
            task.spawn(function()
                for i = 1, 10 do
                    gui.BorderStroke.Thickness = 5 + math.sin(tick() * 10) * 2
                    task.wait(0.1)
                end
            end)
        end
    },
    Figure = {
        Title = "👹 FIGURE ACTIVE",
        Message = "🤫 THE FIGURE IS NEAR! STAY SILENT, CROUCH, AND AVOID DETECTION!",
        Color = Color3.fromRGB(139, 0, 0),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(178, 34, 34)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 0, 0))
        },
        Icon = "👹",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Wave",
        ParticleType = "Shadow",  -- Unique: Shadowy tendrils
        FlashIntensity = 0.5,
        ExtraEffect = function(gui)
            -- Unique: Fading in/out shadow effect
            TweenService:Create(gui.Frame, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 2), {BackgroundTransparency = 0.2}):Play()
        end
    },
    A60 = {
        Title = "💀 A-60 DETECTED",
        Message = "🚪 A-60 IS APPROACHING FAST! FIND A HIDING SPOT IMMEDIATELY!",
        Color = Color3.fromRGB(128, 0, 128),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(128, 0, 128)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(75, 0, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128))
        },
        Icon = "💀",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Pulse",
        ParticleType = "Skull",  -- Unique: Skull-shaped particles
        FlashIntensity = 0.6,
        ExtraEffect = function(gui)
            -- Unique: Pulsing skull icon
            TweenService:Create(gui.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1), {TextSize = 100}):Play()
        end
    },
    A90 = {
        Title = "⛔ A-90 WARNING",
        Message = "🛑 A-90 IS HERE! FREEZE AND STOP ALL MOVEMENT TO AVOID ATTACK!",
        Color = Color3.fromRGB(255, 0, 127),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 127)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 20, 147)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 127))
        },
        Icon = "⛔",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Shake",
        ParticleType = "StopSign",  -- Unique: Stop sign particles
        FlashIntensity = 0.7,
        ExtraEffect = function(gui)
            -- Unique: Freezing animation (scale down/up)
            TweenService:Create(gui.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 780, 0, 200)}):Play()
            task.wait(0.3)
            TweenService:Create(gui.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 800, 0, 220)}):Play()
        end
    },
    A120 = {
        Title = "☠️ A-120 INCOMING",
        Message = "🚪 A-120 IS RUSHING! GET INTO A CLOSET AND PRAY IT PASSES!",
        Color = Color3.fromRGB(255, 215, 0),
        GradientColors = {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
        },
        Icon = "☠️",
        Sound = "rbxassetid://6073491164",
        AnimationStyle = "Pulse",
        ParticleType = "Explode",  -- Unique: Explosive particles
        FlashIntensity = 0.8,
        ExtraEffect = function(gui)
            -- Unique: Explosive expansion
            TweenService:Create(gui.Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 850, 0, 240)}):Play()
            task.wait(0.4)
            TweenService:Create(gui.Frame, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 800, 0, 220)}):Play()
        end
    }
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

local function GetPlayerPosition()
    local character = Player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            return rootPart.Position
        end
    end
    return nil
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function GetMainPart(object)
    if object:IsA("BasePart") then
        return object
    elseif object:IsA("Model") then
        if object.Name == "Door" then
            return object:FindFirstChild("Door") or object.PrimaryPart
        end
        
        local partNames = {"Handle", "Main", "Hitbox", "Base", "Center", "RootPart"}
        for _, name in ipairs(partNames) do
            local part = object:FindFirstChild(name)
            if part and part:IsA("BasePart") then
                return part
            end
        end
        
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function GetObjectCenter(object)
    local mainPart = GetMainPart(object)
    if mainPart then
        local cf = mainPart.CFrame
        local size = mainPart.Size
        return cf.Position + Vector3.new(0, size.Y / 4, 0)
    end
    return nil
end

local function IsValidObject(object)
    return object and object.Parent and object:IsDescendantOf(Workspace)
end

local function ShouldESPObject(object, category)
    local pattern = ObjectPatterns[category]
    if not pattern then return false end
    
    -- Use custom check function if available
    if pattern.Check then
        local success, result = pcall(pattern.Check, object)
        return success and result
    end
    
    -- Check names
    if pattern.Names then
        for _, name in ipairs(pattern.Names) do
            if object.Name == name or object.Name:find(name) then
                return true
            end
        end
    end
    
    return false
end

-- ========================================
-- VISUAL ENHANCEMENT
-- ========================================

local function SaveOriginalLighting()
    if next(OriginalLighting) then return end
    
    OriginalLighting = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        ClockTime = Lighting.ClockTime,
        ExposureCompensation = Lighting.ExposureCompensation
    }
end

local function EnableNoDark()
    SaveOriginalLighting()
    Config.Visual.NoDark = true
    
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = Config.Visual.Brightness
    Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.ClockTime = 14
    Lighting.ExposureCompensation = 0.5
    
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BlurEffect") then
            if not effect.Name:find("RabbitCore") then
                effect.Enabled = false
            end
        end
    end
    
    if Connections.NoDark then
        Connections.NoDark:Disconnect()
    end
    
    Connections.NoDark = Lighting.Changed:Connect(function(property)
        if not Config.Visual.NoDark then return end
        task.wait(0.1)
        
        if property == "Ambient" then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        elseif property == "Brightness" then
            Lighting.Brightness = Config.Visual.Brightness
        elseif property == "ColorShift_Bottom" then
            Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
        elseif property == "ColorShift_Top" then
            Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        elseif property == "ClockTime" then
            Lighting.ClockTime = 14
        end
    end)
end

local function DisableNoDark()
    Config.Visual.NoDark = false
    
    if Connections.NoDark then
        Connections.NoDark:Disconnect()
        Connections.NoDark = nil
    end
    
    if next(OriginalLighting) then
        for property, value in pairs(OriginalLighting) do
            pcall(function()
                Lighting[property] = value
            end)
        end
    end
    
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("BlurEffect") then
            if not effect.Name:find("RabbitCore") then
                effect.Enabled = true
            end
        end
    end
end

local function EnableNoFog()
    SaveOriginalLighting()
    Config.Visual.NoFog = true
    
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") then
            effect.Density = 0
            effect.Offset = 0
            effect.Glare = 0
            effect.Haze = 0
        end
    end
end

local function DisableNoFog()
    Config.Visual.NoFog = false
    
    if next(OriginalLighting) then
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.FogStart = OriginalLighting.FogStart
    end
    
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") then
            effect.Density = 0.5
        end
    end
end

local function EnableFullBright()
    Config.Visual.FullBright = true
    
    if FullBrightFolder then
        FullBrightFolder:Destroy()
    end
    
    FullBrightFolder = Instance.new("Folder")
    FullBrightFolder.Name = "RabbitCoreFullBright"
    FullBrightFolder.Parent = Lighting
    
    local fullBright = Instance.new("ColorCorrectionEffect")
    fullBright.Name = "FullBright"
    fullBright.Brightness = 0.15
    fullBright.Contrast = 0.15
    fullBright.Saturation = 0.05
    fullBright.TintColor = Color3.fromRGB(255, 255, 255)
    fullBright.Enabled = true
    fullBright.Parent = FullBrightFolder
    
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "FullBrightBloom"
    bloom.Intensity = 0.3
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Enabled = true
    bloom.Parent = FullBrightFolder
end

local function DisableFullBright()
    Config.Visual.FullBright = false
    
    if FullBrightFolder then
        FullBrightFolder:Destroy()
        FullBrightFolder = nil
    end
end



local function CreateHighlight(object, color, category)
    local highlight = Instance.new("Highlight")
    highlight.Name = "RabbitCoreESP_" .. category
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = object
    
    return highlight
end

local function CreateBillboardText(object, text, color)
    local mainPart = GetMainPart(object)
    if not mainPart then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RabbitCoreText"
    billboard.Adornee = mainPart
    billboard.Size = UDim2.new(0, 100, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = mainPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 16
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboard
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = color
    uiStroke.Thickness = 2
    uiStroke.Parent = textLabel
    
    return billboard
end

local function AddESP(object, category)
    if ProcessedObjects[object] then return end
    if not IsValidObject(object) then return end
    
    local mainPart = GetMainPart(object)
    if not mainPart then return end
    
    local color = Config.Colors[category] or Color3.fromRGB(255, 255, 255)
    
    local highlight = CreateHighlight(object, color, category)
    local billboard = CreateBillboardText(object, category, color)
    
    ESPCache[object] = {
        Highlight = highlight,
        Billboard = billboard,
        Part = mainPart,
        Category = category,
        Color = color,
        Center = GetObjectCenter(object)
    }
    
    ProcessedObjects[object] = true
end

local function RemoveESP(object)
    if ESPCache[object] then
        if ESPCache[object].Highlight then
            ESPCache[object].Highlight:Destroy()
        end
        if ESPCache[object].Billboard then
            ESPCache[object].Billboard:Destroy()
        end
        ESPCache[object] = nil
    end
    
    if TracerCache[object] then
        TracerCache[object]:Remove()
        TracerCache[object] = nil
    end
    
    ProcessedObjects[object] = nil
end

local function CreateTracer(color)
    local line = Drawing.new("Line")
    line.Thickness = Config.Tracers.Thickness
    line.Color = color
    line.Transparency = 0.8
    line.Visible = false
    return line
end

local function UpdateESP()
    if not Config.ESP.Enabled then return end
    
    local currentTime = tick()
    if currentTime - LastESPUpdate < Config.ESP.UpdateRate then return end
    LastESPUpdate = currentTime
    
    local playerPos = GetPlayerPosition()
    if not playerPos then return end
    
    local toRemove = {}
    
    for object, data in pairs(ESPCache) do
        if not IsValidObject(object) or not data.Part or not data.Part.Parent then
            table.insert(toRemove, object)
        else
            local distance = GetDistance(playerPos, data.Part.Position)
            local inRange = distance <= Config.ESP.MaxDistance
            
            if data.Highlight then
                data.Highlight.Enabled = inRange
            end
            
            if data.Billboard then
                data.Billboard.Enabled = inRange
                if inRange then
                    data.Billboard.StudsOffset = Vector3.new(0, 3 + math.sin(tick() * 2) * 0.3, 0)
                end
            end
        end
    end
    
    for _, object in ipairs(toRemove) do
        RemoveESP(object)
    end
end

local function UpdateTracers()
    if not Config.Tracers.Enabled then
        for _, tracer in pairs(TracerCache) do
            if tracer.Visible then
                tracer.Visible = false
            end
        end
        return
    end
    
    local currentTime = tick()
    if currentTime - LastTracerUpdate < Config.Tracers.UpdateRate then return end
    LastTracerUpdate = currentTime
    
    local playerPos = GetPlayerPosition()
    if not playerPos then return end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local toRemove = {}
    
    for object, data in pairs(ESPCache) do
        if not IsValidObject(object) or not data.Center then
            if TracerCache[object] then
                table.insert(toRemove, object)
            end
        else
            local distance = GetDistance(playerPos, data.Center)
            
            if distance <= Config.ESP.MaxDistance and distance > 5 then
                if not TracerCache[object] then
                    TracerCache[object] = CreateTracer(data.Color)
                end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(data.Center)
                
                if onScreen and screenPos.Z > 0 then
                    local tracer = TracerCache[object]
                    tracer.From = screenCenter
                    tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    tracer.Color = data.Color
                    tracer.Visible = true
                else
                    if TracerCache[object] then
                        TracerCache[object].Visible = false
                    end
                end
            else
                if TracerCache[object] then
                    TracerCache[object].Visible = false
                end
            end
        end
    end
    
    for _, object in ipairs(toRemove) do
        if TracerCache[object] then
            TracerCache[object]:Remove()
            TracerCache[object] = nil
        end
    end
end

-- Final optimized queue-based scanning with even smaller batches and longer yields
local function ProcessScanQueue()
    if ProcessingQueue then return end
    ProcessingQueue = true
    
    task.spawn(function()
        while #ScanQueue > 0 and Config.ESP.Enabled do
            local batch = {}
            for i = 1, math.min(Config.ESP.ScanBatchSize, #ScanQueue) do
                table.insert(batch, table.remove(ScanQueue, 1))
            end
            
            for _, data in ipairs(batch) do
                local object, category = data.object, data.category
                
                if not ProcessedObjects[object] and IsValidObject(object) then
                    local mainPart = GetMainPart(object)
                    if mainPart then
                        local playerPos = GetPlayerPosition()
                        if playerPos then
                            local distance = GetDistance(playerPos, mainPart.Position)
                            if distance <= Config.ESP.MaxDistance then
                                AddESP(object, category)
                            end
                        end
                    end
                end
            end
            
            task.wait(Config.ESP.ScanYield * 2)  -- Doubled yield for new room loads to ensure zero freezes
        end
        
        ProcessingQueue = false
    end)
end

local function ScanForObjects()
    if not Config.ESP.Enabled then return end
    
    local playerPos = GetPlayerPosition()
    if not playerPos then return end
    
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if not currentRooms then return end
    
    local rooms = currentRooms:GetChildren()
    
    for _, room in ipairs(rooms) do
        local descendants = room:GetDescendants()
        for i = 1, #descendants, Config.ESP.ScanBatchSize do
            for j = i, math.min(i + Config.ESP.ScanBatchSize - 1, #descendants) do
                local descendant = descendants[j]
                if not ProcessedObjects[descendant] and (descendant:IsA("Model") or descendant:IsA("BasePart")) then
                    for category, enabled in pairs(Config.ESP) do
                        if type(enabled) == "boolean" and enabled and category ~= "Enabled" and category ~= "MaxDistance" and category ~= "UpdateRate" and category ~= "Entities" then
                            if ShouldESPObject(descendant, category) then
                                table.insert(ScanQueue, {object = descendant, category = category})
                                break
                            end
                        end
                    end
                end
            end
            task.wait(Config.ESP.ScanYield * 1.5)  -- Increased yield per batch for smoother performance
        end
        task.wait(0.15)  -- Increased yield between rooms to spread load
    end
    
    ProcessScanQueue()
end

local function ClearAllESP()
    for object, _ in pairs(ESPCache) do
        RemoveESP(object)
    end
    
    ESPCache = {}
    TracerCache = {}
    ProcessedObjects = {}
    ScanQueue = {}
end

-- ========================================
-- ULTRA BEAUTIFUL ALERT SYSTEM (ENHANCED WITH UNIQUE PER-ENTITY ANIMATIONS)
-- ========================================

local function CreateParticleEffect(parent, color, particleType)
    local particles = {}
    
    local numParticles = 12  -- Increased for more visual appeal
    local angles = {}
    for i = 1, numParticles do
        angles[i] = (i - 1) * (360 / numParticles)
    end
    
    for i = 1, numParticles do
        local particle = Instance.new("Frame")
        particle.Name = "Particle" .. i
        particle.Size = UDim2.new(0, 15 + math.random(5, 15), 0, 15 + math.random(5, 15))
        particle.BackgroundColor3 = color
        particle.BackgroundTransparency = 0.2
        particle.BorderSizePixel = 0
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.Position = UDim2.new(0.5, 0, 0.5, 0)
        particle.ZIndex = 5
        particle.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        table.insert(particles, particle)
    end
    
    return particles, angles
end

local function AnimateParticles(particles, angles, color, duration, particleType)
    for i, particle in ipairs(particles) do
        task.spawn(function()
            local angle = math.rad(angles[i])
            local distance = 200 + math.random(-50, 50)
            
            if particleType == "Burst" then
                -- Explosive burst outward
                for t = 0, duration, 0.03 do
                    if not particle or not particle.Parent then break end
                    
                    local progress = t / duration
                    local currentDist = distance * progress ^ 2  -- Accelerate outward
                    local x = math.cos(angle) * currentDist
                    local y = math.sin(angle) * currentDist
                    
                    particle.Position = UDim2.new(0.5, x, 0.5, y)
                    particle.BackgroundTransparency = 0.2 + progress * 0.8
                    particle.Rotation = progress * 720
                    
                    task.wait(0.03)
                end
            elseif particleType == "Swirl" then
                -- Swirling rebound
                for t = 0, duration, 0.04 do
                    local progress = t / duration
                    local currentDist = distance * math.sin(progress * math.pi)
                    local swirlAngle = angle + progress * math.pi * 4
                    local x = math.cos(swirlAngle) * currentDist
                    local y = math.sin(swirlAngle) * currentDist
                    
                    particle.Position = UDim2.new(0.5, x, 0.5, y)
                    particle.BackgroundTransparency = 0.2 + progress * 0.8
                    particle.Size = UDim2.new(0, 20 * (1 - progress), 0, 20 * (1 - progress))
                    
                    task.wait(0.04)
                end
            elseif particleType == "EyesBlink" then
                -- Blinking and fading
                for t = 0, duration, 0.05 do
                    local progress = t / duration
                    local currentDist = distance * progress
                    local x = math.cos(angle + math.sin(progress * 10)) * currentDist
                    local y = math.sin(angle + math.sin(progress * 10)) * currentDist
                    
                    particle.Position = UDim2.new(0.5, x, 0.5, y)
                    particle.BackgroundTransparency = math.abs(math.sin(progress * 5)) * 0.5 + 0.2
                    
                    task.wait(0.05)
                end
            elseif particleType == "Scatter" then
                -- Scattering randomly
                local randX = math.random(-200, 200)
                local randY = math.random(-200, 200)
                TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Exponential), {
                    Position = UDim2.new(0.5, randX, 0.5, randY),
                    BackgroundTransparency = 1,
                    Rotation = math.random(0, 360)
                }):Play()
                task.wait(duration)
            elseif particleType == "Barrier" then
                -- Horizontal barrier lines
                particle.Size = UDim2.new(1, 0, 0, 5)
                particle.Position = UDim2.new(0.5, 0, 0.5 + (i - numParticles/2) * 0.1, 0)
                TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 180}):Play()
            elseif particleType == "Flame" then
                -- Rising flames
                for t = 0, duration, 0.03 do
                    local progress = t / duration
                    local x = math.cos(angle) * (distance * progress) + math.sin(tick() * 5) * 10
                    local y = -200 * progress  -- Rise upward
                    particle.Position = UDim2.new(0.5, x, 0.5, y)
                    particle.BackgroundTransparency = progress
                    particle.Size = UDim2.new(0, 20 * (1 - progress), 0, 30 * (1 - progress))
                    task.wait(0.03)
                end
            elseif particleType == "Shadow" then
                -- Spreading shadows
                particle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(0, 50, 0, 50),
                    BackgroundTransparency = 0.8,
                    Position = UDim2.new(0.5 + math.cos(angle) * 0.3, 0, 0.5 + math.sin(angle) * 0.3, 0)
                }):Play()
                task.wait(duration)
            elseif particleType == "Skull" then
                -- Floating skulls
                particle.Text = "💀"
                particle.TextSize = 20
                TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(0.5, math.cos(angle) * distance, 0.5, math.sin(angle) * distance - 100),
                    TextTransparency = 1
                }):Play()
                task.wait(duration)
            elseif particleType == "StopSign" then
                -- Spinning stop signs
                particle.Text = "⛔"
                particle.TextSize = 25
                for t = 0, duration, 0.04 do
                    particle.Rotation = t * 360 / duration
                    particle.Position = UDim2.new(0.5, math.cos(angle + t) * distance, 0.5, math.sin(angle + t) * distance)
                    particle.TextTransparency = t / duration
                    task.wait(0.04)
                end
            elseif particleType == "Explode" then
                -- Explosive scatter
                local randDir = Vector2.new(math.random(-1,1), math.random(-1,1)).Unit * distance
                TweenService:Create(particle, TweenInfo.new(duration * math.random(0.5,1.5), Enum.EasingStyle.Exponential), {
                    Position = UDim2.new(0.5, randDir.X, 0.5, randDir.Y),
                    BackgroundTransparency = 1,
                    Rotation = math.random(360, 720)
                }):Play()
                task.wait(duration)
            end
            if particle and particle.Parent then
                particle:Destroy()
            end
        end)
    end
end

local function CreateAlertGUI()
    if AlertGUI then return AlertGUI end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RabbitCore_EntityAlert"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999999
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    local AlertFrame = Instance.new("Frame")
    AlertFrame.Name = "AlertFrame"
    AlertFrame.Size = UDim2.new(0, 800, 0, 220)
    AlertFrame.Position = UDim2.new(0.5, -400, 0.1, 0)
    AlertFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    AlertFrame.BackgroundTransparency = 0.05
    AlertFrame.BorderSizePixel = 0
    AlertFrame.Visible = false
    AlertFrame.ZIndex = 10
    AlertFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 25)
    MainCorner.Parent = AlertFrame
    
    local BorderStroke = Instance.new("UIStroke")
    BorderStroke.Name = "BorderStroke"
    BorderStroke.Color = Color3.fromRGB(255, 0, 0)
    BorderStroke.Thickness = 5
    BorderStroke.Transparency = 0
    BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    BorderStroke.Parent = AlertFrame
    
    local BorderGradient = Instance.new("UIGradient")
    BorderGradient.Name = "BorderGradient"
    BorderGradient.Rotation = 0
    BorderGradient.Parent = BorderStroke
    
    local GlowOuter = Instance.new("ImageLabel")
    GlowOuter.Name = "GlowOuter"
    GlowOuter.Size = UDim2.new(1, 60, 1, 60)
    GlowOuter.Position = UDim2.new(0, -30, 0, -30)
    GlowOuter.BackgroundTransparency = 1
    GlowOuter.Image = "rbxassetid://5028857084"
    GlowOuter.ImageColor3 = Color3.fromRGB(255, 0, 0)
    GlowOuter.ImageTransparency = 0.4
    GlowOuter.ScaleType = Enum.ScaleType.Slice
    GlowOuter.SliceCenter = Rect.new(24, 24, 276, 276)
    GlowOuter.ZIndex = 8
    GlowOuter.Parent = AlertFrame
    
    local GlowInner = Instance.new("ImageLabel")
    GlowInner.Name = "GlowInner"
    GlowInner.Size = UDim2.new(1, 30, 1, 30)
    GlowInner.Position = UDim2.new(0, -15, 0, -15)
    GlowInner.BackgroundTransparency = 1
    GlowInner.Image = "rbxassetid://5028857084"
    GlowInner.ImageColor3 = Color3.fromRGB(255, 0, 0)
    GlowInner.ImageTransparency = 0.6
    GlowInner.ScaleType = Enum.ScaleType.Slice
    GlowInner.SliceCenter = Rect.new(24, 24, 276, 276)
    GlowInner.ZIndex = 8
    GlowInner.Parent = AlertFrame
    
    local ParticleContainer = Instance.new("Frame")
    ParticleContainer.Name = "ParticleContainer"
    ParticleContainer.Size = UDim2.new(1, 0, 1, 0)
    ParticleContainer.BackgroundTransparency = 1
    ParticleContainer.BorderSizePixel = 0
    ParticleContainer.ZIndex = 15
    ParticleContainer.Parent = AlertFrame
    
    local IconContainer = Instance.new("Frame")
    IconContainer.Name = "IconContainer"
    IconContainer.Size = UDim2.new(0, 140, 0, 140)
    IconContainer.Position = UDim2.new(0, 30, 0.5, -70)
    IconContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    IconContainer.BackgroundTransparency = 0.3
    IconContainer.BorderSizePixel = 0
    IconContainer.ZIndex = 11
    IconContainer.Parent = AlertFrame
    
    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = UDim.new(0, 20)
    IconCorner.Parent = IconContainer
    
    local IconStroke = Instance.new("UIStroke")
    IconStroke.Name = "IconStroke"
    IconStroke.Color = Color3.fromRGB(255, 0, 0)
    IconStroke.Thickness = 3
    IconStroke.Parent = IconContainer
    
    local IconGlow = Instance.new("ImageLabel")
    IconGlow.Name = "IconGlow"
    IconGlow.Size = UDim2.new(1, 20, 1, 20)
    IconGlow.Position = UDim2.new(0, -10, 0, -10)
    IconGlow.BackgroundTransparency = 1
    IconGlow.Image = "rbxassetid://5028857084"
    IconGlow.ImageColor3 = Color3.fromRGB(255, 0, 0)
    IconGlow.ImageTransparency = 0.5
    IconGlow.ScaleType = Enum.ScaleType.Slice
    IconGlow.SliceCenter = Rect.new(24, 24, 276, 276)
    IconGlow.ZIndex = 10
    IconGlow.Parent = IconContainer
    
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "IconLabel"
    IconLabel.Size = UDim2.new(1, 0, 1, 0)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.Text = "⚠️"
    IconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    IconLabel.TextSize = 90
    IconLabel.TextStrokeTransparency = 0
    IconLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    IconLabel.ZIndex = 12
    IconLabel.Parent = IconContainer
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -200, 0, 80)
    TitleLabel.Position = UDim2.new(0, 190, 0, 25)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = ""
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 48
    TitleLabel.TextStrokeTransparency = 0
    TitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextYAlignment = Enum.TextYAlignment.Center
    TitleLabel.ZIndex = 12
    TitleLabel.Parent = AlertFrame
    
    local TitleStroke = Instance.new("UIStroke")
    TitleStroke.Name = "TitleStroke"
    TitleStroke.Color = Color3.fromRGB(255, 0, 0)
    TitleStroke.Thickness = 2
    TitleStroke.Parent = TitleLabel
    
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Name = "MessageLabel"
    MessageLabel.Size = UDim2.new(1, -200, 0, 70)
    MessageLabel.Position = UDim2.new(0, 190, 0, 115)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.Text = ""
    MessageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    MessageLabel.TextSize = 28
    MessageLabel.TextStrokeTransparency = 0.3
    MessageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    MessageLabel.TextWrapped = true
    MessageLabel.ZIndex = 12
    MessageLabel.Parent = AlertFrame
    
    local WarningLine1 = Instance.new("Frame")
    WarningLine1.Name = "WarningLine1"
    WarningLine1.Size = UDim2.new(1, 0, 0, 3)
    WarningLine1.Position = UDim2.new(0, 0, 0, 0)
    WarningLine1.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    WarningLine1.BorderSizePixel = 0
    WarningLine1.ZIndex = 13
    WarningLine1.Parent = AlertFrame
    
    local Line1Gradient = Instance.new("UIGradient")
    Line1Gradient.Rotation = 0
    Line1Gradient.Parent = WarningLine1
    
    local WarningLine2 = WarningLine1:Clone()
    WarningLine2.Name = "WarningLine2"
    WarningLine2.Position = UDim2.new(0, 0, 1, -3)
    WarningLine2.Parent = AlertFrame
    
    local FlashOverlay = Instance.new("Frame")
    FlashOverlay.Name = "FlashOverlay"
    FlashOverlay.Size = UDim2.new(1, 0, 1, 0)
    FlashOverlay.Position = UDim2.new(0, 0, 0, 0)
    FlashOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    FlashOverlay.BackgroundTransparency = 1
    FlashOverlay.BorderSizePixel = 0
    FlashOverlay.ZIndex = 1000
    FlashOverlay.Visible = false
    FlashOverlay.Parent = ScreenGui
    
    AlertGUI = {
        ScreenGui = ScreenGui,
        Frame = AlertFrame,
        BorderStroke = BorderStroke,
        BorderGradient = BorderGradient,
        GlowOuter = GlowOuter,
        GlowInner = GlowInner,
        ParticleContainer = ParticleContainer,
        IconContainer = IconContainer,
        IconStroke = IconStroke,
        IconGlow = IconGlow,
        Icon = IconLabel,
        Title = TitleLabel,
        TitleStroke = TitleStroke,
        Message = MessageLabel,
        WarningLine1 = WarningLine1,
        Line1Gradient = Line1Gradient,
        WarningLine2 = WarningLine2,
        FlashOverlay = FlashOverlay
    }
    
    return AlertGUI
end

local function AnimateAlertShake(frame, duration, intensity)
    local originalPosition = frame.Position
    
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            local offsetX = math.random(-intensity, intensity)
            local offsetY = math.random(-intensity, intensity)
            
            frame.Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset + offsetX,
                originalPosition.Y.Scale,
                originalPosition.Y.Offset + offsetY
            )
            
            task.wait(1/60)
        end
        
        frame.Position = originalPosition
    end)
end

local function AnimateAlertPulse(elements, duration, color)
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            local pulse = math.abs(math.sin(tick() * 5))
            
            for _, element in ipairs(elements) do
                if element and element.Parent then
                    if element:IsA("UIStroke") then
                        element.Thickness = 3 + pulse * 2
                    elseif element:IsA("ImageLabel") then
                        element.ImageTransparency = 0.4 + pulse * 0.3
                    end
                end
            end
            
            task.wait(0.1)
        end
    end)
end

local function AnimateAlertWave(gradient, duration)
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            gradient.Rotation = (gradient.Rotation + 6) % 360
            task.wait(1/60)
        end
    end)
end

local function ShowAlert(entityType)
    if DetectedEntities[entityType] then return end
    DetectedEntities[entityType] = true
    
    local alertData = EntityAlerts[entityType]
    if not alertData or not Config.Entities.AlertEnabled or not Config.Entities[entityType] then return end
    
    if not AlertGUI then
        CreateAlertGUI()
    end
    
    local mainColor = alertData.Color
    AlertGUI.BorderStroke.Color = mainColor
    AlertGUI.BorderGradient.Color = ColorSequence.new(alertData.GradientColors)
    AlertGUI.GlowOuter.ImageColor3 = mainColor
    AlertGUI.GlowInner.ImageColor3 = mainColor
    AlertGUI.IconStroke.Color = mainColor
    AlertGUI.IconGlow.ImageColor3 = mainColor
    AlertGUI.TitleStroke.Color = mainColor
    AlertGUI.WarningLine1.BackgroundColor3 = mainColor
    AlertGUI.WarningLine2.BackgroundColor3 = mainColor
    AlertGUI.Line1Gradient.Color = ColorSequence.new(alertData.GradientColors)
    
    AlertGUI.Icon.Text = alertData.Icon
    AlertGUI.Title.Text = alertData.Title
    AlertGUI.Message.Text = alertData.Message
    
    AlertGUI.Frame.Size = UDim2.new(0, 0, 0, 0)
    AlertGUI.Frame.Position = UDim2.new(0.5, 0, 0.1, 0)
    AlertGUI.Frame.Rotation = 0
    AlertGUI.Frame.Visible = true
    
    local openTween = TweenService:Create(AlertGUI.Frame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {
            Size = UDim2.new(0, 800, 0, 220),
            Position = UDim2.new(0.5, -400, 0.1, 0)
        }
    )
    openTween:Play()
    
    AlertGUI.IconContainer.Size = UDim2.new(0, 0, 0, 0)
    task.wait(0.3)
    
    local iconTween = TweenService:Create(AlertGUI.IconContainer,
        TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, 140, 0, 140)
        }
    )
    iconTween:Play()
    
    if alertData.AnimationStyle == "Shake" then
        AnimateAlertShake(AlertGUI.Frame, Config.Entities.AlertDuration, 3)
    elseif alertData.AnimationStyle == "Pulse" then
        AnimateAlertPulse({
            AlertGUI.BorderStroke,
            AlertGUI.IconStroke,
            AlertGUI.GlowOuter,
            AlertGUI.GlowInner,
            AlertGUI.IconGlow
        }, Config.Entities.AlertDuration, mainColor)
    elseif alertData.AnimationStyle == "Wave" then
        AnimateAlertWave(AlertGUI.BorderGradient, Config.Entities.AlertDuration)
        AnimateAlertWave(AlertGUI.Line1Gradient, Config.Entities.AlertDuration)
    end
    
    local particles, angles = CreateParticleEffect(AlertGUI.ParticleContainer, mainColor, alertData.ParticleType)
    AnimateParticles(particles, angles, mainColor, 3, alertData.ParticleType)
    
    AlertGUI.FlashOverlay.BackgroundColor3 = mainColor
    AlertGUI.FlashOverlay.BackgroundTransparency = alertData.FlashIntensity
    AlertGUI.FlashOverlay.Visible = true
    
    TweenService:Create(AlertGUI.FlashOverlay,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    ):Play()
    
    task.wait(0.5)
    AlertGUI.FlashOverlay.Visible = false
    
    pcall(function()
        local flash = Instance.new("ColorCorrectionEffect")
        flash.Name = "RabbitCoreFlash"
        flash.TintColor = mainColor
        flash.Brightness = 0.5
        flash.Contrast = 0.3
        flash.Parent = Lighting
        
        task.wait(0.2)
        
        TweenService:Create(flash, TweenInfo.new(0.6), {
            Brightness = 0,
            Contrast = 0
        }):Play()
        
        task.wait(0.6)
        flash:Destroy()
    end)
    
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = alertData.Sound
        sound.Volume = 0.8
        sound.Parent = Workspace
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 3)
    end)
    
    pcall(alertData.ExtraEffect, AlertGUI)  -- Call unique extra effect
    
    Rayfield:Notify({
        Title = alertData.Title,
        Content = alertData.Message,
        Duration = Config.Entities.AlertDuration,
        Image = 4483362458
    })
    
    task.delay(Config.Entities.AlertDuration, function()
        if not AlertGUI or not AlertGUI.Frame then return end
        
        local closeTween = TweenService:Create(AlertGUI.Frame,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.1, 0),
                Rotation = 360
            }
        )
        closeTween:Play()
        closeTween.Completed:Wait()
        
        if AlertGUI and AlertGUI.Frame then
            AlertGUI.Frame.Visible = false
        end
    end)
    
    task.delay(30, function()
        DetectedEntities[entityType] = nil
    end)
end


local function DetectEntity(objectName)
    for entityType, patterns in pairs(EntityPatterns) do
        for _, pattern in ipairs(patterns) do
            if objectName == pattern or objectName:find(pattern) then
                return entityType
            end
        end
    end
    return nil
end

local function MonitorEntities()
    Connections.EntityMonitor = Workspace.DescendantAdded:Connect(function(object)
        task.wait(0.1)
        
        if not object or not object.Parent then return end
        
        local entityType = DetectEntity(object.Name)
        if entityType then
            if Config.Entities.AlertEnabled and Config.Entities[entityType] then
                pcall(function()
                    ShowAlert(entityType)
                end)
            end
            
            if Config.ESP.Enabled and Config.ESP.Entities then
                task.wait(0.2)
                pcall(function()
                    AddESP(object, "Entities")
                end)
            end
        else
            -- Check for regular objects as well
            if Config.ESP.Enabled then
                for category, enabled in pairs(Config.ESP) do
                    if type(enabled) == "boolean" and enabled and category ~= "Enabled" and category ~= "MaxDistance" and category ~= "UpdateRate" and category ~= "Entities" then
                        if ShouldESPObject(object, category) then
                            table.insert(ScanQueue, {object = object, category = category})
                            break
                        end
                    end
                end
                ProcessScanQueue()
            end
        end
    end)
end


local lastHeartbeat = 0
Connections.Heartbeat = RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastHeartbeat < 0.016 then return end
    lastHeartbeat = now
    
    pcall(function()
        if Config.ESP.Enabled then
            UpdateESP()
        end
        
        if Config.Tracers.Enabled then
            UpdateTracers()
        end
    end)
end)

Connections.ScanLoop = task.spawn(function()
    while task.wait(5) do
        pcall(function()
            if Config.ESP.Enabled then
                ScanForObjects()
            end
        end)
    end
end)

Connections.RoomDetection = task.spawn(function()
    pcall(function()
        local currentRooms = Workspace:WaitForChild("CurrentRooms")
        local latestRoom = ReplicatedStorage:WaitForChild("GameData"):WaitForChild("LatestRoom")
        
        latestRoom.Changed:Connect(function(newValue)
            if Config.ESP.Enabled then
                task.wait(1.5)
                local newRoom = currentRooms:FindFirstChild(tostring(newValue))
                if newRoom then
                    local descendants = newRoom:GetDescendants()
                    for i = 1, #descendants, Config.ESP.ScanBatchSize do
                        for j = i, math.min(i + Config.ESP.ScanBatchSize - 1, #descendants) do
                            local descendant = descendants[j]
                            if not ProcessedObjects[descendant] and (descendant:IsA("Model") or descendant:IsA("BasePart")) then
                                for category, enabled in pairs(Config.ESP) do
                                    if type(enabled) == "boolean" and enabled and category ~= "Enabled" and category ~= "MaxDistance" and category ~= "UpdateRate" and category ~= "Entities" then
                                        if ShouldESPObject(descendant, category) then
                                            table.insert(ScanQueue, {object = descendant, category = category})
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(Config.ESP.ScanYield * 1.5)  -- Increased for new rooms
                    end
                    ProcessScanQueue()
                end
            end
        end)
    end)
end)

Connections.RoomAdded = task.spawn(function()
    local currentRooms = Workspace:WaitForChild("CurrentRooms")
    currentRooms.ChildAdded:Connect(function(newRoom)
        if Config.ESP.Enabled then
            task.wait(0.5)
            local descendants = newRoom:GetDescendants()
            for i = 1, #descendants, Config.ESP.ScanBatchSize do
                for j = i, math.min(i + Config.ESP.ScanBatchSize - 1, #descendants) do
                    local descendant = descendants[j]
                    if not ProcessedObjects[descendant] and (descendant:IsA("Model") or descendant:IsA("BasePart")) then
                        for category, enabled in pairs(Config.ESP) do
                            if type(enabled) == "boolean" and enabled and category ~= "Enabled" and category ~= "MaxDistance" and category ~= "UpdateRate" and category ~= "Entities" then
                                if ShouldESPObject(descendant, category) then
                                    table.insert(ScanQueue, {object = descendant, category = category})
                                    break
                                end
                            end
                        end
                    end
                end
                task.wait(Config.ESP.ScanYield * 1.5)  -- Increased for new rooms
            end
            ProcessScanQueue()
        end
    end)
end)

-- ========================================
-- GUI CREATION
-- ========================================

local ESPTab = Window:CreateTab("👁️ ESP System", 4483362458)
local VisualTab = Window:CreateTab("🌟 Visual", 4483362458)
local EntityTab = Window:CreateTab("⚠️ Alerts", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

-- ESP TAB
ESPTab:CreateSection("🎯 Main Controls")

ESPTab:CreateToggle({
    Name = "✨ Enable ESP",
    CurrentValue = false,
    Flag = "MainESP",
    Callback = function(Value)
        Config.ESP.Enabled = Value
        
        if Value then
            task.spawn(ScanForObjects)
            Rayfield:Notify({
                Title = "🐰 RabbitCore ESP",
                Content = "ESP System Activated!",
                Duration = 3,
                Image = 4483362458
            })
        else
            ClearAllESP()
            Rayfield:Notify({
                Title = "🐰 RabbitCore ESP",
                Content = "ESP System Deactivated!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

ESPTab:CreateToggle({
    Name = "📏 Enable Tracers",
    CurrentValue = false,
    Flag = "Tracers",
    Callback = function(Value)
        Config.Tracers.Enabled = Value
        
        if not Value then
            for _, tracer in pairs(TracerCache) do
                tracer.Visible = false
            end
        end
    end
})

ESPTab:CreateSlider({
    Name = "🔭 Max Distance",
    Range = {50, 300},
    Increment = 10,
    Suffix = "m",
    CurrentValue = 150,
    Flag = "MaxDistance",
    Callback = function(Value)
        Config.ESP.MaxDistance = Value
    end
})

ESPTab:CreateSection("🚪 Doors (Fixed)")

ESPTab:CreateToggle({
    Name = "🚪 Next Doors (Green - To Progress)",
    CurrentValue = true,
    Flag = "NextDoors",
    Callback = function(Value)
        Config.ESP.NextDoors = Value
    end
})

ESPTab:CreateToggle({
    Name = "🚪 Normal Doors (Orange - Already Passed)",
    CurrentValue = false,
    Flag = "NormalDoors",
    Callback = function(Value)
        Config.ESP.NormalDoors = Value
    end
})

ESPTab:CreateSection("🔑 Important Items")

ESPTab:CreateToggle({
    Name = "🔑 Keys (Fixed Detection)",
    CurrentValue = true,
    Flag = "Keys",
    Callback = function(Value)
        Config.ESP.Keys = Value
    end
})

ESPTab:CreateToggle({
    Name = "🔦 Items (Flashlight, Lighter, etc)",
    CurrentValue = true,
    Flag = "Items",
    Callback = function(Value)
        Config.ESP.Items = Value
    end
})

ESPTab:CreateToggle({
    Name = "🔓 Lockpicks",
    CurrentValue = true,
    Flag = "Lockpicks",
    Callback = function(Value)
        Config.ESP.Lockpicks = Value
    end
})

ESPTab:CreateSection("💎 Collectibles")

ESPTab:CreateToggle({
    Name = "💰 Coins",
    CurrentValue = true,
    Flag = "Coins",
    Callback = function(Value)
        Config.ESP.Coins = Value
    end
})

ESPTab:CreateToggle({
    Name = "💎 Gold Chests",
    CurrentValue = true,
    Flag = "GoldChests",
    Callback = function(Value)
        Config.ESP.GoldChests = Value
    end
})

ESPTab:CreateToggle({
    Name = "📖 Books",
    CurrentValue = true,
    Flag = "Books",
    Callback = function(Value)
        Config.ESP.Books = Value
    end
})

ESPTab:CreateSection("🔧 Interactive")

ESPTab:CreateToggle({
    Name = "🎚️ Levers",
    CurrentValue = true,
    Flag = "Levers",
    Callback = function(Value)
        Config.ESP.Levers = Value
    end
})

ESPTab:CreateToggle({
    Name = "⚡ Generators",
    CurrentValue = true,
    Flag = "Generators",
    Callback = function(Value)
        Config.ESP.Generators = Value
    end
})

ESPTab:CreateToggle({
    Name = "🔌 Breakers",
    CurrentValue = true,
    Flag = "Breakers",
    Callback = function(Value)
        Config.ESP.Breakers = Value
    end
})

ESPTab:CreateSection("🛡️ Safety")

ESPTab:CreateToggle({
    Name = "🛏️ Hiding Spots",
    CurrentValue = true,
    Flag = "HidingSpots",
    Callback = function(Value)
        Config.ESP.HidingSpots = Value
    end
})

ESPTab:CreateToggle({
    Name = "👹 Entities ESP",
    CurrentValue = true,
    Flag = "EntitiesESP",
    Callback = function(Value)
        Config.ESP.Entities = Value
    end
})

-- VISUAL TAB
VisualTab:CreateSection("💡 Lighting Enhancement")

VisualTab:CreateToggle({
    Name = "🌞 No Dark",
    CurrentValue = false,
    Flag = "NoDark",
    Callback = function(Value)
        if Value then
            EnableNoDark()
            Rayfield:Notify({
                Title = "🌞 No Dark",
                Content = "Full visibility enabled!",
                Duration = 3,
                Image = 4483362458
            })
        else
            DisableNoDark()
            Rayfield:Notify({
                Title = "🌞 No Dark",
                Content = "Normal lighting restored!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

VisualTab:CreateToggle({
    Name = "🌫️ No Fog",
    CurrentValue = false,
    Flag = "NoFog",
    Callback = function(Value)
        if Value then
            EnableNoFog()
            Rayfield:Notify({
                Title = "🌫️ No Fog",
                Content = "Crystal clear view!",
                Duration = 3,
                Image = 4483362458
            })
        else
            DisableNoFog()
            Rayfield:Notify({
                Title = "🌫️ No Fog",
                Content = "Normal fog restored!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

VisualTab:CreateToggle({
    Name = "💡 FullBright",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(Value)
        if Value then
            EnableFullBright()
            Rayfield:Notify({
                Title = "💡 FullBright",
                Content = "Maximum brightness!",
                Duration = 3,
                Image = 4483362458
            })
        else
            DisableFullBright()
            Rayfield:Notify({
                Title = "💡 FullBright",
                Content = "Normal brightness!",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

VisualTab:CreateSlider({
    Name = "☀️ Brightness Level",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "x",
    CurrentValue = 2,
    Flag = "Brightness",
    Callback = function(Value)
        Config.Visual.Brightness = Value
        if Config.Visual.NoDark then
            Lighting.Brightness = Value
        end
    end
})

VisualTab:CreateButton({
    Name = "✨ Apply All Enhancements",
    Callback = function()
        EnableNoDark()
        EnableNoFog()
        EnableFullBright()
        Rayfield:Notify({
            Title = "✨ Enhanced",
            Content = "All visual enhancements applied!",
            Duration = 4,
            Image = 4483362458
        })
    end
})

-- ENTITY ALERTS TAB
EntityTab:CreateSection("⚠️ Alert System")

EntityTab:CreateToggle({
    Name = "🔔 Enable Alerts",
    CurrentValue = true,
    Flag = "Alerts",
    Callback = function(Value)
        Config.Entities.AlertEnabled = Value
    end
})

EntityTab:CreateSlider({
    Name = "⏱️ Alert Duration",
    Range = {3, 10},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 6,
    Flag = "AlertDuration",
    Callback = function(Value)
        Config.Entities.AlertDuration = Value
    end
})

EntityTab:CreateSection("👹 Main Entities")

EntityTab:CreateToggle({
    Name = "⚠️ Rush",
    CurrentValue = true,
    Flag = "Rush",
    Callback = function(Value)
        Config.Entities.Rush = Value
    end
})

EntityTab:CreateToggle({
    Name = "⚡ Ambush",
    CurrentValue = true,
    Flag = "Ambush",
    Callback = function(Value)
        Config.Entities.Ambush = Value
    end
})

EntityTab:CreateToggle({
    Name = "🔥 Seek",
    CurrentValue = true,
    Flag = "Seek",
    Callback = function(Value)
        Config.Entities.Seek = Value
    end
})

EntityTab:CreateToggle({
    Name = "👹 Figure",
    CurrentValue = true,
    Flag = "Figure",
    Callback = function(Value)
        Config.Entities.Figure = Value
    end
})

EntityTab:CreateSection("👁️ Special Entities")

EntityTab:CreateToggle({
    Name = "👁️ Eyes",
    CurrentValue = true,
    Flag = "Eyes",
    Callback = function(Value)
        Config.Entities.Eyes = Value
    end
})

EntityTab:CreateToggle({
    Name = "😱 Screech",
    CurrentValue = true,
    Flag = "Screech",
    Callback = function(Value)
        Config.Entities.Screech = Value
    end
})

EntityTab:CreateToggle({
    Name = "🚫 Halt",
    CurrentValue = true,
    Flag = "Halt",
    Callback = function(Value)
        Config.Entities.Halt = Value
    end
})

EntityTab:CreateSection("💀 Rare Entities")

EntityTab:CreateToggle({
    Name = "💀 A-60",
    CurrentValue = true,
    Flag = "A60",
    Callback = function(Value)
        Config.Entities.A60 = Value
    end
})

EntityTab:CreateToggle({
    Name = "⛔ A-90",
    CurrentValue = true,
    Flag = "A90",
    Callback = function(Value)
        Config.Entities.A90 = Value
    end
})

EntityTab:CreateToggle({
    Name = "☠️ A-120",
    CurrentValue = true,
    Flag = "A120",
    Callback = function(Value)
        Config.Entities.A120 = Value
    end
})

EntityTab:CreateSection("🎨 Test Alerts")

EntityTab:CreateButton({
    Name = "⚠️ Test Rush Alert",
    Callback = function()
        DetectedEntities.Rush = false
        ShowAlert("Rush")
    end
})

EntityTab:CreateButton({
    Name = "👁️ Test Eyes Alert",
    Callback = function()
        DetectedEntities.Eyes = false
        ShowAlert("Eyes")
    end
})

EntityTab:CreateButton({
    Name = "⚡ Test Ambush Alert",
    Callback = function()
        DetectedEntities.Ambush = false
        ShowAlert("Ambush")
    end
})

EntityTab:CreateButton({
    Name = "😱 Test Screech Alert",
    Callback = function()
        DetectedEntities.Screech = false
        ShowAlert("Screech")
    end
})

EntityTab:CreateButton({
    Name = "🚫 Test Halt Alert",
    Callback = function()
        DetectedEntities.Halt = false
        ShowAlert("Halt")
    end
})

EntityTab:CreateButton({
    Name = "🔥 Test Seek Alert",
    Callback = function()
        DetectedEntities.Seek = false
        ShowAlert("Seek")
    end
})

EntityTab:CreateButton({
    Name = "👹 Test Figure Alert",
    Callback = function()
        DetectedEntities.Figure = false
        ShowAlert("Figure")
    end
})

EntityTab:CreateButton({
    Name = "💀 Test A-60 Alert",
    Callback = function()
        DetectedEntities.A60 = false
        ShowAlert("A60")
    end
})

EntityTab:CreateButton({
    Name = "⛔ Test A-90 Alert",
    Callback = function()
        DetectedEntities.A90 = false
        ShowAlert("A90")
    end
})

EntityTab:CreateButton({
    Name = "☠️ Test A-120 Alert",
    Callback = function()
        DetectedEntities.A120 = false
        ShowAlert("A120")
    end
})

-- SETTINGS TAB
SettingsTab:CreateSection("⚙️ Performance")

SettingsTab:CreateSlider({
    Name = "🔄 ESP Update Rate",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "ESPUpdateRate",
    Callback = function(Value)
        Config.ESP.UpdateRate = Value
    end
})

SettingsTab:CreateSlider({
    Name = "📏 Tracer Thickness",
    Range = {1, 5},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 2,
    Flag = "TracerThickness",
    Callback = function(Value)
        Config.Tracers.Thickness = Value
        for _, tracer in pairs(TracerCache) do
            tracer.Thickness = Value
        end
    end
})

SettingsTab:CreateSlider({
    Name = "🧮 Scan Batch Size",
    Range = {5, 30},
    Increment = 5,
    CurrentValue = 10,
    Flag = "ScanBatchSize",
    Callback = function(Value)
        Config.ESP.ScanBatchSize = Value
    end
})

SettingsTab:CreateSlider({
    Name = "⏸️ Scan Yield Time",
    Range = {0.02, 0.2},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.05,
    Flag = "ScanYield",
    Callback = function(Value)
        Config.ESP.ScanYield = Value
    end
})

SettingsTab:CreateSection("🧹 Maintenance")

SettingsTab:CreateButton({
    Name = "🔄 Rescan All Objects",
    Callback = function()
        ClearAllESP()
        ProcessedObjects = {}
        task.wait(0.5)
        ScanForObjects()
        Rayfield:Notify({
            Title = "🔄 Rescanned",
            Content = "All objects rescanned!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

SettingsTab:CreateButton({
    Name = "🧹 Clear All ESP",
    Callback = function()
        ClearAllESP()
        Rayfield:Notify({
            Title = "🧹 Cleared",
            Content = "All ESP cleared!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- INFO TAB
InfoTab:CreateSection("🐰 RabbitCore Information")

InfoTab:CreateLabel("🎯 Version: 5.4 Final Optimization")
InfoTab:CreateLabel("🔥 Status: All Fixed & Enhanced")
InfoTab:CreateLabel("📅 Updated: 2025")



InfoTab:CreateSection("📱 Contact")

InfoTab:CreateButton({
    Name = "📋 Copy Telegram",
    Callback = function()
        setclipboard("https://t.me/RabbitCoreScript")
        Rayfield:Notify({
            Title = "📱 Copied!",
            Content = "Telegram: @RabbitCoreScript",
            Duration = 5,
            Image = 4483362458
        })
    end
})

InfoTab:CreateLabel("📱 Telegram: @RabbitCoreScript")
InfoTab:CreateLabel("🐰 Made with ❤️ by RabbitCore")

-- INITIALIZATION
SaveOriginalLighting()
CreateAlertGUI()
MonitorEntities()

Player.CharacterRemoving:Connect(function()
    ClearAllESP()
    DisableNoDark()
    DisableNoFog()
    DisableFullBright()
end)

Player.CharacterAdded:Connect(function()
    task.wait(2)
    if Config.ESP.Enabled then
        pcall(ScanForObjects)
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == Player then
        for name, connection in pairs(Connections) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
            elseif typeof(connection) == "thread" then
                task.cancel(connection)
            end
        end
        
        ClearAllESP()
        
        if AlertGUI and AlertGUI.ScreenGui then
            AlertGUI.ScreenGui:Destroy()
        end
    end
end)

Rayfield:Notify({
    Title = "🐰 RabbitCore ESP v5.4",
    Content = "Final optimization with zero freezes & mild alert sounds loaded!",
    Duration = 5,
    Image = 4483362458
})

print("╔" .. string.rep("═", 70) .. "╗")
print("║" .. string.rep(" ", 15) .. "🐰 RABBITCORE ESP v5.4 FINAL OPTIMIZED" .. string.rep(" ", 15) .. "║")
print("╠" .. string.rep("═", 70) .. "╣")
print("║  ✅ ABSOLUTELY ZERO MICRO-FREEZES!" .. string.rep(" ", 34) .. "║")
print("║  ⚡ Smaller batches & longer yields" .. string.rep(" ", 34) .. "║")
print("║  🎵 Mild notification sounds for alerts" .. string.rep(" ", 29) .. "║")
print("║  🚪 Smooth new room loading" .. string.rep(" ", 41) .. "║")
print("║  🔑 Ultimate performance" .. string.rep(" ", 43) .. "║")
print("╠" .. string.rep("═", 70) .. "╣")
print("║  📱 Telegram: @RabbitCoreScript" .. string.rep(" ", 37) .. "║")
print("╚" .. string.rep("═", 70) .. "╝")
print("\n✨ Enjoy the perfectly smooth experience with gentle alerts! ✨\n")
