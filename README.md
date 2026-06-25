📘 NoirUI V3 Ultimate - Hướng Dẫn Sử Dụng Đầy Đủ Nhất

---

📌 Mục Lục

1. Giới Thiệu
2. Cài Đặt
3. Tạo Window
4. Các Tham Số Window
5. Hiệu Ứng & Animation
6. Tạo Tab
7. TabGroup (Nhóm Tab)
8. Các Element Trong Tab
9. Component Mới
10. Thông Báo (Notification)
11. Hệ Thống Nhạc Nền
12. Âm Thanh Tương Tác
13. Lệnh Tùy Chỉnh (Custom Commands)
14. Undo/Redo System
15. Key System
16. Hủy UI
17. Ví Dụ Đầy Đủ
18. Bảng Icon
19. Mẹo & Thủ Thuật
20. Khắc Phục Sự Cố

---

🚀 Giới Thiệu

NoirUI V3 Ultimate là thư viện giao diện người dùng hiện đại, tối giản và tùy biến cao cho Roblox Executor (Synapse X, Krnl, ScriptWare, Fluxus, v.v.).

✨ Tính năng nổi bật

· 🎨 Tùy biến màu sắc - Thay đổi accent, background, text color
· 🌟 Hiệu ứng Glow - Viền neon mềm mại
· 🎵 Nhạc nền - Tích hợp sẵn player
· 🔊 Âm thanh tương tác - Click, Tab, Element, v.v.
· 📂 TabGroup - Nhóm tab theo danh mục
· 🔑 Key System - Bảo vệ UI bằng key
· 🖼️ Hỗ trợ ảnh nền - Cho window, loading, notification
· 🌫️ Blur effect - Lớp phủ tối làm nổi bật nội dung
· 📱 Responsive - Hỗ trợ cả chuột và cảm ứng
· ✨ 10+ hiệu ứng - Ripple, Particles, Neon, Glitch, Pop, Bounce, Slide, Floating, Confetti, Typing
· 🆕 Component mới - Icon Button, Grid, Badge, Segmented Control, Progress Bar, Radio Group, Card, Loading Spinner
· 🔄 Undo/Redo System - Lưu lịch sử thao tác

---

📦 Cài Đặt

```lua
local NoirUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirNotFun/NUI/refs/heads/main/NoirUI.lua"))()
```

---

⚙️ Tạo Window

```lua
local Window = NoirUI:CreateWindow({
    -- Thông tin cơ bản
    Name = "NOIR HUB",                    -- string: Tiêu đề
    Accent = Color3.fromRGB(170, 85, 255), -- Color3: Màu chủ đạo
    AutoContrast = false,                  -- bool: Tự động tương phản chữ
    UseGlow = false,                       -- bool: Bật glow viền
    Icon = nil,                            -- string/number: Icon float
    LogoID = nil,                          -- string/number: Logo header
    DefaultPosition = UDim2.new(0.5, -210, 0.5, -150),
    FloatDefaultPosition = UDim2.new(0, 15, 0.5, -22),
    FloatSize = 45,
    FloatIconSize = 24,
    FloatCornerRadius = 12,

    -- Màu nền & Blur
    MainBgColor = Color3.fromRGB(10, 10, 10),
    MainBgTransparency = 0,
    MainBlur = 0,                                   -- 0-1: Lớp tối
    LoadingBlur = 0,
    KeyBlur = 0,
    NotificationBlur = 0,
    ConfirmBlur = 0,
    ElementBackgroundColor = nil,                   -- Màu nền element
    SidebarBackgroundColor = nil,                   -- Màu nền sidebar
    SidebarTransparency = 0.8,
    TabBackgroundColor = nil,                       -- Màu nền tab
    ConfirmBackgroundColor = Color3.fromRGB(15,15,15),
    NotificationBackgroundColor = Color3.fromRGB(15,15,15),

    -- Nền ảnh (tùy chọn)
    Background = nil,                               -- {Image = "...", Transparency = 0}
    LoadingBackground = nil,
    KeyBackground = nil,
    NotificationBackground = nil,
    FloatBackground = nil,

    -- ============================================
    -- HIỆU ỨNG (MỚI)
    -- ============================================
    UseRipple = false,           -- Hiệu ứng gợn sóng khi click
    UseParticles = false,        -- Hiệu ứng hạt nền
    ParticleCount = 30,          -- Số lượng hạt (nếu UseParticles = true)
    UseNeon = false,             -- Hiệu ứng viền neon nhấp nháy
    UseGlitch = false,           -- Hiệu ứng lỗi GLITCH
    UsePop = false,              -- Hiệu ứng bật lên
    UseBounce = false,           -- Hiệu ứng nảy
    UseSlide = false,            -- Hiệu ứng trượt
    UseFloating = false,         -- Hiệu ứng lơ lửng
    UseConfetti = false,         -- Hiệu ứng pháo hoa
    UseTyping = false,           -- Hiệu ứng đánh chữ

    -- Key System
    KeySystem = false,
    KeySettings = {
        Title = "KEY SYSTEM",
        Subtitle = "Nhập key",
        Note = "Liên hệ admin",
        Key = "password",                           -- hoặc {"key1","key2"}
        SaveKey = false,
        FileName = "NoirKey"
    },

    -- Nhạc nền
    BackgroundMusic = {
        Enabled = false,
        AutoPlay = false,
        Volume = 0.3,
        SingleTrack = nil,                          -- rbxassetid
        Playlist = {},                              -- {id1, id2, ...}
        LoopMode = "single"                         -- "single", "playlist", "off"
    }
})
```

