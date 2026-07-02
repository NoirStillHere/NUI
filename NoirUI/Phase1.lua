--[[
    NoirUI Phase 1 - Core Architecture
    Library Owner: NoirNF
    Version: 1.0.0
    Focus: Clean Architecture, No Animation
    
    Changelog:
    - Removed all animation systems
    - Implemented Lucide Icons only
    - Clean Core structure
    - Event system for core interactions only
]]

-- ============================================
-- CORE LIBRARY
-- ============================================

local NoirUI = {
    Version = "1.0.0",
    Phase = 1,
    Windows = {},
    Notifications = {},
    ActiveConfirmFrame = nil,
    CustomCommands = {},
    Events = {},
    Settings = {
        SoundEnabled = true,
        SoundVolume = 0.5,
        MusicEnabled = false,
        MusicVolume = 0.3,
        MusicTrack = nil,
        MusicPlaylist = {},
        MusicLoopMode = "single",
        MusicCurrentIndex = 1
    }
}

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- ============================================
-- ICON SYSTEM (Lucide Only)
-- ============================================

local LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/icons.lua"))()

local IconSystem = {
    Sources = {
        Lucide = "lucide",
        RobloxAsset = "rbxasset",
        RobloxThumb = "rbxthumb",
        URL = "url"
    }
}

function IconSystem:DetectSource(icon)
    if not icon then return nil, nil end
    
    if type(icon) == "number" then
        return self.Sources.RobloxAsset, "rbxassetid://" .. tostring(icon)
    end
    
    if type(icon) == "string" then
        -- Check for rbxassetid://
        if icon:match("^rbxassetid://") then
            return self.Sources.RobloxAsset, icon
        end
        
        -- Check for rbxthumb://
        if icon:match("^rbxthumb://") then
            return self.Sources.RobloxThumb, icon
        end
        
        -- Check for URL
        if icon:match("^https?://") then
            return self.Sources.URL, icon
        end
        
        -- Check Lucide
        local lucideIcon = LucideIcons[icon:lower()]
        if lucideIcon then
            return self.Sources.Lucide, lucideIcon
        end
    end
    
    return nil, nil
end

function IconSystem:Resolve(icon)
    local source, resolved = self:DetectSource(icon)
    return resolved
end

function IconSystem:CreateIcon(icon, properties)
    properties = properties or {}
    
    if not icon then return nil end
    
    local resolved = self:Resolve(icon)
    if not resolved then return nil end
    
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = resolved
    imageLabel.ScaleType = Enum.ScaleType.Fit
    imageLabel.ClipsDescendants = true
    
    -- Apply properties
    if properties.Size then imageLabel.Size = properties.Size end
    if properties.Position then imageLabel.Position = properties.Position end
    if properties.ImageColor3 then imageLabel.ImageColor3 = properties.ImageColor3 end
    if properties.ImageTransparency then imageLabel.ImageTransparency = properties.ImageTransparency end
    if properties.ZIndex then imageLabel.ZIndex = properties.ZIndex end
    if properties.Name then imageLabel.Name = properties.Name end
    
    return imageLabel
end

-- ============================================
-- SOUND SYSTEM
-- ============================================

local SoundSystem = {
    Sounds = {
        Click = nil,
        Hover = nil,
        Toggle = nil,
        Notification = nil,
        WindowOpen = nil,
        WindowClose = nil,
        LoaderComplete = nil
    },
    Enabled = true,
    Volume = 0.5
}

function SoundSystem:Play(soundType)
    if not self.Enabled then return end
    
    local soundId = self.Sounds[soundType]
    if not soundId then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = self.Volume
    sound.Parent = CoreGui
    
    sound:Play()
    task.delay(3, function()
        if sound then sound:Destroy() end
    end)
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function SoundSystem:SetSound(soundType, soundId)
    self.Sounds[soundType] = soundId
end

function SoundSystem:SetEnabled(enabled)
    self.Enabled = enabled
end

function SoundSystem:SetVolume(volume)
    self.Volume = math.clamp(volume, 0, 1)
end

-- ============================================
-- MUSIC SYSTEM
-- ============================================

local MusicSystem = {
    CurrentSound = nil,
    CurrentTrack = nil,
    IsPlaying = false,
    Volume = 0.3,
    Playlist = {},
    LoopMode = "single", -- "single", "playlist", "off"
    CurrentIndex = 1
}

function MusicSystem:PlayTrack(trackId)
    if not trackId then return end
    
    if not self.CurrentSound then
        self.CurrentSound = Instance.new("Sound")
        self.CurrentSound.Parent = CoreGui
        self.CurrentSound.Volume = self.Volume
        
        self.CurrentSound.Ended:Connect(function()
            if self.IsPlaying then
                self:PlayNext()
            end
        end)
    end
    
    self.CurrentSound:Stop()
    self.CurrentSound.SoundId = "rbxassetid://" .. tostring(trackId)
    self.CurrentSound:Play()
    self.CurrentTrack = trackId
    self.IsPlaying = true
end

