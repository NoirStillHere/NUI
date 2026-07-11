local NoirUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirStillHere/NUI/main/src/Main.lua"))()
local LocalPlayer = game:GetService("Players").LocalPlayer

NoirUI:EnableAssetCache("NoirUI_Full_Cache")

local Logger = NoirUI:CreateLogger()
Logger:new("info", " Ultimate Demo is initializing...", 5)

local Loader = NoirUI:CreateLoader({
    Icon = "rbxassetid://1241838301",
    Duration = 2.5,
    Text = "Loading All NoirUI Systems...",
    Shape = "tron",
    OnComplete = function()
        Logger:new("success", " Loader finished!", 3)
    end
})

task.delay(0.5, function() Loader:updateProgress(0.4) end)
task.delay(1.5, function() Loader:updateText("Spawning Main UI...") end)

Loader:yield()

local Config = NoirUI:CreateConfigManager({
    Directory = "NoirUI_Ultimate_Configs",
    EnableNotifications = true
})

local Window = NoirUI:CreateWindow({
    Name = "NoirUI Ultimate v2.9.1",
    Theme = "Noir",
    Accent = Color3.fromRGB(138, 116, 249),
    ShineEffect = true,
    
    Background = {
        Image = "rbxassetid://5850220408",
        GlassEffect = true,
        GlassOpacity = 0.2
    },
    MainBlur = 10,
    
    FloatSize = 55,
    FloatIconSize = 30,
    FloatCornerRadius = 12,
    Icon = "sparkles",
    
    SidebarBackgroundColor = Color3.fromRGB(10, 10, 15),
    SidebarTransparency = 0.2,
    TabBackgroundColor = Color3.fromRGB(22, 22, 28),
    NotificationWidth = 320,
    
    ClickSound = "rbxassetid://9120385669",
    TabSound = "rbxassetid://9120385669",
    ElementSound = "rbxassetid://9120385669"
})

local HomeTab = Window:CreateTab("Home", "home")
local ToolsTab = Window:CreateTab("Tools", "wrench")
local SystemTab = Window:CreateTab("System", "settings")

local Section1 = HomeTab:CreateSection("️ Core Controls", false)

local Toggle1 = Section1:CreateToggle({
    Name = "Auto Farm",
    Subtitle = "Bật chế độ tự động farm",
    Default = false,
    FlagName = "AutoFarm",
    Callback = function(v) NoirUI:Notify("Toggle", "Auto Farm: "..tostring(v), "check-circle", "Element", 2) end
})

local Slider1 = Section1:CreateSlider({
    Name = "Speed",
    Subtitle = "Tốc độ di chuyển (1-100)",
    range = {1, 100},
    increment = 1,
    Default = 50,
    FlagName = "Speed",
    Callback = function(v) end
})

local Picker1 = Section1:CreateColorPicker({
    Name = "Accent Color",
    Subtitle = "Đổi màu toàn bộ giao diện",
    Default = Color3.fromRGB(138, 116, 249),
    Callback = function(color)
        Window:SetAccent(color)
    end
})

local Section2 = HomeTab:CreateSection(" Inputs", false)
Section2:CreateTextBox({
    Name = "Username",
    Subtitle = "Nhập tên người dùng",
    Default = "Player1",
    Callback = function(t) NoirUI:Notify("Input", "Set to: "..t, "user", "Element", 2) end
})

Section2:CreateDropdown({
    Name = "Select Game Mode",
    Subtitle = "Chọn chế độ chơi",
    Default = "Normal",
    Options = {"Normal", "Hard", "Expert", "Legendary"},
    FlagName = "GameMode",
    Callback = function(v) NoirUI:Notify("Dropdown", "Selected: "..v, "gamepad-2", "Element", 2) end
})

Section2:CreateKeybind({
    Name = "Toggle Menu",
    Subtitle = "Phím tắt ẩn/hiện UI",
    Default = "RightControl",
    FlagName = "MenuKeybind",
    Callback = function(k) NoirUI:Notify("Keybind", "Set to: "..k, "keyboard", "Success", 2) end
})

local Section3 = HomeTab:CreateSection(" Actions", false)
Section3:CreateButton({
    Name = "Execute Script",
    Subtitle = "Chạy code demo",
    Callback = function()
        NoirUI:Notify("Button", "Script executed!", "play", "Success", 3)
        Logger:new("info", "User clicked Execute Script", 3)
    end
})

local ProgressBar = Section3:CreateProgressBar("Loading Map", 100)
ProgressBar:set(70, true)

local ToolSection = ToolsTab:CreateSection(" Card System Showcase", false)

ToolsTab:CreateCard({
    Type = "Standard",
    Title = "Welcome",
    Layout = "Left",
    Image = "sparkles",
    Content = "NoirUI hỗ trợ Card với nhiều layout khác nhau.",
    Footer = {{Text="OK", Callback=function() NoirUI:Notify("Card", "Closed", "check", "Element", 2) end}}
})

ToolsTab:CreateCard({
    Type = "Dashboard",
    Title = "Live Stats",
    Items = {
        {Label = "Kills", Value = "999"},
        {Label = "Deaths", Value = "12"},
        {Label = "KD", Value = "83.2"}
    },
    FooterText = "Updated in real-time"
})