---

🎨 Hiệu Ứng & Animation

Cách bật hiệu ứng

Trong CreateWindow, thêm các tham số sau:

```lua
local Window = NoirUI:CreateWindow({
    Name = "My UI",
    UseRipple = true,      -- Gợn sóng khi click
    UseParticles = true,   -- Hạt bay trong nền
    ParticleCount = 30,    -- Số lượng hạt
    UseNeon = true,        -- Viền neon nhấp nháy
    UseGlitch = true,      -- Lỗi GLITCH
    UsePop = true,         -- Bật lên
    UseBounce = true,      -- Nảy
    UseSlide = true,       -- Trượt
    UseFloating = true,    -- Lơ lửng
    UseConfetti = true,    -- Pháo hoa
    UseTyping = true,      -- Đánh chữ
})
```

Sử dụng hiệu ứng thủ công

```lua
-- Ripple Effect (gợn sóng)
CreateRippleEffect(button, Color3.fromRGB(255,255,255), 0.5)

-- Bounce Effect (nảy)
BounceEffect(frame, 20, 0.5)

-- Pop Effect (bật lên)
PopEffect(frame, 1.2)

-- Shake Effect (rung lắc)
ShakeEffect(frame, 5, 0.3)

-- Slide In (trượt vào)
SlideIn(frame, "left", 0.4)

-- Floating Animation (lơ lửng)
CreateFloatingAnimation(frame, 5, 1)

-- Neon Pulse (neon nhấp nháy)
CreateNeonPulse(frame, Color3.fromRGB(255,0,0), 0.3)

-- Glitch Effect (lỗi)
CreateGlitchEffect(label, 2)

-- Typing Effect (đánh chữ)
CreateTypingEffect(label, "Hello World", 0.05)

-- Confetti Burst (pháo hoa)
CreateConfettiBurst(parent, 30)

-- Particle Background (hạt nền)
CreateParticleBackground(parent, Color3.fromRGB(170,85,255), 30)

-- Morphing Gradient (gradient chuyển động)
CreateMorphingGradient(frame, {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0)}, 1)

-- Pulse Effect (đập nhịp)
CreatePulseEffect(frame, 1.1, 1)
```

---

📑 Tạo Tab

Tab Root (luôn hiển thị ở sidebar)

```lua
local tab = Window:CreateTab("Tên Tab", "icon")
```

· icon: tên icon từ Lucide (ví dụ: "home", "settings") hoặc rbxassetid://...

Tab Trong Group

```lua
local group = Window:CreateTabGroup("Tên Nhóm", true) -- true = mở sẵn
local tab = group:CreateTab("Tên Tab", "icon")
```

---

📂 TabGroup (Nhóm Tab)

