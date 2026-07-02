-- ============================================
-- NOIRUI - PHASE 1 COMPLETE
-- UI Framework for Roblox
-- ============================================

--[[
    Library Owner: NoirNF
    UI Engineer: NoirNF
    Architecture: NoirNF & DeepSeek
    Lua Scripter: NoirNF, Adono
]]

-- ============================================
-- CORE
-- ============================================

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Clean old GUI
local OldGui = game.CoreGui:FindFirstChild("NoirUI_V3_Ultimate")
if OldGui then OldGui:Destroy() end

-- Main table
local NoirUI = { 
    Notifications = {}, 
    ActiveConfirmFrame = nil, 
    CustomCommands = {}, 
    Connections = {}, 
    Glows = {}, 
    TabGroups = {},
    _WindowSettings = {}
}

-- Icon resolver
local LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/icons.lua"))()

local function ResolveIcon(iconInput)
    if not iconInput then return nil end
    if type(iconInput) == "number" then
        return "rbxassetid://" .. tostring(iconInput)
    end
    if type(iconInput) == "string" then
        if iconInput:match("^rbxassetid://") or iconInput:match("^http") then
            return iconInput
        end
        local iconName = iconInput:lower()
        if LucideIcons[iconName] then
            return LucideIcons[iconName]
        end
        return nil
    end
    return nil
end

-- ============================================
-- NOIR TIMER
-- ============================================

local NoirTimer = {}

function NoirTimer:Delay(duration, callback)
    if duration <= 0 then
        callback()
        return
    end
    
    local startTime = tick()
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        if tick() - startTime >= duration then
            connection:Disconnect()
            callback()
        end
    end)
    
    return connection
end

-- ============================================
-- ANIMATION ENGINE
-- ============================================

local NoirAnimations = {
    Presets = {},
    Handlers = {},
    ActiveAnimations = {}
}

-- Animation Handle
local AnimationHandle = {}
AnimationHandle.__index = AnimationHandle

function AnimationHandle.new(target, presetName)
    return setmetatable({
        Target = target,
        Preset = presetName,
        Tweens = {},
        IsCancelled = false,
        IsCompleted = false
    }, AnimationHandle)
end

function AnimationHandle:AddTween(tween)
    table.insert(self.Tweens, tween)
    return tween
end

function AnimationHandle:Cancel()
    if self.IsCancelled or self.IsCompleted then return end
    self.IsCancelled = true
    for _, tween in pairs(self.Tweens) do
        pcall(function() tween:Cancel() end)
    end
    self.Tweens = {}
end

function AnimationHandle:Complete()
    self.IsCompleted = true
    self.Tweens = {}
end

function AnimationHandle:GetStatus()
    if self.IsCancelled then return "Cancelled" end
    if self.IsCompleted then return "Completed" end
    return "Playing"
end

-- Engine functions
function NoirAnimations:RegisterHandler(typeName, handler)
    self.Handlers[typeName] = handler
end

function NoirAnimations:Play(target, presetName, options)
    local preset = self.Presets[presetName]
    if not preset then return end
    
    local config = {}
    for k, v in pairs(preset) do config[k] = v end
    for k, v in pairs(options or {}) do config[k] = v end
    
    local handler = self.Handlers[config.Type]
    if not handler then return end
    
    self:Cancel(target)
    
    local onComplete = config.OnComplete
    local wrappedComplete = function(status)
        self.ActiveAnimations[target] = nil
        if onComplete then
            onComplete(status)
        end
    end
    
    local handle = handler(target, config, wrappedComplete)
    if handle then
        self.ActiveAnimations[target] = handle
    end
    
    return handle
end

function NoirAnimations:Cancel(target)
    local handle = self.ActiveAnimations[target]
    if handle then
        handle:Cancel()
        self.ActiveAnimations[target] = nil
        return true
    end
    return false
end

function NoirAnimations:StopAll()
    for target, handle in pairs(self.ActiveAnimations) do
        handle:Cancel()
    end
    self.ActiveAnimations = {}
end

function NoirAnimations:GetStatus(target)
    local handle = self.ActiveAnimations[target]
    if handle then
        return handle:GetStatus()
    end
    return nil
end

function NoirAnimations:GetPresetsByCategory(category)
    local result = {}
    for name, preset in pairs(self.Presets) do
        if preset.Category == category then
            result[name] = preset
        end
    end
    return result
end

function NoirAnimations:GetPresetsByTag(tag)
    local result = {}
    for name, preset in pairs(self.Presets) do
        if preset.Tags and table.find(preset.Tags, tag) then
            result[name] = preset
        end
    end
    return result
end

-- ============================================
-- ANIMATION PRESETS
-- ============================================

NoirAnimations.Presets = {
    NoirReveal = {
        Type = "Reveal",
        Duration = 1.2,
        Category = "Loader",
        Tags = {"Premium", "Cinematic"}
    },
    
    PhantomOpen = {
        Type = "PhantomOpen",
        Category = "Window",
        Tags = {"Premium", "Smooth"}
    },
    
    PhantomClose = {
        Type = "PhantomClose",
        Category = "Window",
        Tags = {"Premium", "Smooth"}
    },
    
    NoirGhost = {
        Type = "Fade",
        Duration = 0.3,
        Category = "Element",
        Tags = {"Clean", "Subtle"}
    },
    
    NoirExpand = {
        Type = "Scale",
        From = 0.8,
        To = 1,
        Duration = 0.3,
        Category = "Element",
        Tags = {"Bouncy", "Premium"}
    },
    
    NoirScan = {
        Type = "AccentScan",
        Duration = 0.3,
        Category = "Loader",
        Tags = {"Premium", "Cyber"}
    }
}

-- ============================================
-- ANIMATION HANDLERS
-- ============================================

-- Reveal (dùng Gradient)
NoirAnimations:RegisterHandler("Reveal", function(target, config, onComplete)
    local handle = AnimationHandle.new(target, "Reveal")
    local duration = config.Duration or 1.2
    
    local gradient = Instance.new("UIGradient", target)
    gradient.Rotation = 0
    gradient.Offset = Vector2.new(1, 0)
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.01, 0),
        NumberSequenceKeypoint.new(1, 0)
    })
    
    local tween = TweenService:Create(gradient, TweenInfo.new(duration, 
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Offset = Vector2.new(0, 0)
    })
    handle:AddTween(tween)
    
    tween.Completed:Connect(function(state)
        if handle.IsCancelled then
            onComplete("Cancelled")
            return
        end
        
        if state == Enum.PlaybackState.Cancelled then
            onComplete("Cancelled")
            return
        end
        
        gradient:Destroy()
        handle:Complete()
        onComplete("Completed")
    end)
    
    tween:Play()
    return handle
end)

-- PhantomOpen
NoirAnimations:RegisterHandler("PhantomOpen", function(target, config, onComplete)
    local handle = AnimationHandle.new(target, "PhantomOpen")
    
    local size = target.AbsoluteSize
    if size.X == 0 or size.Y == 0 then
        size = Vector2.new(target.Size.X.Offset, target.Size.Y.Offset)
    end
    
    local screenSize = UIS.AbsoluteSize
    local centerX = (screenSize.X - size.X) / 2
    local centerY = (screenSize.Y - size.Y) / 2
    
    target.Visible = true
    target.Size = UDim2.new(0, 2, 0, 2)
    target.Position = UDim2.new(0, centerX + (size.X/2) - 1, 0, centerY + (size.Y/2) - 1)
    
    local t1 = TweenService:Create(target, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, size.X, 0, 2),
        Position = UDim2.new(0, centerX, 0, centerY + (size.Y/2) - 1)
    })
    handle:AddTween(t1)
    
    local t2
    t1.Completed:Connect(function(state)
        if handle.IsCancelled then
            onComplete("Cancelled")
            return
        end
        
        if state == Enum.PlaybackState.Cancelled then
            onComplete("Cancelled")
            return
        end
        
        t2 = TweenService:Create(target, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, size.X, 0, size.Y),
            Position = UDim2.new(0, centerX, 0, centerY)
        })
        handle:AddTween(t2)
        
        t2.Completed:Connect(function(state2)
            if handle.IsCancelled then
                onComplete("Cancelled")
                return
            end
            
            if state2 == Enum.PlaybackState.Cancelled then
                onComplete("Cancelled")
                return
            end
            
            handle:Complete()
            onComplete("Completed")
        end)
        
        t2:Play()
    end)
    
    t1:Play()
    return handle
end)

-- PhantomClose
NoirAnimations:RegisterHandler("PhantomClose", function(target, config, onComplete)
    local handle = AnimationHandle.new(target, "PhantomClose")
    
    local pos = target.Position
    local size = target.AbsoluteSize
    
    local centerX = pos.X.Offset + (size.X / 2) - 1
    local centerY = pos.Y.Offset + (size.Y / 2) - 1
    
    local t1 = TweenService:Create(target, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, size.X, 0, 2),
        Position = UDim2.new(0, pos.X.Offset, 0, centerY)
    })
    handle:AddTween(t1)
    
    local t2
    t1.Completed:Connect(function(state)
        if handle.IsCancelled then
            onComplete("Cancelled")
            return
        end
        
        if state == Enum.PlaybackState.Cancelled then
            onComplete("Cancelled")
            return
        end
        
        t2 = TweenService:Create(target, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 2, 0, 2),
            Position = UDim2.new(0, centerX, 0, centerY)
        })
        handle:AddTween(t2)
        
        t2.Completed:Connect(function(state2)
            if handle.IsCancelled then
                onComplete("Cancelled")
                return
            end
            
            if state2 == Enum.PlaybackState.Cancelled then
                onComplete("Cancelled")
                return
            end
            
            target.Visible = false
            handle:Complete()
            onComplete("Completed")
        end)
        
        t2:Play()
    end)
    
    t1:Play()
    return handle
end)

-- Fade (hỗ trợ multiple properties)
NoirAnimations:RegisterHandler("Fade", function(target, config, onComplete)
    local handle = AnimationHandle.new(target, "Fade")
    local duration = config.Duration or 0.3
    
    local properties = config.Properties or {}
    if config.Property then
        properties[config.Property] = config.To or 0
    end
    
    local tweenData = {}
    for prop, toValue in pairs(properties) do
        local fromValue = config.From
        if fromValue == nil then
            fromValue = target[prop]
        end
        target[prop] = fromValue
        tweenData[prop] = toValue
    end
    
    local tween = TweenService:Create(target, TweenInfo.new(duration, 
        Enum.EasingStyle.Quad, Enum.EasingDirection.Out), tweenData)
    handle:AddTween(tween)
    
    tween.Completed:Connect(function(state)
        if handle.IsCancelled then
            onComplete("Cancelled")
            return
        end
        
        if state == Enum.PlaybackState.Cancelled then
            onComplete("Cancelled")
            return
        end
        
        handle:Complete()
        onComplete("Completed")
    end)
    
    tween:Play()
    return handle
end)

-- Scale (dùng _NoirUIScale)
NoirAnimations:RegisterHandler("Scale", function(target, config, onComplete)
    local handle = AnimationHandle.new(target, "Scale")
    local from = config.From or 0.8
    local to = config.To or 1
    local duration = config.Duration or 0.3
    
    local scale = target:FindFirstChild("_NoirUIScale")
    if not scale then
        scale = Instance.new("UIScale", target)
        scale.Name = "_NoirUIScale"
    end
    
    scale.Scale = from
    
    local tween = TweenService:Create(scale, TweenInfo.new(duration, 
        Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Scale = to
    })
    handle:AddTween(tween)
    
    tween.Completed:Connect(function(state)
        if handle.IsCancelled then
            onComplete("Cancelled")
            return
        end
        
        if state == Enum.PlaybackState.Cancelled then
            onComplete("Cancelled")
            return
        end
        
        handle:Complete()
        onComplete("Completed")
    end)
    
    tween:Play()
    return handle
end)

