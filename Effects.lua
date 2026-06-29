-- ============================================
-- NoirUI - Effects Module
-- ============================================
local Effects = {}

-- ============================================
-- 1. RIPPLE EFFECT
-- ============================================
function Effects.CreateRipple(button, color, duration)
    duration = duration or 0.5
    color = color or Color3.fromRGB(255, 255, 255)
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    
    local connection
    connection = button.MouseButton1Click:Connect(function()
        local oldRipple = button:FindFirstChild("RippleEffect")
        if oldRipple then oldRipple:Destroy() end
        
        local ripple = Instance.new("Frame", button)
        ripple.Name = "RippleEffect"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.BackgroundColor3 = color
        ripple.BackgroundTransparency = 0.6
        ripple.ZIndex = 10
        ripple.ClipsDescendants = false
        
        local corner = Instance.new("UICorner", ripple)
        corner.CornerRadius = UDim.new(1, 0)
        
        local mousePos = UIS:GetMouseLocation()
        local absPos = button.AbsolutePosition
        local x = (mousePos.X - absPos.X) / button.AbsoluteSize.X
        local y = (mousePos.Y - absPos.Y) / button.AbsoluteSize.Y
        
        ripple.Position = UDim2.new(x, 0, y, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 0.8
        
        TweenService:Create(ripple, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
            Position = UDim2.new(x, 0, y, 0)
        }):Play()
        
        task.delay(duration + 0.1, function()
            if ripple and ripple.Parent then
                ripple:Destroy()
            end
        end)
    end)
    
    return connection
end

-- ============================================
-- 2. NEON PULSE
-- ============================================
function Effects.CreateNeonPulse(frame, color, speed)
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    
    local stroke = frame:FindFirstChildWhichIsA("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke", frame)
        stroke.Thickness = 2
        stroke.Color = color or Color3.fromRGB(170, 85, 255)
    end
    
    local pulse = 0
    local conn = RunService.RenderStepped:Connect(function()
        if not frame.Parent then conn:Disconnect() return end
        pulse = (pulse + (speed or 0.02)) % 1
        local alpha = math.abs(math.sin(pulse * math.pi))
        stroke.Transparency = 1 - alpha
        stroke.Thickness = 1 + alpha * 3
    end)
    
    return conn
end

-- ============================================
-- 3. GLOW STROKE
-- ============================================
function Effects.AddGlowStroke(parent, accentColor, baseThickness, glowThickness, glowTransparency)
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
-- 4. GLOW AURA
-- ============================================
function Effects.CreateUIGlow(frame, color, intensity, parent)
    local RunService = game:GetService("RunService")
    if not frame then return nil end
    if not parent then parent = frame.Parent end
    
    local oldGlow = frame:FindFirstChild("_UIGlow")
    if oldGlow then oldGlow:Destroy() end
    
    local glow = Instance.new("Frame", parent)
    glow.Name = "_UIGlow"
    glow.Size = frame.Size + UDim2.new(0, 30, 0, 30)
    glow.Position = frame.Position - UDim2.new(0, 15, 0, 15)
    glow.BackgroundTransparency = 1
    glow.ZIndex = frame.ZIndex - 1
    glow.Visible = frame.Visible
    glow.ClipsDescendants = false
    
    local glow1 = Instance.new("ImageLabel", glow)
    glow1.Size = UDim2.new(1, 0, 1, 0)
    glow1.Position = UDim2.new(0, 0, 0, 0)
    glow1.BackgroundTransparency = 1
    glow1.Image = "rbxassetid://1312311753"
    glow1.ImageColor3 = color or Color3.fromRGB(170, 85, 255)
    glow1.ImageTransparency = 0.3 - (intensity or 0.3)
    glow1.ScaleType = Enum.ScaleType.Slice
    glow1.SliceCenter = Rect.new(15, 15, 15, 15)
    glow1.ZIndex = 0
    
    local glow2 = Instance.new("ImageLabel", glow)
    glow2.Size = UDim2.new(0.9, 0, 0.9, 0)
    glow2.Position = UDim2.new(0.05, 0, 0.05, 0)
    glow2.BackgroundTransparency = 1
    glow2.Image = "rbxassetid://1312311753"
    glow2.ImageColor3 = color or Color3.fromRGB(170, 85, 255)
    glow2.ImageTransparency = 0.5 - (intensity or 0.3)
    glow2.ScaleType = Enum.ScaleType.Slice
    glow2.SliceCenter = Rect.new(12, 12, 12, 12)
    glow2.ZIndex = 1
    
    local glow3 = Instance.new("ImageLabel", glow)
    glow3.Size = UDim2.new(0.8, 0, 0.8, 0)
    glow3.Position = UDim2.new(0.1, 0, 0.1, 0)
    glow3.BackgroundTransparency = 1
    glow3.Image = "rbxassetid://1312311753"
    glow3.ImageColor3 = color or Color3.fromRGB(170, 85, 255)
    glow3.ImageTransparency = 0.7 - (intensity or 0.3)
    glow3.ScaleType = Enum.ScaleType.Slice
    glow3.SliceCenter = Rect.new(10, 10, 10, 10)
    glow3.ZIndex = 2
    
    local connection = RunService.RenderStepped:Connect(function()
        if not frame or not frame.Parent then
            connection:Disconnect()
            return
        end
        glow.Size = frame.Size + UDim2.new(0, 30, 0, 30)
        glow.Position = frame.Position - UDim2.new(0, 15, 0, 15)
        glow.Visible = frame.Visible
        glow.ZIndex = frame.ZIndex - 1
    end)
    
    return glow, connection
