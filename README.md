📘 NoirUI V3 Ultimate - Hướng Dẫn Sử Dụng Đầy Đủ

---

🚀 Cài Đặt

```lua
local NoirUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/ui.lua"))()
```

---

⚙️ Tạo Cửa Sổ (Window)

```lua
local Window = NoirUI:CreateWindow({
    -- Thông tin cơ bản
    Name = "Tiêu đề UI",                    -- string: Tiêu đề
    Accent = Color3.fromRGB(255, 200, 50),  -- Color3: Màu chủ đạo
    AutoContrast = true,                    -- bool: Tự động tương phản chữ
    UseGlow = true,                         -- bool: Bật glow viền
    Icon = "home",                          -- string/number: Icon nút float
    
    -- Màu nền & Blur
    MainBgColor = Color3.fromRGB(10, 10, 15),
    MainBlur = 0.2,                         -- 0-1: Lớp tối
    ElementBackgroundColor = Color3.fromRGB(25, 25, 35),
    SidebarBackgroundColor = Color3.fromRGB(15, 15, 25),
    SidebarTransparency = 0.85,
    TabBackgroundColor = Color3.fromRGB(30, 30, 45),
    ConfirmBackgroundColor = Color3.fromRGB(20, 20, 30),
    NotificationBackgroundColor = Color3.fromRGB(20, 20, 30),
    
    -- Nền ảnh (tùy chọn)
    Background = { Image = "rbxassetid://123", Transparency = 0.5 },
    LoadingBackground = { Image = "rbxassetid://456", Transparency = 0.3 },
    KeyBackground = { Image = "rbxassetid://789", Transparency = 0.4 },
    
    -- Key System
    KeySystem = false,
    KeySettings = {
        Title = "KEY SYSTEM",
        Subtitle = "Nhập key",
        Note = "Liên hệ admin",
        Key = "password",                   -- hoặc {"key1", "key2"}
        SaveKey = false,
        FileName = "NoirKey"
    },
    
    -- Nhạc nền
    BackgroundMusic = {
        Enabled = false,
        AutoPlay = false,
        Volume = 0.3,
        SingleTrack = 1234567890,           -- rbxassetid
        Playlist = {123, 456, 789},
        LoopMode = "single"                 -- "single", "playlist", "off"
    }
})
```

---

📑 Tạo Tab

Tab Root (luôn hiển thị ở sidebar)

```lua
local tab = Window:CreateTab("Tên Tab", "icon")
```

· icon: tên icon từ Lucide (ví dụ: "home", "settings") hoặc rbxassetid://...

Tab Trong Group (nhóm tab)

```lua
-- Tạo group trước
local group = Window:CreateTabGroup("Tên Nhóm", true) -- true = mở sẵn

-- Tạo tab trong group
local tab = group:CreateTab("Tên Tab", "icon")
```

---

📂 TabGroup (Nhóm Tab)

```lua
-- Tạo group
local group = Window:CreateTabGroup("⚡ Tự Động", true)  -- true: mở sẵn, false: đóng

-- Thêm tab vào group (cách dùng giống tab thường)
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

Danh sách tĩnh:

```lua
tab:CreateDropdown({
    Name = "Chọn",
    Subtitle = "Danh sách",
    Options = {"A", "B", "C"},
    Default = "A",
    Callback = function(option) print(option) end
})
```

Danh sách động:

```lua
tab:CreateDropdown({
    Name = "Chọn",
    GetOptions = function() return {"X", "Y", "Z"} end,
    RefreshOnOpen = true,  -- cập nhật mỗi khi mở
    Callback = function(opt) print(opt) end
})
```

9. TextBox (Ô nhập)

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
    ClearOnExecute = true  -- tự động xóa sau khi chạy
})
```

Hỗ trợ:

· Lệnh tùy chỉnh: .command arg1 arg2
· loadstring("...")
· Lua code trực tiếp

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
local NoirUI = loadstring(game:HttpGet("..."))()

local Window = NoirUI:CreateWindow({
    Name = "Script Hub Pro",
    Accent = Color3.fromRGB(255, 200, 50),
    AutoContrast = true,
    UseGlow = true,
    Icon = "home",
    MainBgColor = Color3.fromRGB(10, 10, 15),
    MainBlur = 0.2,
    ElementBackgroundColor = Color3.fromRGB(25, 25, 35),
    SidebarBackgroundColor = Color3.fromRGB(15, 15, 25),
    TabBackgroundColor = Color3.fromRGB(30, 30, 45),
})

-- Tab Root
local homeTab = Window:CreateTab("🏠 Trang Chủ", "home")
homeTab:CreateParagraph({
    Title = "Script Hub Pro",
    Content = "Chào mừng bạn đến với Script Hub Pro!"
})

-- TabGroup 1
local autoGroup = Window:CreateTabGroup("⚡ Tự Động", true)

local farmTab = autoGroup:CreateTab("Farm", "zap")
farmTab:CreateToggle({
    Name = "Bật Farm",
    Default = false,
    Callback = function(s)
        NoirUI:Notify("Farm", s and "✅ Đã bật!" or "❌ Đã tắt!", "zap", s and "Success" or nil)
    end
})

local combatTab = autoGroup:CreateTab("Chiến đấu", "sword")
combatTab:CreateToggle({
    Name = "Auto Attack",
    Default = false,
    Callback = function(s) print("Auto Attack:", s) end
})

-- TabGroup 2
local settingsGroup = Window:CreateTabGroup("⚙️ Cài Đặt", false)

local uiTab = settingsGroup:CreateTab("Giao diện", "palette")
uiTab:CreateColorPicker({
    Name = "Màu chủ đạo",
    Default = Color3.fromRGB(255, 200, 50),
    Callback = function(c) print(c) end
})

local soundTab = settingsGroup:CreateTab("Âm thanh", "volume-2")
soundTab:CreateSlider({
    Name = "Âm lượng",
    range = {0, 100},
    Default = 50,
    Callback = function(v) NoirUI:SetVolume(v/100) end
})

-- TabGroup 3
local musicGroup = Window:CreateTabGroup("🎵 Nhạc Nền", true)

local playerTab = musicGroup:CreateTab("Phát nhạc", "music")
playerTab:CreateButton({
    Name = "▶ Play",
    Align = true,
    Callback = function()
        NoirUI:StartMusic()
        NoirUI:Notify("Nhạc", "Đang phát!", "music", "Success")
    end
})

-- Đăng ký lệnh
NoirUI:RegisterCommand("help", function(args)
    NoirUI:Notify("📖 Trợ giúp", ".farm on/off\n.music play/pause\n.stats", "help-circle")
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

-- Thông báo khởi động
task.wait(1)
NoirUI:Notify("🚀 Script Hub Pro", "Đã tải thành công!\nGõ .help để xem lệnh", "rocket", "Success")
```

---

💡 Ghi Chú Quan Trọng

1. Blur là lớp phủ tối (không phải Gaussian blur thực), giúp làm nổi bật nội dung
2. AutoContrast = true sẽ tự động điều chỉnh màu chữ tương phản với nền
3. TabGroup giúp tổ chức tab theo nhóm, click vào tiêu đề để thu gọn/mở rộng
4. Tất cả element đều hỗ trợ Subtitle để thêm mô tả
5. Có thể tạo nhiều tab root và nhiều group

---

Chúc bạn tạo được giao diện đẹp mắt và chuyên nghiệp! 🚀