-- AccentScan
NoirAnimations:RegisterHandler("AccentScan", function(target, config, onComplete)
    local handle = AnimationHandle.new(target, "AccentScan")
    local duration = config.Duration or 0.3
    local color = config.Color or Color3.fromRGB(170, 85, 255)
    
    local line = Instance.new("Frame", target.Parent)
    line.Size = UDim2.new(0, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = color
    line.BackgroundTransparency = 0.8
    line.ZIndex = target.ZIndex + 1
    line.AnchorPoint = Vector2.new(0, 0.5)
    
    line.Position = UDim2.new(0, -50, 0.5, 0)
    
    local scan = TweenService:Create(line, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        Position = UDim2.new(1, 50, 0.5, 0),
        BackgroundTransparency = 0.3
    })
    handle:AddTween(scan)
    
    scan.Completed:Connect(function(state)
        if handle.IsCancelled then
            onComplete("Cancelled")
            return
        end
        
        if state == Enum.PlaybackState.Cancelled then
            onComplete("Cancelled")
            return
        end
        
        local fade = TweenService:Create(line, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        handle:AddTween(fade)
        
        fade.Completed:Connect(function(state2)
            if handle.IsCancelled then
                onComplete("Cancelled")
                return
            end
            
            if state2 == Enum.PlaybackState.Cancelled then
                onComplete("Cancelled")
                return
            end
            
            line:Destroy()
            handle:Complete()
            onComplete("Completed")
        end)
        
        fade:Play()
    end)
    
    scan:Play()
    return handle
end)

-- ============================================
-- EVENTS
-- ============================================

local NoirEvents = {}

function NoirEvents:new()
    return {
        LoaderFinished = Instance.new("BindableEvent"),
        WindowOpened = Instance.new("BindableEvent"),
        WindowClosed = Instance.new("BindableEvent")
    }
end

-- ============================================
-- AUTO CONTRAST
-- ============================================

local function GetColorBrightness(color)
    return (0.299 * color.R + 0.587 * color.G + 0.114 * color.B)
end

local function GetContrastColor(backgroundColor)
    local brightness = GetColorBrightness(backgroundColor)
    if brightness > 0.5 then
        return Color3.fromRGB(0, 0, 0)
    else
        return Color3.fromRGB(255, 255, 255)
    end
end

-- ============================================
-- GLOW STROKE
-- ============================================

local function AddGlowStroke(parent, accentColor, baseThickness, glowThickness, glowTransparency)
    if not parent then return nil end
    local existing = parent:FindFirstChild("GlowStroke")
    if existing then return existing end

    local glow = Instance.new("UIStroke", parent)
    glow.Name = "GlowStroke"
    glow.Color = accentColor
    glow.Thickness = glowThickness or (baseThickness + 4)
    glow.Transparency = glowTransparency or 0.8
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return glow
end

-- ============================================
-- BLUR OVERLAY
-- ============================================

local function AddBlurOverlay(parent, blurAmount)
    if not parent or not blurAmount or blurAmount <= 0 then return nil end
    local existing = parent:FindFirstChild("BlurWrapper")
    if existing then existing:Destroy() end
    
    local wrapper = Instance.new("Frame", parent)
    wrapper.Name = "BlurWrapper"
    wrapper.Size = UDim2.new(1, 0, 1, 0)
    wrapper.Position = UDim2.new(0, 0, 0, 0)
    wrapper.BackgroundTransparency = 1
    wrapper.ZIndex = 0
    wrapper.ClipsDescendants = true
    
    local parentCorner = parent:FindFirstChild("UICorner")
    if parentCorner then
        local corner = Instance.new("UICorner", wrapper)
        corner.CornerRadius = parentCorner.CornerRadius
    end
    
    local blur = Instance.new("Frame", wrapper)
    blur.Name = "BlurOverlay"
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blur.BackgroundTransparency = 1 - math.clamp(blurAmount, 0, 1)
    blur.ZIndex = 0
    blur.BorderSizePixel = 0
    
    return wrapper
end

-- ============================================
-- UI HELPERS
-- ============================================

local function CreateClickScaleEffect(button)
    if not button then return end
    local origSize = button.Size
    TweenService:Create(button, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = origSize - UDim2.new(0, 2, 0, 2)
    }):Play()
    task.wait(0.06)
    TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = origSize
    }):Play()
end

local function CreateHoverEffect(button)
    if not button then return end
    local isHovering = false
    local hoverTween = nil
    local origTransparency = button.BackgroundTransparency
    local origSize = button.Size
    button.MouseEnter:Connect(function()
        if isHovering then return end
        isHovering = true
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = math.max(origTransparency - 0.05, 0),
            Size = origSize + UDim2.new(0, 1, 0, 1)
        })
        hoverTween:Play()
    end)
    button.MouseLeave:Connect(function()
        isHovering = false
        if hoverTween then hoverTween:Cancel() end
        hoverTween = TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = origTransparency,
            Size = origSize
        })
        hoverTween:Play()
    end)
end

local function AddSubtitle(parent, subtitleText, yOffset)
    if not subtitleText or subtitleText == "" then return nil end
    local subtitle = Instance.new("TextLabel", parent)
    subtitle.Size = UDim2.new(1, -20, 0, 0)
    subtitle.Position = UDim2.new(0, 10, 0, yOffset)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = subtitleText
    subtitle.TextColor3 = Color3.fromRGB(160, 160, 160)
    subtitle.TextTransparency = 0
    subtitle.Font = "Gotham"
    subtitle.TextSize = 10
    subtitle.TextXAlignment = "Left"
    subtitle.TextYAlignment = "Top"
    subtitle.TextWrapped = true
    subtitle.Name = "Subtitle"
    local function updateHeight()
        local textBounds = subtitle.TextBounds
        local lineCount = math.max(1, math.ceil(textBounds.X / (subtitle.AbsoluteSize.X - 20)))
        local newHeight = lineCount * 14
        subtitle.Size = UDim2.new(1, -20, 0, newHeight)
    end
    task.defer(updateHeight)
    subtitle:GetPropertyChangedSignal("Text"):Connect(updateHeight)
    subtitle:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateHeight)
    return subtitle
end

local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function SetupBackground(frame, bgSetting, bgColor, defaultTransparency)
    local existingBg = frame:FindFirstChild("_BackgroundImage")
    if existingBg then existingBg:Destroy() end
    if bgSetting and bgSetting.Image then
        local frameCorner = frame:FindFirstChild("UICorner")
        local cornerRadius = frameCorner and frameCorner.CornerRadius or UDim.new(0, 12)
        local bgImage = Instance.new("ImageLabel")
        bgImage.Name = "_BackgroundImage"
        bgImage.Size = UDim2.new(1, 0, 1, 0)
        bgImage.Position = UDim2.new(0, 0, 0, 0)
        bgImage.BackgroundTransparency = 1
        bgImage.ImageTransparency = bgSetting.Transparency or 0
        bgImage.ScaleType = Enum.ScaleType.Crop
        bgImage.ZIndex = 0
        bgImage.Parent = frame
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = cornerRadius
        bgCorner.Parent = bgImage
        local imgValue = bgSetting.Image
        if type(imgValue) == "number" or (type(imgValue) == "string" and imgValue:match("^%d+$")) then
            bgImage.Image = "rbxassetid://" .. tostring(imgValue)
        elseif type(imgValue) == "string" then
            bgImage.Image = imgValue
        end
        bgImage.ZIndex = 0
        for _, child in pairs(frame:GetChildren()) do
            if child ~= bgImage and child:IsA("GuiObject") then
                child.ZIndex = math.max(child.ZIndex, 1)
            end
        end
        frame.ClipsDescendants = true
        frame.BackgroundTransparency = 1
        return true
    else
        frame.BackgroundTransparency = defaultTransparency or 0
        frame.BackgroundColor3 = bgColor or Color3.fromRGB(10, 10, 10)
        frame.ClipsDescendants = false
        return false
    end
end

-- ============================================
-- GLOW TEXT (Legacy support)
-- ============================================

local function CreateGlowTextSlide(label, colors, speed)
    if not label then return nil end
    local gradient = Instance.new("UIGradient", label)
    local colorKeypoints = {}
    for i, color in ipairs(colors) do
        local position = (i - 1) / (#colors - 1)
        table.insert(colorKeypoints, ColorSequenceKeypoint.new(position, color))
    end
    gradient.Color = ColorSequence.new(colorKeypoints)
    gradient.Transparency = NumberSequence.new(0)
    gradient.Rotation = 30
    speed = speed or 1.5
    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if not label or not label.Parent then
            connection:Disconnect()
            return
        end
        local offset = (tick() * speed) % 2 - 1
        gradient.Offset = Vector2.new(offset, 0)
    end)
    table.insert(NoirUI.Connections, connection)
    return gradient, connection
end

-- ============================================
-- SOUND SYSTEM
-- ============================================

local SoundSettings = {
    Enabled = true,
    Volume = 0.5,
    ClickSoundId = nil,
    TabSoundId = nil,
    ElementSoundId = nil,
    OpenSoundId = nil,
    CloseSoundId = nil,
    NotificationSoundId = nil,
    ErrorSoundId = nil,
    SuccessSoundId = nil,
}

local BackgroundMusic = {
    CurrentSound = nil,
    CurrentTrackId = nil,
    IsPlaying = false,
    Volume = 0.3,
    Playlist = {},
    CurrentIndex = 1,
    LoopMode = "single",
    UIHidden = false,
}

local function PlaySound(soundType)
    if not SoundSettings.Enabled then return end
    local soundId = nil
    if soundType == "Click" then soundId = SoundSettings.ClickSoundId
    elseif soundType == "Tab" then soundId = SoundSettings.TabSoundId
    elseif soundType == "Element" then soundId = SoundSettings.ElementSoundId
    elseif soundType == "Open" then soundId = SoundSettings.OpenSoundId
    elseif soundType == "Close" then soundId = SoundSettings.CloseSoundId
    elseif soundType == "Notification" then soundId = SoundSettings.NotificationSoundId
    elseif soundType == "Error" then soundId = SoundSettings.ErrorSoundId
    elseif soundType == "Success" then soundId = SoundSettings.SuccessSoundId
    end
    if not soundId then return end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = SoundSettings.Volume
    sound.Parent = game:GetService("CoreGui")
    sound:Play()
    sound.Ended:Connect(function() sound:Destroy() end)
    task.delay(3, function() if sound then sound:Destroy() end end)
end

local function InitBackgroundMusic(settings)
    if not settings or not settings.Enabled then return end
    if settings.Playlist and #settings.Playlist > 0 then
        BackgroundMusic.Playlist = settings.Playlist
        BackgroundMusic.LoopMode = settings.LoopMode or "single"
    elseif settings.SingleTrack then
        BackgroundMusic.Playlist = {settings.SingleTrack}
        BackgroundMusic.LoopMode = "single"
    end
    BackgroundMusic.Volume = settings.Volume or 0.3
    if not BackgroundMusic.CurrentSound then
        BackgroundMusic.CurrentSound = Instance.new("Sound")
        BackgroundMusic.CurrentSound.Volume = BackgroundMusic.Volume
        BackgroundMusic.CurrentSound.Looped = false
        BackgroundMusic.CurrentSound.Parent = game:GetService("CoreGui")
        BackgroundMusic.CurrentSound.Ended:Connect(function()
            if BackgroundMusic.IsPlaying and not BackgroundMusic.UIHidden then
                PlayNextTrack()
            end
        end)
    end
    if settings.AutoPlay and #BackgroundMusic.Playlist > 0 then
        BackgroundMusic.CurrentIndex = 1
        PlayTrackById(BackgroundMusic.Playlist[1])
    end
end

local function PlayTrackById(trackId)
    if not trackId or not BackgroundMusic.CurrentSound then return end
    BackgroundMusic.CurrentSound:Stop()
    BackgroundMusic.CurrentSound.SoundId = "rbxassetid://" .. tostring(trackId)
    BackgroundMusic.CurrentSound:Play()
    BackgroundMusic.CurrentTrackId = trackId
    BackgroundMusic.IsPlaying = true
end

local function PlayNextTrack()
    if BackgroundMusic.LoopMode == "single" and BackgroundMusic.CurrentTrackId then
        PlayTrackById(BackgroundMusic.CurrentTrackId)
    elseif BackgroundMusic.LoopMode == "playlist" and #BackgroundMusic.Playlist > 0 then
        BackgroundMusic.CurrentIndex = BackgroundMusic.CurrentIndex % #BackgroundMusic.Playlist + 1
        PlayTrackById(BackgroundMusic.Playlist[BackgroundMusic.CurrentIndex])
    end
