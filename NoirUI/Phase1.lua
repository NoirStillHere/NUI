local NoirUI_Radial = {}

-- 1. Hàm Load Icon từ GitHub (của bạn)
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

-- 2. Core Logic Tạo Radial (Nâng cấp từ repo của bạn)
function NoirUI_Radial.Create(config)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NoirUI_Radial"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 600, 0, 600)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    -- Cấu hình Pagination (Tối đa 8 nút / trang)
    local MAX_ITEMS = 8
    local currentPage = 1
    local totalPages = math.ceil(#config.Items / MAX_ITEMS)
    if totalPages == 0 then totalPages = 1 end
    
    local activeNodes = {}
    local centerLogo

    -- Hàm vẽ các nút trên vòng tròn
    local function RenderPage(pageNum)
        -- Xóa các nút cũ
        for _, node in pairs(activeNodes) do node:Destroy() end
        activeNodes = {}

        local startIndex = (pageNum - 1) * MAX_ITEMS + 1
        local endIndex = math.min(startIndex + MAX_ITEMS - 1, #config.Items)
        local count = endIndex - startIndex + 1

        if count <= 0 then return end

        local radius = 160
        local centerPos = Vector2.new(300, 300) -- Tâm của container 600x600
        local angleStep = (2 * math.pi) / count

        for i = startIndex, endIndex do
            local data = config.Items[i]
            local angle = (i - startIndex) * angleStep - (math.pi / 2)
            local pos = centerPos + Vector2.new(radius * math.cos(angle), radius * math.sin(angle))

            -- Tạo nút
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 70, 0, 70)
            btn.Position = UDim2.new(0, pos.X - 35, 0, pos.Y - 35)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.Text = ""
            btn.Parent = container
            table.insert(activeNodes, btn)

            -- Icon
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0.6, 0, 0.6, 0)
            icon.Position = UDim2.new(0.5, 0, 0.5, 0)
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.BackgroundTransparency = 1
            icon.Image = ResolveIcon(data.Icon)
            icon.Parent = btn

            -- Logic Click: Nested hoặc Open Panel
            btn.MouseButton1Click:Connect(function()
                if data.Children and #data.Children > 0 then
                    -- TODO: Ở phiên bản tiếp theo, mình sẽ viết hàm mở vòng ngoài (Level 2) tại đây
                    warn("🔄 Sẽ mở vòng ngoài cho: " .. tostring(data.Label))
                elseif data.OnSelect then
                    -- Đóng Radial và gọi hàm mở Panel
                    screenGui:Destroy()
                    data.OnSelect()
                end
            end)
        end
    end

    -- 3. Tạo Logo Trung Tâm (Pagination Button)
    centerLogo = Instance.new("TextButton")
    centerLogo.Size = UDim2.new(0, 100, 0, 100)
    centerLogo.Position = UDim2.new(0.5, -50, 0.5, -50)
    centerLogo.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    centerLogo.Text = ""
    centerLogo.Parent = container
    
    local logoIcon = Instance.new("ImageLabel")
    logoIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
    logoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    logoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    logoIcon.BackgroundTransparency = 1
    logoIcon.Image = ResolveIcon(config.CenterLogo or "layout")
    logoIcon.Parent = centerLogo

    -- Tooltip thông báo trang
    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(0, 120, 0, 20)
    tooltip.Position = UDim2.new(0.5, -60, 1, 15)
    tooltip.BackgroundTransparency = 1
    tooltip.Text = "Trang " .. currentPage .. "/" .. totalPages
    tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
    tooltip.TextSize = 12
    tooltip.Parent = centerLogo

    -- Sự kiện bấm Logo để chuyển trang
    centerLogo.MouseButton1Click:Connect(function()
        currentPage = currentPage + 1
        if currentPage > totalPages then currentPage = 1 end
        tooltip.Text = "Trang " .. currentPage .. "/" .. totalPages
        RenderPage(currentPage)
    end)

    -- Vẽ trang đầu tiên
    RenderPage(currentPage)

    return screenGui
end

return NoirUI_Radial