end

-- ============================================
-- 5. PARTICLE BACKGROUND
-- ============================================
function Effects.CreateParticles(parent, color, count)
    local RunService = game:GetService("RunService")
    count = count or 30
    color = color or Color3.fromRGB(170, 85, 255)
    local particles = {}
    
    for i = 1, count do
        local particle = Instance.new("Frame", parent)
        particle.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
        particle.BackgroundColor3 = color
        particle.BackgroundTransparency = 0.5
        Instance.new("UICorner", particle).CornerRadius = UDim.new(1, 0)
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.ZIndex = 0
        
        local speedX = (math.random() - 0.5) * 0.5
        local speedY = (math.random() - 0.5) * 0.5
        table.insert(particles, { obj = particle, speedX = speedX, speedY = speedY })
    end
    
    local conn = RunService.RenderStepped:Connect(function()
        for _, p in ipairs(particles) do
            if not p.obj.Parent then continue end
            local newX = p.obj.Position.X.Scale + p.speedX * 0.01
            local newY = p.obj.Position.Y.Scale + p.speedY * 0.01
            if newX > 1 or newX < 0 then p.speedX = -p.speedX end
            if newY > 1 or newY < 0 then p.speedY = -p.speedY end
            p.obj.Position = UDim2.new(newX, 0, newY, 0)
        end
    end)
    
    return conn
end