end

local function StopAndCleanupMusic()
    if BackgroundMusic.CurrentSound then
        BackgroundMusic.CurrentSound:Stop()
    end
    BackgroundMusic.IsPlaying = false
end

function NoirUI:EnableBackgroundMusic(settings)
    InitBackgroundMusic(settings)
end

function NoirUI:StartMusic()
    if BackgroundMusic.CurrentSound and #BackgroundMusic.Playlist > 0 then
        if BackgroundMusic.CurrentSound.Playing then
            BackgroundMusic.CurrentSound:Resume()
        else
            PlayTrackById(BackgroundMusic.Playlist[BackgroundMusic.CurrentIndex])
        end
        BackgroundMusic.IsPlaying = true
        BackgroundMusic.UIHidden = false
        BackgroundMusic.CurrentSound.Volume = BackgroundMusic.Volume
    end
end

function NoirUI:StopMusic()
    StopAndCleanupMusic()
end

function NoirUI:PauseMusic()
    if BackgroundMusic.CurrentSound and BackgroundMusic.IsPlaying then
        BackgroundMusic.CurrentSound:Pause()
        BackgroundMusic.IsPlaying = false
    end
end

function NoirUI:ResumeMusic()
    if BackgroundMusic.CurrentSound and not BackgroundMusic.IsPlaying and not BackgroundMusic.UIHidden then
        BackgroundMusic.CurrentSound:Resume()
        BackgroundMusic.IsPlaying = true
    end
end

function NoirUI:SetMusicVolume(volume)
    BackgroundMusic.Volume = math.clamp(volume, 0, 1)
    if BackgroundMusic.CurrentSound then
        BackgroundMusic.CurrentSound.Volume = BackgroundMusic.Volume
    end
end

function NoirUI:AddMusicTrack(trackId)
    table.insert(BackgroundMusic.Playlist, trackId)
    NoirUI:Notify("🎵 Music", "Đã thêm bài hát vào playlist", "plus", "Success")
end

function NoirUI:RemoveMusicTrack(index)
    table.remove(BackgroundMusic.Playlist, index)
    if BackgroundMusic.CurrentIndex > #BackgroundMusic.Playlist then
        BackgroundMusic.CurrentIndex = 1
    end
    NoirUI:Notify("🎵 Music", "Đã xóa bài hát khỏi playlist", "minus", "Success")
end

function NoirUI:SetMusicLoopMode(mode)
    if mode == "single" or mode == "playlist" or mode == "off" then
        BackgroundMusic.LoopMode = mode
        if mode == "off" then
            self:StopMusic()
        end
        NoirUI:Notify("🔄 Loop Mode", "Chế độ: " .. mode, "repeat", "Success")
    end
end

function NoirUI:SetCustomSound(soundType, soundId)
    if soundType == "Click" then SoundSettings.ClickSoundId = soundId
    elseif soundType == "Tab" then SoundSettings.TabSoundId = soundId
    elseif soundType == "Element" then SoundSettings.ElementSoundId = soundId
    elseif soundType == "Open" then SoundSettings.OpenSoundId = soundId
    elseif soundType == "Close" then SoundSettings.CloseSoundId = soundId
    elseif soundType == "Notification" then SoundSettings.NotificationSoundId = soundId
    elseif soundType == "Error" then SoundSettings.ErrorSoundId = soundId
    elseif soundType == "Success" then SoundSettings.SuccessSoundId = soundId
    end
end

function NoirUI:ToggleSound(enabled)
    SoundSettings.Enabled = enabled
    NoirUI:Notify("🔊 Sound", "Đã " .. (enabled and "bật" or "tắt") .. " âm thanh", enabled and "volume-2" or "volume-x")
end

function NoirUI:SetVolume(volume)
    SoundSettings.Volume = math.clamp(volume, 0, 1)
    NoirUI:Notify("🔊 Volume", "Âm lượng: " .. math.floor(volume * 100) .. "%", "volume-2")
end

-- ============================================
-- NOIRUI CORE FUNCTIONS
-- ============================================

function NoirUI:RegisterCommand(prefix, callback)
    NoirUI.CustomCommands[prefix:lower()] = callback
end

function NoirUI:Destroy()
    StopAndCleanupMusic()
    for _, connection in pairs(NoirUI.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    for _, notif in pairs(NoirUI.Notifications) do
        pcall(function() notif:Destroy() end)
    end
    local gui = game.CoreGui:FindFirstChild("NoirUI_V3_Ultimate")
    if gui then
        gui:Destroy()
    end
    NoirUI.Notifications = {}
    NoirUI.ActiveConfirmFrame = nil
    NoirUI.Connections = {}
    NoirUI.Glows = {}
end

function NoirUI:Notify(title, message, iconName, soundType)
    if soundType then
        PlaySound(soundType)
    else
        PlaySound("Notification")
    end
    
    -- Get screen GUI
    local screenGui = game.CoreGui:FindFirstChild("NoirUI_V3_Ultimate")
    if not screenGui then return end
    
    -- Create notification
    local n = Instance.new("Frame", screenGui)
    n.Size = UDim2.new(0, 320, 0, 65)
    n.Position = UDim2.new(1, 20, 0.8, 0)
    n.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    local notifCorner = Instance.new("UICorner", n)
    notifCorner.CornerRadius = UDim.new(0, 8)
    local ns = Instance.new("UIStroke", n)
    ns.Color = Color3.fromRGB(170, 85, 255)
    AddGlowStroke(n, Color3.fromRGB(170, 85, 255), 2, 5, 0.75)
    AddBlurOverlay(n, 0.3)
    SetupBackground(n, nil, Color3.fromRGB(15, 15, 15), 0.25)
    
    -- Animate in
    NoirAnimations:Play(n, "NoirExpand", {
        From = 0.7,
        To = 1,
        Duration = 0.3
    })
    
    if iconName then
        local iconImg = ResolveIcon(iconName)
        if iconImg then
            local icon = Instance.new("ImageLabel", n)
            icon.Size = UDim2.new(0, 24, 0, 24)
            icon.Position = UDim2.new(0, 10, 0.5, -12)
            icon.BackgroundTransparency = 1
            icon.Image = iconImg
            icon.ImageColor3 = Color3.new(1, 1, 1)
            icon.ZIndex = 2
        end
    end
    
    local tl = Instance.new("TextLabel", n)
    tl.Size = UDim2.new(1, iconName and -45 or -15, 0, 20)
    tl.Position = UDim2.new(0, iconName and 40 or 15, 0, 5)
    tl.Text = title
    tl.TextColor3 = Color3.fromRGB(170, 85, 255)
    tl.TextTransparency = 0
    tl.BackgroundTransparency = 1
    tl.Font = "GothamBold"
    tl.TextSize = 13
    tl.TextXAlignment = "Left"
    
    local ml = Instance.new("TextLabel", n)
    ml.Size = UDim2.new(1, iconName and -45 or -25, 0, 35)
    ml.Position = UDim2.new(0, iconName and 40 or 15, 0, 25)
    ml.Text = message
    ml.TextColor3 = Color3.new(1,1,1)
    ml.TextTransparency = 0
    ml.BackgroundTransparency = 1
    ml.TextWrapped = true
    ml.TextXAlignment = "Left"
    ml.TextYAlignment = "Top"
    ml.Font = "Gotham"
    ml.TextSize = 11
    
    -- Push existing notifications up
    for i, v in ipairs(NoirUI.Notifications) do
        TweenService:Create(v, TweenInfo.new(0.3), {Position = UDim2.new(1, -280, 0.8, -(i * 75))}):Play()
    end
    table.insert(NoirUI.Notifications, 1, n)
    
    TweenService:Create(n, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(1, -280, 0.8, 0)}):Play()
    
    task.delay(4, function()
        TweenService:Create(n, TweenInfo.new(0.5), {Position = UDim2.new(1, 20, n.Position.Y.Scale, n.Position.Y.Offset), BackgroundTransparency = 1}):Play()
        task.wait(0.5)
        for i, v in ipairs(NoirUI.Notifications) do
            if v == n then
                table.remove(NoirUI.Notifications, i)
                break
            end
        end
        n:Destroy()
    end)
end

-- ============================================
-- WINDOW SYSTEM
-- ============================================

local WindowInstances = {}
local AnimationState = {
    Current = "Closed"
}