function MusicSystem:PlayNext()
    if self.LoopMode == "off" then
        self:Stop()
        return
    end
    
    if self.LoopMode == "single" and self.CurrentTrack then
        self:PlayTrack(self.CurrentTrack)
        return
    end
    
    if self.LoopMode == "playlist" and #self.Playlist > 0 then
        self.CurrentIndex = (self.CurrentIndex % #self.Playlist) + 1
        self:PlayTrack(self.Playlist[self.CurrentIndex])
    end
end

function MusicSystem:Play()
    if self.CurrentTrack then
        self:PlayTrack(self.CurrentTrack)
    elseif #self.Playlist > 0 then
        self.CurrentIndex = 1
        self:PlayTrack(self.Playlist[1])
    end
end

function MusicSystem:Pause()
    if self.CurrentSound and self.IsPlaying then
        self.CurrentSound:Pause()
        self.IsPlaying = false
    end
end

function MusicSystem:Resume()
    if self.CurrentSound and not self.IsPlaying then
        self.CurrentSound:Resume()
        self.IsPlaying = true
    end
end

function MusicSystem:Stop()
    if self.CurrentSound then
        self.CurrentSound:Stop()
        self.IsPlaying = false
    end
end

function MusicSystem:SetVolume(volume)
    self.Volume = math.clamp(volume, 0, 1)
    if self.CurrentSound then
        self.CurrentSound.Volume = self.Volume
    end
end

function MusicSystem:SetPlaylist(playlist)
    self.Playlist = playlist or {}
    self.CurrentIndex = 1
end

function MusicSystem:SetLoopMode(mode)
    if mode == "single" or mode == "playlist" or mode == "off" then
        self.LoopMode = mode
    end
end

function MusicSystem:AddTrack(trackId)
    table.insert(self.Playlist, trackId)
end

function MusicSystem:RemoveTrack(index)
    table.remove(self.Playlist, index)
    if self.CurrentIndex > #self.Playlist then
        self.CurrentIndex = 1
    end
end

-- ============================================
-- ASSET MANAGER
-- ============================================

local AssetManager = {
    Assets = {
        Icons = {},
        Images = {},
        Fonts = {},
        Sounds = {}
    }
}

function AssetManager:RegisterIcon(name, assetId)
    self.Assets.Icons[name] = assetId
end

function AssetManager:GetIcon(name)
    return self.Assets.Icons[name]
end

function AssetManager:RegisterImage(name, assetId)
    self.Assets.Images[name] = assetId
end

function AssetManager:GetImage(name)
    return self.Assets.Images[name]
end

function AssetManager:RegisterFont(name, assetId)
    self.Assets.Fonts[name] = assetId
end

function AssetManager:GetFont(name)
    return self.Assets.Fonts[name]
end

function AssetManager:RegisterSound(name, assetId)
    self.Assets.Sounds[name] = assetId
end

function AssetManager:GetSound(name)
    return self.Assets.Sounds[name]
end

-- ============================================
-- THEME DATA
-- ============================================

local ThemeData = {
    Default = {
        Background = Color3.fromRGB(10, 10, 10),
        BackgroundSecondary = Color3.fromRGB(20, 20, 20),
        BackgroundElement = Color3.fromRGB(25, 25, 25),
        Accent = Color3.fromRGB(170, 85, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Stroke = Color3.fromRGB(60, 60, 60),
        Shadow = Color3.fromRGB(0, 0, 0),
        Transparency = {
            Background = 0.95,
            Element = 0.7,
            Stroke = 0.5
        },
        CornerRadius = 8,
        Padding = 10
    }
}

-- ============================================
-- EVENT SYSTEM
-- ============================================

function NoirUI:RegisterEvent(eventName)
    if not self.Events[eventName] then
        self.Events[eventName] = {}
    end
end

function NoirUI:On(eventName, callback)
    self:RegisterEvent(eventName)
    table.insert(self.Events[eventName], callback)
end

function NoirUI:Fire(eventName, ...)
    self:RegisterEvent(eventName)
    local events = self.Events[eventName]
    for _, callback in pairs(events) do
        pcall(callback, ...)
    end
end

function NoirUI:RemoveEvent(eventName, callback)
    if not self.Events[eventName] then return end
    for i, cb in pairs(self.Events[eventName]) do
        if cb == callback then
            table.remove(self.Events[eventName], i)
            break
        end
    end
end

-- ============================================
-- BASE ELEMENT
-- ============================================

local BaseElement = {}
BaseElement.__index = BaseElement

function BaseElement.new()
    local self = setmetatable({}, BaseElement)
    self.IsVisible = true
    self.IsLocked = false
    self.IsEnabled = true
    self.Children = {}
    self.Properties = {}
    self.Events = {}
    return self
end

function BaseElement:Set(property, value)
    self.Properties[property] = value
    self:OnPropertyChanged(property, value)
    return self
end

function BaseElement:Get(property)
    return self.Properties[property]
end

function BaseElement:Show()
    self.IsVisible = true
    if self.Instance then
        self.Instance.Visible = true
    end
    self:OnShow()
    return self
end

function BaseElement:Hide()
    self.IsVisible = false
    if self.Instance then
        self.Instance.Visible = false
    end
    self:OnHide()
    return self
end

function BaseElement:Destroy()
    if self.Instance then
        self.Instance:Destroy()
    end
    self:OnDestroy()
    return self
end

function BaseElement:Lock()
    self.IsLocked = true
    return self
end

function BaseElement:Unlock()
    self.IsLocked = false
    return self
end

function BaseElement:OnPropertyChanged(property, value)
    -- Override in child
end

function BaseElement:OnShow()
    -- Override in child
end

function BaseElement:OnHide()
    -- Override in child
end

function BaseElement:OnDestroy()
    -- Override in child
end

-- ============================================
-- WINDOW MANAGER
-- ============================================

local WindowManager = {
    Windows = {},
    ActiveWindow = nil
}

function WindowManager:CreateWindow(settings)
    settings = settings or {}
    
    -- Create GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NoirUI_Window"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 420, 0, 300)
    mainFrame.Position = settings.Position or UDim2.new(0.5, -210, 0.5, -150)
    mainFrame.BackgroundColor3 = settings.Background or ThemeData.Default.Background
    mainFrame.BackgroundTransparency = settings.BackgroundTransparency or 0.1
    mainFrame.Parent = screenGui
    mainFrame.Visible = settings.Visible ~= false
    
    -- Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, settings.CornerRadius or ThemeData.Default.CornerRadius)
    corner.Parent = mainFrame
    
    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = settings.Accent or ThemeData.Default.Accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    stroke.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = settings.Title or "NoirUI"
    title.TextColor3 = settings.Accent or ThemeData.Default.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Buttons container
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(0, 60, 1, 0)
    btnContainer.Position = UDim2.new(1, -65, 0, 0)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = header
    
    -- Window state
    local windowState = {
        IsOpen = true,
        IsMinimized = false,
        IsDragging = false
    }
    
    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 22, 0, 22)
    minimizeBtn.Position = UDim2.new(0, 0, 0.5, -11)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = btnContainer
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 4)
    minCorner.Parent = minimizeBtn
    
    minimizeBtn.MouseButton1Click:Connect(function()
        windowState.IsMinimized = not windowState.IsMinimized
        mainFrame.Size = windowState.IsMinimized and UDim2.new(0, 420, 0, 40) or UDim2.new(0, 420, 0, 300)
        NoirUI:Fire("WindowMinimized", windowState.IsMinimized)
    end)
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 22, 0, 22)
    closeBtn.Position = UDim2.new(1, -22, 0.5, -11)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = btnContainer
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        windowState.IsOpen = false
        mainFrame.Visible = false
        NoirUI:Fire("WindowClosed")
    end)
    
    -- Make draggable
    local dragStart, startPos, dragInput
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            windowState.IsDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and windowState.IsDragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            windowState.IsDragging = false
        end
    end)
    
    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 110, 1, -50)
    sidebar.Position = UDim2.new(0, 5, 0, 40)
    sidebar.BackgroundColor3 = settings.SidebarBackground or Color3.fromRGB(15, 15, 15)
    sidebar.BackgroundTransparency = 0.8
    sidebar.Parent = mainFrame
    
    local sideCorner = Instance.new("UICorner")
    sideCorner.CornerRadius = UDim.new(0, 6)
    sideCorner.Parent = sidebar
    
    -- Tab scroll
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, 0, 1, -10)
    tabScroll.BackgroundTransparency = 1
    tabScroll.ScrollBarThickness = 2
    tabScroll.ScrollBarImageColor3 = settings.Accent or ThemeData.Default.Accent
    tabScroll.ScrollBarImageTransparency = 0.5
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.Parent = sidebar
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabScroll
    
    -- Content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -125, 1, -50)
    contentContainer.Position = UDim2.new(0, 120, 0, 40)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ClipsDescendants = true
    contentContainer.Parent = mainFrame
    
    -- Create window object
    local window = setmetatable({
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Sidebar = sidebar,
        TabScroll = tabScroll,
        ContentContainer = contentContainer,
        State = windowState,
        Settings = settings,
        Tabs = {},
        ActiveTab = nil,
        Groups = {},
        Sections = {},
        Elements = {}
    }, BaseElement)
    
    -- Window methods
    function window:Open()
        self.State.IsOpen = true
        self.MainFrame.Visible = true
        NoirUI:Fire("WindowOpened", self)
        SoundSystem:Play("WindowOpen")
        return self
    end
    
    function window:Close()
        self.State.IsOpen = false
        self.MainFrame.Visible = false
        NoirUI:Fire("WindowClosed", self)
        SoundSystem:Play("WindowClose")
        return self
    end
    
    function window:Destroy()
        self.ScreenGui:Destroy()
        NoirUI:Fire("WindowDestroyed", self)
        return self
    end
    
    function window:SetTitle(title)
        self.Settings.Title = title
        title.Text = title
        return self
    end
    
    function window:SetAccent(color)
        self.Settings.Accent = color
        -- Update all accent elements
        return self
    end
    
    function window:CreateTab(name, icon)
        -- Create tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -4, 0, 32)
        tabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        tabBtn.BackgroundTransparency = 0.7
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabScroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = tabBtn
        
        -- Icon
        local iconLabel = nil
        if icon then
            iconLabel = IconSystem:CreateIcon(icon, {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 8, 0.5, -9),
                ImageColor3 = Color3.fromRGB(150, 150, 150),
                ZIndex = 2
            })
            iconLabel.Parent = tabBtn
        end
        
        -- Tab name
        local tabName = Instance.new("TextLabel")
        tabName.Size = UDim2.new(1, -10, 1, 0)
        tabName.Position = UDim2.new(0, icon and 35 or 8, 0, 0)
        tabName.BackgroundTransparency = 1
        tabName.Text = name
        tabName.TextColor3 = Color3.fromRGB(150, 150, 150)
        tabName.Font = Enum.Font.GothamBold
        tabName.TextSize = 12
        tabName.TextXAlignment = Enum.TextXAlignment.Left
        tabName.Parent = tabBtn
        
        -- Tab container
        local tabContainer = Instance.new("ScrollingFrame")
        tabContainer.Size = UDim2.new(1, 0, 1, 0)
        tabContainer.BackgroundTransparency = 1
        tabContainer.ScrollBarThickness = 2
        tabContainer.ScrollBarImageColor3 = settings.Accent or ThemeData.Default.Accent
        tabContainer.ScrollBarImageTransparency = 0.5
        tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContainer.Visible = false
        tabContainer.Parent = contentContainer
        
        local tabContentLayout = Instance.new("UIListLayout")
        tabContentLayout.Padding = UDim.new(0, 8)
        tabContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabContentLayout.Parent = tabContainer
        
        -- Create tab object
        local tab = setmetatable({
            Name = name,
            Icon = icon,
            Button = tabBtn,
            Container = tabContainer,
            ContentLayout = tabContentLayout,
            Elements = {},
            Groups = {},
            Sections = {},
            CurrentGroup = nil,
            CurrentSection = nil,
            ParentWindow = window
        }, BaseElement)
        
        -- Tab methods
        function tab:Select()
            -- Hide all tabs
            for _, t in pairs(window.Tabs) do
                t.Container.Visible = false
                t.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                -- Reset colors
                local btnText = t.Button:FindFirstChildWhichIsA("TextLabel")
                if btnText then
                    btnText.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
                local btnIcon = t.Button:FindFirstChildWhichIsA("ImageLabel")
                if btnIcon then
                    btnIcon.ImageColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
            
            -- Show this tab
            self.Container.Visible = true
            self.Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            local btnText = self.Button:FindFirstChildWhichIsA("TextLabel")
            if btnText then
                btnText.TextColor3 = settings.Accent or ThemeData.Default.Accent
            end
            local btnIcon = self.Button:FindFirstChildWhichIsA("ImageLabel")
            if btnIcon then
                btnIcon.ImageColor3 = settings.Accent or ThemeData.Default.Accent
            end
            
            window.ActiveTab = self
            NoirUI:Fire("TabChanged", self, self.Name)
            SoundSystem:Play("Click")
            
            -- Update canvas
            task.wait()
            self.Container.CanvasSize = UDim2.new(0, 0, 0, self.ContentLayout.AbsoluteContentSize.Y + 10)
            return self
        end
        
        function tab:CreateGroup(name, defaultOpen)
            local group = {}
            local isOpen = defaultOpen ~= false
            
            -- Group frame
            local groupFrame = Instance.new("Frame")
            groupFrame.Size = UDim2.new(1, -4, 0, 0)
            groupFrame.BackgroundTransparency = 1
            groupFrame.ClipsDescendants = true
            groupFrame.Parent = tab.Container
            
            -- Group header
            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 28)
            header.BackgroundTransparency = 1
            header.Text = ""
            header.AutoButtonColor = false
            header.Parent = groupFrame
            
            -- Group title
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -30, 1, 0)
            titleLabel.Position = UDim2.new(0, 8, 0, 0)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = name:upper()
            titleLabel.TextColor3 = settings.Accent or ThemeData.Default.Accent
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 11
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = header
            
            -- Arrow
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = isOpen and "▼" or "▶"
            arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
            arrow.Font = Enum.Font.GothamMedium
            arrow.TextSize = 10
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.TextYAlignment = Enum.TextYAlignment.Center
            arrow.Parent = header
            
            -- Group content
            local content = Instance.new("Frame")
            content.Size = UDim2.new(1, 0, 0, 0)
            content.Position = UDim2.new(0, 0, 0, 28)
            content.BackgroundTransparency = 1
            content.Parent = groupFrame
            
            local contentLayout = Instance.new("UIListLayout")
            contentLayout.Padding = UDim.new(0, 2)
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Parent = content
            
            -- Group object
            local groupObj = {
                Name = name,
                Frame = groupFrame,
                Header = header,
                Content = content,
                ContentLayout = contentLayout,
                IsOpen = isOpen,
                Elements = {},
                Sections = {},
                CurrentSection = nil,
                ParentTab = tab
            }
            
            function groupObj:Toggle()
                isOpen = not isOpen
                self.IsOpen = isOpen
                arrow.Text = isOpen and "▼" or "▶"
                
                local targetHeight = isOpen and (self.ContentLayout.AbsoluteContentSize.Y + 10) or 0
                self.Content.Size = UDim2.new(1, 0, 0, targetHeight)
                self.Frame.Size = UDim2.new(1, -4, 0, 28 + targetHeight)
                
                -- Update canvas
                task.wait()
                tab.Container.CanvasSize = UDim2.new(0, 0, 0, tab.ContentLayout.AbsoluteContentSize.Y + 10)
                return self
            end
            
            function groupObj:CreateSection(name, noLine)
                local section = {}
                
                local sectionFrame = Instance.new("Frame")
                sectionFrame.Size = UDim2.new(1, 0, 0, 25)
                sectionFrame.BackgroundTransparency = 1
                sectionFrame.Parent = groupObj.Content
                
                -- Section header
                local header = Instance.new("TextButton")
                header.Size = UDim2.new(1, 0, 0, 25)
                header.BackgroundTransparency = 1
                header.Text = ""
                header.AutoButtonColor = false
                header.Parent = sectionFrame
                
                -- Section title
                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, -30, 1, 0)
                titleLabel.Position = UDim2.new(0, 8, 0, 0)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = name:upper()
                titleLabel.TextColor3 = settings.Accent or ThemeData.Default.Accent
                titleLabel.Font = Enum.Font.GothamBold
                titleLabel.TextSize = 10
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.Parent = header
                
                -- Section content
                local content = Instance.new("Frame")
                content.Size = UDim2.new(1, 0, 0, 0)
                content.Position = UDim2.new(0, 0, 0, 25)
                content.BackgroundTransparency = 1
                content.Parent = sectionFrame
                
                local contentLayout = Instance.new("UIListLayout")
                contentLayout.Padding = UDim.new(0, 4)
                contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
                contentLayout.Parent = content
                
                -- Section object
                local sectionObj = {
                    Name = name,
                    Frame = sectionFrame,
                    Header = header,
                    Content = content,
                    ContentLayout = contentLayout,
                    Elements = {},
                    ParentGroup = groupObj
                }
                
                function sectionObj:AddElement(element)
                    table.insert(self.Elements, element)
                    return self
                end
                
                groupObj.CurrentSection = sectionObj
                table.insert(groupObj.Sections, sectionObj)
                
                -- Update layout
                task.wait()
                local contentHeight = contentLayout.AbsoluteContentSize.Y + 10
                sectionFrame.Size = UDim2.new(1, 0, 0, 25 + contentHeight)
                content.Size = UDim2.new(1, 0, 0, contentHeight)
                
                groupObj:Toggle()
                if groupObj.IsOpen then
                    groupObj:Toggle()
                end
                
                return sectionObj
            end
            
            -- Set initial size
            task.wait()
            local contentHeight = contentLayout.AbsoluteContentSize.Y + 10
            if isOpen then
                content.Size = UDim2.new(1, 0, 0, contentHeight)
                groupFrame.Size = UDim2.new(1, -4, 0, 28 + contentHeight)
            end
            
            -- Toggle on click
            header.MouseButton1Click:Connect(function()
                groupObj:Toggle()
                SoundSystem:Play("Click")
            end)
            
            table.insert(tab.Groups, groupObj)
            tab.CurrentGroup = groupObj
            
            return groupObj
        end
        
        function tab:CreateSection(name, noLine)
            -- If we're inside a group, use group's section
            if self.CurrentGroup then
                return self.CurrentGroup:CreateSection(name, noLine)
            end
            
            -- Otherwise create standalone section
            local section = {}
            
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Size = UDim2.new(0.95, 0, 0, 25)
            sectionFrame.BackgroundTransparency = 1
            sectionFrame.Parent = tab.Container
            
            -- Section header
            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 25)
            header.BackgroundTransparency = 1
            header.Text = ""
            header.AutoButtonColor = false
            header.Parent = sectionFrame
            
            -- Section title
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -30, 1, 0)
            titleLabel.Position = UDim2.new(0, 8, 0, 0)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = name:upper()
            titleLabel.TextColor3 = settings.Accent or ThemeData.Default.Accent
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 11
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = header
            
            -- Section content
            local content = Instance.new("Frame")
            content.Size = UDim2.new(1, 0, 0, 0)
            content.Position = UDim2.new(0, 0, 0, 25)
            content.BackgroundTransparency = 1
            content.Parent = sectionFrame
            
            local contentLayout = Instance.new("UIListLayout")
            contentLayout.Padding = UDim.new(0, 4)
            contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Parent = content
            
            -- Section object
            local sectionObj = {
                Name = name,
                Frame = sectionFrame,
                Header = header,
                Content = content,
                ContentLayout = contentLayout,
                Elements = {},
                ParentTab = tab
            }
            
            function sectionObj:AddElement(element)
                table.insert(self.Elements, element)
                return self
            end
            
            table.insert(tab.Sections, sectionObj)
            tab.CurrentSection = sectionObj
            
            -- Update layout
            task.wait()
            local contentHeight = contentLayout.AbsoluteContentSize.Y + 10
            sectionFrame.Size = UDim2.new(0.95, 0, 0, 25 + contentHeight)
            content.Size = UDim2.new(1, 0, 0, contentHeight)
            
            -- Update canvas
            tab.Container.CanvasSize = UDim2.new(0, 0, 0, tab.ContentLayout.AbsoluteContentSize.Y + 10)
            
            return sectionObj
        end
        
        function tab:CreateLabel(text)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.95, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = settings.TextColor or ThemeData.Default.Text
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = tab.CurrentSection and tab.CurrentSection.Content or tab.Container
            
            table.insert(tab.Elements, label)
            return label
        end
        
        function tab:CreateButton(options)
            local hasSubtitle = options.Subtitle and options.Subtitle ~= ""
            local height = hasSubtitle and 55 or 35
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0.95, 0, 0, height)
            button.BackgroundColor3 = settings.ElementBackground or ThemeData.Default.BackgroundElement
            button.BackgroundTransparency = 0.6
            button.Text = options.Name
            button.TextColor3 = settings.TextColor or ThemeData.Default.Text
            button.Font = Enum.Font.GothamMedium
            button.TextSize = 12
            button.AutoButtonColor = false
            button.Parent = tab.CurrentSection and tab.CurrentSection.Content or tab.Container
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = button
            
            if options.Align == false then
                button.TextXAlignment = Enum.TextXAlignment.Left
                button.Text = "  " .. options.Name
            else
                button.TextXAlignment = Enum.TextXAlignment.Center
            end
            
            if hasSubtitle then
                local subtitle = Instance.new("TextLabel")
                subtitle.Size = UDim2.new(1, -20, 0, 0)
                subtitle.Position = UDim2.new(0, 10, 0, 38)
                subtitle.BackgroundTransparency = 1
                subtitle.Text = options.Subtitle
                subtitle.TextColor3 = ThemeData.Default.TextSecondary
                subtitle.Font = Enum.Font.Gotham
                subtitle.TextSize = 10
                subtitle.TextXAlignment = Enum.TextXAlignment.Left
                subtitle.TextYAlignment = Enum.TextYAlignment.Top
                subtitle.TextWrapped = true
                subtitle.Parent = button
            end
            
            button.MouseButton1Click:Connect(function()
                if options.Callback then
                    options.Callback()
                end
                SoundSystem:Play("Click")
            end)
            
            table.insert(tab.Elements, button)
            return button
        end
        
        function tab:CreateToggle(options)
            local hasSubtitle = options.Subtitle and options.Subtitle ~= ""
            local height = hasSubtitle and 55 or 35
            local state = options.Default or false
            
            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(0.95, 0, 0, height)
            toggle.BackgroundColor3 = settings.ElementBackground or ThemeData.Default.BackgroundElement
            toggle.BackgroundTransparency = 0.6
            toggle.Text = "  " .. options.Name
            toggle.TextColor3 = state and settings.TextColor or ThemeData.Default.TextSecondary
            toggle.Font = Enum.Font.GothamMedium
            toggle.TextSize = 12
            toggle.TextXAlignment = Enum.TextXAlignment.Left
            toggle.AutoButtonColor = false
            toggle.Parent = tab.CurrentSection and tab.CurrentSection.Content or tab.Container
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = toggle
            
            -- Toggle switch
            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 30, 0, 16)
            switch.Position = UDim2.new(1, -40, 0.5, hasSubtitle and -15 or -8)
            switch.BackgroundColor3 = state and (settings.Accent or ThemeData.Default.Accent) or Color3.fromRGB(40, 40, 40)
            switch.BackgroundTransparency = 0.3
            switch.Parent = toggle
            
            local switchCorner = Instance.new("UICorner")
            switchCorner.CornerRadius = UDim.new(1, 0)
            switchCorner.Parent = switch
            
            if hasSubtitle then
                local subtitle = Instance.new("TextLabel")
                subtitle.Size = UDim2.new(1, -20, 0, 0)
                subtitle.Position = UDim2.new(0, 10, 0, 38)
                subtitle.BackgroundTransparency = 1
                subtitle.Text = options.Subtitle
                subtitle.TextColor3 = ThemeData.Default.TextSecondary
                subtitle.Font = Enum.Font.Gotham
                subtitle.TextSize = 10
                subtitle.TextXAlignment = Enum.TextXAlignment.Left
                subtitle.TextYAlignment = Enum.TextYAlignment.Top
                subtitle.TextWrapped = true
                subtitle.Parent = toggle
            end
            
            toggle.MouseButton1Click:Connect(function()
                state = not state
                toggle.TextColor3 = state and settings.TextColor or ThemeData.Default.TextSecondary
                switch.BackgroundColor3 = state and (settings.Accent or ThemeData.Default.Accent) or Color3.fromRGB(40, 40, 40)
                
                if options.Callback then
                    options.Callback(state)
                end
                SoundSystem:Play("Toggle")
            end)
            
            table.insert(tab.Elements, toggle)
            return toggle
        end
        
        function tab:CreateSlider(options)
            local hasSubtitle = options.Subtitle and options.Subtitle ~= ""
            local height = hasSubtitle and 70 or 50
            local min = options.Min or 0
            local max = options.Max or 100
            local value = options.Default or min
            local increment = options.Increment or 1
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0.95, 0, 0, height)
            frame.BackgroundColor3 = settings.ElementBackground or ThemeData.Default.BackgroundElement
            frame.BackgroundTransparency = 0.7
            frame.Parent = tab.CurrentSection and tab.CurrentSection.Content or tab.Container
            
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 6)
            frameCorner.Parent = frame
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.Position = UDim2.new(0, 12, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = options.Name .. ": " .. tostring(value)
            label.TextColor3 = settings.TextColor or ThemeData.Default.Text
            label.Font = Enum.Font.GothamMedium
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            
            local sliderBg = Instance.new("Frame")
            sliderBg.Size = UDim2.new(0.9, 0, 0, 8)
            sliderBg.Position = UDim2.new(0.05, 0, hasSubtitle and 0.55 or 0.7, 0)
            sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            sliderBg.BackgroundTransparency = 0.5
            sliderBg.Parent = frame
            
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(1, 0)
            sliderCorner.Parent = sliderBg
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = settings.Accent or ThemeData.Default.Accent
            fill.Parent = sliderBg
            
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fill
            
            if hasSubtitle then
                local subtitle = Instance.new("TextLabel")
                subtitle.Size = UDim2.new(1, -20, 0, 0)
                subtitle.Position = UDim2.new(0, 10, 0, 48)
                subtitle.BackgroundTransparency = 1
                subtitle.Text = options.Subtitle
                subtitle.TextColor3 = ThemeData.Default.TextSecondary
                subtitle.Font = Enum.Font.Gotham
                subtitle.TextSize = 10
                subtitle.TextXAlignment = Enum.TextXAlignment.Left
                subtitle.TextYAlignment = Enum.TextYAlignment.Top
                subtitle.TextWrapped = true
                subtitle.Parent = frame
            end
            
            local isHeld = false
            
            local function updateSlider(input)
                local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                local rawValue = min + (max - min) * relativeX
                local newValue = math.floor((rawValue - min) / increment) * increment + min
                newValue = math.clamp(newValue, min, max)
                
                value = newValue
                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                label.Text = options.Name .. ": " .. tostring(value)
                
                if options.Callback then
                    options.Callback(value)
                end
            end
            
            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    isHeld = true
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    isHeld = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if isHeld and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                               input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
            
            table.insert(tab.Elements, frame)
            return frame
        end
        
        function tab:CreateDropdown(options)
            local hasSubtitle = options.Subtitle and options.Subtitle ~= ""
            local height = hasSubtitle and 55 or 35
            local isOpen = false
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0.95, 0, 0, height)
            frame.BackgroundColor3 = settings.ElementBackground or ThemeData.Default.BackgroundElement
            frame.BackgroundTransparency = 0.7
            frame.ClipsDescendants = true
            frame.Parent = tab.CurrentSection and tab.CurrentSection.Content or tab.Container
            
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 6)
            frameCorner.Parent = frame
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, 0, 0, 35)
            button.BackgroundTransparency = 1
            button.Text = "  " .. options.Name .. ": " .. (options.Default or options.Options[1] or "Select...")
            button.TextColor3 = settings.TextColor or ThemeData.Default.Text
            button.Font = Enum.Font.GothamMedium
            button.TextSize = 12
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.AutoButtonColor = false
            button.Parent = frame
            
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 30, 1, 0)
            arrow.Position = UDim2.new(1, -35, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = ThemeData.Default.TextSecondary
            arrow.Font = Enum.Font.GothamMedium
            arrow.TextSize = 14
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            arrow.Parent = button
            
            if hasSubtitle then
                local subtitle = Instance.new("TextLabel")
                subtitle.Size = UDim2.new(1, -20, 0, 0)
                subtitle.Position = UDim2.new(0, 10, 0, 38)
                subtitle.BackgroundTransparency = 1
                subtitle.Text = options.Subtitle
                subtitle.TextColor3 = ThemeData.Default.TextSecondary
                subtitle.Font = Enum.Font.Gotham
                subtitle.TextSize = 10
                subtitle.TextXAlignment = Enum.TextXAlignment.Left
                subtitle.TextYAlignment = Enum.TextYAlignment.Top
                subtitle.TextWrapped = true
                subtitle.Parent = frame
            end
            
            local optionsList = Instance.new("ScrollingFrame")
            optionsList.Size = UDim2.new(1, 0, 0, 0)
            optionsList.Position = UDim2.new(0, 0, 0, 35)
            optionsList.BackgroundTransparency = 1
            optionsList.ScrollBarThickness = 2
            optionsList.Visible = false
            optionsList.Parent = frame
            
            local optionsLayout = Instance.new("UIListLayout")
            optionsLayout.Padding = UDim.new(0, 2)
            optionsLayout.Parent = optionsList
            
            local function populateOptions()
                for _, child in pairs(optionsList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                
                local optionItems = options.GetOptions and options.GetOptions() or options.Options
                if not optionItems then return end
                
                for _, option in pairs(optionItems) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 30)
                    optBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                    optBtn.BackgroundTransparency = 0.5
                    optBtn.Text = option
                    optBtn.TextColor3 = settings.TextColor or ThemeData.Default.Text
                    optBtn.Font = Enum.Font.GothamMedium
                    optBtn.TextSize = 11
                    optBtn.AutoButtonColor = false
                    optBtn.Parent = optionsList
                    
                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 4)
                    optCorner.Parent = optBtn
                    
                    optBtn.MouseButton1Click:Connect(function()
                        button.Text = "  " .. options.Name .. ": " .. option
                        isOpen = false
                        optionsList.Visible = false
                        arrow.Text = "▼"
                        frame.Size = UDim2.new(0.95, 0, 0, height)
                        
                        if options.Callback then
                            options.Callback(option)
                        end
                        SoundSystem:Play("Click")
                    end)
                end
                
                task.wait()
                local optionCount = math.min(#optionItems, 4)
                optionsList.Size = UDim2.new(1, 0, 0, optionCount * 32)
            end
            
            populateOptions()
            
            button.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                optionsList.Visible = isOpen
                arrow.Text = isOpen and "▲" or "▼"
                frame.Size = isOpen and UDim2.new(0.95, 0, 0, height + optionsList.Size.Y.Offset) or UDim2.new(0.95, 0, 0, height)
                SoundSystem:Play("Click")
            end)
            
            table.insert(tab.Elements, frame)
            return frame
        end
        
        -- Add tab to window
        table.insert(window.Tabs, tab)
        
        -- Select first tab
        if #window.Tabs == 1 then
            tab:Select()
        end
        
        return tab
    end
    
    function window:Notify(title, message, icon, soundType)
        local notification = Instance.new("Frame")
        notification.Size = UDim2.new(0, 280, 0, 65)
        notification.Position = UDim2.new(1, 20, 0.8, 0)
        notification.BackgroundColor3 = settings.NotificationBackground or Color3.fromRGB(15, 15, 15)
        notification.BackgroundTransparency = 0.25
        notification.Parent = self.ScreenGui
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notification
        
        local notifStroke = Instance.new("UIStroke")
        notifStroke.Color = settings.Accent or ThemeData.Default.Accent
        notifStroke.Thickness = 1.5
        notifStroke.Transparency = 0.5
        notifStroke.Parent = notification
        
        if icon then
            local iconLabel = IconSystem:CreateIcon(icon, {
                Size = UDim2.new(0, 24, 0, 24),
                Position = UDim2.new(0, 10, 0.5, -12),
                ImageColor3 = settings.Accent or ThemeData.Default.Accent,
                ZIndex = 2
            })
            iconLabel.Parent = notification
        end
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, icon and -45 or -15, 0, 20)
        titleLabel.Position = UDim2.new(0, icon and 40 or 15, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = settings.Accent or ThemeData.Default.Accent
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 13
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = notification
        
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, icon and -45 or -25, 0, 35)
        messageLabel.Position = UDim2.new(0, icon and 40 or 15, 0, 25)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = settings.TextColor or ThemeData.Default.Text
        messageLabel.Font = Enum.Font.Gotham
        messageLabel.TextSize = 11
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.TextYAlignment = Enum.TextYAlignment.Top
        messageLabel.TextWrapped = true
        messageLabel.Parent = notification
        
        table.insert(NoirUI.Notifications, notification)
        SoundSystem:Play(soundType or "Notification")
        
        task.delay(4, function()
            notification:Destroy()
            for i, n in pairs(NoirUI.Notifications) do
                if n == notification then
                    table.remove(NoirUI.Notifications, i)
                    break
                end
            end
        end)
        
        return notification
    end
    
    -- Store window
    table.insert(NoirUI.Windows, window)
    WindowManager.ActiveWindow = window
    
    NoirUI:Fire("WindowCreated", window)
    
    return window
