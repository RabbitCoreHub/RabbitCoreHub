--[[
    RabbitCore UI Showcase - Comprehensive Example
    
    This script demonstrates all the features of the RabbitCore UI library.
    It includes examples of all UI elements and their configurations.
]]

-- Load RabbitCore library
local RabbitCore = loadstring(game:HttpGet("https://raw.githubusercontent.com/RabbitCoreHub/RabbitCoreHub/refs/heads/main/UI.lua", true))()

-- ============================================================
-- MAIN WINDOW CONFIGURATION
-- ============================================================
local Window = RabbitCore:CreateWindow({
    Name = "RabbitCore UI Showcase",
    Subtitle = "v1.0.0",
    LogoID = "6031097225", -- Default Roblox logo
    LoadingEnabled = true,
    LoadingTitle = "RabbitCore UI",
    LoadingSubtitle = "Loading all components...",
    
    ConfigSettings = {
        RootFolder = "RabbitCoreConfigs",
        ConfigFolder = "RabbitCoreConfigs"
    },
    
    KeySystem = false, -- Set to true to enable key system
    KeySettings = {
        Title = "RabbitCore Key System",
        Subtitle = "Enter your access key",
        Note = "Get your key from our Discord server!",
        SaveKey = true,
        Key = {"ExampleKey123"},
        SecondAction = {
            Enabled = true,
            Type = "Discord",
            Parameter = "https://discord.gg/EcyXwrDx7j"
        }
    }
})

-- ============================================================
-- HOME TAB
-- ============================================================
Window:CreateHomeTab({
    SupportedExecutors = {"Synapse X", "Script-Ware", "KRNL", "Fluxus"},
    DiscordInvite = "https://discord.gg/EcyXwrDx7j",
    Icon = 1
})

-- ============================================================
-- BUTTONS TAB
-- ============================================================
local ButtonsTab = Window:CreateTab({
    Name = "Buttons",
    Icon = "toc"
})

-- Regular Button
local Button1 = ButtonsTab:CreateButton({
    Name = "Standard Button",
    Description = "A simple button with a callback",
    Callback = function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Button Pressed",
            Text = "You clicked the standard button!",
            Duration = 3
        })
    end
})

-- Button with confirmation
local Button2 = ButtonsTab:CreateButton({
    Name = "Dangerous Action",
    Description = "This button requires confirmation",
    Callback = function()
        -- This will be called after confirmation
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Action Confirmed",
            Text = "Dangerous action executed!",
            Duration = 3
        })
    end
})

-- ============================================================
-- TOGGLES TAB
-- ============================================================
local TogglesTab = Window:CreateTab({
    Name = "Toggles",
    Icon = "toggle_on"
})

-- Basic Toggle
local Toggle1 = TogglesTab:CreateToggle({
    Name = "Enable Feature",
    Description = "Turns a feature on/off",
    CurrentValue = false,
    Callback = function(Value)
        print("Feature enabled:", Value)
    end
}, "FeatureToggle")

-- Toggle with custom styling
local Toggle2 = TogglesTab:CreateToggle({
    Name = "Dark Mode",
    Description = "Toggle between light and dark theme",
    CurrentValue = false,
    Callback = function(Value)
        -- This would typically change the UI theme
        print("Dark mode:", Value and "Enabled" or "Disabled")
    end
}, "DarkModeToggle")

-- ============================================================
-- SLIDERS TAB
-- ============================================================
local SlidersTab = Window:CreateTab({
    Name = "Sliders",
    Icon = "tune"
})

-- Basic Slider
local Slider1 = SlidersTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 2,
    CurrentValue = 16,
    Callback = function(Value)
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = Value
        end
    end
}, "WalkSpeedSlider")

-- Slider with custom range and increment
local Slider2 = SlidersTab:CreateSlider({
    Name = "Field of View",
    Range = {50, 120},
    Increment = 5,
    CurrentValue = 70,
    Callback = function(Value)
        game:GetService("Workspace").CurrentCamera.FieldOfView = Value
    end
}, "FOVSlider")

-- ============================================================
-- DROPDOWNS TAB
-- ============================================================
local DropdownsTab = Window:CreateTab({
    Name = "Dropdowns",
    Icon = "arrow_drop_down_circle"
})

-- Single-select Dropdown
local Dropdown1 = DropdownsTab:CreateDropdown({
    Name = "Select a Weapon",
    Description = "Choose your primary weapon",
    Options = {"Pistol", "Rifle", "Shotgun", "Sniper", "Rocket Launcher"},
    CurrentOption = {"Pistol"},
    MultipleOptions = false,
    Callback = function(Option)
        print("Selected weapon:", Option)
    end
}, "WeaponDropdown")