```lua
-- Tạo group
local group = Window:CreateTabGroup("⚡ Tự Động", true)  -- true: mở sẵn, false: đóng

-- Thêm tab vào group
local tab1 = group:CreateTab("Farm", "zap")
local tab2 = group:CreateTab("Combat", "sword")
```

Tính năng:

· Click vào tiêu đề group để thu gọn/mở rộng
· Tab con được thụt lề để phân biệt
· Tất cả element hoạt động bình thường trong tab con

---

🧩 Các Element Trong Tab

Tất cả element đều hỗ trợ Subtitle để thêm mô tả bên dưới.

1. Label (Nhãn văn bản)

```lua
tab:CreateLabel("Nội dung")
-- Cập nhật động:
tab:CreateLabel(function() return "Giá trị: " .. value end)
```

2. Section (Phần nhóm element)

```lua
local section = tab:CreateSection("Tên Section", true) -- true: ẩn đường kẻ
-- Các element tiếp theo sẽ nằm trong section này
```

3. Paragraph (Khối văn bản)

```lua
tab:CreateParagraph({
    Title = "Tiêu đề",
    Content = "Nội dung mô tả dài..."
})
```

4. Button (Nút bấm)

```lua
tab:CreateButton({
    Name = "Tên nút",
    Subtitle = "Phụ đề",
    Align = false,  -- false: căn trái, true: căn giữa
    Callback = function() print("Đã bấm!") end
})
```

5. Toggle (Công tắc)

```lua
tab:CreateToggle({
    Name = "Tên toggle",
    Subtitle = "Mô tả",
    Default = true,
    Callback = function(state) print(state) end
})
```

6. Slider (Thanh trượt)

```lua
tab:CreateSlider({
    Name = "Âm lượng",
    Subtitle = "Điều chỉnh",
    range = {0, 100},   -- [min, max]
    increment = 5,      -- bước nhảy
    Default = 50,
    Callback = function(value) print(value) end
})
```

7. Color Picker (Chọn màu)

```lua
tab:CreateColorPicker({
    Name = "Chọn màu",
    Subtitle = "Màu accent",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color) print(color) end
})
```

8. Dropdown (Danh sách thả xuống)

```lua
-- Danh sách tĩnh
tab:CreateDropdown({
    Name = "Chọn",
    Subtitle = "Danh sách",
    Options = {"A", "B", "C"},
    Default = "A",
    Callback = function(option) print(option) end
})

-- Danh sách động
tab:CreateDropdown({
    Name = "Chọn",
    GetOptions = function() return {"X", "Y", "Z"} end,
    RefreshOnOpen = true,
    Callback = function(opt) print(opt) end
})
```

9. TextBox (Ô nhập liệu)

```lua
tab:CreateTextBox({
    Name = "Nhập",
    Subtitle = "Mô tả",
    Default = "Giá trị mặc định",
    Callback = function(text) print(text) end
})
```

10. RunBox (Thực thi lệnh)

```lua
tab:CreateRunBox({
    Placeholder = "Nhập .cmd, loadstring, hoặc lua code...",
    ClearOnExecute = true
})
```

---

🆕 Component Mới

1. Icon Button (Nút icon)

```lua
local btn, icon = tab:CreateIconButton(
    parent,          -- Frame cha
    "home",          -- Tên icon
    UDim2.new(0,0,0,0), -- Vị trí
    36,              -- Kích thước
    Color3.fromRGB(40,40,50), -- Màu nền
    16,              -- Kích thước icon
    Color3.fromRGB(255,255,255), -- Màu icon
    function() print("Clicked!") end -- Callback
)
```

2. Grid Layout

```lua
-- Grid ngang
local grid, layout = tab:CreateHorizontalGrid(
    parent,          -- Frame cha
    4,               -- Số cột
    UDim2.new(0, 60, 0, 60), -- Kích thước ô
    UDim2.new(0, 5, 0, 5)    -- Khoảng cách
)

-- Grid dọc
local grid, layout = tab:CreateVerticalGrid(
    parent,          -- Frame cha
    2,               -- Số cột
    UDim2.new(0, 70, 0, 50), -- Kích thước ô
    UDim2.new(0, 10, 0, 5)   -- Khoảng cách
)

-- Grid tùy chỉnh
local grid, layout = tab:CreateGrid(
    parent,          -- Frame cha
    3,               -- Số cột
    UDim2.new(0, 50, 0, 50), -- Kích thước ô
    UDim2.new(0, 5, 0, 5)    -- Khoảng cách
)
```

