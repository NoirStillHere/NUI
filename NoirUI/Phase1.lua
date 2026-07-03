local NoirUI = {}
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 1. Hàm load icon từ GitHub của bạn
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

    -- Bo góc và đổ bóng nhẹ
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
    container.Size = UDim2.new(0, 360, 0, 360) -- Nhỏ lại như bạn yêu cầu
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = parentGui

    local centerPos = Vector2.new(180, 180)
    local mainRadius = 130
    local subRadius = 85 -- Bán kính vòng con nằm bên ngoài

    -- Hàm tạo một nút tròn
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

    -- Vẽ vòng tròn chính (Level 1)
    local function renderLevel1(items)
        local count = #items
        if count == 0 then return end
        local angleStep = (2 * math.pi) / count

        for i, data in ipairs(items) do
            local angle = (i - 1) * angleStep - (math.pi / 2)
            local pos = centerPos + Vector2.new(mainRadius * math.cos(angle), mainRadius * math.sin(angle))

            local btn = createRoundButton(container, pos.X, pos.Y, 60, Color3.fromRGB(50, 50, 55), data.Icon)
            
            btn.MouseButton1Click:Connect(function()
                -- Logic: Có con thì mở vòng ngoài, không có con thì mở Panel
                if data.Children and #data.Children > 0 then
                    renderLevel2(data.Children, centerPos, angle)
                elseif data.OnSelect then
                    -- Đóng menu hiện tại, mở Panel
                    container:Destroy()
                    NoirUI._OpenPanel({
                        Title = data.Label or "Menu",
                        Content = data.OnSelect
                    })
                end
            end)
        end
    end

    -- Vẽ vòng tròn con (Level 2 - Nằm ngoài rìa như ảnh)
    local function renderLevel2(items, centerPos, parentAngle)
        -- Xóa các nút Level 1 (ẩn đi khi mở Level 2)
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
                -- Level 2 luôn mở Panel (hoặc bạn có thể check con tiếp theo nếu muốn)
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

    -- ===== LOGO TRUNG TÂM (Nút chuyển trang - Pagination) =====
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

    -- Pagination logic
    local MAX_PER_PAGE = 8
    local currentPage = 1
    local allItems = config.Items or {}
    local totalPages = math.ceil(#allItems / MAX_PER_PAGE)
    if totalPages == 0 then totalPages = 1 end

    -- Hàm render theo trang
    local function renderPage(pageNum)
        -- Xóa các nút Level 1 cũ (giữ lại nút trung tâm)
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

    -- Render trang đầu
    renderPage(1)
    return container
end

-- ==================== 3. MAIN PANEL (Flat UI trượt trái) ====================
function NoirUI._OpenPanel(config)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NoirUI_Panel"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    -- Tạo background mờ (overlay)
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.Parent = screenGui

    -- Main Panel (trượt từ trái vào)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 480, 1, 0)
    panel.Position = UDim2.new(0, -480, 0, 0) -- Nằm ngoài màn hình trước
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    panel.Parent = screenGui

    -- Bo góc và đổ bóng
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    -- Header (Thanh tiêu đề)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundTransparency = 1
    header.Parent = panel

    -- Nút Back (<)
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

    -- Tiêu đề
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

    -- Container để bạn đặt component vào
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -20, 1, -80)
    contentContainer.Position = UDim2.new(0, 10, 0, 70)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = panel

    -- Hiệu ứng trượt vào
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(panel, tweenInfo, {Position = UDim2.new(0, 0, 0, 0)}):Play()

    -- Xử lý nút Back (Đóng Panel và mở lại Radial)
    backBtn.MouseButton1Click:Connect(function()
        -- Trượt ra ngoài rồi destroy
        local tweenOut = TweenService:Create(panel, tweenInfo, {Position = UDim2.new(0, -480, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            screenGui:Destroy()
            -- Gọi lại Trigger để mở lại Radial (nếu bạn muốn)
            -- Hoặc bạn có thể custom ở đây tùy ý
        end)
    end)

    -- Gọi hàm Content (Nếu config.Content là function)
    if type(config.Content) == "function" then
        config.Content(contentContainer)
    end

    return screenGui
end

return NoirUI