function NoirUI:CreateWindow(settings)
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "NoirUI_V3_Ultimate"
    ScreenGui.ResetOnSpawn = false
    
    local ACCENT = settings.Accent or Color3.fromRGB(170, 85, 255)
    local useAutoContrast = settings.AutoContrast or false
    
    -- Store settings for components
    NoirUI._WindowSettings = settings
    
    settings.MainBlur = settings.MainBlur or 0
    settings.KeyBlur = settings.KeyBlur or 0
    settings.NotificationBlur = settings.NotificationBlur or 0
    settings.ConfirmBlur = settings.ConfirmBlur or 0
    settings.ElementBackgroundColor = settings.ElementBackgroundColor or nil
    settings.SidebarBackgroundColor = settings.SidebarBackgroundColor or nil
    settings.SidebarTransparency = settings.SidebarTransparency or 0.8
    settings.TabBackgroundColor = settings.TabBackgroundColor or nil
    settings.ConfirmBackgroundColor = settings.ConfirmBackgroundColor or Color3.fromRGB(15, 15, 15)
    settings.NotificationBackgroundColor = settings.NotificationBackgroundColor or Color3.fromRGB(15, 15, 15)
    
    local mainDefaultPos = settings.DefaultPosition or UDim2.new(0.5, -210, 0.5, -150)
    local floatDefaultPos = settings.FloatDefaultPosition or UDim2.new(0, 15, 0.5, -22)
    
    if settings.BackgroundMusic then
        InitBackgroundMusic(settings.BackgroundMusic)
    end
    
    -- Animation Config
    local AnimationConfig = {
        Open = settings.Animation and settings.Animation.Open or "PhantomOpen",
        Close = settings.Animation and settings.Animation.Close or "PhantomClose",
        Duration = settings.Animation and settings.Animation.Duration or 0.3
    }
    
    -- Events
    local Events = NoirEvents:new()
    local Connections = {}
    
    -- ============================================
    -- MAIN WINDOW
    -- ============================================
    
    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 420, 0, 300)
    Main.Position = mainDefaultPos
    Main.BackgroundColor3 = settings.MainBgColor or Color3.fromRGB(10, 10, 10)
    Main.Visible = false
    local mainCorner = Instance.new("UICorner", Main)
    mainCorner.CornerRadius = UDim.new(0, 12)
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Thickness = 2
    MainStroke.Color = ACCENT
    AddGlowStroke(Main, ACCENT, 2, 6, 0.7)
    AddBlurOverlay(Main, settings.MainBlur)
    SetupBackground(Main, settings.Background, settings.MainBgColor, settings.MainBgTransparency or 0)
    MakeDraggable(Main)
    
    -- ============================================
    -- FLOAT BUTTON
    -- ============================================
    
    local floatSize = settings.FloatSize or 45
    local floatIconSize = settings.FloatIconSize or 24
    local floatCornerRadius = settings.FloatCornerRadius or 12
    local TBtn = Instance.new("ImageButton", ScreenGui)
    TBtn.Size = UDim2.new(0, floatSize, 0, floatSize)
    TBtn.Position = floatDefaultPos
    TBtn.BackgroundTransparency = 1
    TBtn.Image = ""
    TBtn.ZIndex = 10
    TBtn.ClipsDescendants = true
    TBtn.AutoButtonColor = false
    TBtn.Visible = false
    
    local floatCorner = Instance.new("UICorner", TBtn)
    floatCorner.CornerRadius = UDim.new(0, floatCornerRadius)
    
    local ClipGroup = Instance.new("Frame", TBtn)
    ClipGroup.Name = "ClipGroup"
    ClipGroup.Size = UDim2.new(1, 0, 1, 0)
    ClipGroup.Position = UDim2.new(0, 0, 0, 0)
    ClipGroup.BackgroundTransparency = 1
    ClipGroup.ClipsDescendants = true
    ClipGroup.ZIndex = TBtn.ZIndex
    local clipCorner = Instance.new("UICorner", ClipGroup)
    clipCorner.CornerRadius = UDim.new(0, floatCornerRadius)
    
    if settings.FloatBackground and settings.FloatBackground.Image then
        local bgImage = Instance.new("ImageLabel", ClipGroup)
        bgImage.Name = "BackgroundImage"
        bgImage.Size = UDim2.new(1, 0, 1, 0)
        bgImage.Position = UDim2.new(0, 0, 0, 0)
        bgImage.BackgroundTransparency = 1
        bgImage.ImageTransparency = settings.FloatBackground.Transparency or 0
        bgImage.ScaleType = Enum.ScaleType.Crop
        bgImage.ZIndex = 1
        local imgValue = settings.FloatBackground.Image
        if type(imgValue) == "number" or (type(imgValue) == "string" and imgValue:match("^%d+$")) then
            bgImage.Image = "rbxassetid://" .. tostring(imgValue)
        elseif type(imgValue) == "string" then
            bgImage.Image = imgValue
        end
        local bgCorner = Instance.new("UICorner", bgImage)
        bgCorner.CornerRadius = UDim.new(0, floatCornerRadius)
        local overlay = Instance.new("Frame", ClipGroup)
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 0.4
        overlay.ZIndex = 2
        local overlayCorner = Instance.new("UICorner", overlay)
        overlayCorner.CornerRadius = UDim.new(0, floatCornerRadius)
    else
        local bgColor = Instance.new("Frame", ClipGroup)
        bgColor.Size = UDim2.new(1, 0, 1, 0)
        bgColor.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        bgColor.BackgroundTransparency = 0
        bgColor.ZIndex = 1
        local bgCorner = Instance.new("UICorner", bgColor)
        bgCorner.CornerRadius = UDim.new(0, floatCornerRadius)
    end
    
    local iconValue = settings.Icon
    if iconValue then
        local iconImage = ResolveIcon(iconValue)
        if iconImage then
            local FI = Instance.new("ImageLabel", ClipGroup)
            FI.Size = UDim2.new(0, floatIconSize, 0, floatIconSize)
            FI.Position = UDim2.new(0.5, -floatIconSize/2, 0.5, -floatIconSize/2)
            FI.BackgroundTransparency = 1
            FI.Image = iconImage
            FI.ImageColor3 = Color3.new(1, 1, 1)
            FI.ScaleType = Enum.ScaleType.Crop
            FI.ZIndex = 3
        elseif type(iconValue) == "string" then
            local textIcon = Instance.new("TextLabel", ClipGroup)
            textIcon.Size = UDim2.new(1, 0, 1, 0)
            textIcon.Position = UDim2.new(0, 0, 0, 0)
            textIcon.BackgroundTransparency = 1
            textIcon.Text = iconValue
            textIcon.TextColor3 = Color3.new(1, 1, 1)
            textIcon.TextTransparency = 0
            textIcon.TextSize = 28
            textIcon.Font = Enum.Font.GothamBold
            textIcon.TextScaled = true
            textIcon.ZIndex = 3
        end
    end
    
    local TS = Instance.new("UIStroke", TBtn)
    TS.Color = ACCENT
    TS.Thickness = 2
    AddGlowStroke(TBtn, ACCENT, 2, 5, 0.75)
    
    local floatDragging = false
    local floatDragStart, floatStartPos, floatDragInput
    TBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDragging = true
            floatDragStart = input.Position
            floatStartPos = TBtn.Position
        end
    end)
    TBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            floatDragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == floatDragInput and floatDragging then
            local delta = input.Position - floatDragStart
            TBtn.Position = UDim2.new(floatStartPos.X.Scale, floatStartPos.X.Offset + delta.X, floatStartPos.Y.Scale, floatStartPos.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDragging = false
        end
    end)
    
    -- ============================================
    -- LOADER
    -- ============================================
    
    local function CreateLoader()
        local duration = settings.LoaderDuration or 3
        local logo = settings.Logo
        
        local Loader = Instance.new("Frame", ScreenGui)
        Loader.Size = UDim2.new(1, 0, 1, 0)
        Loader.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Loader.BackgroundTransparency = 0.65
        Loader.ZIndex = 1000
        
        local Container = Instance.new("Frame", Loader)
        Container.AutomaticSize = Enum.AutomaticSize.XY
        Container.Position = UDim2.new(0.5, 0, 0.5, 0)
        Container.AnchorPoint = Vector2.new(0.5, 0.5)
        Container.BackgroundTransparency = 1
        
        local MainLayout = Instance.new("UIListLayout", Container)
        MainLayout.FillDirection = Enum.FillDirection.Vertical
        MainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        MainLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        MainLayout.Padding = UDim.new(0, 5)
        
        local Row = Instance.new("Frame", Container)
        Row.AutomaticSize = Enum.AutomaticSize.XY
        Row.BackgroundTransparency = 1
        
        local RowLayout = Instance.new("UIListLayout", Row)
        RowLayout.FillDirection = Enum.FillDirection.Horizontal
        RowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        RowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        RowLayout.Padding = UDim.new(0, 15)
        
        local LogoImg = Instance.new("ImageLabel", Row)
        LogoImg.Size = UDim2.new(0, 50, 0, 50)
        LogoImg.BackgroundTransparency = 1
        if logo then
            local resolvedLogo = ResolveIcon(logo)
            LogoImg.Image = resolvedLogo or logo
        end
        
        local Title = Instance.new("TextLabel", Row)
        Title.AutomaticSize = Enum.AutomaticSize.XY
        Title.BackgroundTransparency = 1
        Title.Text = "NoirUI"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 34
        
        local Subtitle = Instance.new("TextLabel", Container)
        Subtitle.AutomaticSize = Enum.AutomaticSize.XY
        Subtitle.BackgroundTransparency = 1
        Subtitle.Text = "by NoirNF"
        Subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
        Subtitle.Font = Enum.Font.Gotham
        Subtitle.TextSize = 10
        Subtitle.TextXAlignment = Enum.TextXAlignment.Right
        Subtitle.TextTransparency = 1
        
        local function startSequence()
            NoirAnimations:Play(Container, "NoirReveal", {
                OnComplete = function(status)
                    if status == "Cancelled" then return end
                    
                    NoirAnimations:Play(Subtitle, "NoirGhost", {
                        Properties = {
                            TextTransparency = 0
                        },
                        OnComplete = function(status)
                            if status == "Cancelled" then return end
                            
                            NoirAnimations:Play(Title, "NoirScan", {
                                Color = ACCENT,
                                OnComplete = function(status)
                                    if status == "Cancelled" then return end
                                    
                                    local holdTime = duration - 1.9
                                    if holdTime < 0 then holdTime = 0 end
                                    
                                    NoirTimer:Delay(holdTime, function()
                                        NoirAnimations:Play(Loader, "NoirGhost", {
                                            From = 0.65,
                                            To = 1,
                                            OnComplete = function(status)
                                                if status == "Cancelled" then return end
                                                
                                                NoirAnimations:Play(Container, "NoirExpand", {
                                                    From = 1,
                                                    To = 0.9,
                                                    OnComplete = function(status)
                                                        if status == "Cancelled" then return end
                                                        Loader:Destroy()
                                                        Events.LoaderFinished:Fire()
                                                    end
                                                })
                                            end
                                        })
                                    end)
                                end
                            })
                        end
                    })
                end
            })
        end
        
        startSequence()
        return Loader
    end
    
    -- ============================================
    -- WINDOW OPEN/CLOSE
    -- ============================================
    
    local function OpenUI()
        if AnimationState.Current ~= "Closed" then return end
        AnimationState.Current = "Opening"
        
        NoirAnimations:Play(Main, AnimationConfig.Open, {
            Duration = AnimationConfig.Duration,
            OnComplete = function(status)
                if status == "Cancelled" then
                    AnimationState.Current = "Closed"
                    return
                end
                AnimationState.Current = "Opened"
                Events.WindowOpened:Fire()
            end
        })
    end
    
    local function CloseUI()
        if AnimationState.Current ~= "Opened" then return end
        AnimationState.Current = "Closing"
        
        NoirAnimations:Play(Main, AnimationConfig.Close, {
            Duration = AnimationConfig.Duration,
            OnComplete = function(status)
                if status == "Cancelled" then
                    AnimationState.Current = "Opened"
                    return
                end
                AnimationState.Current = "Closed"
                Events.WindowClosed:Fire()
            end
        })
    end
    
    local function ToggleUI()
        if AnimationState.Current == "Closed" then
            OpenUI()
        elseif AnimationState.Current == "Opened" then
            CloseUI()
        end
    end
    
    -- Float Button Click
    TBtn.MouseButton1Click:Connect(function()
        CreateClickScaleEffect(TBtn)
        ToggleUI()
    end)
    
    -- ============================================
    -- LOADER & WINDOW CONNECTION
    -- ============================================
    
    local loaderConn = Events.LoaderFinished:Connect(function()
        OpenUI()
    end)
    table.insert(Connections, loaderConn)
    
    -- ============================================
    -- HEADER
    -- ============================================
    
    local Header = Instance.new("Frame", Main)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundTransparency = 1
    
    if settings.LogoID then
        local L = Instance.new("ImageLabel", Header)
        L.Size = UDim2.new(0, 24, 0, 24)
        L.Position = UDim2.new(0, 10, 0.5, -12)
        L.BackgroundTransparency = 1
        local logoImage = ResolveIcon(settings.LogoID)
        if logoImage then L.Image = logoImage end
    end
    
    local Title = Instance.new("TextLabel", Header)
    Title.Size = UDim2.new(1, -120, 1, 0)
    Title.Position = UDim2.new(0, settings.LogoID and 40 or 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = settings.Name or "NOIR HUB"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.TextTransparency = 0
    Title.Font = "GothamBold"
    Title.TextSize = 14
    Title.TextXAlignment = "Left"
    
    local Btns = Instance.new("Frame", Header)
    Btns.Size = UDim2.new(0, 70, 1, 0)
    Btns.Position = UDim2.new(1, -75, 0, 0)
    Btns.BackgroundTransparency = 1
    local BL = Instance.new("UIListLayout", Btns)
    BL.FillDirection = "Horizontal"
    BL.HorizontalAlignment = "Right"
    BL.VerticalAlignment = "Center"
    BL.Padding = UDim.new(0, 8)
    
    local function TopB(txt, col, cb)
        local b = Instance.new("TextButton", Btns)
        b.Size = UDim2.new(0, 22, 0, 22)
        b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        b.Text = txt
        b.TextColor3 = col
        b.TextTransparency = 0
        b.Font = "GothamBold"
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.AutoButtonColor = false
        CreateHoverEffect(b)
        b.MouseButton1Click:Connect(function()
            CreateClickScaleEffect(b)
            cb()
        end)
    end
    
    local isM = false
    TopB("—", Color3.fromRGB(255, 200, 50), function()
        PlaySound("Click")
        isM = not isM
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = isM and UDim2.new(0, 420, 0, 40) or UDim2.new(0, 420, 0, 300)
        }):Play()
    end)
    
    TopB("X", Color3.fromRGB(255, 100, 100), function()
        PlaySound("Click")
        if NoirUI.ActiveConfirmFrame then return end
        local Conf = Instance.new("Frame", ScreenGui)
        NoirUI.ActiveConfirmFrame = Conf
        Conf.Size = UDim2.new(0, 260, 0, 120)
        Conf.Position = UDim2.new(0.5, -130, 0.5, -60)
        Conf.BackgroundColor3 = settings.ConfirmBackgroundColor
        Conf.ZIndex = 100
        local confCorner = Instance.new("UICorner", Conf)
        confCorner.CornerRadius = UDim.new(0, 12)
        local s = Instance.new("UIStroke", Conf)
        s.Color = ACCENT
        s.Thickness = 2
        AddGlowStroke(Conf, ACCENT, 2, 4, 0.85)
        AddBlurOverlay(Conf, settings.ConfirmBlur)
        
        local t = Instance.new("TextLabel", Conf)
        t.Size = UDim2.new(1, 0, 0.5, 0)
        t.BackgroundTransparency = 1
        t.Text = "Bạn có muốn đóng UI không?"
        if useAutoContrast then
            t.TextColor3 = GetContrastColor(settings.ConfirmBackgroundColor)
        else
            t.TextColor3 = Color3.new(1,1,1)
        end
        t.TextTransparency = 0
        t.Font = "Gotham"
        t.TextSize = 13
        t.ZIndex = 101
        
        local cbtn = Instance.new("TextButton", Conf)
        cbtn.Size = UDim2.new(0.4, 0, 0, 32)
        cbtn.Position = UDim2.new(0.07, 0, 0.6, 0)
        cbtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        cbtn.Text = "Cancel"
        cbtn.TextColor3 = Color3.new(1,1,1)
        cbtn.TextTransparency = 0
        cbtn.ZIndex = 101
        Instance.new("UICorner", cbtn).CornerRadius = UDim.new(0, 6)
        cbtn.AutoButtonColor = false
        cbtn.Font = "GothamBold"
        CreateHoverEffect(cbtn)
        
        local fbtn = Instance.new("TextButton", Conf)
        fbtn.Size = UDim2.new(0.4, 0, 0, 32)
        fbtn.Position = UDim2.new(0.53, 0, 0.6, 0)
        fbtn.BackgroundColor3 = ACCENT
        fbtn.Text = "Confirm"
        if useAutoContrast then
            fbtn.TextColor3 = GetContrastColor(ACCENT)
        else
            fbtn.TextColor3 = Color3.new(1,1,1)
        end
        fbtn.TextTransparency = 0
        fbtn.ZIndex = 101
        Instance.new("UICorner", fbtn).CornerRadius = UDim.new(0, 6)
        fbtn.AutoButtonColor = false
        fbtn.Font = "GothamBold"
        CreateHoverEffect(fbtn)
        
        local function destroyConfirm()
            NoirUI.ActiveConfirmFrame = nil
            TweenService:Create(Conf, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            Conf:Destroy()
        end
        
        cbtn.MouseButton1Click:Connect(function()
            PlaySound("Click")
            CreateClickScaleEffect(cbtn)
            destroyConfirm()
        end)
        
        fbtn.MouseButton1Click:Connect(function()
            PlaySound("Click")
            CreateClickScaleEffect(fbtn)
            StopAndCleanupMusic()
            ScreenGui:Destroy()
            destroyConfirm()
            PlaySound("Close")
        end)
    end)
    
    -- ============================================
    -- SIDEBAR
    -- ============================================
    
    local Side = Instance.new("Frame", Main)
    Side.Size = UDim2.new(0, 110, 1, -50)
    Side.Position = UDim2.new(0, 5, 0, 40)
    Side.BackgroundTransparency = 1
    Side.ClipsDescendants = true
    local sideCorner = Instance.new("UICorner", Side)
    sideCorner.CornerRadius = UDim.new(0, 8)
    if settings.SidebarBackgroundColor then
        Side.BackgroundColor3 = settings.SidebarBackgroundColor
        Side.BackgroundTransparency = settings.SidebarTransparency or 0.8
    end
    local SideStroke = Instance.new("UIStroke", Side)
    SideStroke.Color = ACCENT
    SideStroke.Thickness = 1
    SideStroke.Transparency = 0.7
    AddGlowStroke(Side, ACCENT, 1, 1, 0.85)
    
    local TScroll = Instance.new("ScrollingFrame", Side)
    TScroll.Size = UDim2.new(1, 0, 1, -55)
    TScroll.Position = UDim2.new(0, 0, 0, 0)
    TScroll.BackgroundTransparency = 1
    TScroll.ScrollBarThickness = 3
    TScroll.ScrollBarImageColor3 = ACCENT
    TScroll.ScrollBarImageTransparency = 0.5
    TScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    local TLayout = Instance.new("UIListLayout", TScroll)
    TLayout.Padding = UDim.new(0, 5)
    TLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function updateSidebarCanvas()
        task.wait()
        TScroll.CanvasSize = UDim2.new(0, 0, 0, TLayout.AbsoluteContentSize.Y + 10)
    end
    TLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSidebarCanvas)
    
    local UA = Instance.new("Frame", Side)
    UA.Size = UDim2.new(1, 0, 0, 50)
    UA.Position = UDim2.new(0, 0, 1, -45)
    UA.BackgroundTransparency = 1
    UA.ZIndex = 10
    local AI = Instance.new("ImageLabel", UA)
    AI.Size = UDim2.new(0, 38, 0, 38)
    AI.Position = UDim2.new(0.5, -19, 0, 0)
    pcall(function() AI.Image = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
    Instance.new("UICorner", AI).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke", AI).Color = ACCENT
    
    -- ============================================
    -- CONTENT
    -- ============================================
    
    local Cont = Instance.new("Frame", Main)
    Cont.Size = UDim2.new(1, -125, 1, -50)
    Cont.Position = UDim2.new(0, 120, 0, 40)
    Cont.BackgroundTransparency = 1
    Cont.ClipsDescendants = true
    local contCorner = Instance.new("UICorner", Cont)
    contCorner.CornerRadius = UDim.new(0, 8)
    local ContStroke = Instance.new("UIStroke", Cont)
    ContStroke.Color = ACCENT
    ContStroke.Thickness = 1
    ContStroke.Transparency = 0.7
    AddGlowStroke(Cont, ACCENT, 1, 1, 0.7)
    
    -- ============================================
    -- START
    -- ============================================
    
    TBtn.Visible = true
    CreateLoader()
    
    -- ============================================
    -- TAB SYSTEM
    -- ============================================
    
    local Window = {}
    local allTabButtons = {}
    local currentTab = nil
    
    function Window:CreateTab(name, icon)
        local B = Instance.new("TextButton", TScroll)
        B.Size = UDim2.new(1, -5, 0, 32)
        if settings.TabBackgroundColor then
            B.BackgroundColor3 = settings.TabBackgroundColor
        else
            B.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end
        B.BackgroundTransparency = 0.7
        B.Text = ""
        B.AutoButtonColor = false
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)
        CreateHoverEffect(B)
        
        local tabStroke = Instance.new("UIStroke", B)
        tabStroke.Color = ACCENT
        tabStroke.Thickness = 1
        tabStroke.Transparency = 1
        tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        tabStroke.ZIndex = 2
        local tabGlowStroke = AddGlowStroke(B, ACCENT, 2, 1, 0.9)
        if tabGlowStroke then
            tabGlowStroke.Transparency = 1
        end
        
        local BT = Instance.new("TextLabel", B)
        BT.Size = UDim2.new(1, -10, 1, 0)
        BT.Position = UDim2.new(0, icon and 35 or 8, 0, 0)
        BT.BackgroundTransparency = 1
        BT.Text = name
        if useAutoContrast then
            BT.TextColor3 = GetContrastColor(B.BackgroundColor3)
        else
            BT.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        BT.TextTransparency = 0
        BT.Font = "GothamBold"
        BT.TextSize = 13
        BT.TextXAlignment = "Left"
        BT.ZIndex = 2
        BT.TextTruncate = Enum.TextTruncate.None
        
        if icon then
            local IC = Instance.new("ImageLabel", B)
            IC.Size = UDim2.new(0, 18, 0, 18)
            IC.Position = UDim2.new(0, 8, 0.5, -9)
            IC.BackgroundTransparency = 1
            IC.ClipsDescendants = true
            IC.ScaleType = Enum.ScaleType.Crop
            IC.ZIndex = 2
            local iconCorner = Instance.new("UICorner", IC)
            iconCorner.CornerRadius = UDim.new(0, 4)
            local iconImage = ResolveIcon(icon)
            if iconImage then
                IC.Image = iconImage
            else
                IC.Image = "rbxassetid://6031094700"
            end
            IC.ImageColor3 = Color3.new(1, 1, 1)
        end
        
        local TabContainer = Instance.new("ScrollingFrame", Cont)
        TabContainer.Size = UDim2.new(1, 0, 1, 0)
        TabContainer.BackgroundTransparency = 1
        TabContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        TabContainer.Visible = false
        TabContainer.ScrollBarThickness = 3
        TabContainer.ScrollBarImageColor3 = ACCENT
        TabContainer.ScrollBarImageTransparency = 0.5
        TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContainer.BorderSizePixel = 0
        TabContainer.ClipsDescendants = true
        
        -- Search
        local SearchFrame = Instance.new("Frame", TabContainer)
        SearchFrame.Size = UDim2.new(1, -20, 0, 35)
        SearchFrame.Position = UDim2.new(0, 10, 0, 0)
        if settings.ElementBackgroundColor then
            SearchFrame.BackgroundColor3 = settings.ElementBackgroundColor
        else
            SearchFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end
        SearchFrame.BackgroundTransparency = 0.5
        Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 8)
        local searchStroke = Instance.new("UIStroke", SearchFrame)
        searchStroke.Color = ACCENT
        searchStroke.Thickness = 1
        searchStroke.Transparency = 0.7
        searchStroke.ZIndex = 2
        AddGlowStroke(SearchFrame, ACCENT, 1, 1, 0.85)
        
        local SearchIcon = Instance.new("TextLabel", SearchFrame)
        SearchIcon.Size = UDim2.new(0, 30, 1, 0)
        SearchIcon.BackgroundTransparency = 1
        SearchIcon.Text = "🔍"
        if useAutoContrast then
            SearchIcon.TextColor3 = GetContrastColor(SearchFrame.BackgroundColor3)
        else
            SearchIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        SearchIcon.TextTransparency = 0
        SearchIcon.Font = "GothamMedium"
        SearchIcon.TextSize = 14
        
        local SearchBox = Instance.new("TextBox", SearchFrame)
        SearchBox.Size = UDim2.new(1, -35, 1, 0)
        SearchBox.Position = UDim2.new(0, 35, 0, 0)
        SearchBox.BackgroundTransparency = 1
        SearchBox.PlaceholderText = "Tìm kiếm..."
        SearchBox.Text = ""
        SearchBox.TextColor3 = Color3.new(1,1,1)
        SearchBox.TextTransparency = 0
        SearchBox.Font = "Gotham"
        SearchBox.TextSize = 12
        SearchBox.ClearTextOnFocus = false
        
        local ContentFrame = Instance.new("Frame", TabContainer)
        ContentFrame.Size = UDim2.new(1, 0, 0, 0)
        ContentFrame.Position = UDim2.new(0, 0, 0, 45)
        ContentFrame.BackgroundTransparency = 1
        local ContentLayout = Instance.new("UIListLayout", ContentFrame)
        ContentLayout.Padding = UDim.new(0, 8)
        ContentLayout.HorizontalAlignment = "Center"
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local function updateCanvas()
            task.wait()
            TabContainer.CanvasSize = UDim2.new(0, 0, 0, ContentFrame.AbsoluteSize.Y + 55)
        end
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
        
        local function resetAllTabs()
            for _, btn in pairs(allTabButtons) do
                local t = btn:FindFirstChild("TextLabel")
                if t then
                    if useAutoContrast then
                        t.TextColor3 = GetContrastColor(btn.BackgroundColor3)
                    else
                        t.TextColor3 = Color3.fromRGB(150, 150, 150)
                    end
                end
                local img = btn:FindFirstChild("ImageLabel")
                if img then img.ImageColor3 = Color3.fromRGB(150, 150, 150) end
                local stroke = btn:FindFirstChildWhichIsA("UIStroke")
                if stroke and stroke.Name ~= "GlowStroke" then stroke.Transparency = 1 end
                local glow = btn:FindFirstChild("GlowStroke")
                if glow then glow.Transparency = 1 end
            end
        end
        
        local function selectThisTab()
            for _, v in pairs(Cont:GetChildren()) do
                if v:IsA("ScrollingFrame") then
                    v.Visible = false
                end
            end
            TabContainer.Visible = true
            resetAllTabs()
            BT.TextColor3 = ACCENT
            tabStroke.Transparency = 0
            if tabGlowStroke then tabGlowStroke.Transparency = 0.7 end
            local tabImg = B:FindFirstChild("ImageLabel")
            if tabImg then tabImg.ImageColor3 = ACCENT end
            updateCanvas()
        end
        
        B.MouseButton1Click:Connect(function()
            PlaySound("Tab")
            CreateClickScaleEffect(B)
            selectThisTab()
        end)
        
        table.insert(allTabButtons, B)
        
        if #TScroll:GetChildren() == 1 then
            selectThisTab()
        end
        
        -- Tab Object
        local Tab = { Count = 0, Elements = {}, Connections = {}, _currentSectionContent = nil, _sectionLayout = nil }
        
        local function GetO() 
            Tab.Count = Tab.Count + 1
            return Tab.Count 
        end
        
        local function filterElements(searchText)
            local search = searchText:lower()
            for _, element in pairs(Tab.Elements) do
                if search == "" or (element.Name and element.Name:lower():find(search)) then
                    element.Visible = true
                else
                    element.Visible = false
                end
            end
            updateCanvas()
        end
        
        SearchBox.Changed:Connect(function(prop)
            if prop == "Text" then 
                filterElements(SearchBox.Text) 
            end
        end)
        
        -- ============================================
        -- COMPONENTS
        -- ============================================
        
        function Tab:CreateLabel(text, updateFunction)
            local parent = Tab._currentSectionContent or ContentFrame
            local l = Instance.new("TextLabel", parent)
            l.Size = UDim2.new(0.95, 0, 0, 20)
            l.BackgroundTransparency = 1
            l.Text = type(text) == "function" and text() or text
            if useAutoContrast then
                l.TextColor3 = GetContrastColor(Color3.fromRGB(15, 15, 15))
            else
                l.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            l.TextTransparency = 0
            l.Font = "Gotham"
            l.TextSize = 12
            l.TextXAlignment = "Left"
            l.LayoutOrder = GetO()
            l.Name = "Label"
            table.insert(Tab.Elements, l)
            
            if type(text) == "function" then
                local connection = RunService.RenderStepped:Connect(function()
                    if l and l.Parent then
                        l.Text = text()
                    else
                        connection:Disconnect()
                    end
                end)
                table.insert(Tab.Connections, connection)
                table.insert(NoirUI.Connections, connection)
            end
            return l
        end
        
        function Tab:CreateSection(title, noLine)
            local s = Instance.new("Frame", ContentFrame)
            s.Size = UDim2.new(0.95, 0, 0, noLine and 25 or 35)
            s.BackgroundTransparency = 1
            s.LayoutOrder = GetO()
            s.Name = title
            s.ClipsDescendants = true
            table.insert(Tab.Elements, s)
            
            local headerBtn = Instance.new("TextButton", s)
            headerBtn.Size = UDim2.new(1, 0, 0, 25)
            headerBtn.Position = UDim2.new(0, 0, 0, 0)
            headerBtn.BackgroundTransparency = 1
            headerBtn.Text = ""
            headerBtn.AutoButtonColor = false
            CreateHoverEffect(headerBtn)
            
            local lbl = Instance.new("TextLabel", headerBtn)
            lbl.Size = UDim2.new(1, -30, 1, 0)
            lbl.Position = UDim2.new(0, 0, 0, 0)
            lbl.Text = title:upper()
            if useAutoContrast then
                lbl.TextColor3 = GetContrastColor(Color3.fromRGB(15, 15, 15))
            else
                lbl.TextColor3 = ACCENT
            end
            lbl.TextTransparency = 0
            lbl.Font = "GothamBold"
            lbl.TextSize = 11
            lbl.TextXAlignment = "Left"
            lbl.BackgroundTransparency = 1
            
            local arrow = Instance.new("TextLabel", headerBtn)
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Position = UDim2.new(1, -25, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            if useAutoContrast then
                arrow.TextColor3 = GetContrastColor(Color3.fromRGB(15, 15, 15))
            else
                arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
            arrow.TextTransparency = 0
            arrow.Font = "GothamMedium"
            arrow.TextSize = 10
            arrow.TextXAlignment = "Center"
            arrow.TextYAlignment = "Center"
            arrow.Name = "Arrow"
            
            local sectionContent = Instance.new("Frame", s)
            sectionContent.Size = UDim2.new(1, 0, 0, 0)
            sectionContent.Position = UDim2.new(0, 0, 0, 25)
            sectionContent.BackgroundTransparency = 1
            sectionContent.Name = "SectionContent"
            local sectionLayout = Instance.new("UIListLayout", sectionContent)
            sectionLayout.Padding = UDim.new(0, 4)
            sectionLayout.HorizontalAlignment = "Center"
            sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            
            local isCollapsed = false
            local contentHeight = 0
            local function updateSectionHeight()
                task.wait()
                contentHeight = sectionLayout.AbsoluteContentSize.Y
                if not isCollapsed then
                    s.Size = UDim2.new(0.95, 0, 0, 25 + contentHeight)
                    sectionContent.Size = UDim2.new(1, 0, 0, contentHeight)
                end
            end
            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSectionHeight)
            
            headerBtn.MouseButton1Click:Connect(function()
                PlaySound("Element")
                CreateClickScaleEffect(headerBtn)
                isCollapsed = not isCollapsed
                arrow.Text = isCollapsed and "▶" or "▼"
                if isCollapsed then
                    TweenService:Create(sectionContent, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 0)
                    }):Play()
                    TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0.95, 0, 0, 25)
                    }):Play()
                else
                    TweenService:Create(sectionContent, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, contentHeight)
                    }):Play()
                    TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0.95, 0, 0, 25 + contentHeight)
                    }):Play()
                end
            end)
            
            if not noLine then
                local line = Instance.new("Frame", s)
                line.Size = UDim2.new(1, 0, 0, 1)
                line.Position = UDim2.new(0, 0, 0, 22)
                line.BackgroundColor3 = ACCENT
                line.BackgroundTransparency = 0.5
                line.BorderSizePixel = 0
            end
            
            Tab._currentSectionContent = sectionContent
            Tab._sectionLayout = sectionLayout
            return s
        end
        
        function Tab:CreateParagraph(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local f = Instance.new("Frame", parent)
            f.Size = UDim2.new(0.95, 0, 0, 65)
            if settings.ElementBackgroundColor then
                f.BackgroundColor3 = settings.ElementBackgroundColor
            else
                f.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            end
            f.BackgroundTransparency = 0.5
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
            f.LayoutOrder = GetO()
            f.Name = opt.Title or ""
            table.insert(Tab.Elements, f)
            
            local title = Instance.new("TextLabel", f)
            title.Size = UDim2.new(1, -20, 0, 25)
            title.Position = UDim2.new(0, 10, 0, 5)
            title.Text = opt.Title or ""
            if useAutoContrast then
                title.TextColor3 = GetContrastColor(f.BackgroundColor3)
            else
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            title.TextTransparency = 0
            title.Font = "GothamBold"
            title.TextSize = 13
            title.BackgroundTransparency = 1
            title.TextXAlignment = "Left"
            
            local content = Instance.new("TextLabel", f)
            content.Size = UDim2.new(1, -20, 0, 30)
            content.Position = UDim2.new(0, 10, 0, 25)
            content.Text = opt.Content or ""
            content.TextColor3 = Color3.fromRGB(200, 200, 200)
            content.TextTransparency = 0
            content.Font = "Gotham"
            content.TextSize = 11
            content.BackgroundTransparency = 1
            content.TextWrapped = true
            content.TextXAlignment = "Left"
            content.TextYAlignment = "Top"
            return f
        end
        
        function Tab:CreateTextBox(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local hasSubtitle = opt.Subtitle and opt.Subtitle ~= ""
            local f = Instance.new("Frame", parent)
            f.Size = UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)
            if settings.ElementBackgroundColor then
                f.BackgroundColor3 = settings.ElementBackgroundColor
            else
                f.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            end
            f.BackgroundTransparency = 0.7
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
            f.LayoutOrder = GetO()
            f.Name = opt.Name or ""
            table.insert(Tab.Elements, f)
            
            local i = Instance.new("TextBox", f)
            i.Size = UDim2.new(1, -20, 0, 35)
            i.Position = UDim2.new(0, 10, 0, 0)
            i.BackgroundTransparency = 1
            i.PlaceholderText = opt.Name
            i.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            i.Text = opt.Default or ""
            if useAutoContrast then
                i.TextColor3 = GetContrastColor(f.BackgroundColor3)
            else
                i.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            i.TextTransparency = 0
            i.Font = "Gotham"
            i.TextSize = 12
            i.TextXAlignment = "Left"
            i.FocusLost:Connect(function() 
                if opt.Callback then 
                    opt.Callback(i.Text) 
                end 
            end)
            if hasSubtitle then
                AddSubtitle(f, opt.Subtitle, 38)
            end
            return i
        end
        
        function Tab:CreateButton(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local hasSubtitle = opt.Subtitle and opt.Subtitle ~= ""
            local b = Instance.new("TextButton", parent)
            b.Size = UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)
            if settings.ElementBackgroundColor then
                b.BackgroundColor3 = settings.ElementBackgroundColor
            else
                b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            end
            b.BackgroundTransparency = 0.6
            b.Text = opt.Name
            if useAutoContrast then
                b.TextColor3 = GetContrastColor(b.BackgroundColor3)
            else
                b.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            b.TextTransparency = 0
            b.Font = "GothamMedium"
            b.TextSize = 12
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            b.LayoutOrder = GetO()
            b.Name = opt.Name
            b.AutoButtonColor = false
            table.insert(Tab.Elements, b)
            
            if opt.Align == false then
                b.TextXAlignment = "Left"
                b.Text = "  " .. opt.Name
                local hint = Instance.new("TextLabel", b)
                hint.Size = UDim2.new(0, 50, 0, 35)
                hint.Position = UDim2.new(1, -55, 0, 0)
                hint.BackgroundTransparency = 1
                hint.Text = "button"
                hint.TextColor3 = Color3.fromRGB(150, 150, 150)
                hint.TextTransparency = 0
                hint.Font = "Gotham"
                hint.TextSize = 10
                hint.TextXAlignment = "Right"
                hint.TextYAlignment = "Center"
                hint.ZIndex = 2
            else
                b.TextXAlignment = "Center"
            end
            
            if hasSubtitle then
                AddSubtitle(b, opt.Subtitle, 38)
            end
            
            b.MouseButton1Click:Connect(function()
                PlaySound("Element")
                CreateClickScaleEffect(b)
                if opt.Callback then 
                    opt.Callback() 
                end
            end)
            return b
        end
        
        function Tab:CreateToggle(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local hasSubtitle = opt.Subtitle and opt.Subtitle ~= ""
            local s = opt.Default or false
            local t = Instance.new("TextButton", parent)
            t.Size = UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)
            if settings.ElementBackgroundColor then
                t.BackgroundColor3 = settings.ElementBackgroundColor
            else
                t.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            end
            t.BackgroundTransparency = 0.6
            t.Text = "  " .. opt.Name
            if useAutoContrast then
                t.TextColor3 = s and GetContrastColor(t.BackgroundColor3) or Color3.fromRGB(180, 180, 180)
            else
                t.TextColor3 = s and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
            end
            t.TextTransparency = 0
            t.TextXAlignment = "Left"
            t.TextSize = 12
            t.Font = "GothamMedium"
            Instance.new("UICorner", t).CornerRadius = UDim.new(0, 8)
            t.LayoutOrder = GetO()
            t.Name = opt.Name
            t.AutoButtonColor = false
            table.insert(Tab.Elements, t)
            
            local bx = Instance.new("Frame", t)
            bx.Size = UDim2.new(0, 30, 0, 16)
            bx.Position = UDim2.new(1, -40, 0.5, hasSubtitle and -15 or -8)
            bx.BackgroundColor3 = s and ACCENT or Color3.fromRGB(40, 40, 40)
            bx.BackgroundTransparency = 0.3
            Instance.new("UICorner", bx).CornerRadius = UDim.new(1, 0)
            
            if hasSubtitle then
                AddSubtitle(t, opt.Subtitle, 38)
            end
            
            t.MouseButton1Click:Connect(function()
                PlaySound("Element")
                CreateClickScaleEffect(t)
                s = not s
                if useAutoContrast then
                    t.TextColor3 = s and GetContrastColor(t.BackgroundColor3) or Color3.fromRGB(180, 180, 180)
                else
                    t.TextColor3 = s and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
                end
                TweenService:Create(bx, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    BackgroundColor3 = s and ACCENT or Color3.fromRGB(40, 40, 40)
                }):Play()
                if opt.Callback then 
                    opt.Callback(s) 
                end
            end)
            return t
        end
        
        function Tab:CreateSlider(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local hasSubtitle = opt.Subtitle and opt.Subtitle ~= ""
            local range = opt.range or {0, 100}
            local min = range[1]
            local max = range[2]
            local increment = opt.increment or 1
            local defaultValue = opt.Default or min
            defaultValue = math.floor((defaultValue - min) / increment) * increment + min
            defaultValue = math.clamp(defaultValue, min, max)
            
            local f = Instance.new("Frame", parent)
            f.Size = UDim2.new(0.95, 0, 0, hasSubtitle and 70 or 50)
            if settings.ElementBackgroundColor then
                f.BackgroundColor3 = settings.ElementBackgroundColor
            else
                f.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            end
            f.BackgroundTransparency = 0.7
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
            f.LayoutOrder = GetO()
            f.Name = opt.Name or ""
            table.insert(Tab.Elements, f)
            
            local l = Instance.new("TextLabel", f)
            l.Size = UDim2.new(1, 0, 0, 20)
            l.Position = UDim2.new(0, 12, 0, hasSubtitle and 5 or 5)
            l.BackgroundTransparency = 1
            l.Text = opt.Name .. ": " .. defaultValue
            if useAutoContrast then
                l.TextColor3 = GetContrastColor(f.BackgroundColor3)
            else
                l.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            l.TextTransparency = 0
            l.TextXAlignment = "Left"
            l.TextSize = 11
            l.Font = "GothamMedium"
            
            local sbg = Instance.new("Frame", f)
            sbg.Size = UDim2.new(0.9, 0, 0, 8)
            sbg.Position = UDim2.new(0.05, 0, hasSubtitle and 0.55 or 0.7, 0)
            sbg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            sbg.BackgroundTransparency = 0.5
            Instance.new("UICorner", sbg)
            
            local fill = Instance.new("Frame", sbg)
            local percent = (defaultValue - min) / (max - min)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            fill.BackgroundColor3 = ACCENT
            Instance.new("UICorner", fill)
            
            if hasSubtitle then
                AddSubtitle(f, opt.Subtitle, 48)
            end
            
            local isHeld = false
            local function UpdateSlider(input)
                local p = math.clamp((input.Position.X - sbg.AbsolutePosition.X) / sbg.AbsoluteSize.X, 0, 1)
                local rawValue = min + (max - min) * p
                local v = math.floor((rawValue - min) / increment) * increment + min
                v = math.clamp(v, min, max)
                local newPercent = (v - min) / (max - min)
                TweenService:Create(fill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(newPercent, 0, 1, 0)
                }):Play()
                l.Text = opt.Name .. ": " .. v
                if opt.Callback then 
                    opt.Callback(v) 
                end
            end
            
            sbg.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    isHeld = true
                    UpdateSlider(i)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    isHeld = false
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if isHeld and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(i)
                end
            end)
            return f
        end
        
        function Tab:CreateColorPicker(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local hasSubtitle = opt.Subtitle and opt.Subtitle ~= ""
            local ColorSelected = opt.Default or Color3.fromRGB(170, 85, 255)
            local h, s, v = ColorSelected:ToHSV()
            local open = false
            
            local f = Instance.new("Frame", parent)
            f.Size = UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)
            if settings.ElementBackgroundColor then
                f.BackgroundColor3 = settings.ElementBackgroundColor
            else
                f.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            end
            f.BackgroundTransparency = 0.7
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
            f.LayoutOrder = GetO()
            f.ClipsDescendants = true
            f.Name = opt.Name or ""
            table.insert(Tab.Elements, f)
            
            local t = Instance.new("TextLabel", f)
            t.Size = UDim2.new(1, 0, 0, 35)
            t.Position = UDim2.new(0, 12, 0, 0)
            t.BackgroundTransparency = 1
            t.Text = opt.Name
            if useAutoContrast then
                t.TextColor3 = GetContrastColor(f.BackgroundColor3)
            else
                t.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            t.TextTransparency = 0
            t.Font = "GothamMedium"
            t.TextSize = 12
            t.TextXAlignment = "Left"
            
            local pvw = Instance.new("TextButton", f)
            pvw.Size = UDim2.new(0, 40, 0, 18)
            pvw.Position = UDim2.new(1, -50, 0, hasSubtitle and 8.5 or 8.5)
            pvw.BackgroundColor3 = ColorSelected
            pvw.Text = ""
            Instance.new("UICorner", pvw).CornerRadius = UDim.new(0, 4)
            pvw.AutoButtonColor = false
            
            if hasSubtitle then
                AddSubtitle(f, opt.Subtitle, 38)
            end
            
            local Holder = Instance.new("Frame", f)
            Holder.Size = UDim2.new(1, 0, 0, 140)
            Holder.Position = UDim2.new(0, 0, 0, 35)
            Holder.BackgroundTransparency = 1
            
            local satBox = Instance.new("ImageButton", Holder)
            satBox.Size = UDim2.new(0.9, 0, 0, 100)
            satBox.Position = UDim2.new(0.05, 0, 0, 5)
            satBox.Image = "rbxassetid://4155801252"
            satBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            Instance.new("UICorner", satBox).CornerRadius = UDim.new(0, 6)
            satBox.AutoButtonColor = false
            
            local cursor = Instance.new("Frame", satBox)
            cursor.Size = UDim2.new(0, 10, 0, 10)
            cursor.AnchorPoint = Vector2.new(0.5, 0.5)
            cursor.BackgroundColor3 = Color3.new(1, 1, 1)
            cursor.Position = UDim2.new(s, 0, 1 - v, 0)
            Instance.new("UICorner", cursor).CornerRadius = UDim.new(1, 0)
            cursor.BorderSizePixel = 1
            cursor.BorderColor3 = Color3.fromRGB(50, 50, 50)
            
            local hueSlide = Instance.new("ImageButton", Holder)
            hueSlide.Size = UDim2.new(0.9, 0, 0, 14)
            hueSlide.Position = UDim2.new(0.05, 0, 0, 115)
            Instance.new("UICorner", hueSlide).CornerRadius = UDim.new(0, 6)
            hueSlide.AutoButtonColor = false
            
            local hueGradient = Instance.new("UIGradient", hueSlide)
            local hueColorSequence = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
            hueGradient.Color = hueColorSequence
            
            local hCursor = Instance.new("Frame", hueSlide)
            hCursor.Size = UDim2.new(0, 4, 1, 4)
            hCursor.Position = UDim2.new(h, 0, 0.5, 0)
            hCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", hCursor)
            hCursor.BorderSizePixel = 1
            hCursor.BorderColor3 = Color3.fromRGB(50, 50, 50)
            
            local function UpdateColor()
                local finalCol = Color3.fromHSV(h, s, v)
                pvw.BackgroundColor3 = finalCol
                satBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                cursor.Position = UDim2.new(s, 0, 1 - v, 0)
                hCursor.Position = UDim2.new(h, 0, 0.5, 0)
                local lightness = (s + v) / 2
                if lightness > 0.6 then
                    cursor.BackgroundColor3 = Color3.new(0, 0, 0)
                else
                    cursor.BackgroundColor3 = Color3.new(1, 1, 1)
                end
                if opt.Callback then 
                    pcall(function() opt.Callback(finalCol) end)
                end
            end
            
            local isDraggingSat = false
            satBox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingSat = true
                    local relativeX = math.clamp((input.Position.X - satBox.AbsolutePosition.X) / satBox.AbsoluteSize.X, 0, 1)
                    local relativeY = math.clamp((input.Position.Y - satBox.AbsolutePosition.Y) / satBox.AbsoluteSize.Y, 0, 1)
                    s = math.clamp(relativeX, 0, 1)
                    v = math.clamp(1 - relativeY, 0, 1)
                    UpdateColor()
                end
            end)
            
            local isDraggingHue = false
            hueSlide.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingHue = true
                    local relativeX = math.clamp((input.Position.X - hueSlide.AbsolutePosition.X) / hueSlide.AbsoluteSize.X, 0, 1)
                    h = math.clamp(relativeX, 0, 1)
                    UpdateColor()
                end
            end)
            
            UIS.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if isDraggingSat then
                        local relativeX = math.clamp((input.Position.X - satBox.AbsolutePosition.X) / satBox.AbsoluteSize.X, 0, 1)
                        local relativeY = math.clamp((input.Position.Y - satBox.AbsolutePosition.Y) / satBox.AbsoluteSize.Y, 0, 1)
                        s = math.clamp(relativeX, 0, 1)
                        v = math.clamp(1 - relativeY, 0, 1)
                        UpdateColor()
                    elseif isDraggingHue then
                        local relativeX = math.clamp((input.Position.X - hueSlide.AbsolutePosition.X) / hueSlide.AbsoluteSize.X, 0, 1)
                        h = math.clamp(relativeX, 0, 1)
                        UpdateColor()
                    end
                end
            end)
            
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isDraggingSat = false
                    isDraggingHue = false
                end
            end)
            
            pvw.MouseButton1Click:Connect(function()
                PlaySound("Element")
                CreateClickScaleEffect(pvw)
                open = not open
                TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = open and UDim2.new(0.95, 0, 0, 180) or UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)
                }):Play()
            end)
            UpdateColor()
            return f
        end
        
        function Tab:CreateDropdown(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local hasSubtitle = opt.Subtitle and opt.Subtitle ~= ""
            local d = Instance.new("Frame", parent)
            d.Size = UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)
            if settings.ElementBackgroundColor then
                d.BackgroundColor3 = settings.ElementBackgroundColor
            else
                d.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
            end
            d.BackgroundTransparency = 0.7
            Instance.new("UICorner", d).CornerRadius = UDim.new(0, 8)
            d.LayoutOrder = GetO()
            d.ClipsDescendants = true
            d.Name = opt.Name or ""
            table.insert(Tab.Elements, d)
            
            local t = Instance.new("TextButton", d)
            t.Name = "DropdownButton"
            t.Size = UDim2.new(1, 0, 0, 35)
            t.BackgroundTransparency = 1
            t.Text = "  " .. opt.Name .. " : " .. (opt.Default or (opt.Options and opt.Options[1] or "Đang tải..."))
            if useAutoContrast then
                t.TextColor3 = GetContrastColor(d.BackgroundColor3)
            else
                t.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            t.TextTransparency = 0
            t.Font = "GothamMedium"
            t.TextSize = 12
            t.TextXAlignment = "Left"
            t.AutoButtonColor = false
            CreateHoverEffect(t)
            
            local Arrow = Instance.new("TextLabel", t)
            Arrow.Name = "ArrowLabel"
            Arrow.Size = UDim2.new(0, 30, 1, 0)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            if useAutoContrast then
                Arrow.TextColor3 = GetContrastColor(d.BackgroundColor3)
            else
                Arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
            end
            Arrow.TextTransparency = 0
            Arrow.Font = "GothamMedium"
            Arrow.TextSize = 14
            Arrow.TextXAlignment = "Center"
            
            if hasSubtitle then
                AddSubtitle(d, opt.Subtitle, 38)
            end
            
            local il = Instance.new("ScrollingFrame", d)
            il.Name = "OptionsList"
            il.Size = UDim2.new(1, 0, 0, 120)
            il.Position = UDim2.new(0, 0, 0, 35)
            il.BackgroundTransparency = 1
            il.ScrollBarThickness = 2
            il.AutomaticCanvasSize = "Y"
            il.Visible = false
            local ilLayout = Instance.new("UIListLayout", il)
            ilLayout.Padding = UDim.new(0, 2)
            
            local function refreshOptions()
                if not opt.GetOptions then return end
                local newOptions = opt.GetOptions()
                if not newOptions then return end
                for _, child in pairs(il:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                for _, option in pairs(newOptions) do
                    local it = Instance.new("TextButton", il)
                    it.Size = UDim2.new(1, 0, 0, 30)
                    if settings.ElementBackgroundColor then
                        it.BackgroundColor3 = settings.ElementBackgroundColor
                    else
                        it.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                    end
                    it.BackgroundTransparency = 0.5
                    it.Text = option
                    if useAutoContrast then
                        it.TextColor3 = GetContrastColor(it.BackgroundColor3)
                    else
                        it.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                    it.TextTransparency = 0
                    it.Font = "GothamMedium"
                    it.TextSize = 11
                    it.AutoButtonColor = false
                    it.MouseButton1Click:Connect(function()
                        PlaySound("Element")
                        CreateClickScaleEffect(it)
                        il.Visible = false
                        Arrow.Text = "▼"
                        t.Text = "  " .. opt.Name .. " : " .. option
                        TweenService:Create(d, TweenInfo.new(0.3), {Size = UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)}):Play()
                        if opt.Callback then 
                            opt.Callback(option) 
                        end
                    end)
                end
                task.wait()
                local optionCount = math.min(#newOptions, 4)
                il.Size = UDim2.new(1, 0, 0, optionCount * 32)
                if opt.Default then
                    t.Text = "  " .. opt.Name .. " : " .. opt.Default
                elseif newOptions[1] then
                    t.Text = "  " .. opt.Name .. " : " .. newOptions[1]
                end
            end
            
            local open = false
            t.MouseButton1Click:Connect(function()
                PlaySound("Element")
                CreateClickScaleEffect(t)
                open = not open
                il.Visible = open
                Arrow.Text = open and "▲" or "▼"
                if open and opt.RefreshOnOpen then
                    refreshOptions()
                end
                TweenService:Create(d, TweenInfo.new(0.3), {Size = open and UDim2.new(0.95, 0, 0, 35 + il.Size.Y.Offset + (hasSubtitle and 20 or 0)) or UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)}):Play()
            end)
            
            if opt.GetOptions then
                refreshOptions()
            elseif opt.Options then
                for _, v in pairs(opt.Options) do
                    local it = Instance.new("TextButton", il)
                    it.Size = UDim2.new(1, 0, 0, 30)
                    if settings.ElementBackgroundColor then
                        it.BackgroundColor3 = settings.ElementBackgroundColor
                    else
                        it.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
                    end
                    it.BackgroundTransparency = 0.5
                    it.Text = v
                    if useAutoContrast then
                        it.TextColor3 = GetContrastColor(it.BackgroundColor3)
                    else
                        it.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                    it.TextTransparency = 0
                    it.Font = "GothamMedium"
                    it.TextSize = 11
                    it.AutoButtonColor = false
                    it.MouseButton1Click:Connect(function()
                        PlaySound("Element")
                        CreateClickScaleEffect(it)
                        open = false
                        il.Visible = false
                        Arrow.Text = "▼"
                        t.Text = "  " .. opt.Name .. " : " .. v
                        TweenService:Create(d, TweenInfo.new(0.3), {Size = UDim2.new(0.95, 0, 0, hasSubtitle and 55 or 35)}):Play()
                        if opt.Callback then 
                            opt.Callback(v) 
                        end
                    end)
                end
                local optionCount = math.min(#opt.Options, 4)
                il.Size = UDim2.new(1, 0, 0, optionCount * 32)
            end
            
            if opt.RefreshInterval and opt.GetOptions then
                local refreshConnection = RunService.RenderStepped:Connect(function()
                    if d and d.Parent then
                        local newOptions = opt.GetOptions()
                        if newOptions then
                            local currentCount = 0
                            for _, child in pairs(il:GetChildren()) do
                                if child:IsA("TextButton") then 
                                    currentCount = currentCount + 1 
                                end
                            end
                            if currentCount ~= #newOptions then
                                refreshOptions()
                            end
                        end
                    else
                        refreshConnection:Disconnect()
                    end
                end)
                table.insert(Tab.Connections, refreshConnection)
                table.insert(NoirUI.Connections, refreshConnection)
            end
            return d
        end
        
        function Tab:CreateRunBox(opt)
            local parent = Tab._currentSectionContent or ContentFrame
            local f = Instance.new("Frame", parent)
            f.Size = UDim2.new(0.95, 0, 0, 38)
            if settings.ElementBackgroundColor then
                f.BackgroundColor3 = settings.ElementBackgroundColor
            else
                f.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            end
            f.BackgroundTransparency = 0.7
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
            f.LayoutOrder = GetO()
            f.Name = "RunBox"
            table.insert(Tab.Elements, f)
            
            local i = Instance.new("TextBox", f)
            i.Size = UDim2.new(1, -65, 1, 0)
            i.Position = UDim2.new(0, 10, 0, 0)
            i.BackgroundTransparency = 1
            i.PlaceholderText = opt.Placeholder or "Nhập: .cmd, loadstring('url'), or lua code"
            i.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
            i.Text = ""
            if useAutoContrast then
                i.TextColor3 = GetContrastColor(f.BackgroundColor3)
            else
                i.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            i.TextTransparency = 0
            i.Font = "Gotham"
            i.TextSize = 11
            i.TextXAlignment = "Left"
            i.ClearTextOnFocus = false
            
            local r = Instance.new("TextButton", f)
            r.Size = UDim2.new(0, 50, 0, 26)
            r.Position = UDim2.new(1, -55, 0.5, -13)
            r.BackgroundColor3 = ACCENT
            r.Text = "RUN"
            if useAutoContrast then
                r.TextColor3 = GetContrastColor(ACCENT)
            else
                r.TextColor3 = Color3.new(1,1,1)
            end
            r.TextTransparency = 0
            r.Font = "GothamBold"
            r.TextSize = 10
            Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)
            r.AutoButtonColor = false
            
            r.MouseButton1Click:Connect(function()
                PlaySound("Element")
                CreateClickScaleEffect(r)
                local input = i.Text
                if input == "" then return end
                
                if input:sub(1, 1) == "." then
                    local parts = {}
                    for part in input:sub(2):gmatch("%S+") do
                        table.insert(parts, part)
                    end
                    local cmd = parts[1] and parts[1]:lower() or ""
                    local args = {}
                    for j = 2, #parts do
                        table.insert(args, parts[j])
                    end
                    local customCallback = NoirUI.CustomCommands[cmd]
                    if customCallback then
                        local success, err = pcall(function()
                            customCallback(args)
                        end)
                        if not success then
                            NoirUI:Notify("Command Error", err or "Lỗi không xác định", nil, "Error")
                        end
                    else
                        NoirUI:Notify("❌ Unknown Command", "Không tìm thấy lệnh: ." .. cmd, nil, "Error")
                    end
                elseif input:lower():match("loadstring") then
                    local str = input:match("loadstring%((.+)%)")
                    if str then
                        local cleaned = str:gsub("^[\"'](.*)[\"']$", "%1")
                        local success, err = loadstring(cleaned)
                        if success then
                            success()
                            NoirUI:Notify("Loadstring", "Đã chạy thành công!", nil, "Success")
                        else
                            NoirUI:Notify("Loadstring Error", err or "Lỗi cú pháp", nil, "Error")
                        end
                    else
                        NoirUI:Notify("Loadstring Error", "Cú pháp không hợp lệ", nil, "Error")
                    end
                else
                    local success, err = loadstring(input)
                    if success then
                        success()
                        NoirUI:Notify("Execute", "Code đã chạy thành công!", nil, "Success")
                    else
                        NoirUI:Notify("Error", err or "Lỗi cú pháp", nil, "Error")
                    end
                end
                if opt.ClearOnExecute then
                    i.Text = ""
                end
            end)
            return f
        end
        
        -- Store button reference for TabGroup
        Tab._button = B
        
        return Tab
    end
    
    -- ============================================
    -- TAB GROUP
    -- ============================================
    
    function Window:CreateTabGroup(title, defaultOpen)
        local group = {}
        local isOpen = defaultOpen ~= false
        
        local groupFrame = Instance.new("Frame", TScroll)
        groupFrame.Size = UDim2.new(1, -5, 0, 0)
        groupFrame.BackgroundTransparency = 1
        groupFrame.ClipsDescendants = true
        groupFrame.LayoutOrder = #TScroll:GetChildren() + 1
        
        local header = Instance.new("TextButton", groupFrame)
        header.Size = UDim2.new(1, 0, 0, 28)
        header.BackgroundTransparency = 1
        header.Text = ""
        header.AutoButtonColor = false
        CreateHoverEffect(header)
        
        local titleLabel = Instance.new("TextLabel", header)
        titleLabel.Size = UDim2.new(1, -30, 1, 0)
        titleLabel.Position = UDim2.new(0, 8, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title:upper()
        titleLabel.TextColor3 = ACCENT
        titleLabel.TextTransparency = 0
        titleLabel.Font = "GothamBold"
        titleLabel.TextSize = 11
        titleLabel.TextXAlignment = "Left"
        
        local arrow = Instance.new("TextLabel", header)
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -25, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = isOpen and "▼" or "▶"
        arrow.TextColor3 = Color3.fromRGB(180, 180, 180)
        arrow.TextTransparency = 0
        arrow.Font = "GothamMedium"
        arrow.TextSize = 10
        arrow.TextXAlignment = "Center"
        arrow.TextYAlignment = "Center"
        arrow.Name = "Arrow"
        
        local content = Instance.new("Frame", groupFrame)
        content.Size = UDim2.new(1, 0, 0, 0)
        content.Position = UDim2.new(0, 0, 0, 28)
        content.BackgroundTransparency = 1
        content.Name = "TabGroupContent"
        local contentLayout = Instance.new("UIListLayout", content)
        contentLayout.Padding = UDim.new(0, 2)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        function group:CreateTab(name, icon)
            local tab = Window:CreateTab(name, icon)
            local btn = tab._button
            if btn then
                btn.Parent = content
                btn.Position = UDim2.new(0, 15, 0, 0)
                btn.Size = UDim2.new(1, -5, 0, 32)
                if settings.TabBackgroundColor then
                    btn.BackgroundColor3 = settings.TabBackgroundColor
                end
            end
            task.wait()
            local contentHeight = contentLayout.AbsoluteContentSize.Y + 10
            if isOpen then
                content.Size = UDim2.new(1, 0, 0, contentHeight)
                groupFrame.Size = UDim2.new(1, -5, 0, 28 + contentHeight)
            end
            updateSidebarCanvas()
            return tab
        end
        
        header.MouseButton1Click:Connect(function()
            PlaySound("Element")
            CreateClickScaleEffect(header)
            isOpen = not isOpen
            arrow.Text = isOpen and "▼" or "▶"
            local targetHeight = isOpen and (contentLayout.AbsoluteContentSize.Y + 10) or 0
            TweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, targetHeight)
            }):Play()
            local totalHeight = 28 + targetHeight
            TweenService:Create(groupFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -5, 0, totalHeight)
            }):Play()
            updateSidebarCanvas()
        end)
        
        task.wait()
        local contentHeight = contentLayout.AbsoluteContentSize.Y + 10
        content.Size = UDim2.new(1, 0, 0, isOpen and contentHeight or 0)
        groupFrame.Size = UDim2.new(1, -5, 0, 28 + (isOpen and contentHeight or 0))
        
        table.insert(NoirUI.TabGroups, group)
        return group
    end
    
    -- ============================================
    -- WINDOW API
    -- ============================================
    
    function Window:Close()
        CloseUI()
        return self
    end
    
    function Window:Open()
        OpenUI()
        return self
    end
    
    function Window:Toggle()
        ToggleUI()
        return self
    end
    
    function Window:Destroy()
        NoirAnimations:StopAll()
        for _, conn in pairs(Connections) do
            pcall(function() conn:Disconnect() end)
        end
        ScreenGui:Destroy()
        return self
    end
    
    function Window:GetEvents()
        return Events
    end
    
    function Window:GetState()
        return AnimationState.Current
    end
    
    function Window:GetAnimations()
        return AnimationConfig
    end
    
    -- Update sidebar canvas
    task.wait()
    updateSidebarCanvas()
    
    return Window
end

-- ============================================
-- RETURN
-- ============================================

return NoirUI