3. Badge (Huy hiệu)

```lua
tab:CreateBadge("12", Color3.fromRGB(255, 50, 50))  -- Badge đỏ
tab:CreateBadge("✓", Color3.fromRGB(50, 255, 50))   -- Badge xanh
tab:CreateBadge("99+", Color3.fromRGB(255, 200, 50)) -- Badge vàng
```

4. Segmented Control (Thanh chọn)

```lua
local seg, buttons = tab:CreateSegmentedControl(
    {"Option 1", "Option 2", "Option 3"},
    "Option 1",
    function(selected)
        print("Selected:", selected)
    end
)
```

5. Progress Bar (Thanh tiến trình)

```lua
local bar, update = tab:CreateProgressBar(50, 100)
-- Cập nhật sau
update(75, 100)
```

6. Radio Group (Nhóm radio button)

```lua
local radio, btns = tab:CreateRadioGroup(
    {"Option A", "Option B", "Option C"},
    "Option A",
    function(selected)
        print("Selected:", selected)
    end
)
```

7. Card (Thẻ nội dung)

```lua
tab:CreateCard("📊 Thông tin", "Đã apply: 15 avatar\nFavorites: 3")
```

8. Loading Spinner (Spinner loading)

```lua
local spinner = tab:CreateLoadingSpinner(40)
spinner:Show()  -- Hiển thị
spinner:Hide()   -- Ẩn
spinner:Destroy() -- Hủy
```

---

🔔 Thông Báo (Notification)

```lua
NoirUI:Notify("Tiêu đề", "Nội dung", "icon", "Success")
```

· icon: tên Lucide hoặc rbxassetid (có thể để nil)
· soundType: "Success", "Error", "Notification" (mặc định)

---

🎵 Hệ Thống Nhạc Nền

Cấu hình

```lua
BackgroundMusic = {
    Enabled = true,
    AutoPlay = true,
    Volume = 0.3,
    SingleTrack = 1234567890,      -- rbxassetid
    -- hoặc Playlist = {123, 456, 789},
    LoopMode = "single"            -- "single", "playlist", "off"
}
```

Các hàm điều khiển

```lua
NoirUI:StartMusic()                -- Phát nhạc
NoirUI:PauseMusic()                -- Tạm dừng
NoirUI:ResumeMusic()               -- Tiếp tục
NoirUI:StopMusic()                 -- Dừng
NoirUI:SetMusicVolume(0.5)         -- Âm lượng (0-1)
NoirUI:AddMusicTrack(1234567890)   -- Thêm vào playlist
NoirUI:RemoveMusicTrack(1)         -- Xóa theo index
NoirUI:SetMusicLoopMode("playlist") -- "single", "playlist", "off"
```

---

🔊 Âm Thanh Tương Tác

Tùy chỉnh âm thanh

```lua
NoirUI:SetCustomSound("Click", "rbxassetid://123")
NoirUI:SetCustomSound("Tab", "rbxassetid://456")
NoirUI:SetCustomSound("Element", "rbxassetid://789")
NoirUI:SetCustomSound("Open", "...")
NoirUI:SetCustomSound("Close", "...")
NoirUI:SetCustomSound("Notification", "...")
NoirUI:SetCustomSound("Error", "...")
NoirUI:SetCustomSound("Success", "...")
```

Điều khiển

```lua
NoirUI:ToggleSound(true)   -- Bật/tắt
NoirUI:SetVolume(0.8)      -- Âm lượng (0-1)
```

---

🛠️ Lệnh Tùy Chỉnh (Custom Commands)

Đăng ký lệnh để sử dụng trong RunBox:

```lua
NoirUI:RegisterCommand("hello", function(args)
    NoirUI:Notify("Hello", "Bạn đã gõ: " .. table.concat(args, " "))
end)
-- Trong RunBox gõ: .hello xin chào
```

---

🔄 Undo/Redo System