-- ============================================
-- 6. GLITCH EFFECT
-- ============================================
function Effects.CreateGlitch(label, interval)
    local RunService = game:GetService("RunService")
    interval = interval or 2
    local originalText = label.Text
    local glitchChars = {"█", "▓", "▒", "░", "■", "□", "▄", "▀"}
    
    local conn = RunService.Heartbeat:Connect(function()
        if not label.Parent then conn:Disconnect() return end
        if math.random() > 0.05 then return end
        
        local glitch = ""
        for i = 1, #originalText do
            if math.random() < 0.3 then
                glitch = glitch .. glitchChars[math.random(#glitchChars)]
            else
                glitch = glitch .. originalText:sub(i, i)
            end
        end
        label.Text = glitch
        label.TextColor3 = Color3.fromRGB(255 - math.random(0, 50), 255 - math.random(0, 50), 255 - math.random(0, 50))
        task.delay(0.05, function()
            label.Text = originalText
            label.TextColor3 = Color3.new(1,1,1)
        end)
    end)
    
    return conn
end

-- ============================================
-- 7. GLOW TEXT SLIDE
-- ============================================
function Effects.CreateGlowText(label, colors, speed)
    local RunService = game:GetService("RunService")
    if not label then return nil end
    
    local gradient = Instance.new("UIGradient", label)
    local colorKeypoints = {}
    for i, color in ipairs(colors or {Color3.fromRGB(200,200,200), Color3.fromRGB(255,255,255), Color3.fromRGB(200,200,200)}) do
        local position = (i - 1) / (#colors - 1)
        table.insert(colorKeypoints, ColorSequenceKeypoint.new(position, color))
    end
    gradient.Color = ColorSequence.new(colorKeypoints)
    gradient.Transparency = NumberSequence.new(0)
    gradient.Rotation = 30
    
    speed = speed or 1.5
    local connection = RunService.RenderStepped:Connect(function()
        if not label or not label.Parent then
            connection:Disconnect()
            return
        end
        local offset = (tick() * speed) % 2 - 1
        gradient.Offset = Vector2.new(offset, 0)
    end)
    
    return gradient, connection
end

-- ============================================
-- 8. CONFETTI BURST
-- ============================================
function Effects.CreateConfetti(parent, count, colors)
    local TweenService = game:GetService("TweenService")
    count = count or 30
    colors = colors or {
        Color3.fromRGB(255, 50, 50),
        Color3.fromRGB(50, 255, 50),
        Color3.fromRGB(50, 50, 255),
        Color3.fromRGB(255, 255, 50)
    }
    
    for i = 1, count do
        local confetti = Instance.new("Frame", parent)
        confetti.Size = UDim2.new(0, math.random(4, 8), 0, math.random(4, 8))
        confetti.BackgroundColor3 = colors[math.random(#colors)]
        Instance.new("UICorner", confetti).CornerRadius = UDim.new(0, math.random(0, 4))
        confetti.Position = UDim2.new(0.5, 0, 0.5, 0)
        confetti.BackgroundTransparency = 0.8
        confetti.ZIndex = 100
        
        local angle = math.rad(math.random(0, 360))
        local distance = math.random(50, 200)
        local targetX = math.cos(angle) * distance
        local targetY = math.sin(angle) * distance
        
        TweenService:Create(confetti, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, targetX, 0.5, targetY),
            BackgroundTransparency = 1,
            Rotation = math.random(0, 720)
        }):Play()
        
        task.delay(1.8, function() confetti:Destroy() end)
    end
end

-- ============================================
-- 9. TYPING EFFECT
-- ============================================
function Effects.CreateTyping(label, text, speed)
    local RunService = game:GetService("RunService")
    speed = speed or 0.05
    local currentText = ""
    label.Text = ""
    
    local conn = RunService.Heartbeat:Connect(function()
        if not label.Parent then conn:Disconnect() return end
        if #currentText < #text then
            currentText = text:sub(1, #currentText + 1)
            label.Text = currentText
        else
            conn:Disconnect()
        end
    end)
    
    return conn
end

-- ============================================
-- 10. POP EFFECT
-- ============================================
function Effects.Pop(frame, scale)
    local TweenService = game:GetService("TweenService")
    scale = scale or 1.2
    local origSize = frame.Size
    
    TweenService:Create(frame, TweenInfo.new(0.15), {
        Size = UDim2.new(origSize.X.Scale, origSize.X.Offset * scale, origSize.Y.Scale, origSize.Y.Offset * scale)
    }):Play()
    task.wait(0.15)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = origSize
    }):Play()
end

-- ============================================
-- 11. BOUNCE EFFECT
-- ============================================
function Effects.Bounce(frame, height, duration)
    local TweenService = game:GetService("TweenService")
    height = height or 20
    duration = duration or 0.5
    local startPos = frame.Position
    
    TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset, startPos.Y.Scale, startPos.Y.Offset - height)
    }):Play()
end

-- ============================================
-- 12. SLIDE IN EFFECT
-- ============================================
function Effects.SlideIn(frame, direction, duration)
    local TweenService = game:GetService("TweenService")
    direction = direction or "left"
    duration = duration or 0.4
    local pos = frame.Position
    local offset = 50
    
    if direction == "left" then
        frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset - offset, pos.Y.Scale, pos.Y.Offset)
    elseif direction == "right" then
        frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset + offset, pos.Y.Scale, pos.Y.Offset)
    elseif direction == "top" then
        frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - offset)
    elseif direction == "bottom" then
        frame.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + offset)
    end
    
    frame.BackgroundTransparency = 1
    frame.Visible = true
    
    TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = pos,
        BackgroundTransparency = 0
    }):Play()
end

return Effects
