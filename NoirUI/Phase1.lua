local NoirUI = {}
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 1. Hàm load icon từ GitHub
local LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/icons.lua"))()
local function ResolveIcon(iconInput)
    if not iconInput then return "rbxassetid://0" end
    if type(iconInput) == "number" then return "rbxassetid://" .. tostring(iconInput) end
    if type(iconInput) == "string" then
        if iconInput:match("^rbxassetid://") or iconInput:match("^http") or iconInput:match("^rbxthumb://") then return iconInput end
        local iconName = iconInput:lower()
        if LucideIcons and LucideIcons[iconName] then return LucideIcons[iconName] end
    end
    return "rbxassetid://0"
end

-- ==================== 1. TRIGGER BUTTON ====================
function NoirUI.CreateTrigger(config)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NoirUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 44)
    btn.Position = config.Position or UDim2.new(1, -60, 0.5, 0)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = ""
    btn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0.6, 0, 0.6, 0)
    icon.Position = UDim2.new(0.5, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = ResolveIcon(config.Icon or "menu")
    icon.Parent = btn

    local isOpen = false
    local menuInstance = nil

    btn.MouseButton1Click:Connect(function()
        if isOpen then
            if menuInstance then menuInstance:Destroy() end
            isOpen = false
        else
            menuInstance = NoirUI._OpenRadial(config, screenGui)
            isOpen = true
        end
    end)

    return btn
end

-- ==================== 2. RADIAL CORE (Vòng Cha & Vòng Con) ====================
function NoirUI._OpenRadial(config, parentGui)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 360, 0, 360)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = parentGui

    local centerPos = Vector2.new(180, 180)
    local mainRadius = 130
    local subRadius = 85

    local function createRoundButton(parent, posX, posY, size, color, iconInput)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, size, 0, size)
        btn.Position = UDim2.new(0, posX - size/2, 0, posY - size/2)
        btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 50)
        btn.Text = ""
        btn.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = btn

        if iconInput then
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0.5, 0, 0.5, 0)
            icon.Position = UDim2.new(0.5, 0, 0.5, 0)
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.BackgroundTransparency = 1
            icon.Image = ResolveIcon(iconInput)
            icon.Parent = btn
        end
        return btn
    end

    local function renderLevel1(items)
        local count = #items
        if count == 0 then return end
        local angleStep = (2 * math.pi) / count

        for i, data in ipairs(items) do
            local angle = (i - 1) * angleStep - (math.pi / 2)
            local pos = centerPos + Vector2.new(mainRadius * math.cos(angle), mainRadius * math.sin(angle))
            local btn = createRoundButton(container, pos.X, pos.Y, 60, Color3.fromRGB(50, 50, 55), data.Icon)
            
            btn.MouseButton1Click:Connect(function()
                if data.Children and #data.Children > 0 then
                    renderLevel2(data.Children, centerPos, angle)
                elseif data.OnSelect then
                    container:Destroy()
                    -- Bây giờ data.OnSelect là một bảng cấu hình (Config), không phải hàm nữa
                    NoirUI._OpenPanel({
                        Title = data.Label or "Menu",
                        Content = data.OnSelect -- Đây là config chứa các component
                    })
                end
            end)
        end
    end

    local function renderLevel2(items, centerPos, parentAngle)
        for _, child in pairs(container:GetChildren()) do
            if child:IsA("TextButton") and child.Position ~= UDim2.new(0.5, -45, 0.5, -45) then
                child:Destroy()
            end
        end

        local count = #items
        if count == 0 then return end
        local angleStep = (2 * math.pi) / count
        local startAngle = parentAngle - (count * angleStep) / 2 + (angleStep / 2)

        for i, data in ipairs(items) do
            local angle = startAngle + (i - 1) * angleStep
            local pos = centerPos + Vector2.new((mainRadius + subRadius) * math.cos(angle), (mainRadius + subRadius) * math.sin(angle))
            local btn = createRoundButton(container, pos.X, pos.Y, 48, Color3.fromRGB(35, 35, 40), data.Icon)
            
            btn.MouseButton1Click:Connect(function()
                if data.OnSelect then
                    container:Destroy()
                    NoirUI._OpenPanel({
                        Title = data.Label or "Sub Menu",
                        Content = data.OnSelect
                    })
                end
            end)
        end
    end

    local centerBtn = createRoundButton(container, centerPos.X, centerPos.Y, 90, Color3.fromRGB(35, 35, 40), config.CenterLogo or "layout")
    local centerText = Instance.new("TextLabel")
    centerText.Size = UDim2.new(1, 0, 0.3, 0)
    centerText.Position = UDim2.new(0.5, 0, 1, -10)
    centerText.AnchorPoint = Vector2.new(0.5, 1)
    centerText.BackgroundTransparency = 1
    centerText.Text = "NOIR"
    centerText.TextColor3 = Color3.fromRGB(200, 200, 200)
    centerText.TextSize = 12
    centerText.Font = Enum.Font.GothamBold
    centerText.Parent = centerBtn

    local MAX_PER_PAGE = 8
    local currentPage = 1
    local allItems = config.Items or {}
    local totalPages = math.ceil(#allItems / MAX_PER_PAGE)
    if totalPages == 0 then totalPages = 1 end

    local function renderPage(pageNum)
        for _, child in pairs(container:GetChildren()) do
            if child:IsA("TextButton") and child ~= centerBtn then
                child:Destroy()
            end
        end

        local startIdx = (pageNum - 1) * MAX_PER_PAGE + 1
        local endIdx = math.min(startIdx + MAX_PER_PAGE - 1, #allItems)
        local pageItems = {}
        for i = startIdx, endIdx do
            table.insert(pageItems, allItems[i])
        end
        renderLevel1(pageItems)
    end

    centerBtn.MouseButton1Click:Connect(function()
        currentPage = currentPage + 1
        if currentPage > totalPages then currentPage = 1 end
        renderPage(currentPage)
    end)

    renderPage(1)
    return container
end

-- ==================== 3. MAIN PANEL & COMPONENTS ====================

-- 3.1. Core Panel
function NoirUI._OpenPanel(config)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NoirUI_Panel"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.Parent = screenGui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 480, 1, 0)
    panel.Position = UDim2.new(0, -480, 0, 0)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundTransparency = 1
    header.Parent = panel

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0, 40, 0, 40)
    backBtn.Position = UDim2.new(0, 15, 0.5, 0)
    backBtn.AnchorPoint = Vector2.new(0, 0.5)
    backBtn.BackgroundTransparency = 1
    backBtn.Text = "<"
    backBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    backBtn.TextSize = 24
    backBtn.Font = Enum.Font.GothamBold
    backBtn.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 60, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Menu"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -20, 1, -80)
    contentContainer.Position = UDim2.new(0, 10, 0, 70)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = panel

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(panel, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()

    backBtn.MouseButton1Click:Connect(function()
        local tweenOut = TweenService:Create(panel, tweenInfo, {Position = UDim2.new(0, -480, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end)

    -- Gọi hàm dựng UI từ config.Content
    local componentsConfig = config.Content
    if type(componentsConfig) == "table" then
        for _, compData in ipairs(componentsConfig) do
            if type(compData) == "table" and compData.Type then
                local ComponentFunc = NoirUI.Components[compData.Type]
                if ComponentFunc then
                    ComponentFunc(contentContainer, compData)
                end
            end
        end
    end

    return screenGui
end

-- 3.2. Components Library (Nơi chứa tất cả UI mẫu)
NoirUI.Components = {
    -- Component: Label (Chữ)
    Label = function(parent, config)
        local lbl = Instance.new("TextLabel")
        lbl.Size = config.Size or UDim2.new(1, 0, 0, 40)
        lbl.Position = config.Position or UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = config.Text or "Label"
        lbl.TextColor3 = config.TextColor or Color3.fromRGB(255, 255, 255)
        lbl.TextSize = config.TextSize or 16
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = parent
        return lbl
    end,

    -- Component: Button
    Button = function(parent, config)
        local btn = Instance.new("TextButton")
        btn.Size = config.Size or UDim2.new(1, 0, 0, 45)
        btn.Position = config.Position or UDim2.new(0, 0, 0, 0)
        btn.BackgroundColor3 = config.Color or Color3.fromRGB(45, 45, 50)
        btn.Text = config.Text or "Button"
        btn.TextColor3 = config.TextColor or Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        if config.OnClick then
            btn.MouseButton1Click:Connect(config.OnClick)
        end
        return btn
    end,

    -- Component: Slider (Thanh trượt)
    Slider = function(parent, config)
        local container = Instance.new("Frame")
        container.Size = config.Size or UDim2.new(1, 0, 0, 50)
        container.Position = config.Position or UDim2.new(0, 0, 0, 0)
        container.BackgroundTransparency = 1
        container.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = config.Label or "Slider"
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0.5, 0, 0, 6)
        bg.Position = UDim2.new(0.5, 0, 0.5, 0)
        bg.AnchorPoint = Vector2.new(0.5, 0.5)
        bg.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        bg.Parent = container
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(config.Value or 0.5, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
        fill.Parent = bg

        return container
    end,

    -- Component: Toggle (Công tắc)
    Toggle = function(parent, config)
        local container = Instance.new("Frame")
        container.Size = config.Size or UDim2.new(1, 0, 0, 40)
        container.BackgroundTransparency = 1
        container.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = config.Label or "Toggle"
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = container

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 20)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btn.Text = ""
        btn.Parent = container

        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, 16, 0, 16)
        circle.Position = UDim2.new(0, 2, 0.5, 0)
        circle.AnchorPoint = Vector2.new(0, 0.5)
        circle.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
        circle.Parent = btn

        local isOn = config.Default or false
        local function updateToggle()
            local targetX = isOn and 22 or 2
            local targetColor = isOn and Color3.fromRGB(80, 140, 255) or Color3.fromRGB(120, 120, 120)
            TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, targetX, 0.5, 0)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        end
        updateToggle()

        btn.MouseButton1Click:Connect(function()
            isOn = not isOn
            updateToggle()
            if config.OnToggle then config.OnToggle(isOn) end
        end)
        return container
    end
}

return NoirUI