```lua
-- Push state vào history
Window:PushHistory({ value = "Some value" })
Window:PushHistory({ count = 10 })
Window:PushHistory({ enabled = true })

-- Undo (quay lại)
Window:Undo(function(state)
    print("Undo:", state)
end)

-- Redo (làm lại)
Window:Redo(function(state)
    print("Redo:", state)
end)
```

---

🔑 Key System

```lua
KeySystem = true,
KeySettings = {
    Title = "NHẬP KEY",
    Subtitle = "Vui lòng nhập key",
    Note = "Liên hệ admin để lấy key",
    Key = "mypassword",   -- hoặc {"key1", "key2"}
    SaveKey = true,       -- lưu vào file
    FileName = "MyKey"    -- tên file lưu (mặc định "NoirKey")
}
```

---

🗑️ Hủy UI

```lua
NoirUI:Destroy()
```

---

📝 Ví Dụ Đầy Đủ

```lua
-- ============================================
-- 1. TẢI NOIRUI
-- ============================================
local NoirUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/ui.lua"))()

-- ============================================
-- 2. TẠO WINDOW VỚI TẤT CẢ HIỆU ỨNG
-- ============================================
local Window = NoirUI:CreateWindow({
    Name = "Script Hub Pro",
    Accent = Color3.fromRGB(255, 200, 50),
    AutoContrast = true,
    UseGlow = true,
    UseRipple = true,
    UseParticles = true,
    UseNeon = true,
    UseGlitch = true,
    UsePop = true,
    UseBounce = true,
    UseSlide = true,
    UseFloating = true,
    UseConfetti = true,
    UseTyping = true,
    Icon = "home",
    MainBgColor = Color3.fromRGB(10, 10, 15),
    MainBlur = 0.2,
    ElementBackgroundColor = Color3.fromRGB(25, 25, 35),
    SidebarBackgroundColor = Color3.fromRGB(15, 15, 25),
    TabBackgroundColor = Color3.fromRGB(30, 30, 45),
    BackgroundMusic = {
        Enabled = true,
        AutoPlay = false,
        Volume = 0.3,
        SingleTrack = 1234567890,
        LoopMode = "single"
    }
})

-- ============================================
-- 3. TẠO TAB ROOT
-- ============================================
local homeTab = Window:CreateTab("🏠 Trang Chủ", "home")
homeTab:CreateParagraph({
    Title = "Script Hub Pro",
    Content = "Chào mừng bạn đến với Script Hub Pro!\n\n✨ Tính năng:\n• Farm tự động\n• Auto combat\n• Tùy chỉnh giao diện\n• Nhạc nền\n• 10+ hiệu ứng"
})

homeTab:CreateButton({
    Name = "🚀 Bắt Đầu",
    Align = true,
    Callback = function()
        NoirUI:Notify("Bắt đầu", "Script đã được kích hoạt!", "rocket", "Success")
    end
})

-- ============================================
-- 4. TẠO GROUP 1: TỰ ĐỘNG
-- ============================================
local autoGroup = Window:CreateTabGroup("⚡ Tự Động", true)

local farmTab = autoGroup:CreateTab("Farm", "zap")
farmTab:CreateToggle({
    Name = "Bật Farm",
    Subtitle = "Tự động farm khi bật",
    Default = false,
    Callback = function(state)
        NoirUI:Notify("Farm", state and "✅ Đã bật!" or "❌ Đã tắt!", "zap", state and "Success" or nil)
    end
})

farmTab:CreateSlider({
    Name = "Tốc Độ Farm",
    range = {1, 10},
    Default = 5,
    Callback = function(value) print("Tốc độ farm:", value) end
})

local combatTab = autoGroup:CreateTab("Chiến Đấu", "sword")
combatTab:CreateToggle({
    Name = "Auto Attack",
    Subtitle = "Tự động tấn công",
    Default = false,
    Callback = function(state) print("Auto Attack:", state) end
})

-- ============================================
-- 5. TẠO GROUP 2: CÀI ĐẶT
-- ============================================
local settingsGroup = Window:CreateTabGroup("⚙️ Cài Đặt", false)

local uiTab = settingsGroup:CreateTab("Giao Diện", "palette")
uiTab:CreateColorPicker({
    Name = "Màu Chủ Đạo",
    Subtitle = "Thay đổi màu accent",
    Default = Color3.fromRGB(255, 200, 50),
    Callback = function(color)
        NoirUI:Notify("Màu sắc", "Đã đổi màu chủ đạo!", "check", "Success")
    end
})

local soundTab = settingsGroup:CreateTab("Âm Thanh", "volume-2")
soundTab:CreateToggle({
    Name = "Bật Âm Thanh",
    Subtitle = "Bật/tắt âm thanh tương tác",
    Default = true,
    Callback = function(state)
        NoirUI:ToggleSound(state)
    end
})

soundTab:CreateSlider({
    Name = "Âm Lượng",
    range = {0, 100},
    Default = 50,
    Callback = function(value)
        NoirUI:SetVolume(value/100)
    end
})

-- ============================================
-- 6. TẠO GROUP 3: NHẠC NỀN
-- ============================================
local musicGroup = Window:CreateTabGroup("🎵 Nhạc Nền", true)

local playerTab = musicGroup:CreateTab("Phát Nhạc", "music")
playerTab:CreateButton({
    Name = "▶ Play",
    Align = true,
    Callback = function()
        NoirUI:StartMusic()
        NoirUI:Notify("Nhạc", "Đang phát!", "music", "Success")
    end
})

playerTab:CreateButton({
    Name = "⏸ Pause",
    Align = true,
    Callback = function()
        NoirUI:PauseMusic()
        NoirUI:Notify("Nhạc", "Đã tạm dừng!", "pause")
    end
})

-- ============================================
-- 7. TẠO GROUP 4: TIỆN ÍCH
-- ============================================
local utilGroup = Window:CreateTabGroup("🛠 Tiện Ích", true)

-- Tab Lệnh
local cmdTab = utilGroup:CreateTab("Lệnh", "terminal")
cmdTab:CreateRunBox({
    Placeholder = "Nhập .help để xem lệnh...",
    ClearOnExecute = true
})

-- Tab Component Demo
local compTab = utilGroup:CreateTab("Components", "grid")
compTab:CreateSection("📱 Grid Ngang")
local grid = compTab:CreateHorizontalGrid(
    compTab._currentSectionContent or compTab.ContentFrame,
    4,
    UDim2.new(0, 55, 0, 55),
    UDim2.new(0, 8, 0, 8)
)

-- Thêm Icon Button vào grid
for _, name in ipairs({"home", "settings", "music", "palette"}) do
    Window:CreateIconButton(grid, name, nil, 40, Color3.fromRGB(40,40,55), 18)
end

compTab:CreateSection("📊 Progress Bar")
local bar, update = compTab:CreateProgressBar(50, 100)
compTab:CreateButton({
    Name = "Tăng tiến trình",
    Align = true,
    Callback = function()
        local current = tonumber(bar:FindFirstChild("TextLabel").Text:gsub("%%", "")) or 0
        update(math.min(current + 10, 100), 100)
    end
})

-- ============================================
-- 8. ĐĂNG KÝ LỆNH
-- ============================================
NoirUI:RegisterCommand("help", function(args)
    local helpText = [[
📖 Danh sách lệnh:
.farm on/off     - Bật/tắt farm
.combat on/off   - Bật/tắt chiến đấu
.sound on/off    - Bật/tắt âm thanh
.music play      - Phát nhạc
.music pause     - Tạm dừng nhạc
.music stop      - Dừng nhạc
.stats           - Xem thống kê
.help            - Hiển thị trợ giúp này
]]
    NoirUI:Notify("📖 Trợ giúp", helpText, "help-circle")
end)

NoirUI:RegisterCommand("farm", function(args)
    local state = args[1] and args[1]:lower() or "toggle"
    if state == "on" then
        NoirUI:Notify("Farm", "✅ Đã bật farm!", "zap", "Success")
    elseif state == "off" then
        NoirUI:Notify("Farm", "❌ Đã tắt farm!", "zap")
    else
        NoirUI:Notify("Farm", "⚠️ Dùng: .farm on/off")
    end
end)

-- ============================================
-- 9. THÔNG BÁO KHỞI ĐỘNG
-- ============================================
task.wait(1)
NoirUI:Notify("🚀 Script Hub Pro", "Đã tải thành công!\nGõ .help để xem lệnh", "rocket", "Success")

print("✅ Script Hub Pro đã sẵn sàng!")
```

