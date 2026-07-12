<p align="center">
  <img src="https://raw.githubusercontent.com/NoirStillHere/NUI/refs/heads/main/assets/logo.png" alt="NoirUI Icon" width="60" style="margin-right: 15px;" />
  
  <img src="https://raw.githubusercontent.com/NoirStillHere/NUI/refs/heads/main/assets/logo.jpg" alt="NoirUI helper" width="160" />
</p>

![Version](https://img.shields.io/badge/Version-2.0.5-8B5CF6?style=for-the-badge&logo=roblox&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-100%25-8B5CF6?style=for-the-badge&logo=lua&logoColor=white)
[![Discord](https://img.shields.io/discord/123456789012345678?style=for-the-badge&logo=discord&logoColor=white&color=5865F2)](https://discord.gg/fw7zDS8ccv)

<p align="center">
  <em><strong>Dev by<br/>
  <a href="https://github.com/NoirStillHere"><img src="https://img.shields.io/badge/Dev-NoirNF-8B5CF6?style=for-the-badge&logo=github&logoColor=white"></a>
  <a href="https://github.com/NoirGoodBoi"><img src="https://img.shields.io/badge/Dev-Adono-8B5CF6?style=for-the-badge&logo=github&logoColor=white"></a>
</p>

# NoirUI v2.0.5 - Complete Reference
**NoirUI** is a modern, feature-rich Roblox UI Library. It includes a comprehensive theme engine, config manager, asset cache, built-in music player, complex UI elements (Cards, Presets, Accordions, Carousels), and a robust key system.

---

## 📦 Installation

```lua
local NoirUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirStillHere/NUI/main/src/NoirUI.lua"))()
```

## 🖼️ Demo Screenshots

<div align="center" style="display: flex; flex-wrap: wrap; justify-content: center; gap: 10px;">
  <img src="https://raw.githubusercontent.com/NoirStillHere/NUI/refs/heads/main/assets/demo/Screenshot_20260712-220412_Delta%20X%20VNG.jpg" alt="Main UI & Glassmorphism" width="45%" style="max-width: 400px; border-radius: 8px;" />
  <img src="https://raw.githubusercontent.com/NoirStillHere/NUI/refs/heads/main/assets/demo/Screenshot_20260712-220419_Delta%20X%20VNG.jpg" alt="Preset Buttons & Cards" width="45%" style="max-width: 400px; border-radius: 8px;" />
  <img src="https://raw.githubusercontent.com/NoirStillHere/NUI/refs/heads/main/assets/demo/Screenshot_20260712-221027_Delta%20X%20VNG.jpg" alt="Float Button & Notification" width="45%" style="max-width: 400px; border-radius: 8px;" />
  <img src="https://raw.githubusercontent.com/NoirStillHere/NUI/refs/heads/main/assets/demo/Screenshot_20260712-220430_Delta%20X%20VNG.jpg" alt="Theme Selector & Color Picker" width="45%" style="max-width: 400px; border-radius: 8px;" />
</div>

<p align="center">
  <em>NoirUI v2.0.5 Full Demo - Dark Theme, Glassmorphism, Dynamic Elements & Float Button</em>
</p>

---

## 🚀 Core Features (Global API)

These functions are available directly from the NoirUI table.

### 1. Theme Engine

```lua
-- Apply a theme
NoirUI:ApplyTheme("Noir") 

-- Get the current active theme table
local theme = NoirUI:GetCurrentTheme()

-- Get a list of all available theme names
local list = NoirUI:GetThemeList()

-- Directly get a specific theme table by name
local specificTheme = NoirUI:GetTheme("Noir")

-- Register an element to auto-update when theme changes
NoirUI:RegisterThemeElement(instance, "BackgroundColor3", "element")
```

### 2. Asset Cache System (Execution & Studio Support)

Caches images to the local filesystem for faster loading.

```lua
-- Enable the cache (Creates a folder in your workspace)
NoirUI:EnableAssetCache("MyHub_Cache")

-- Automatically resolved by the library when using Icon/Image parameters
-- Supports: rbxassetid, rbxthumb, and raw HTTP URLs.
```

### 3. Config Manager & Flag System

```lua
-- Create a Config Manager
local Config = NoirUI:CreateConfigManager({
    Directory = "NoirUI_Configs", -- Folder name
    EnableNotifications = true
})

-- Config Manager Methods:
Config:SaveConfig("MySettings", "AuthorName")
Config:LoadConfig("MySettings")
Config:DeleteConfig("MySettings")
Config:GetConfigs() -- Returns {string} of config filenames
Config:GetConfigInfo("MySettings") -- Returns metadata table
Config:GetConfigCount()

-- Flag System (Interact with elements programmatically)
NoirUI:RegisterFlag("AutoFarm", toggleElementObject) -- Auto-done by elements
NoirUI:GetFlag("AutoFarm")
NoirUI:GetFlagValue("AutoFarm")
NoirUI:SetFlagValue("AutoFarm", true)
NoirUI:GetAllFlags() -- Returns all registered flags
NoirUI:ResetAllFlags() -- Resets all to defaults
```

### 4. Auto-Save System

```lua
local AutoSave = NoirUI:CreateAutoSave({
    Interval = 60, -- Seconds
    ConfigManager = Config,
    ConfigName = "autosave",
    EnableNotifications = false
})

AutoSave:Start()
AutoSave:Stop()
AutoSave:GetLastSave() -- Timestamp
AutoSave:GetTimeSinceLastSave()
```

### 5. Hotkey & Keybind System

```lua
-- Register a global hotkey
NoirUI:RegisterHotkey(Enum.KeyCode.R, function() print("Pressed R") end, "Reload")
NoirUI:DisableHotkey(Enum.KeyCode.R)
NoirUI:EnableHotkey(Enum.KeyCode.R)
NoirUI:UnregisterHotkey(Enum.KeyCode.R)

-- The listener runs automatically, but you can manually restart it:
NoirUI:InitHotkeyListener()
```

### 6. Sound System

```lua
NoirUI:SetCustomSound("Click", "rbxassetid://...")
NoirUI:SetCustomSound("Tab", "rbxassetid://...")
NoirUI:SetCustomSound("Element", "rbxassetid://...")
NoirUI:SetCustomSound("Open", "rbxassetid://...")
NoirUI:SetCustomSound("Close", "rbxassetid://...")
NoirUI:SetCustomSound("Notification", "rbxassetid://...")
NoirUI:SetCustomSound("Error", "rbxassetid://...")
NoirUI:SetCustomSound("Success", "rbxassetid://...")
```

### 7. Music Player (Full System)

```lua
-- Load a playlist
NoirUI.Music:LoadPlaylist({1234567890, 9876543210})

-- Control
NoirUI.Music:Play()
NoirUI.Music:Pause()
NoirUI.Music:Stop()
NoirUI.Music:Next()
NoirUI.Music:Previous()
NoirUI.Music:SetVolume(0.5)
NoirUI.Music:Seek(10) -- Seek to 10 seconds
local current, duration = NoirUI.Music:GetTime()

-- Playlist Management
NoirUI.Music:AddTrack(1234567890)
NoirUI.Music:RemoveTrack(1)
NoirUI.Music:ClearPlaylist()
NoirUI.Music:GetQueue()

-- Modes: "Single", "Repeat One", "Playlist", "Shuffle"
NoirUI.Music:SetMode("Shuffle")
local modeName = NoirUI.Music:GetModeName()
```

### 8. Notifications

```lua
NoirUI:Notify(
    "Title", 
    "Message content here", 
    "info",         -- Icon (Lucide name, Asset ID, or URL)
    "Success",      -- Sound type
    4,              -- Duration
    Color3.fromRGB(138, 116, 249) -- Progress Bar Color
)
```

### 9. Loader (Splash Screen)

```lua
local Loader = NoirUI:CreateLoader({
    Icon = "rbxassetid://6031094700",
    Duration = 3.5,
    Theme = NoirUI.Themes.Presets["Noir"],
    Text = "Loading...",
    Shape = "bo-goc", -- "tron", "vuong", "chu-nhat", "trai-tim", "tam-giac", "ngoi-sao", "bo-goc"
    OnComplete = function() end
})

Loader:updateProgress(0.5) -- Set to 50%
Loader:updateText("Loading assets...")
Loader:yield() -- Wait for finish
Loader:destroy()
```

### 10. Logger System

```lua
local Logger = NoirUI:CreateLogger()
Logger:new("info", "Log message", 3) -- Icon, Message, Duration
```

### 11. Commands

```lua
NoirUI:RegisterCommand("/reload", function() print("Reloading...") end)
```

### 12. Utilities

```lua
NoirUI:GetVersion() -- Returns "2.9.1"
NoirUI:Destroy() -- Destroys the entire CoreGui
NoirUI:CreateShineEffect(textLabel, 45, 1.5) -- Apply glow to text
```

---

## 🪟 Window & Tab API

### 1. Creating the Window

```lua
local Window = NoirUI:CreateWindow({
    Name = "Noir Hub",
    Theme = "Noir",
    Accent = Color3.fromRGB(138, 116, 249),
    Background = { Image = "rbxassetid://...", Gradient = {...}, GlassEffect = true },
    
    -- Blur Settings (Creates a blur effect behind specific elements)
    MainBlur = 0,
    NotificationBlur = 0,
    ConfirmBlur = 0,
    
    -- Layout Positioning
    DefaultPosition = UDim2.new(0.5, -260, 0.5, -200),
    FloatDefaultPosition = UDim2.new(0, 15, 0.5, -22),
    FloatSize = 45, FloatIconSize = 24, FloatCornerRadius = 8,
    FloatBackground = { Image = "...", Transparency = 0 },
    
    -- Coloring
    ElementBackgroundColor = Color3.fromRGB(...),
    SidebarBackgroundColor = Color3.fromRGB(...),
    SidebarTransparency = 0.8,
    TabBackgroundColor = Color3.fromRGB(...),
    ConfirmBackgroundColor = Color3.fromRGB(15,15,15),
    NotificationBackgroundColor = Color3.fromRGB(15,15,15),
    NotificationWidth = 260,
    
    ShineEffect = true, -- Enables animated glow on all titles
    KeySystem = { KeySettings = { Key = {"KEY123"}, FileName = "key.txt" }, KeySystem = "Once" },
    
    -- Sound IDs
    ClickSound = "rbxassetid://...", TabSound = "...", ElementSound = "...", etc.
})

-- Window Methods:
Window:SetAccent(Color3.new(1,0,0))
Window:SetTheme("Noir")
Window:SetBackground("rbxassetid://...")
Window:SetBlur(5)
Window:Hide() -- Hide UI, show Float button
Window:Show() -- Show UI, hide Float button
Window:GetTheme() -- Returns current theme table
```

### 2. Creating Tabs

```lua
local Tab = Window:CreateTab("Home", "home")
local TabGroup = Window:CreateTabGroup("Settings", true) -- default open
local TabFromGroup = TabGroup:CreateTab("General", "settings")
```

### 3. Tab Elements (`Tab:Create...`)

All elements support `Subtitle` (text below the main element).

#### 📝 Basic Display
- **`Label`**: `Tab:CreateLabel("Hello", function() return "Dynamic" end)`
- **`Divider`**: `Tab:CreateDivider()`
- **`Spacer`**: `Tab:CreateSpacer(10)`
- **`Section`**: `Tab:CreateSection("Title", true)` *(no line)*
- **`Paragraph`**: `Tab:CreateParagraph({Title="", Content=""})`
- **`Progress Bar`**: Returns `{ set(value, animate), get() }`

#### 🎮 Interactive Inputs
- **`TextBox`**: `Tab:CreateTextBox({Name="", Subtitle="", Default="", Callback=fn})`
- **`Button`**: `Tab:CreateButton({Name="", Subtitle="", Align=false, Callback=fn})`
- **`Toggle`**: `Tab:CreateToggle({Name="", Subtitle="", Default=false, FlagName="", Callback=fn})`
- **`Slider`**: `Tab:CreateSlider({Name="", Subtitle="", range={0,100}, increment=1, Default=50, FlagName="", Callback=fn})`
- **`ColorPicker`**: `Tab:CreateColorPicker({Name="", Subtitle="", Default=Color3, Callback=fn})`
- **`Keybind`**: `Tab:CreateKeybind({Name="", Subtitle="", Default="RightControl", FlagName="", Callback=fn})`
- **`Dropdown`**: `Tab:CreateDropdown({Name="", Subtitle="", Options={}, GetOptions=fn, FlagName="", Callback=fn})`

#### 🖼️ Visual & Layout
- **`Image`**: `Tab:CreateImage({Name="", Image="...", Height=120, ScaleType=Enum.ScaleType.Fit, CornerRadius=8})` -> Returns `{ set(newId) }`
- **`PresetButton`**: `Tab:CreatePresetButton({Presets={"M","L","XL"}, Default="M", FlagName="", Callback=fn})` -> Returns `{ set(value), get() }`
---

### 🃏 Card System (Tab:CreateCard)

Allows building complex layouts inside a single element.

#### 1. Standard Card (with Layout)

```lua
Tab:CreateCard({
    Title = "User",
    Type = "Standard", -- Default
    Layout = "Left", -- "Left", "Right", "Center"
    Image = "user",
    Content = "Welcome to the hub!",
    Footer = {
        { Text = "Save", Callback = function() end }
    }
})
```

#### 2. Accordion (Collapsible)

```lua
Tab:CreateCard({
    Type = "Accordion",
    Title = "Advanced Settings",
    Content = "Hidden settings content here."
})
```

#### 3. Dashboard (Stats Grid)

```lua
Tab:CreateCard({
    Type = "Dashboard",
    Title = "Stats",
    Items = {
        { Label = "Kills", Value = "123" },
        { Label = "Deaths", Value = "45" }
    },
    FooterText = "Updated 2m ago"
})
```

#### 4. Carousel (Swipe/Click Icons)

```lua
Tab:CreateCard({
    Type = "Carousel",
    Title = "Icons",
    Items = {"home", "settings", "user", "info"},
    Footer = {
        { Text = "Apply", Callback = function() end }
    },
    OnItemClick = function(item) print(item) end
})
```

#### 5. Image Grid

```lua
Tab:CreateCard({
    Type = "Grid",
    Title = "Gallery",
    Items = {"rbxassetid://1", "rbxassetid://2", "rbxassetid://3"},
    OnItemClick = function(item) print(item) end
})
```

#### 6. Action Card (Big CTA)

```lua
Tab:CreateCard({
    Type = "Action",
    Title = "Action Required",
    Content = "Click the button below to proceed.",
    Footer = {
        { Text = "Confirm", Callback = function() end }
    }
})
```

---

### 🔑 Key System (Detailed)

The KeySystem inside CreateWindow supports 2 modes.

· KeySystem = "Once": Saves the valid key locally to a file. User only needs to enter it once.
· KeySystem = "Everytime": User must enter the key every time they execute the script.

```lua
KeySystem = {
    KeySettings = {
        Key = {"KEY1", "KEY2"},       -- Array of valid keys
        FileName = "hub_key",         -- File to store the key (for Once mode)
        Title = "Verification",
        Subtitle = "Enter your key",
        Note = "Join our Discord for keys"
    },
    KeySystem = "Once"                -- or "Everytime"
}
```

---

### 🛠️ Internal Utilities (Advanced)

#### 1. Resolve Icon

The library automatically resolves:

· Lucide Icons (e.g. "home", "user", "settings")
· Roblox Asset IDs (e.g. 1234567890)
· Thumbnail URLs (e.g. "rbxthumb://...")
· HTTP URLs (e.g. "https://i.imgur.com/...")

#### 2. Shine Effect

You can manually apply the animated gradient shine to any TextLabel:

```lua
NoirUI:CreateShineEffect(textLabel, 45, 1.5) -- Rotation, Speed
```

It creates a permanent override on the text, keeping a static white base and a moving gradient overlay.

#### 3. File System Compatibility (Studio Support)

The library automatically detects if it is running in Roblox Studio. If it is, it emulates the readfile, writefile, isfile, listfiles, makefolder, and delfile functions using StringValues inside ReplicatedFirst. This ensures that features like Asset Cache, Config Manager, and Key System work perfectly even when testing in Studio.

#### 4. Dynamic Dropdowns

When creating a Dropdown, you can provide a GetOptions function instead of a static Options array. The Dropdown will call this function every time it opens if RefreshOnOpen = true, or every RefreshInterval seconds.

```lua
Tab:CreateDropdown({
    Name = "Players",
    GetOptions = function() return game.Players:GetPlayers() end,
    RefreshOnOpen = true,
    Callback = function(player) print(player.Name) end
})
```

#### 5. Spring & Hover Effects

· CreateSpringEffect(frame, delay): Animates elements popping in from the side.
· CreateHoverEffect(button): Adds a subtle scale and transparency change on mouse hover.

---

## 🎨 Theme Properties Reference

When creating a custom theme or modifying the current one, the following keys are expected:

```lua
{
    bg = Color3,        -- Main window background
    container = Color3, -- Header, Progress Bar Track
    element = Color3,   -- Buttons, Toggles, Sliders, Tabs
    hover = Color3,     -- Hover state of elements
    active = Color3,    -- Active/Selected state of elements
    accent = Color3,    -- Toggle ON, Slider Fill, Tab Indicator
    text = Color3,      -- Main text
    subtext = Color3,   -- Subtitles, Descriptions
    border = Color3     -- Dividers, Strokes
}
```

---

## 📝 Credits & License

**NoirUI** được phát triển bởi:
*   **NoirNF** - UI Engineer & Core Developer
*   **Adono** - Lua Scripter & Animation Engineer

---
*Made for the Roblox scripting community.*