ToolsTab:CreateCard({
    Type = "Carousel",
    Title = "Icon Carousel",
    Items = {"home", "settings", "user", "shield", "music"},
    OnItemClick = function(item)
        NoirUI:Notify("Carousel", "Selected: "..item, "mouse-pointer-click", "Element", 2)
    end
})

ToolsTab:CreateSection(" Theme Switcher (Preset)", false)
ToolsTab:CreatePresetButton({
    Presets = {"Noir", "Dark", "Ocean", "Cyber"},
    Default = "Noir",
    Spacing = 8,
    FlagName = "ThemePreset",
    Callback = function(value)
        Window:SetTheme(value)
        NoirUI:Notify("Theme", "Switched to: "..value, "palette", "Success", 2)
    end
})

local SysSection = SystemTab:CreateSection(" Backend Engines", false)

SystemTab:CreateParagraph({
    Title = "Asset Cache Engine",
    Content = "Ảnh và Thumbnail sẽ được cache vào ổ cứng. Lần chạy thứ 2 sẽ load ngay lập tức."
})

SystemTab:CreateButton({
    Name = " Test Cache System",
    Subtitle = "Load ảnh và báo thời gian",
    Callback = function()
        local start = tick()
        local img = AssetCache:GetAsset("rbxassetid://6031094700")
        local duration = tick() - start
        NoirUI:Notify("Cache", "Loaded in "..string.format("%.2f", duration).."s", "image", "Success", 3)
        Logger:new("cache", "Image: "..img.." loaded in "..duration.."s", 4)
    end
})

SystemTab:CreateDivider()

SystemTab:CreateParagraph({
    Title = " NoirUI Music Player",
    Content = "Hỗ trợ Playlist, Shuffle, Repeat. Chạy độc lập với UI."
})

NoirUI.Music:LoadPlaylist({
    "rbxassetid://1868809034", 
    "rbxassetid://9120386151",
    "rbxassetid://6586616878"
})

SystemTab:CreateCard({
    Type = "Action",
    Title = "Media Controls",
    Footer = {
        { Text = " Prev", Callback = function() NoirUI.Music:Previous() end },
        { Text = " Play", Callback = function() NoirUI.Music:Play() end },
        { Text = " Pause", Callback = function() NoirUI.Music:Pause() end },
        { Text = " Next", Callback = function() NoirUI.Music:Next() end },
        { Text = " Shuffle", Callback = function()
            NoirUI.Music:SetMode("Shuffle")
            NoirUI:Notify("Music", "Mode: Shuffle", "repeat", "Element", 2)
        end }
    }
})

SystemTab:CreateDivider()

SystemTab:CreateButton({
    Name = " Save Config Manually",
    Subtitle = "Lưu trạng thái hiện tại vào file",
    Callback = function()
        Config:SaveConfig("Manual_Save_"..os.time(), LocalPlayer.Name)
        NoirUI:Notify("Config", "Saved successfully!", "save", "Success", 3)
    end
})

SystemTab:CreateButton({
    Name = " Export All Flags",
    Subtitle = "In toàn bộ Flag ra Console",
    Callback = function()
        local flags = NoirUI:GetAllFlags()
        for name, data in pairs(flags) do
            print(name .. ": " .. tostring(data.Value))
        end
        Logger:new("success", "Flags exported to F9!", 3)
    end
})

SystemTab:CreateButton({
    Name = " Reset All Flags",
    Subtitle = "Reset toàn bộ về mặc định",
    Callback = function()
        NoirUI:ResetAllFlags()
        NoirUI:Notify("Config", "Reset all flags!", "refresh-ccw", "Success", 3)
    end
})

SystemTab:CreateDivider()

SystemTab:CreateParagraph({
    Title = " Global Hotkeys",
    Content = "Đã đăng ký: [ U ] = Ẩn/Hiện UI, [ H ] = Hiện Help, [ K ] = Test Log."
})

NoirUI:RegisterHotkey(Enum.KeyCode.U, function()
    if not _uiHidden then Window:Hide() _uiHidden = true else Window:Show() _uiHidden = false end
end, "Toggle UI")

NoirUI:RegisterHotkey(Enum.KeyCode.H, function()
    NoirUI:Notify("Hotkey", "Avail: U=Toggle, H=Help, K=Log", "help-circle", "Element", 3)
end, "Show Help")

NoirUI:RegisterHotkey(Enum.KeyCode.K, function()
    Logger:new("info", "Hotkey [K] triggered!", 3)
end, "Logger Test")

NoirUI:RegisterCommand("/stats", function()
    local flags = NoirUI:GetAllFlags()
    NoirUI:Notify("Command", "Flags count: "..tableLength(flags), "bar-chart", "Element", 3)
end)

task.delay(2, function()
    NoirUI:Notify(" NoirUI Ultimate", "All 100% features loaded successfully!", "party-popper", "Success", 6, Color3.fromRGB(255, 200, 50))
    
    Logger:new("info", " Ultimate Demo is fully running!", 5)
    Logger:new("warning", "Cache, Config, Music, Hotkey, UI = ALL SYSTEM GO!", 5)
    
    print(" NoirUI Ultimate Demo is loaded!")
    print(" Try typing '/stats' in chat, or pressing 'U', 'H', 'K'!")
end)