---

🎨 Bảng Icon

Icon phổ biến

Icon Tên Icon Tên
🏠 home ⚙️ settings
📁 folder 💡 lightbulb
🎵 music 🎨 palette
☀️ sun 🌙 moon
🔔 bell ❌ x
✅ check 📋 clipboard
🔄 refresh-cw 💀 skull
🚀 rocket 📊 chart
⭐ star ❤️ heart
🔍 search 📦 package
🎯 target 🛠️ tool
🖥️ monitor 📱 smartphone
🔗 link 📌 pin
🎮 gamepad 🏆 trophy
👤 user 👥 users
🔒 lock 🔓 unlock
📝 edit 🗑️ trash
📤 upload 📥 download
🔄 rotate-cw 🔃 rotate-ccw

Cách xem tất cả icon

```lua
local LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/icons.lua"))()
for name, id in pairs(LucideIcons) do
    print(name, id)
end
```

---

💡 Mẹo & Thủ Thuật

1. Tạo UI đẹp với hiệu ứng

```lua
local Window = NoirUI:CreateWindow({
    Name = "My UI",
    UseRipple = true,   -- Gợn sóng khi click
    UseNeon = true,     -- Viền neon
    UseParticles = true,-- Hạt nền
    UseTyping = true,   -- Đánh chữ
})
```