end

-- ============================================
-- NOIRUI PUBLIC API
-- ============================================

function NoirUI:CreateWindow(settings)
    return WindowManager:CreateWindow(settings)
end

function NoirUI:Notify(title, message, icon, soundType)
    local window = WindowManager.ActiveWindow
    if window then
        return window:Notify(title, message, icon, soundType)
    end
end

function NoirUI:RegisterCommand(command, callback)
    self.CustomCommands[command:lower()] = callback
end

function NoirUI:SetSound(soundType, soundId)
    SoundSystem:SetSound(soundType, soundId)
end

function NoirUI:SetSoundEnabled(enabled)
    SoundSystem:SetEnabled(enabled)
end

function NoirUI:SetSoundVolume(volume)
    SoundSystem:SetVolume(volume)
end

function NoirUI:PlaySound(soundType)
    SoundSystem:Play(soundType)
end

function NoirUI:SetMusicTrack(trackId)
    MusicSystem:PlayTrack(trackId)
end

function NoirUI:SetMusicPlaylist(playlist)
    MusicSystem:SetPlaylist(playlist)
end

function NoirUI:PlayMusic()
    MusicSystem:Play()
end

function NoirUI:PauseMusic()
    MusicSystem:Pause()
end

function NoirUI:ResumeMusic()
    MusicSystem:Resume()
end

function NoirUI:StopMusic()
    MusicSystem:Stop()
end

function NoirUI:SetMusicVolume(volume)
    MusicSystem:SetVolume(volume)
end

function NoirUI:SetMusicLoopMode(mode)
    MusicSystem:SetLoopMode(mode)
end

function NoirUI:RegisterIcon(name, assetId)
    AssetManager:RegisterIcon(name, assetId)
end

function NoirUI:GetIcon(name)
    return AssetManager:GetIcon(name)
end

function NoirUI:Destroy()
    for _, window in pairs(self.Windows) do
        window:Destroy()
    end
    self.Windows = {}
    self.Notifications = {}
    MusicSystem:Stop()
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Register core events
NoirUI:RegisterEvent("WindowCreated")
NoirUI:RegisterEvent("WindowOpened")
NoirUI:RegisterEvent("WindowClosed")
NoirUI:RegisterEvent("WindowDestroyed")
NoirUI:RegisterEvent("WindowMinimized")
NoirUI:RegisterEvent("TabChanged")

-- Default sounds (optional - user can override)
-- SoundSystem:SetSound("Click", "rbxassetid://123456789")

return NoirUI
