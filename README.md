Để bảng hiển thị đẹp trên GitHub (trong file README.md), bạn cần sử dụng cú pháp Markdown cho bảng. Dưới đây là toàn bộ nội dung README.md hoàn chỉnh, bao gồm các bảng, hướng dẫn, ví dụ – bạn có thể copy-paste trực tiếp vào file README.md của dự án.

---

```markdown
# NoirUI V3 Ultimate

**NoirUI V3 Ultimate** là thư viện giao diện người dùng hiện đại, tối giản và tùy biến cao dành cho các Roblox Executor (Synapse, Krnl, ScriptWare…). Hỗ trợ hiệu ứng mượt mà, âm thanh, nhạc nền, hệ thống key và nhiều tùy chỉnh màu sắc.

---

## 🚀 Cài Đặt

```lua
local NoirUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/ui.lua"))()
```

---

⚙️ Tạo Cửa Sổ (Window)

```lua
local Window = NoirUI:CreateWindow({
    -- Các tham số tùy chỉnh (xem bảng bên dưới)
})
```

Bảng tham số CreateWindow

Tham số Loại Mô tả Mặc định
Name string Tiêu đề cửa sổ "NOIR HUB"
Accent Color3 Màu chủ đạo (viền, glow, nút) RGB(170,85,255)
AutoContrast bool Tự động điều chỉnh màu chữ tương phản với nền false
UseGlow bool Bật hiệu ứng glow aura xung quanh cửa sổ false
Icon string/number Icon cho nút float (tên Lucide hoặc rbxassetid) nil
LogoID string/number Logo hiển thị trên header nil
DefaultPosition UDim2 Vị trí khởi tạo cửa sổ chính (0.5,-210,0.5,-150)
FloatDefaultPosition UDim2 Vị trí nút float (0,15,0.5,-22)
FloatSize number Kích thước nút float 45
FloatIconSize number Kích thước icon trong float 24
FloatCornerRadius number Độ bo tròn nút float 12
MainBgColor Color3 Màu nền chính (10,10,10)
MainBgTransparency number Độ trong suốt nền chính 0
MainBlur number (0-1) Lớp tối phủ lên nền chính (0=trong, 1=đen) 0
LoadingBlur number (0-1) Lớp tối trong màn hình loading 0
KeyBlur number (0-1) Lớp tối trong key system 0
NotificationBlur number (0-1) Lớp tối thông báo 0
ConfirmBlur number (0-1) Lớp tối hộp thoại xác nhận 0
ElementBackgroundColor Color3 Màu nền chung cho tất cả element (button, toggle, slider, dropdown, ...) nil (dùng màu mặc định)
SidebarBackgroundColor Color3 Màu nền sidebar (thanh tab bên trái) nil
SidebarTransparency number (0-1) Độ trong suốt của sidebar 0.8
TabBackgroundColor Color3 Màu nền từng tab (khi chưa chọn) nil
ConfirmBackgroundColor Color3 Màu nền hộp thoại xác nhận (15,15,15)
NotificationBackgroundColor Color3 Màu nền thông báo (15,15,15)
KeySystem bool Bật hệ thống key false
KeySettings table Cấu hình key system (xem bên dưới) nil
BackgroundMusic table Cấu hình nhạc nền (xem bên dưới) nil

Hỗ trợ nền ảnh

Các tham số sau dùng để đặt ảnh nền cho từng thành phần (mỗi tham số là một table với cấu trúc { Image = "rbxassetid://..." hoặc "http://...", Transparency = 0.5 }):

Tham số Mô tả
Background Ảnh nền cho cửa sổ chính
LoadingBackground Ảnh nền màn hình loading
KeyBackground Ảnh nền key system
NotificationBackground Ảnh nền thông báo
FloatBackground Ảnh nền nút float

---

📑 Tạo Tab

```lua
local Tab = Window:CreateTab("Tên Tab", "icon")
```

· icon: tên icon từ thư viện Lucide (ví dụ "home", "settings") hoặc rbxassetid://....

---

🧩 Các Element Trong Tab

Tất cả các element đều hỗ trợ tham số Subtitle (chuỗi) để thêm phụ đề bên dưới.

1. Label (Nhãn)

```lua
Tab:CreateLabel("Nội dung")
-- Cập nhật động:
Tab:CreateLabel(function() return "Giá trị: " .. someVariable end)
```

2. Section (Phần nhóm)

```lua
local section = Tab:CreateSection("Tên Section", true) -- true: ẩn đường kẻ
-- Sau khi gọi, các element tiếp theo sẽ được đặt vào section này.
```

3. Paragraph (Khối văn bản)

```lua
Tab:CreateParagraph({
    Title = "Tiêu đề",
    Content = "Nội dung mô tả dài..."
})
```

4. Button (Nút bấm)

```lua
Tab:CreateButton({
    Name = "Tên nút",
    Subtitle = "Phụ đề",
    Align = false,  -- false: căn trái, true: căn giữa
    Callback = function() print("Bấm!") end
})
```

5. Toggle (Công tắc)

```lua
Tab:CreateToggle({
    Name = "Chức năng",
    Subtitle = "Mô tả",
    Default = true,
    Callback = function(state) print(state) end
})
```

6. Slider (Thanh trượt)

```lua
Tab:CreateSlider({
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
Tab:CreateColorPicker({
    Name = "Chọn màu",
    Subtitle = "Màu accent",
    Default = Color3.fromRGB(255,0,0),
    Callback = function(color) print(color) end
})
```

8. Dropdown (Danh sách thả xuống)

```lua
-- Tĩnh:
Tab:CreateDropdown({
    Name = "Chọn",
    Subtitle = "Danh sách",
    Options = {"A", "B", "C"},
    Default = "A",
    Callback = function(option) print(option) end
})

-- Động (cập nhật mỗi khi mở):
Tab:CreateDropdown({
    Name = "Danh sách động",
    GetOptions = function() return {"X", "Y", "Z"} end,
    RefreshOnOpen = true,
    Callback = function(opt) print(opt) end
})
```

9. TextBox (Ô nhập)

```lua
Tab:CreateTextBox({
    Name = "Tên",
    Subtitle = "Nhập tên của bạn",
    Default = "Noir",
    Callback = function(text) print(text) end
})
```

10. RunBox (Thực thi lệnh)

```lua
Tab:CreateRunBox({
    Placeholder = "Nhập lệnh hoặc code...",
    ClearOnExecute = true   -- tự động xóa sau khi chạy
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

· icon: tên Lucide hoặc rbxassetid, có thể để nil
· soundType: "Success", "Error", "Notification" (mặc định)

---

🎵 Hệ Thống Nhạc Nền

Cấu hình khi tạo Window

```lua
BackgroundMusic = {
    Enabled = true,
    AutoPlay = true,
    Volume = 0.3,
    SingleTrack = 1234567890,    -- rbxassetid
    -- Hoặc dùng Playlist:
    -- Playlist = {123, 456, 789},
    LoopMode = "single" -- hoặc "playlist", "off"
}
```

Các hàm điều khiển

```lua
NoirUI:StartMusic()
NoirUI:PauseMusic()
NoirUI:ResumeMusic()
NoirUI:StopMusic()
NoirUI:SetMusicVolume(0.5)
NoirUI:AddMusicTrack(1234567890)
NoirUI:RemoveMusicTrack(1)        -- xóa theo index
NoirUI:SetMusicLoopMode("playlist") -- "single", "playlist", "off"
```

---

🔊 Âm Thanh Tương Tác

```lua
-- Đặt âm thanh tùy chỉnh cho từng hành động
NoirUI:SetCustomSound("Click", "rbxassetid://123")
NoirUI:SetCustomSound("Tab", "...")
NoirUI:SetCustomSound("Element", "...")
NoirUI:SetCustomSound("Open", "...")
NoirUI:SetCustomSound("Close", "...")
NoirUI:SetCustomSound("Notification", "...")
NoirUI:SetCustomSound("Error", "...")
NoirUI:SetCustomSound("Success", "...")

NoirUI:ToggleSound(true)   -- bật/tắt
NoirUI:SetVolume(0.8)
```

---

🔑 Hệ Thống Key

```lua
KeySystem = true,
KeySettings = {
    Title = "NHẬP KEY",
    Subtitle = "Vui lòng nhập key",
    Note = "Liên hệ admin để lấy key",
    Key = "mypassword",   -- hoặc {"key1", "key2"}
    SaveKey = true,      -- lưu vào file
    FileName = "MyKey"   -- tên file lưu (mặc định "NoirKey")
}
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

🗑️ Hủy UI

```lua
NoirUI:Destroy()
```

---

📝 Ví Dụ Đầy Đủ

```lua
local NoirUI = loadstring(game:HttpGet("..."))()
local Window = NoirUI:CreateWindow({
    Name = "My UI",
    Accent = Color3.fromRGB(255, 100, 100),
    UseGlow = true,
    AutoContrast = true,
    ElementBackgroundColor = Color3.fromRGB(30,30,40),
    SidebarBackgroundColor = Color3.fromRGB(20,20,30),
    TabBackgroundColor = Color3.fromRGB(35,35,45),
    MainBlur = 0.2,
    Icon = "home"
})

local mainTab = Window:CreateTab("Chính", "home")
mainTab:CreateSection("Cài đặt")
mainTab:CreateToggle({
    Name = "Bật tự động",
    Default = true,
    Callback = function(s) print(s) end
})
mainTab:CreateButton({
    Name = "Chạy",
    Callback = function() NoirUI:Notify("Thông báo", "Đã chạy!", "check", "Success") end
})

local settingTab = Window:CreateTab("Cài đặt", "settings")
settingTab:CreateSlider({
    Name = "Âm lượng",
    range = {0,100},
    Default = 50,
    Callback = function(v) NoirUI:SetVolume(v/100) end
})

settingTab:CreateColorPicker({
    Name = "Màu accent",
    Default = Color3.fromRGB(255,0,0),
    Callback = function(c) print(c) end
})
```

---

🧠 Ghi Chú Quan Trọng

· Blur thực chất là một lớp phủ tối, không phải Gaussian blur, giúp làm nổi bật nội dung.
· Với AutoContrast = true, màu chữ sẽ tự động tương phản với màu nền của element đó.
· Tất cả element đều có thể có Subtitle để thêm mô tả.
· Bạn có thể tạo nhiều tab, mỗi tab có thể chứa nhiều section và element.

---

Chúc bạn tạo được giao diện đẹp mắt và chuyên nghiệp! 🌟

```

---

## 📌 Giải thích về cú pháp bảng Markdown

- Dòng đầu tiên: `| Tiêu đề 1 | Tiêu đề 2 | ... |`
- Dòng thứ hai: `|---------|---------| ... |` (dấu `-` tối thiểu 3 ký tự; có thể thêm `:` để căn lề: `:---`, `---:`, `:---:`)
- Các dòng sau: dữ liệu, phân cách bởi `|`.

Ví dụ một bảng đơn giản:

```markdown
| Tên | Tuổi |
|-----|------|
| An  | 20   |
| Bình| 25   |
```

Khi push lên GitHub, nó sẽ tự động render thành bảng đẹp mắt. Bạn có thể copy nội dung trên vào file README.md và commit.