2. Sử dụng Undo/Redo

```lua
-- Lưu trạng thái
Window:PushHistory({ value = someValue })

-- Undo
Window:Undo(function(state)
    print("Undo:", state)
end)

-- Redo
Window:Redo(function(state)
    print("Redo:", state)
end)
```

3. Tạo Grid với Icon Button

```lua
local grid = tab:CreateHorizontalGrid(parent, 4)
local icons = {"home", "settings", "music", "palette"}
for _, icon in ipairs(icons) do
    Window:CreateIconButton(grid, icon, nil, 40)
end
```

4. Tạo Progress Bar động

```lua
local bar, update = tab:CreateProgressBar(0, 100)
-- Cập nhật tiến trình
task.spawn(function()
    for i = 1, 100 do
        task.wait(0.1)
        update(i, 100)
    end
end)
```

5. Tạo Loading Spinner

```lua
local spinner = tab:CreateLoadingSpinner(40)
spinner:Show()
task.wait(3)
spinner:Hide()
```

---

🔧 Khắc Phục Sự Cố

Vấn đề 1: UI không hiển thị

Cách khắc phục:

```lua
-- Thử đặt UI vào PlayerGui
if not pcall(function() sc['Parent'] = game:GetService("CoreGui") end) then
    sc['Parent'] = game.Players.LocalPlayer.PlayerGui
end
```

Vấn đề 2: Hiệu ứng không hoạt động

Cách khắc phục:

```lua
-- Kiểm tra xem hiệu ứng đã được bật trong settings chưa
local Window = NoirUI:CreateWindow({
    UseRipple = true,  -- Phải bật
    UseNeon = true,    -- Phải bật
})
```

Vấn đề 3: Âm thanh không phát

Cách khắc phục:

```lua
NoirUI:ToggleSound(true)
NoirUI:SetVolume(1)
```

Vấn đề 4: Lỗi khi tải UI

Cách khắc phục:

```lua
local success, err = pcall(function()
    local NoirUI = loadstring(game:HttpGet("..."))()
end)
if not success then
    warn("Lỗi tải NoirUI:", err)
end
```

---

📝 Tổng Kết

📌 Điểm mạnh

· ✅ Giao diện đẹp, hiện đại
· ✅ Dễ sử dụng, code ngắn gọn
· ✅ Tùy biến cao
· ✅ Nhiều tính năng (TabGroup, Key System, Music, v.v.)
· ✅ 10+ hiệu ứng animation
· ✅ 8+ component mới
· ✅ Undo/Redo System
· ✅ Hỗ trợ nhiều executor

📌 Hướng phát triển

· Thêm nhiều hiệu ứng mới
· Thêm nhiều component mới
· Tối ưu hiệu năng
· Hỗ trợ theme tối/sáng

---

Chúc bạn tạo được giao diện đẹp mắt và chuyên nghiệp! 🚀