-- Multi-select Dropdown
local Dropdown2 = DropdownsTab:CreateDropdown({
    Name = "Select Abilities",
    Description = "Choose your abilities (multiple allowed)",
    Options = {"Double Jump", "Dash", "Invisibility", "Super Strength", "Teleport"},
    CurrentOption = {"Double Jump"},
    MultipleOptions = true,
    Callback = function(Options)
        print("Selected abilities:")
        for _, option in ipairs(Options) do
            print("-", option)
        end
    end
}, "AbilitiesDropdown")

-- ============================================================
-- COLOR PICKERS TAB
-- ============================================================
local ColorTab = Window:CreateTab({
    Name = "Colors",
    Icon = "palette"
})

-- Color Picker
local ColorPicker1 = ColorTab:CreateColorPicker({
    Name = "UI Accent Color",
    Color = Color3.fromRGB(0, 162, 255),
    Callback = function(Value)
        -- This would typically update the UI theme
        print("New color:", Value)
    end
}, "AccentColorPicker")

-- ============================================================
-- KEYBINDS TAB
-- ============================================================
local KeybindsTab = Window:CreateTab({
    Name = "Keybinds",
    Icon = "keyboard"
})

-- Toggle Keybind
local Keybind1 = KeybindsTab:CreateBind({
    Name = "Toggle Menu",
    Description = "Key to open/close the menu",
    CurrentBind = "RightControl",
    HoldToInteract = false,
    Callback = function(BindState)
        -- Toggle menu visibility
        print("Menu toggled:", BindState and "Open" or "Closed")
    end,
    OnChangedCallback = function(NewBind)
        print("Menu keybind changed to:", NewBind)
    end
}, "MenuKeybind")

-- Hold Keybind
local Keybind2 = KeybindsTab:CreateBind({
    Name = "Sprint",
    Description = "Hold to sprint",
    CurrentBind = "LeftShift",
    HoldToInteract = true,
    Callback = function(IsHolding)
        -- Handle sprinting
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = IsHolding and 32 or 16
        end
    end,
    OnChangedCallback = function(NewBind)
        print("Sprint keybind changed to:", NewBind)
    end
}, "SprintKeybind")

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local NotificationsTab = Window:CreateTab({
    Name = "Notifications",
    Icon = "notifications"
})

-- Show Notification Button
NotificationsTab:CreateButton({
    Name = "Show Notification",
    Description = "Display a test notification",
    Callback = function()
        RabbitCore:Notification({
            Title = "Test Notification",
            Content = "This is a test notification from RabbitCore UI!",
            Duration = 5,
            Callback = function()
                print("Notification was clicked!")
            end
        })
    end
})

-- ============================================================
-- SETTINGS TAB
-- ============================================================
local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "settings"
})

-- Config Section
local ConfigSection = SettingsTab:CreateSection("Configuration")

-- Save Config Button
ConfigSection:CreateButton({
    Name = "Save Configuration",
    Description = "Save current settings to disk",
    Callback = function()
        -- This would typically save all settings
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Settings Saved",
            Text = "Your configuration has been saved!",
            Duration = 3
        })
    end
})

-- Load Config Button
ConfigSection:CreateButton({
    Name = "Load Configuration",
    Description = "Load settings from disk",
    Callback = function()
        -- This would typically load saved settings
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Settings Loaded",
            Text = "Your configuration has been loaded!",
            Duration = 3
        })
    end
})

-- UI Settings Section
local UISection = SettingsTab:CreateSection("UI Settings")

-- UI Scale Slider
UISection:CreateSlider({
    Name = "UI Scale",
    Range = {50, 150},
    Increment = 5,
    CurrentValue = 100,
    Suffix = "%",
    Callback = function(Value)
        -- This would typically scale the UI
        print("UI Scale set to:", Value, "%")
    end
}, "UIScaleSlider")

-- UI Theme Toggle
UISection:CreateToggle({
    Name = "Dark Theme",
    Description = "Toggle between light and dark theme",
    CurrentValue = true,
    Callback = function(Value)
        -- This would typically change the UI theme
        print("Dark theme:", Value and "Enabled" or "Disabled")
    end
}, "DarkThemeToggle")

-- ============================================================
-- INITIALIZATION MESSAGE
-- ============================================================
print("\n=======================================================")
print("  RabbitCore UI Showcase - Successfully Loaded!")
print("  All components are now available in the UI.")
print("  Press RightControl to toggle the menu.")
print("=======================================================\n")

-- Initial notification
RabbitCore:Notification({
    Title = "RabbitCore UI Loaded",
    Content = "All components are now available in the UI.",
    Duration = 5
})
