--============================================================================
-- NOIRUI v1.0.0
-- Phase 4: Component System (Bug Fixes Applied)
-- Fixed: Toggle position, shape, click detection
--============================================================================

--============================================================================
-- SERVICES
--============================================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

--============================================================================
-- CONSTANTS
--============================================================================
local CONST = {
	Z_BACKGROUND = 100, Z_WORKSPACE = 200, Z_HEADER = 300,
	Z_RADIAL = 400, Z_OVERLAY = 500, Z_FLOATING = 600,
	Z_TOAST = 700, Z_MODAL = 800, Z_CONTEXT_MENU = 900, Z_TOOLTIP = 1000,

	S_IDLE = "IDLE", S_RADIAL_OPENING = "RADIAL_OPENING",
	S_GROUP_SELECTION = "GROUP_SELECTION", S_TAB_SELECTION = "TAB_SELECTION",
	S_WORKSPACE_OPENING = "WORKSPACE_OPENING", S_WORKSPACE_ACTIVE = "WORKSPACE_ACTIVE",

	E_STATE_ENTER = "state:enter", E_STATE_EXIT = "state:exit",
	E_SYSTEM_STARTED = "system:started",
	E_TOGGLE_CLICKED = "toggle:clicked",
	E_RADIAL_SLOT_CLICKED = "radial:slotClicked",
	E_RADIAL_LOGO_CLICKED = "radial:logoClicked",
	E_RADIAL_OUTSIDE_CLICKED = "radial:outsideClicked",
	E_RADIAL_ANIMATION_DONE = "radial:animationDone",
	E_HEADER_CLOSE = "header:close",
}

--============================================================================
-- THEME CONFIG
--============================================================================
local DEFAULT_THEME = {
	autoStart = true, debug = false,

	-- Toggle
	toggleWidth = 100,
	toggleHeight = 38,
	toggleDefaultPosX = 0.5,
	toggleDefaultPosY = 0.03,

	-- Radial
	radialMaxGroups = 8, radialMaxTabs = 8,
	radialRadius = 120, radialSlotSize = 48, radialLogoSize = 56, radialVisibleRatio = 0.4,

	-- Timing
	timeOpen = 0.2, timeClose = 0.15, timeRotate = 0.35,
	timeToWorkspace = 0.3, timeToGroup = 0.25,

	-- Workspace
	workspaceWidth = 440, workspaceHeight = 400, headerHeight = 36,

	-- Colors
	colorBg = Color3.fromRGB(18, 18, 18),
	colorSurface = Color3.fromRGB(28, 28, 28),
	colorSurfaceHover = Color3.fromRGB(42, 42, 42),
	colorAccent = Color3.fromRGB(180, 180, 180),
	colorAccentHover = Color3.fromRGB(220, 220, 220),
	colorText = Color3.fromRGB(240, 240, 240),
	colorTextSecondary = Color3.fromRGB(160, 160, 160),
	colorBorder = Color3.fromRGB(50, 50, 50),
	colorRadialSlot = Color3.fromRGB(35, 35, 35),
	colorRadialHover = Color3.fromRGB(55, 55, 55),

	-- Typography
	font = Enum.Font.Gotham,
	fontSizeXS = 10, fontSizeSM = 12, fontSizeMD = 14, fontSizeLG = 16, fontSizeXL = 20,

	-- Spacing
	cornerRadius = 6,
	spacingXS = 4, spacingSM = 8, spacingMD = 12, spacingLG = 16, spacingXL = 24,

	-- Component sizes
	componentHeight = 32, componentPadding = 8,
	sectionTitleHeight = 24, sectionSpacing = 12,
	scrollBarWidth = 4, scrollBuffer = 200,

	-- Component-specific
	toggleWidth_sm = 36, toggleHeight_sm = 20, toggleKnobSize = 16,
	sliderTrackHeight = 4, sliderThumbSize = 14, sliderInputWidth = 56,
	dropdownMaxHeight = 160, dropdownItemHeight = 28,

	-- Animation
	animHover = 0.1, animClick = 0.05, animFade = 0.15,
}

--============================================================================
-- UTILITIES
--============================================================================
local Util = {}

function Util.mergeTheme(user)
	if not user then return DEFAULT_THEME end
	local t = {}
	for k, v in pairs(DEFAULT_THEME) do
		t[k] = (user[k] ~= nil) and user[k] or v
	end
	return t
end

function Util.clamp(v, min, max)
	return math.max(min, math.min(max, v))
end

function Util.radialPosition(cx, cy, r, a, s)
	return cx + math.cos(a) * r - s / 2, cy + math.sin(a) * r - s / 2
end

function Util.slotAngle(i, n)
	return math.rad((360 / n) * i - 90)
end

--============================================================================
-- EVENT BUS
--============================================================================
local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
	return setmetatable({ _listeners = {}, _destroyed = false }, EventBus)
end

function EventBus:on(e, cb)
	if self._destroyed then return function() end end
	if not self._listeners[e] then self._listeners[e] = {} end
	table.insert(self._listeners[e], cb)
	local bus = self
	return function()
		bus:off(e, cb)
	end
end

function EventBus:off(e, cb)
	if self._destroyed then return end
	local list = self._listeners[e]
	if not list then return end
	for i = #list, 1, -1 do
		if list[i] == cb then
			table.remove(list, i)
			break
		end
	end
	if #list == 0 then
		self._listeners[e] = nil
	end
end

function EventBus:emit(e, payload)
	if self._destroyed then return end
	local list = self._listeners[e]
	if not list then return end
	for i = #list, 1, -1 do
		local cb = list[i]
		if cb then
			task.spawn(cb, payload)
		end
	end
end

function EventBus:destroy()
	self._listeners = {}
	self._destroyed = true
end

--============================================================================
-- STATE MACHINE
--============================================================================
local StateMachine = {}
StateMachine.__index = StateMachine

local function _transitions()
	local S = CONST
	return {
		[S.S_IDLE] = { S.S_RADIAL_OPENING },
		[S.S_RADIAL_OPENING] = { S.S_GROUP_SELECTION, S.S_IDLE },
		[S.S_GROUP_SELECTION] = { S.S_TAB_SELECTION, S.S_IDLE },
		[S.S_TAB_SELECTION] = { S.S_WORKSPACE_OPENING, S.S_GROUP_SELECTION, S.S_IDLE },
		[S.S_WORKSPACE_OPENING] = { S.S_WORKSPACE_ACTIVE, S.S_IDLE },
		[S.S_WORKSPACE_ACTIVE] = { S.S_GROUP_SELECTION, S.S_IDLE, S.S_WORKSPACE_ACTIVE },
	}
end

function StateMachine.new(bus, cfg)
	return setmetatable({
		_bus = bus,
		_cfg = cfg,
		_transitions = _transitions(),
		_current = CONST.S_IDLE,
		_previous = nil,
		_history = {},
		_started = false,
	}, StateMachine)
end

function StateMachine:start()
	self._started = true
	self:_emitEnter(CONST.S_IDLE)
end

function StateMachine:transition(newState, data)
	if not self._started then return false end
	local allowed = self._transitions[self._current]
	if not allowed then
		self:_warn(newState)
		return false
	end
	local ok = false
	for _, s in ipairs(allowed) do
		if s == newState then
			ok = true
			break
		end
	end
	if not ok then
		self:_warn(newState)
		return false
	end
	if newState == CONST.S_GROUP_SELECTION or newState == CONST.S_TAB_SELECTION then
		table.insert(self._history, self._current)
	end
	self._bus:emit(CONST.E_STATE_EXIT, { state = self._current, nextState = newState })
	self._previous = self._current
	self._current = newState
	self._bus:emit(CONST.E_STATE_ENTER, { state = newState, previous = self._previous, data = data })
	return true
end

function StateMachine:getState()
	return self._current
end

function StateMachine:back()
	if #self._history == 0 then return false end
	return self:transition(table.remove(self._history))
end

function StateMachine:destroy()
	self._history = {}
	self._started = false
end

function StateMachine:_emitEnter(s)
	self._bus:emit(CONST.E_STATE_ENTER, { state = s })
end

function StateMachine:_warn(s)
	if self._cfg.debug then
		warn(string.format("[NoirUI] Bad transition: %s -> %s", self._current, s))
	end
end

--============================================================================
-- MOTION
--============================================================================
local Motion = {}
Motion.__index = Motion

function Motion.new(bus)
	return setmetatable({ _bus = bus, _tweens = {} }, Motion)
end

function Motion:play(id, inst, props, dur, style, dir, cb)
	self:stop(id)
	local ti = TweenInfo.new(dur, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, 0, false, 0)
	local tw = TweenService:Create(inst, ti, props)
	self._tweens[id] = tw
	tw:Play()
	tw.Completed:Connect(function(s)
		self._tweens[id] = nil
		if s == Enum.PlaybackState.Completed and cb then
			cb()
		end
	end)
end

function Motion:stop(id)
	local tw = self._tweens[id]
	if tw then
		tw:Cancel()
		self._tweens[id] = nil
	end
end

function Motion:cancelAll()
	for _, tw in pairs(self._tweens) do
		tw:Cancel()
	end
	self._tweens = {}
end

function Motion:destroy()
	self:cancelAll()
end

--============================================================================
-- DRAG
--============================================================================
local Drag = {}
Drag.__index = Drag

function Drag.new(bus)
	return setmetatable({ _bus = bus, _d = nil }, Drag)
end

function Drag:start(inst, input, onDrag, onEnd)
	if self._d then
		self:_end()
	end
	local sp = input.Position
	local off = inst.AbsolutePosition - sp
	self._d = {
		inst = inst,
		sp = sp,
		off = off,
		onDrag = onDrag,
		onEnd = onEnd,
		moved = false,
		conn = nil
	}
	local conn
	conn = UserInputService.InputChanged:Connect(function(ci)
		if ci.UserInputType == Enum.UserInputType.MouseMovement then
			self:_onDrag(ci)
		end
	end)
	self._d.conn = conn
end

function Drag:_onDrag(input)
	local d = self._d
	if not d then return end
	local np = input.Position + d.off
	d.moved = true
	d.inst.Position = UDim2.fromOffset(np.X, np.Y)
	if d.onDrag then
		d.onDrag(input.Position)
	end
end

function Drag:finish(input, thresh)
	local d = self._d
	if not d then
		return false, nil
	end
	local dist = 0
	if input and d.sp then
		dist = (input.Position - d.sp).Magnitude
	end
	local moved = d.moved and dist > (thresh or 5)
	self:_end()
	return moved, dist
end

function Drag:_end()
	local d = self._d
	if not d then return end
	if d.conn then
		d.conn:Disconnect()
	end
	if d.onEnd then
		d.onEnd()
	end
	self._d = nil
end

--============================================================================
-- LAYERS
--============================================================================
local Layers = {}
Layers.__index = Layers

local LAYER_DEFS = {
	{ "Background", CONST.Z_BACKGROUND },
	{ "Workspace", CONST.Z_WORKSPACE },
	{ "Header", CONST.Z_HEADER },
	{ "Radial", CONST.Z_RADIAL },
	{ "Overlay", CONST.Z_OVERLAY },
	{ "Floating", CONST.Z_FLOATING },
	{ "Toast", CONST.Z_TOAST },
	{ "Modal", CONST.Z_MODAL },
	{ "ContextMenu", CONST.Z_CONTEXT_MENU },
	{ "Tooltip", CONST.Z_TOOLTIP },
}

function Layers.new(bus)
	return setmetatable({ _bus = bus, _layers = {}, _parent = nil, _mounted = false }, Layers)
end

function Layers:mount()
	if self._mounted then return end
	local p = Players.LocalPlayer
	if not p then error("[NoirUI] No LocalPlayer") end
	local pg = p:WaitForChild("PlayerGui")
	self._parent = pg
	for _, d in ipairs(LAYER_DEFS) do
		local g = Instance.new("ScreenGui")
		g.Name = "NoirUI_" .. d[1]
		g.DisplayOrder = d[2]
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.Parent = pg
		self._layers[d[1]] = g
	end
	self._mounted = true
end

function Layers:get(n)
	return self._layers[n]
end

function Layers:mounted()
	return self._mounted
end

function Layers:unmount()
	for _, g in pairs(self._layers) do
		g:Destroy()
	end
	self._layers = {}
	self._parent = nil
	self._mounted = false
end

--============================================================================
-- FLOATING TOGGLE
--============================================================================
local FloatToggle = {}
FloatToggle.__index = FloatToggle

function FloatToggle.new(bus, cfg)
	return setmetatable({ _bus = bus, _cfg = cfg, _inst = nil }, FloatToggle)
end

function FloatToggle:mount(layer)
	local c = self._cfg

	local f = Instance.new("Frame")
	f.Name = "NoirUI_Toggle"
	f.Size = UDim2.fromOffset(c.toggleWidth, c.toggleHeight)
	f.Position = UDim2.fromScale(c.toggleDefaultPosX, c.toggleDefaultPosY)
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.BackgroundColor3 = c.colorSurface
	f.BackgroundTransparency = 0
	f.BorderSizePixel = 0
	f.Parent = layer

	local cn = Instance.new("UICorner")
	cn.CornerRadius = UDim.new(0, c.cornerRadius)
	cn.Parent = f

	local st = Instance.new("UIStroke")
	st.Color = c.colorBorder
	st.Thickness = 1
	st.Parent = f

	-- NoirUI text label
	local lb = Instance.new("TextLabel")
	lb.Name = "Label"
	lb.Size = UDim2.new(1, -8, 1, 0)
	lb.Position = UDim2.fromOffset(4, 0)
	lb.BackgroundTransparency = 1
	lb.BorderSizePixel = 0
	lb.FontFace = c.font
	lb.TextSize = c.fontSizeMD
	lb.TextColor3 = c.colorText
	lb.Text = "NoirUI"
	lb.TextXAlignment = Enum.TextXAlignment.Left
	lb.Parent = f

	-- Small icon on the right
	local ic = Instance.new("ImageLabel")
	ic.Name = "Icon"
	ic.Size = UDim2.fromOffset(16, 16)
	ic.Position = UDim2.new(1, -22, 0.5, 0)
	ic.AnchorPoint = Vector2.new(0, 0.5)
	ic.BackgroundTransparency = 1
	ic.BorderSizePixel = 0
	ic.Image = ""
	ic.ImageColor3 = c.colorTextSecondary
	ic.ScaleType = Enum.ScaleType.Fit
	ic.Parent = f

	self._inst = f
	return f
end

function FloatToggle:setVisible(v)
	if self._inst then
		self._inst.Visible = v
	end
end

function FloatToggle:getInstance()
	return self._inst
end

function FloatToggle:destroy()
	if self._inst then
		self._inst:Destroy()
		self._inst = nil
	end
end

--============================================================================
-- RADIAL SLOT
--============================================================================
local RadSlot = {}
RadSlot.__index = RadSlot

function RadSlot.new(cfg)
	return setmetatable({ _cfg = cfg, _btn = nil, _icon = nil, _label = nil }, RadSlot)
end

function RadSlot:mount(parent)
	local c = self._cfg
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(c.radialSlotSize, c.radialSlotSize)
	b.BackgroundColor3 = c.colorRadialSlot
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.Parent = parent
	local cn = Instance.new("UICorner")
	cn.CornerRadius = UDim.new(0, c.cornerRadius)
	cn.Parent = b

	local ic = Instance.new("ImageLabel")
	ic.Name = "Icon"
	ic.Size = UDim2.new(0.5, 0, 0.5, 0)
	ic.Position = UDim2.fromScale(0.5, 0.35)
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.BackgroundTransparency = 1
	ic.BorderSizePixel = 0
	ic.Image = ""
	ic.ImageColor3 = c.colorText
	ic.ScaleType = Enum.ScaleType.Fit
	ic.Parent = b

	local lb = Instance.new("TextLabel")
	lb.Name = "Label"
	lb.Size = UDim2.new(1, -8, 0, c.fontSizeSM + 4)
	lb.Position = UDim2.fromScale(0.5, 0.7)
	lb.AnchorPoint = Vector2.new(0.5, 0)
	lb.BackgroundTransparency = 1
	lb.BorderSizePixel = 0
	lb.FontFace = c.font
	lb.TextSize = c.fontSizeSM
	lb.TextColor3 = c.colorText
	lb.Text = ""
	lb.TextTruncate = Enum.TextTruncate.AtEnd
	lb.Parent = b

	self._btn = b
	self._icon = ic
	self._label = lb
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = c.colorRadialHover
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = c.colorRadialSlot
	end)
	return b
end

function RadSlot:setLabel(t)
	if self._label then self._label.Text = t or "" end
end

function RadSlot:setIcon(id)
	if self._icon then self._icon.Image = id or "" end
end

function RadSlot:getButton()
	return self._btn
end

function RadSlot:destroy()
	if self._btn then
		self._btn:Destroy()
		self._btn = nil
	end
end

--============================================================================
-- RADIAL NAV
--============================================================================
local RadialNav = {}
RadialNav.__index = RadialNav

function RadialNav.new(bus, cfg, motion)
	return setmetatable({
		_bus = bus,
		_cfg = cfg,
		_motion = motion,
		_ct = nil,
		_rot = nil,
		_logo = nil,
		_slots = {},
		_vis = false,
	}, RadialNav)
end

function RadialNav:mount(layer)
	local c = self._cfg
	local ct = Instance.new("Frame")
	ct.Name = "NoirUI_Radial"
	ct.Size = UDim2.new(1, 0, 1, 0)
	ct.Position = UDim2.fromScale(0, 0)
	ct.BackgroundTransparency = 1
	ct.Visible = false
	ct.Parent = layer
	ct.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			self._bus:emit(CONST.E_RADIAL_OUTSIDE_CLICKED)
		end
	end)
	self._ct = ct

	local rt = Instance.new("Frame")
	rt.Name = "Rotator"
	local sz = c.radialRadius * 2 + c.radialSlotSize
	rt.Size = UDim2.fromOffset(sz, sz)
	rt.Position = UDim2.fromScale(0.5, 0.5)
	rt.AnchorPoint = Vector2.new(0.5, 0.5)
	rt.BackgroundTransparency = 1
	rt.BorderSizePixel = 0
	rt.Parent = ct
	self._rot = rt

	local lg = Instance.new("TextButton")
	lg.Name = "Logo"
	lg.Size = UDim2.fromOffset(c.radialLogoSize, c.radialLogoSize)
	lg.Position = UDim2.fromScale(0.5, 0.5)
	lg.AnchorPoint = Vector2.new(0.5, 0.5)
	lg.BackgroundColor3 = c.colorSurface
	lg.BorderSizePixel = 0
	lg.AutoButtonColor = false
	lg.Text = ""
	lg.Parent = ct
	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(0, c.cornerRadius)
	lc.Parent = lg
	local li = Instance.new("ImageLabel")
	li.Name = "Icon"
	li.Size = UDim2.new(0.5, 0, 0.5, 0)
	li.Position = UDim2.fromScale(0.5, 0.5)
	li.AnchorPoint = Vector2.new(0.5, 0.5)
	li.BackgroundTransparency = 1
	li.BorderSizePixel = 0
	li.Image = ""
	li.ImageColor3 = c.colorText
	li.ScaleType = Enum.ScaleType.Fit
	li.Parent = lg
	lg.MouseButton1Click:Connect(function()
		self._bus:emit(CONST.E_RADIAL_LOGO_CLICKED)
	end)
	self._logo = lg
end

function RadialNav:showSlots(items, mode)
	for _, s in ipairs(self._slots) do
		s:destroy()
	end
	self._slots = {}
	if not self._rot then return end
	local c = self._cfg
	local max = mode == "group" and c.radialMaxGroups or c.radialMaxTabs
	local n = math.min(#items, max)
	for i = 1, n do
		local item = items[i]
		local a = Util.slotAngle(i - 1, n)
		local x, y = Util.radialPosition(self._rot.AbsoluteSize.X / 2, self._rot.AbsoluteSize.Y / 2, c.radialRadius, a, c.radialSlotSize)
		local sl = RadSlot.new(c)
		local b = sl:mount(self._rot)
		b.Position = UDim2.fromOffset(x, y)
		sl:setLabel(item.name or "")
		if item.icon then
			sl:setIcon(item.icon)
		end
		local idx = i
		b.MouseButton1Click:Connect(function()
			self._bus:emit(CONST.E_RADIAL_SLOT_CLICKED, { index = idx, mode = mode })
		end)
		table.insert(self._slots, sl)
	end
end

function RadialNav:setVisible(v)
	if self._ct then
		self._ct.Visible = v
		self._vis = v
	end
end

function RadialNav:animateToLeft(cb)
	if not self._ct then
		if cb then cb() end
		return
	end
	self._motion:play("radCollapse", self._ct, {
		Position = UDim2.fromScale(-(1 - self._cfg.radialVisibleRatio), 0)
	}, self._cfg.timeToWorkspace, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, cb)
end

function RadialNav:animateToCenter(cb)
	if not self._ct then
		if cb then cb() end
		return
	end
	self._motion:stop("radCollapse")
	self._motion:play("radExpand", self._ct, {
		Position = UDim2.fromScale(0, 0)
	}, self._cfg.timeToGroup, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, cb)
end

function RadialNav:destroy()
	for _, s in ipairs(self._slots) do
		s:destroy()
	end
	self._slots = {}
	if self._ct then
		self._ct:Destroy()
		self._ct = nil
	end
end

--============================================================================
-- HEADER
--============================================================================
local Header = {}
Header.__index = Header

function Header.new(bus, cfg)
	return setmetatable({ _bus = bus, _cfg = cfg, _inst = nil, _title = nil, _bc = nil }, Header)
end

function Header:mount(parent)
	local c = self._cfg
	local f = Instance.new("Frame")
	f.Name = "Header"
	f.Size = UDim2.new(1, 0, 0, c.headerHeight)
	f.BackgroundColor3 = c.colorSurface
	f.BorderSizePixel = 0
	f.Parent = parent
	local cn = Instance.new("UICorner")
	cn.CornerRadius = UDim.new(0, c.cornerRadius)
	cn.Parent = f

	local bd = Instance.new("Frame")
	bd.Name = "Border"
	bd.Size = UDim2.new(1, 0, 0, 1)
	bd.Position = UDim2.fromScale(0, 1)
	bd.BackgroundColor3 = c.colorBorder
	bd.BorderSizePixel = 0
	bd.Parent = f

	local t = Instance.new("TextLabel")
	t.Name = "Title"
	t.Size = UDim2.new(0, 100, 1, 0)
	t.Position = UDim2.fromOffset(12, 0)
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.FontFace = c.font
	t.TextSize = c.fontSizeMD
	t.TextColor3 = c.colorText
	t.Text = "NoirUI"
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextTruncate = Enum.TextTruncate.AtEnd
	t.Parent = f
	self._title = t

	local sp = Instance.new("Frame")
	sp.Name = "Sep"
	sp.Size = UDim2.new(0, 1, 0, 20)
	sp.Position = UDim2.fromOffset(116, (c.headerHeight - 20) / 2)
	sp.BackgroundColor3 = c.colorBorder
	sp.BorderSizePixel = 0
	sp.Parent = f

	local bc = Instance.new("TextLabel")
	bc.Name = "Breadcrumb"
	bc.Size = UDim2.new(1, -160, 1, 0)
	bc.Position = UDim2.fromOffset(124, 0)
	bc.BackgroundTransparency = 1
	bc.BorderSizePixel = 0
	bc.FontFace = c.font
	bc.TextSize = c.fontSizeSM
	bc.TextColor3 = c.colorTextSecondary
	bc.Text = ""
	bc.TextXAlignment = Enum.TextXAlignment.Left
	bc.TextTruncate = Enum.TextTruncate.AtEnd
	bc.Parent = f
	self._bc = bc

	local cb = Instance.new("TextButton")
	cb.Name = "Close"
	cb.Size = UDim2.fromOffset(28, 28)
	cb.Position = UDim2.new(1, -8, 0.5, 0)
	cb.AnchorPoint = Vector2.new(1, 0.5)
	cb.BackgroundColor3 = c.colorSurface
	cb.BorderSizePixel = 0
	cb.FontFace = c.font
	cb.TextSize = c.fontSizeMD
	cb.TextColor3 = c.colorTextSecondary
	cb.Text = "×"
	cb.AutoButtonColor = false
	cb.Parent = f
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, c.cornerRadius)
	cc.Parent = cb

	cb.MouseEnter:Connect(function()
		cb.BackgroundColor3 = c.colorSurfaceHover
		cb.TextColor3 = c.colorText
	end)
	cb.MouseLeave:Connect(function()
		cb.BackgroundColor3 = c.colorSurface
		cb.TextColor3 = c.colorTextSecondary
	end)
	cb.MouseButton1Click:Connect(function()
		self._bus:emit(CONST.E_HEADER_CLOSE)
	end)

	self._inst = f
	return f
end

function Header:setTitle(t)
	if self._title then self._title.Text = t or "NoirUI" end
end

function Header:setBreadcrumb(g, tb)
	if self._bc then
		local txt = g or ""
		if tb then txt = txt .. "  ›  " .. tb end
		self._bc.Text = txt
	end
end

function Header:destroy()
	if self._inst then
		self._inst:Destroy()
		self._inst = nil
	end
end

--============================================================================
-- STYLE UTILS
--============================================================================
local Style = {}

function Style.corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
	return c
end

function Style.stroke(inst, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thick or 1
	s.Parent = inst
	return s
end

function Style.label(parent, cfg, text, size, color, alignX)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.FontFace = cfg.font
	l.TextSize = size or cfg.fontSizeMD
	l.TextColor3 = color or cfg.colorText
	l.Text = text or ""
	l.TextXAlignment = alignX or Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

--============================================================================
-- ANIMATION UTILS
--============================================================================
local Anim = {}
Anim.__index = Anim

function Anim.new(motion, cfg)
	return setmetatable({ _m = motion, _cfg = cfg }, Anim)
end

function Anim:hoverEnter(inst, props, id)
	self._m:play("h_" .. id, inst, props or { BackgroundTransparency = 0 }, self._cfg.animHover, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Anim:hoverLeave(inst, props, id)
	self._m:play("h_" .. id, inst, props or { BackgroundTransparency = 0 }, self._cfg.animHover, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Anim:press(inst, id)
	self._m:play("p_" .. id, inst, { Size = inst.Size - UDim2.fromOffset(2, 2) }, self._cfg.animClick, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Anim:release(inst, id)
	self._m:play("p_" .. id, inst, { Size = inst.Size + UDim2.fromOffset(2, 2) }, self._cfg.animClick, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Anim:fadeIn(inst, id, cb)
	inst.Visible = true
	inst.BackgroundTransparency = 1
	self._m:play("f_" .. id, inst, { BackgroundTransparency = 0 }, self._cfg.animFade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, cb)
end

function Anim:fadeOut(inst, id, cb)
	self._m:play("f_" .. id, inst, { BackgroundTransparency = 1 }, self._cfg.animFade, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
		inst.Visible = false
		if cb then cb() end
	end)
end

--============================================================================
-- COMPONENT REGISTRY
--============================================================================
local Registry = {}
Registry.__index = Registry

function Registry.new()
	return setmetatable({ _comps = {} }, Registry)
end

function Registry:register(id, comp)
	self._comps[id] = comp
end

function Registry:unregister(id)
	self._comps[id] = nil
end

function Registry:find(id)
	return self._comps[id]
end

function Registry:getAll()
	local list = {}
	for _, c in pairs(self._comps) do
		table.insert(list, c)
	end
	return list
end

function Registry:destroyAll()
	for _, c in pairs(self._comps) do
		if not c._destroyed then
			c:destroy()
		end
	end
	self._comps = {}
end

function Registry:count()
	local n = 0
	for _ in pairs(self._comps) do
		n = n + 1
	end
	return n
end

--============================================================================
-- BASE COMPONENT
--============================================================================
local Component = {}
Component.__index = Component

function Component.new(cfg, anim)
	return setmetatable({
		_cfg = cfg,
		_anim = anim,
		_inst = nil,
		_ct = nil,
		_value = nil,
		_cb = nil,
		_enabled = true,
		_visible = true,
		_locked = false,
		_destroyed = false,
		_id = nil,
	}, Component)
end

function Component:mount(parent)
	if self._destroyed then return end
	if self._inst then self._inst.Parent = parent end
end

function Component:show()
	if not self._destroyed and self._inst then
		self._inst.Visible = true
		self._visible = true
	end
end

function Component:hide()
	if not self._destroyed and self._inst then
		self._inst.Visible = false
		self._visible = false
	end
end

function Component:setVisible(v)
	self._visible = v
	if self._inst then self._inst.Visible = v end
end

function Component:setEnabled(v)
	self._enabled = v
end

function Component:setLocked(v)
	self._locked = v
end

function Component:setValue(v)
	self._value = v
end

function Component:getValue()
	return self._value
end

function Component:onChanged(cb)
	self._cb = cb
end

function Component:_emit(v)
	if self._cb and not self._destroyed then
		self._cb(v)
	end
end

function Component:getInstance()
	return self._inst
end

function Component:isDestroyed()
	return self._destroyed
end

function Component:destroy()
	if self._destroyed then return end
	self._destroyed = true
	self._cb = nil
	if self._inst then
		self._inst:Destroy()
		self._inst = nil
	end
end

--============================================================================-- LABEL
--============================================================================
local Label = setmetatable({}, { __index = Component })
Label.__index = Label

function Label.new(cfg, anim, title, desc)
	local self = Component.new(cfg, anim)
	setmetatable(self, Label)
	local totalH = cfg.componentHeight
	if desc then totalH = cfg.componentHeight + cfg.fontSizeSM + 2 end

	local f = Instance.new("Frame")
	f.Name = "Label"
	f.Size = UDim2.new(1, 0, 0, totalH)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	local ly = desc and 0 or (cfg.componentHeight - cfg.fontSizeMD) / 2
	local t = Style.label(f, cfg, title or "", cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	t.Name = "Title"
	t.Size = UDim2.new(1, 0, 0, cfg.fontSizeMD + 2)
	t.Position = UDim2.fromOffset(0, ly)
	self._title = t

	if desc then
		local d = Style.label(f, cfg, desc, cfg.fontSizeSM, cfg.colorTextSecondary, Enum.TextXAlignment.Left)
		d.Name = "Desc"
		d.Size = UDim2.new(1, 0, 0, cfg.fontSizeSM + 2)
		d.Position = UDim2.fromOffset(0, cfg.fontSizeMD + 4)
		self._desc = d
	end

	self._value = title
	return self
end

function Label:setTitle(t)
	self._value = t
	if self._title then self._title.Text = t or "" end
end

function Label:setDescription(d)
	if self._desc then self._desc.Text = d or "" end
end

function Label:setColor(c)
	if self._title then self._title.TextColor3 = c end
end

--============================================================================
-- PARAGRAPH
--============================================================================
local Paragraph = setmetatable({}, { __index = Component })
Paragraph.__index = Paragraph

function Paragraph.new(cfg, anim, title, desc)
	local self = Component.new(cfg, anim)
	setmetatable(self, Paragraph)
	local f = Instance.new("Frame")
	f.Name = "Paragraph"
	f.Size = UDim2.new(1, 0, 0, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	local tl = Style.label(f, cfg, title or "", cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	tl.Name = "Title"
	tl.Size = UDim2.new(1, 0, 0, cfg.fontSizeMD + 4)

	local dl = Style.label(f, cfg, desc or "", cfg.fontSizeSM, cfg.colorTextSecondary, Enum.TextXAlignment.Left)
	dl.Name = "Desc"
	dl.Size = UDim2.new(1, 0, 0, 0)
	dl.Position = UDim2.fromOffset(0, cfg.fontSizeMD + 6)
	dl.TextWrapped = true
	dl.RichText = true
	dl.Size = UDim2.new(1, 0, 0, dl.TextBounds.Y)
	f.Size = UDim2.new(1, 0, 0, cfg.fontSizeMD + 6 + dl.TextBounds.Y)

	self._title = tl
	self._desc = dl
	self._value = { title = title, desc = desc }
	return self
end

function Paragraph:setTitle(t)
	self._value.title = t
	if self._title then self._title.Text = t or "" end
end

function Paragraph:setDescription(d)
	self._value.desc = d
	if self._desc then
		self._desc.Text = d or ""
		self._desc.Size = UDim2.new(1, 0, 0, self._desc.TextBounds.Y)
		self._inst.Size = UDim2.new(1, 0, 0, self._cfg.fontSizeMD + 6 + self._desc.TextBounds.Y)
	end
end

--============================================================================
-- DIVIDER
--============================================================================
local Divider = setmetatable({}, { __index = Component })
Divider.__index = Divider

function Divider.new(cfg, anim, title)
	local self = Component.new(cfg, anim)
	setmetatable(self, Divider)
	local totalH = 1
	if title then totalH = cfg.componentHeight end

	local f = Instance.new("Frame")
	f.Name = "Divider"
	f.Size = UDim2.new(1, 0, 0, totalH)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	if title then
		local l = Style.label(f, cfg, title, cfg.fontSizeSM, cfg.colorTextSecondary, Enum.TextXAlignment.Left)
		l.Name = "Title"
		l.Size = UDim2.new(1, 0, 0, cfg.fontSizeSM + 2)
		l.Position = UDim2.fromOffset(0, (totalH - cfg.fontSizeSM - 2) / 2)
	else
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.Size = UDim2.new(1, 0, 0, 1)
		line.BackgroundColor3 = cfg.colorBorder
		line.BorderSizePixel = 0
		line.Parent = f
	end

	return self
end

--============================================================================
-- BUTTON
--============================================================================
local Button = setmetatable({}, { __index = Component })
Button.__index = Button

function Button.new(cfg, anim, title, desc, cb)
	local self = Component.new(cfg, anim)
	setmetatable(self, Button)
	local totalH = cfg.componentHeight

	local f = Instance.new("Frame")
	f.Name = "Button"
	f.Size = UDim2.new(1, 0, 0, totalH)
	f.BackgroundColor3 = cfg.colorAccent
	f.BorderSizePixel = 0
	self._inst = f
	Style.corner(f, cfg.cornerRadius)

	local l = Style.label(f, cfg, title or "Button", cfg.fontSizeMD, cfg.colorBg, Enum.TextXAlignment.Center)
	l.Name = "Title"
	l.Size = UDim2.new(1, 0, 1, 0)

	local hb = Instance.new("TextButton")
	hb.Name = "Hitbox"
	hb.Size = UDim2.new(1, 0, 1, 0)
	hb.BackgroundTransparency = 1
	hb.BorderSizePixel = 0
	hb.Text = ""
	hb.AutoButtonColor = false
	hb.Parent = f

	self._frame = f
	self._label = l
	self._value = title

	hb.MouseEnter:Connect(function()
		if not self._enabled or self._locked then return end
		anim:hoverEnter(f, { BackgroundColor3 = cfg.colorAccentHover }, self._id)
	end)
	hb.MouseLeave:Connect(function()
		anim:hoverLeave(f, { BackgroundColor3 = cfg.colorAccent }, self._id)
	end)
	hb.MouseButton1Down:Connect(function()
		if not self._enabled or self._locked then return end
		anim:press(f, self._id)
	end)
	hb.MouseButton1Up:Connect(function()
		anim:release(f, self._id)
	end)
	hb.MouseButton1Click:Connect(function()
		if not self._enabled or self._locked then return end
		if cb then cb() end
		self:_emit(true)
	end)

	return self
end

function Button:setTitle(t)
	self._value = t
	if self._label then self._label.Text = t end
end

function Button:setEnabled(v)
	Component.setEnabled(self, v)
	if self._frame then
		self._frame.BackgroundColor3 = v and self._cfg.colorAccent or self._cfg.colorBorder
		if self._label then
			self._label.TextColor3 = v and self._cfg.colorBg or self._cfg.colorTextSecondary
		end
	end
end

--============================================================================
-- TOGGLE
--============================================================================
local Toggle = setmetatable({}, { __index = Component })
Toggle.__index = Toggle

function Toggle.new(cfg, anim, title, desc, default)
	local self = Component.new(cfg, anim)
	setmetatable(self, Toggle)
	self._value = default or false
	local totalH = cfg.componentHeight
	if desc then totalH = cfg.componentHeight + cfg.fontSizeSM + 2 end

	local f = Instance.new("Frame")
	f.Name = "Toggle"
	f.Size = UDim2.new(1, 0, 0, totalH)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	local ly = desc and 0 or (cfg.componentHeight - cfg.fontSizeMD) / 2
	local t = Style.label(f, cfg, title or "", cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	t.Name = "Title"
	t.Size = UDim2.new(1, -cfg.toggleWidth_sm - 8, 0, cfg.fontSizeMD + 2)
	t.Position = UDim2.fromOffset(0, ly)
	self._title = t

	if desc then
		local d = Style.label(f, cfg, desc, cfg.fontSizeSM, cfg.colorTextSecondary, Enum.TextXAlignment.Left)
		d.Name = "Desc"
		d.Size = UDim2.new(1, -cfg.toggleWidth_sm - 8, 0, cfg.fontSizeSM + 2)
		d.Position = UDim2.fromOffset(0, cfg.fontSizeMD + 4)
		self._desc = d
	end

	local sw = Instance.new("Frame")
	sw.Name = "Switch"
	sw.Size = UDim2.fromOffset(cfg.toggleWidth_sm, cfg.toggleHeight_sm)
	sw.Position = UDim2.new(1, -cfg.toggleWidth_sm, 0, (cfg.componentHeight - cfg.toggleHeight_sm) / 2)
	sw.BackgroundColor3 = self._value and cfg.colorAccent or cfg.colorSurfaceHover
	sw.BorderSizePixel = 0
	sw.Parent = f
	Style.corner(sw, cfg.toggleHeight_sm / 2)

	local kn = Instance.new("Frame")
	kn.Name = "Knob"
	kn.Size = UDim2.fromOffset(cfg.toggleKnobSize, cfg.toggleKnobSize)
	local kx = self._value and (cfg.toggleWidth_sm - cfg.toggleKnobSize - 2) or 2
	kn.Position = UDim2.fromOffset(kx, (cfg.toggleHeight_sm - cfg.toggleKnobSize) / 2)
	kn.BackgroundColor3 = cfg.colorText
	kn.BorderSizePixel = 0
	kn.Parent = sw
	Style.corner(kn, cfg.toggleKnobSize / 2)

	local hb = Instance.new("TextButton")
	hb.Name = "Hitbox"
	hb.Size = UDim2.new(1, 0, 1, 0)
	hb.BackgroundTransparency = 1
	hb.BorderSizePixel = 0
	hb.Text = ""
	hb.AutoButtonColor = false
	hb.Parent = f

	self._sw = sw
	self._kn = kn

	hb.MouseButton1Click:Connect(function()
		if not self._enabled or self._locked then return end
		self._value = not self._value
		self:_update()
		self:_emit(self._value)
	end)

	return self
end

function Toggle:_update()
	local c = self._cfg
	local kx = self._value and (c.toggleWidth_sm - c.toggleKnobSize - 2) or 2
	self._sw.BackgroundColor3 = self._value and c.colorAccent or c.colorSurfaceHover
	self._kn.Position = UDim2.fromOffset(kx, (c.toggleHeight_sm - c.toggleKnobSize) / 2)
end

function Toggle:setValue(v)
	self._value = v
	self:_update()
end

function Toggle:toggle()
	self._value = not self._value
	self:_update()
	self:_emit(self._value)
end

--============================================================================
-- SLIDER
--============================================================================
local Slider = setmetatable({}, { __index = Component })
Slider.__index = Slider

function Slider.new(cfg, anim, title, min, max, step, suffix, decimals, default)
	local self = Component.new(cfg, anim)
	setmetatable(self, Slider)
	self._min = min or 0
	self._max = max or 100
	self._step = step or 1
	self._suffix = suffix or ""
	self._decimals = decimals or 0
	self._value = default or self._min
	self._dragging = false

	local f = Instance.new("Frame")
	f.Name = "Slider"
	f.Size = UDim2.new(1, 0, 0, cfg.componentHeight + cfg.fontSizeMD + 6)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	local t = Style.label(f, cfg, title or "", cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	t.Name = "Title"
	t.Size = UDim2.new(1, 0, 0, cfg.fontSizeMD + 2)

	local ib = Instance.new("Frame")
	ib.Name = "InputBg"
	ib.Size = UDim2.fromOffset(cfg.sliderInputWidth, cfg.fontSizeMD + 4)
	ib.Position = UDim2.new(1, -cfg.sliderInputWidth, 0, 0)
	ib.BackgroundColor3 = cfg.colorSurface
	ib.BorderSizePixel = 0
	ib.Parent = f
	Style.corner(ib, cfg.cornerRadius)

	local inp = Instance.new("TextBox")
	inp.Name = "Val"
	inp.Size = UDim2.new(1, -8, 1, 0)
	inp.Position = UDim2.fromOffset(4, 0)
	inp.BackgroundTransparency = 1
	inp.BorderSizePixel = 0
	inp.FontFace = cfg.font
	inp.TextSize = cfg.fontSizeSM
	inp.TextColor3 = cfg.colorText
	inp.Text = self:_fmt()
	inp.TextXAlignment = Enum.TextXAlignment.Center
	inp.Parent = ib

	local ty = cfg.fontSizeMD + 8 + (cfg.componentHeight - cfg.sliderTrackHeight) / 2
	local tk = Instance.new("Frame")
	tk.Name = "Track"
	tk.Size = UDim2.new(1, 0, 0, cfg.sliderTrackHeight)
	tk.Position = UDim2.fromOffset(0, ty)
	tk.BackgroundColor3 = cfg.colorSurfaceHover
	tk.BorderSizePixel = 0
	tk.Parent = f
	Style.corner(tk, cfg.sliderTrackHeight / 2)

	local fl = Instance.new("Frame")
	fl.Name = "Fill"
	fl.Size = UDim2.fromScale(0, 1)
	fl.BackgroundColor3 = cfg.colorAccent
	fl.BorderSizePixel = 0
	fl.Parent = tk
	Style.corner(fl, cfg.sliderTrackHeight / 2)

	local th = Instance.new("Frame")
	th.Name = "Thumb"
	th.Size = UDim2.fromOffset(cfg.sliderThumbSize, cfg.sliderThumbSize)
	th.Position = UDim2.fromOffset(-cfg.sliderThumbSize / 2, (cfg.sliderTrackHeight - cfg.sliderThumbSize) / 2)
	th.BackgroundColor3 = cfg.colorText
	th.BorderSizePixel = 0
	th.Parent = tk
	Style.corner(th, cfg.sliderThumbSize / 2)

	local hb = Instance.new("TextButton")
	hb.Name = "Hitbox"
	hb.Size = UDim2.new(1, 0, 0, cfg.componentHeight)
	hb.Position = UDim2.fromOffset(0, cfg.fontSizeMD + 6)
	hb.BackgroundTransparency = 1
	hb.BorderSizePixel = 0
	hb.Text = ""
	hb.AutoButtonColor = false
	hb.Parent = f

	self._tk = tk
	self._fl = fl
	self._th = th
	self._inp = inp
	self._title = t
	self:_updateVisual()

	hb.InputBegan:Connect(function(i)
		if not self._enabled or self._locked then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			self._dragging = true
			self:_fromMouse(i.Position)
		end
	end)
	hb.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			self._dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if self._dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			self:_fromMouse(i.Position)
		end
	end)

	inp.FocusLost:Connect(function()
		local n = tonumber(inp.Text:gsub(self._suffix, ""))
		if n then
			self._value = Util.clamp(n, self._min, self._max)
			self:_updateVisual()
			self:_emit(self._value)
		end
	end)

	return self
end

function Slider:_fmt()
	local v = self._value
	if self._decimals > 0 then
		v = string.format("%." .. self._decimals .. "f", v)
	else
		v = tostring(v)
	end
	return v .. self._suffix
end

function Slider:_fromMouse(pos)
	local a = self._tk.AbsolutePosition
	local s = self._tk.AbsoluteSize
	local rx = Util.clamp(pos.X - a.X, 0, s.X)
	local pct = rx / s.X
	self._value = self._min + (self._max - self._min) * pct
	if self._step > 0 then
		self._value = math.floor(self._value / self._step + 0.5) * self._step
	end
	self._value = Util.clamp(self._value, self._min, self._max)
	self:_updateVisual()
	self:_emit(self._value)
end

function Slider:_updateVisual()
	local pct = (self._value - self._min) / (self._max - self._min)
	self._fl.Size = UDim2.fromScale(pct, 1)
	local tx = self._tk.AbsoluteSize.X * pct - self._cfg.sliderThumbSize / 2
	self._th.Position = UDim2.fromOffset(tx, (self._cfg.sliderTrackHeight - self._cfg.sliderThumbSize) / 2)
	self._inp.Text = self:_fmt()
end

function Slider:setValue(v)
	self._value = Util.clamp(v, self._min, self._max)
	self:_updateVisual()
end

--============================================================================
-- INPUT
--============================================================================
local Input = setmetatable({}, { __index = Component })
Input.__index = Input

function Input.new(cfg, anim, title, placeholder, default, maxLen, numbersOnly)
	local self = Component.new(cfg, anim)
	setmetatable(self, Input)
	self._value = default or ""
	self._placeholder = placeholder or ""
	self._maxLen = maxLen or 0
	self._numbersOnly = numbersOnly or false

	local f = Instance.new("Frame")
	f.Name = "Input"
	f.Size = UDim2.new(1, 0, 0, cfg.componentHeight + cfg.fontSizeMD + 6)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	local t = Style.label(f, cfg, title or "", cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	t.Name = "Title"
	t.Size = UDim2.new(1, 0, 0, cfg.fontSizeMD + 2)

	local ib = Instance.new("Frame")
	ib.Name = "InputBg"
	ib.Size = UDim2.new(1, 0, 0, cfg.componentHeight)
	ib.Position = UDim2.fromOffset(0, cfg.fontSizeMD + 6)
	ib.BackgroundColor3 = cfg.colorSurface
	ib.BorderSizePixel = 0
	ib.Parent = f
	Style.corner(ib, cfg.cornerRadius)
	Style.stroke(ib, cfg.colorBorder, 1)

	local tb = Instance.new("TextBox")
	tb.Name = "Text"
	tb.Size = UDim2.new(1, -16, 1, 0)
	tb.Position = UDim2.fromOffset(8, 0)
	tb.BackgroundTransparency = 1
	tb.BorderSizePixel = 0
	tb.FontFace = cfg.font
	tb.TextSize = cfg.fontSizeMD
	tb.TextColor3 = cfg.colorText
	tb.PlaceholderText = self._placeholder
	tb.PlaceholderColor3 = cfg.colorTextSecondary
	tb.Text = self._value
	tb.TextXAlignment = Enum.TextXAlignment.Left
	tb.ClearTextOnFocus = false
	tb.Parent = ib

	self._tb = tb
	self._stroke = ib:FindFirstChildOfClass("UIStroke")

	tb.Focused:Connect(function()
		if self._stroke then self._stroke.Color = cfg.colorAccent end
	end)
	tb.FocusLost:Connect(function()
		if self._stroke then self._stroke.Color = cfg.colorBorder end
		self._value = tb.Text
		self:_emit(self._value)
	end)

	tb:GetPropertyChangedSignal("Text"):Connect(function()
		if self._numbersOnly then
			local filtered = tb.Text:gsub("[^%d%.%-]", "")
			if tb.Text ~= filtered then
				tb.Text = filtered
			end
		end
		if self._maxLen > 0 and #tb.Text > self._maxLen then
			tb.Text = tb.Text:sub(1, self._maxLen)
		end
	end)

	return self
end

function Input:setValue(v)
	self._value = v or ""
	if self._tb then self._tb.Text = self._value end
end

function Input:clear()
	self._value = ""
	if self._tb then self._tb.Text = "" end
end

--============================================================================
-- DROPDOWN
--============================================================================
local Dropdown = setmetatable({}, { __index = Component })
Dropdown.__index = Dropdown

function Dropdown.new(cfg, anim, title, items, default, multi)
	local self = Component.new(cfg, anim)
	setmetatable(self, Dropdown)
	self._items = items or {}
	self._multi = multi or false
	self._open = false
	self._list = nil
	self._value = default or (self._multi and {} or nil)

	local f = Instance.new("Frame")
	f.Name = "Dropdown"
	f.Size = UDim2.new(1, 0, 0, cfg.componentHeight + cfg.fontSizeMD + 6)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	local t = Style.label(f, cfg, title or "", cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	t.Name = "Title"
	t.Size = UDim2.new(1, 0, 0, cfg.fontSizeMD + 2)

	local sb = Instance.new("Frame")
	sb.Name = "SelectBg"
	sb.Size = UDim2.new(1, 0, 0, cfg.componentHeight)
	sb.Position = UDim2.fromOffset(0, cfg.fontSizeMD + 6)
	sb.BackgroundColor3 = cfg.colorSurface
	sb.BorderSizePixel = 0
	sb.Parent = f
	Style.corner(sb, cfg.cornerRadius)
	Style.stroke(sb, cfg.colorBorder, 1)

	local tl = Style.label(sb, cfg, self:_display(), cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	tl.Name = "Selected"
	tl.Size = UDim2.new(1, -30, 1, 0)
	tl.Position = UDim2.fromOffset(8, 0)

	local ar = Style.label(sb, cfg, "▼", cfg.fontSizeSM, cfg.colorTextSecondary, Enum.TextXAlignment.Center)
	ar.Name = "Arrow"
	ar.Size = UDim2.fromOffset(20, 20)
	ar.Position = UDim2.new(1, -24, 0.5, 0)
	ar.AnchorPoint = Vector2.new(0, 0.5)

	local hb = Instance.new("TextButton")
	hb.Name = "Hitbox"
	hb.Size = UDim2.new(1, 0, 1, 0)
	hb.BackgroundTransparency = 1
	hb.BorderSizePixel = 0
	hb.Text = ""
	hb.AutoButtonColor = false
	hb.Parent = sb

	self._tl = tl
	self._ar = ar
	self._stroke = sb:FindFirstChildOfClass("UIStroke")

	hb.MouseButton1Click:Connect(function()
		if not self._enabled or self._locked then return end
		if self._open then self:_close() else self:_open() end
	end)

	return self
end

function Dropdown:_display()
	if self._multi then
		local sel = self._value or {}
		if #sel == 0 then return "None selected" end
		local names = {}
		for _, item in ipairs(sel) do
			table.insert(names, type(item) == "table" and item.name or tostring(item))
		end
		return table.concat(names, ", ")
	else
		if not self._value then return "Select..." end
		return type(self._value) == "table" and self._value.name or tostring(self._value)
	end
end

function Dropdown:_open()
	self._open = true
	self._ar.Text = "▲"
	local c = self._cfg
	local lf = Instance.new("Frame")
	lf.Name = "DropdownList"
	lf.Size = UDim2.new(1, 0, 0, 0)
	lf.Position = UDim2.fromOffset(0, c.componentHeight + 2)
	lf.BackgroundColor3 = c.colorSurface
	lf.BorderSizePixel = 0
	lf.ClipsDescendants = true
	lf.ZIndex = 100
	lf.Parent = self._inst:FindFirstChild("SelectBg") or self._inst
	Style.corner(lf, c.cornerRadius)
	Style.stroke(lf, c.colorAccent, 1)

	local lo = Instance.new("UIListLayout")
	lo.Parent = lf
	local th = 0
	for i, item in ipairs(self._items) do
		local nm = type(item) == "table" and item.name or tostring(item)
		local ib = Instance.new("TextButton")
		ib.Name = "Item_" .. i
		ib.Size = UDim2.new(1, 0, 0, c.dropdownItemHeight)
		ib.BackgroundColor3 = c.colorSurface
		ib.BorderSizePixel = 0
		ib.FontFace = c.font
		ib.TextSize = c.fontSizeSM
		ib.TextColor3 = c.colorText
		ib.Text = "  " .. nm
		ib.TextXAlignment = Enum.TextXAlignment.Left
		ib.AutoButtonColor = false
		ib.ZIndex = 100
		ib.Parent = lf

		local sel = false
		if self._multi then
			for _, s in ipairs(self._value) do
				if (type(s) == "table" and s.name or tostring(s)) == nm then
					sel = true
					break
				end
			end
		else
			sel = (self._value and (type(self._value) == "table" and self._value.name or tostring(self._value)) == nm)
		end
		if sel then ib.BackgroundColor3 = c.colorSurfaceHover end

		ib.MouseEnter:Connect(function() ib.BackgroundColor3 = c.colorSurfaceHover end)
		ib.MouseLeave:Connect(function() if not sel then ib.BackgroundColor3 = c.colorSurface end end)
		ib.MouseButton1Click:Connect(function()
			if self._multi then
				local sv = self._value or {}
				local found = false
				for j, s in ipairs(sv) do
					if (type(s) == "table" and s.name or tostring(s)) == nm then
						table.remove(sv, j)
						found = true
						break
					end
				end
				if not found then table.insert(sv, item) end
				self._value = sv
			else
				self._value = item
				self:_close()
			end
			self._tl.Text = self:_display()
			self:_emit(self._value)
		end)
		th = th + c.dropdownItemHeight
	end

	local mh = math.min(th, c.dropdownMaxHeight)
	lf.Size = UDim2.new(1, 0, 0, mh)
	if th > mh then
		local sf = Instance.new("ScrollingFrame")
		sf.Name = "Scroll"
		sf.Size = UDim2.new(1, 0, 1, 0)
		sf.CanvasSize = UDim2.new(0, 0, 0, th)
		sf.ScrollBarThickness = c.scrollBarWidth
		sf.BackgroundTransparency = 1
		sf.BorderSizePixel = 0
		sf.Parent = lf
		lo.Parent = sf
		for _, ch in ipairs(lf:GetChildren()) do
			if ch:IsA("TextButton") then ch.Parent = sf end
		end
	end
	self._list = lf

	local conn
	conn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self._list and not self._list:IsDescendantOf(input.Position) then
				self:_close()
				if conn then conn:Disconnect() end
			end
		end
	end)
end

function Dropdown:_close()
	self._open = false
	self._ar.Text = "▼"
	if self._list then self._list:Destroy(); self._list = nil end
	if self._stroke then self._stroke.Color = self._cfg.colorBorder end
end

function Dropdown:setValue(v)
	self._value = v
	if self._tl then self._tl.Text = self:_display() end
end

function Dropdown:refresh(items)
	self._items = items or {}
end

function Dropdown:addItem(item)
	table.insert(self._items, item)
end

function Dropdown:removeItem(name)
	for i, item in ipairs(self._items) do
		if (type(item) == "table" and item.name or tostring(item)) == name then
			table.remove(self._items, i)
			break
		end
	end
end

function Dropdown:clear()
	self._items = {}
	self._value = self._multi and {} or nil
	if self._tl then self._tl.Text = self:_display() end
end

--============================================================================
-- KEYBIND
--============================================================================
local Keybind = setmetatable({}, { __index = Component })
Keybind.__index = Keybind

function Keybind.new(cfg, anim, title, default, mode)
	local self = Component.new(cfg, anim)
	setmetatable(self, Keybind)
	self._value = default or nil
	self._mode = mode or "Always"
	self._listening = false

	local f = Instance.new("Frame")
	f.Name = "Keybind"
	f.Size = UDim2.new(1, 0, 0, cfg.componentHeight)
	f.BackgroundColor3 = cfg.colorSurface
	f.BorderSizePixel = 0
	self._inst = f
	Style.corner(f, cfg.cornerRadius)
	Style.stroke(f, cfg.colorBorder, 1)

	local disp = self._value and self._value.Name or "None"
	local tl = Style.label(f, cfg, disp, cfg.fontSizeMD, cfg.colorText, Enum.TextXAlignment.Left)
	tl.Name = "KeyText"
	tl.Size = UDim2.new(1, -16, 1, 0)
	tl.Position = UDim2.fromOffset(8, 0)

	local hb = Instance.new("TextButton")
	hb.Name = "Hitbox"
	hb.Size = UDim2.new(1, 0, 1, 0)
	hb.BackgroundTransparency = 1
	hb.BorderSizePixel = 0
	hb.Text = ""
	hb.AutoButtonColor = false
	hb.Parent = f

	self._tl = tl
	self._stroke = f:FindFirstChildOfClass("UIStroke")

	local conn = nil
	hb.MouseButton1Click:Connect(function()
		if not self._enabled or self._locked then return end
		self._listening = true
		self._tl.Text = "..."
		self._stroke.Color = cfg.colorAccent
		if conn then conn:Disconnect() end
		conn = UserInputService.InputBegan:Connect(function(input)
			if not self._listening then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self._value = input.KeyCode
				self._tl.Text = input.KeyCode.Name
				self._listening = false
				self._stroke.Color = cfg.colorBorder
				self:_emit(self._value)
				if conn then conn:Disconnect(); conn = nil end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				self._value = Enum.UserInputType.MouseButton2
				self._tl.Text = "RMB"
				self._listening = false
				self._stroke.Color = cfg.colorBorder
				self:_emit(self._value)
				if conn then conn:Disconnect(); conn = nil end
			end
		end)
	end)

	return self
end

function Keybind:setKey(key)
	self._value = key
	if self._tl then self._tl.Text = key and key.Name or "None" end
end

function Keybind:getKey()
	return self._value
end

function Keybind:setMode(mode)
	self._mode = mode
end

function Keybind:getMode()
	return self._mode
end

--============================================================================
-- LAYOUT ENGINE
--============================================================================
local Layout = {}
Layout.__index = Layout

function Layout.new()
	return setmetatable({ _containers = {} }, Layout)
end

function Layout:bindContainer(container)
	table.insert(self._containers, container)
end

function Layout:updateCanvas(scrollFrame, layout, padding)
	local h = layout.AbsoluteContentSize.Y + (padding or 0) * 2
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, h)
end

--============================================================================
-- COMPONENT FACTORY
--============================================================================
local Factory = {}
Factory.__index = Factory

function Factory.new(cfg, anim)
	return setmetatable({ _cfg = cfg, _anim = anim, _counter = 0 }, Factory)
end

function Factory:_next()
	self._counter += 1
	return self._counter
end

function Factory:Label(title, desc)
	local c = Label.new(self._cfg, self._anim, title, desc)
	c._id = self:_next()
	return c
end

function Factory:Paragraph(title, desc)
	local c = Paragraph.new(self._cfg, self._anim, title, desc)
	c._id = self:_next()
	return c
end

function Factory:Divider(title)
	local c = Divider.new(self._cfg, self._anim, title)
	c._id = self:_next()
	return c
end

function Factory:Button(title, desc, cb)
	local c = Button.new(self._cfg, self._anim, title, desc, cb)
	c._id = self:_next()
	return c
end

function Factory:Toggle(title, desc, default)
	local c = Toggle.new(self._cfg, self._anim, title, desc, default)
	c._id = self:_next()
	return c
end

function Factory:Slider(title, min, max, step, suffix, decimals, default)
	local c = Slider.new(self._cfg, self._anim, title, min, max, step, suffix, decimals, default)
	c._id = self:_next()
	return c
end

function Factory:Input(title, placeholder, default, maxLen, numbersOnly)
	local c = Input.new(self._cfg, self._anim, title, placeholder, default, maxLen, numbersOnly)
	c._id = self:_next()
	return c
end

function Factory:Dropdown(title, items, default, multi)
	local c = Dropdown.new(self._cfg, self._anim, title, items, default, multi)
	c._id = self:_next()
	return c
end

function Factory:Keybind(title, default, mode)
	local c = Keybind.new(self._cfg, self._anim, title, default, mode)
	c._id = self:_next()
	return c
end

--============================================================================
-- SECTION
--============================================================================
local Section = {}
Section.__index = Section

function Section.new(cfg, title, desc)
	local self = setmetatable({
		_cfg = cfg,
		_title = title or "",
		_desc = desc,
		_inst = nil,
		_content = nil,
		_comps = {},
		_collapsed = false,
	}, Section)

	local f = Instance.new("Frame")
	f.Name = "Section"
	f.Size = UDim2.new(1, 0, 0, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	self._inst = f

	local th = 0
	if title and title ~= "" then
		local tl = Style.label(f, cfg, title:upper(), cfg.fontSizeSM, cfg.colorTextSecondary, Enum.TextXAlignment.Left)
		tl.Name = "SectionTitle"
		tl.Size = UDim2.new(1, -cfg.sectionSpacing * 2, 0, cfg.sectionTitleHeight)
		tl.Position = UDim2.fromOffset(cfg.sectionSpacing, cfg.sectionSpacing)
		th = cfg.sectionSpacing + cfg.sectionTitleHeight + cfg.sectionSpacing
		if desc then
			local dl = Style.label(f, cfg, desc, cfg.fontSizeXS, cfg.colorTextSecondary, Enum.TextXAlignment.Left)
			dl.Name = "SectionDesc"
			dl.Size = UDim2.new(1, -cfg.sectionSpacing * 2, 0, cfg.fontSizeXS + 2)
			dl.Position = UDim2.fromOffset(cfg.sectionSpacing, th)
			th = th + cfg.fontSizeXS + 2 + cfg.spacingXS
		end
		local ln = Instance.new("Frame")
		ln.Name = "Divider"
		ln.Size = UDim2.new(1, -cfg.sectionSpacing * 2, 0, 1)
		ln.Position = UDim2.fromOffset(cfg.sectionSpacing, th - 4)
		ln.BackgroundColor3 = cfg.colorBorder
		ln.BorderSizePixel = 0
		ln.Parent = f
	end

	local ct = Instance.new("Frame")
	ct.Name = "Content"
	ct.Size = UDim2.new(1, -cfg.sectionSpacing * 2, 0, 0)
	ct.Position = UDim2.fromOffset(cfg.sectionSpacing, th)
	ct.BackgroundTransparency = 1
	ct.BorderSizePixel = 0
	ct.Parent = f
	self._content = ct

	local lo = Instance.new("UIListLayout")
	lo.Name = "Layout"
	lo.Padding = UDim.new(0, cfg.componentPadding)
	lo.Parent = ct
	self._layout = lo

	f.Size = UDim2.new(1, 0, 0, th)
	return self
end

function Section:mount(parent)
	self._inst.Parent = parent
end

function Section:_add(comp)
	comp:mount(self._content)
	table.insert(self._comps, comp)
	self:_resize()
	return comp
end

function Section:_resize()
	local th = 0
	if self._title and self._title ~= "" then
		th = self._cfg.sectionSpacing + self._cfg.sectionTitleHeight + self._cfg.sectionSpacing
		if self._desc then
			th = th + self._cfg.fontSizeXS + 2 + self._cfg.spacingXS
		end
	end
	th = th + self._layout.AbsoluteContentSize.Y
	self._content.Size = UDim2.new(1, -self._cfg.sectionSpacing * 2, 0, self._layout.AbsoluteContentSize.Y)
	self._inst.Size = UDim2.new(1, 0, 0, th)
end

function Section:collapse()
	self._collapsed = true
	if self._content then self._content.Visible = false end
end

function Section:expand()
	self._collapsed = false
	if self._content then self._content.Visible = true end
end

function Section:getComponents()
	return self._comps
end

function Section:destroy()
	for _, c in ipairs(self._comps) do
		c:destroy()
	end
	self._comps = {}
	if self._inst then
		self._inst:Destroy()
		self._inst = nil
	end
end

--============================================================================
-- GROUP
--============================================================================
local Group = {}
Group.__index = Group

function Group.new(name, icon)
	return setmetatable({ name = name, icon = icon, tabs = {} }, Group)
end

function Group:addTab(name, icon)
	local tab = { name = name, icon = icon, sections = {}, _registry = nil, _factory = nil }

	function tab:_ensure(cfg, anim)
		if not tab._factory then
			tab._factory = Factory.new(cfg, anim)
			tab._registry = Registry.new()
		end
	end

	function tab:addSection(title, desc)
		tab:_ensure(self._cfg, self._anim)
		local sec = Section.new(self._cfg, title, desc)
		table.insert(tab.sections, sec)
		local api = {}

		function api:addLabel(title, desc)
			local c = tab._factory:Label(title, desc)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addParagraph(title, desc)
			local c = tab._factory:Paragraph(title, desc)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addDivider(title)
			local c = tab._factory:Divider(title)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addButton(title, desc, cb)
			local c = tab._factory:Button(title, desc, cb)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addToggle(title, desc, default)
			local c = tab._factory:Toggle(title, desc, default)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addSlider(title, min, max, step, suffix, decimals, default)
			local c = tab._factory:Slider(title, min, max, step, suffix, decimals, default)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addInput(title, placeholder, default, maxLen, numbersOnly)
			local c = tab._factory:Input(title, placeholder, default, maxLen, numbersOnly)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addDropdown(title, items, default, multi)
			local c = tab._factory:Dropdown(title, items, default, multi)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		function api:addKeybind(title, default, mode)
			local c = tab._factory:Keybind(title, default, mode)
			tab._registry:register(c._id, c)
			return sec:_add(c)
		end

		return api
	end

	function tab:getComponents()
		if tab._registry then return tab._registry:getAll() end
		return {}
	end

	function tab:getComponent(id)
		if tab._registry then return tab._registry:find(id) end
		return nil
	end

	table.insert(self.tabs, tab)
	return tab
end

--============================================================================
-- WORKSPACE
--============================================================================
local Workspace = {}
Workspace.__index = Workspace

function Workspace.new(bus, cfg, anim)
	return setmetatable({
		_bus = bus,
		_cfg = cfg,
		_anim = anim,
		_layout = Layout.new(),
		_inst = nil,
		_header = nil,
		_sidebar = nil,
		_tabCons = {},
		_vis = false,
	}, Workspace)
end

function Workspace:mount(layer)
	local c = self._cfg
	local f = Instance.new("Frame")
	f.Name = "NoirUI_Workspace"
	f.Size = UDim2.fromOffset(c.workspaceWidth, c.workspaceHeight)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = c.colorBg
	f.BorderSizePixel = 0
	f.Visible = false
	f.Parent = layer
	Style.corner(f, c.cornerRadius)
	Style.stroke(f, c.colorBorder, 1)

	self._header = Header.new(self._bus, c)
	self._header:mount(f)

	local sb = Instance.new("Frame")
	sb.Name = "Sidebar"
	sb.Size = UDim2.new(0, 40, 1, -c.headerHeight)
	sb.Position = UDim2.fromOffset(0, c.headerHeight)
	sb.BackgroundColor3 = c.colorSurface
	sb.BorderSizePixel = 0
	sb.Parent = f
	local sbb = Instance.new("Frame")
	sbb.Name = "Border"
	sbb.Size = UDim2.new(0, 1, 1, 0)
	sbb.Position = UDim2.fromScale(1, 0)
	sbb.BackgroundColor3 = c.colorBorder
	sbb.BorderSizePixel = 0
	sbb.Parent = sb
	self._sidebar = sb
	self._inst = f
end

function Workspace:createTab(tabName, sections)
	if not self._inst then return end
	if self._tabCons[tabName] then
		self._tabCons[tabName]:Destroy()
	end

	local c = self._cfg
	local sf = Instance.new("ScrollingFrame")
	sf.Name = "Tab_" .. tabName
	sf.Size = UDim2.new(1, -40, 1, -c.headerHeight)
	sf.Position = UDim2.fromOffset(40, c.headerHeight)
	sf.BackgroundColor3 = c.colorBg
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = c.scrollBarWidth
	sf.ScrollBarImageColor3 = c.colorBorder
	sf.Visible = false
	sf.Parent = self._inst

	local lo = Instance.new("UIListLayout")
	lo.Name = "Layout"
	lo.Padding = UDim.new(0, c.sectionSpacing)
	lo.Parent = sf

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, c.sectionSpacing)
	pad.PaddingBottom = UDim.new(0, c.sectionSpacing)
	pad.PaddingLeft = UDim.new(0, c.sectionSpacing)
	pad.PaddingRight = UDim.new(0, c.sectionSpacing)
	pad.Parent = sf

	for _, sec in ipairs(sections) do
		sec:mount(sf)
	end

	lo:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._layout:updateCanvas(sf, lo, c.sectionSpacing)
	end)
	self._layout:updateCanvas(sf, lo, c.sectionSpacing)
	self._layout:bindContainer(sf)

	self._tabCons[tabName] = sf
	return sf
end

function Workspace:setActiveTab(name)
	for n, ct in pairs(self._tabCons) do
		ct.Visible = (n == name)
	end
end

function Workspace:setHeaderInfo(g, t)
	if self._header then self._header:setBreadcrumb(g, t) end
end

function Workspace:show()
	if self._inst then
		self._inst.Visible = true
		self._vis = true
	end
end

function Workspace:hide()
	if self._inst then
		self._inst.Visible = false
		self._vis = false
	end
end

function Workspace:destroy()
	for _, ct in pairs(self._tabCons) do
		ct:Destroy()
	end
	self._tabCons = {}
	if self._header then
		self._header:destroy()
		self._header = nil
	end
	if self._inst then
		self._inst:Destroy()
		self._inst = nil
	end
end

--============================================================================
-- NOIRUI
--============================================================================
local NoirUI = {}
NoirUI.__index = NoirUI

function NoirUI.new(userTheme)
	local self = setmetatable({}, NoirUI)
	self._cfg = Util.mergeTheme(userTheme or {})

	self._bus = EventBus.new()
	self._sm = StateMachine.new(self._bus, self._cfg)
	self._motion = Motion.new(self._bus)
	self._drag = Drag.new(self._bus)
	self._layers = Layers.new(self._bus)

	self._anim = Anim.new(self._motion, self._cfg)

	self._toggle = FloatToggle.new(self._bus, self._cfg)
	self._radial = RadialNav.new(self._bus, self._cfg, self._motion)
	self._workspace = Workspace.new(self._bus, self._cfg, self._anim)

	self._groups = {}
	self._curGroup = nil
	self._curTab = nil

	self:_wire()

	if self._cfg.autoStart then
		self:start()
	end
	return self
end

function NoirUI:start()
	self._layers:mount()
	self._toggle:mount(self._layers:get("Floating"))
	self._radial:mount(self._layers:get("Radial"))
	self._workspace:mount(self._layers:get("Workspace"))

	local ti = self._toggle:getInstance()
	if ti then
		ti.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				self._drag:start(ti, i)
			end
		end)
		ti.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				-- FIX: Pass input to finish() so distance can be calculated
				local wasDragged = self._drag:finish(i)
				if not wasDragged then
					self._bus:emit(CONST.E_TOGGLE_CLICKED)
				end
			end
		end)
	end

	self._sm:start()
	self._bus:emit(CONST.E_SYSTEM_STARTED)
end

function NoirUI:_wire()
	self._bus:on(CONST.E_TOGGLE_CLICKED, function()
		if self._sm:getState() == CONST.S_IDLE then
			self._sm:transition(CONST.S_RADIAL_OPENING)
		else
			self._sm:transition(CONST.S_IDLE)
		end
	end)

	self._bus:on(CONST.E_RADIAL_OUTSIDE_CLICKED, function()
		local s = self._sm:getState()
		if s == CONST.S_GROUP_SELECTION or s == CONST.S_TAB_SELECTION then
			self._sm:transition(CONST.S_IDLE)
		end
	end)

	self._bus:on(CONST.E_RADIAL_LOGO_CLICKED, function()
		local s = self._sm:getState()
		if s == CONST.S_GROUP_SELECTION then
			self._sm:transition(CONST.S_IDLE)
		elseif s == CONST.S_TAB_SELECTION then
			self._sm:transition(CONST.S_GROUP_SELECTION)
		elseif s == CONST.S_WORKSPACE_ACTIVE then
			self._sm:transition(CONST.S_GROUP_SELECTION)
		end
	end)

	self._bus:on(CONST.E_RADIAL_SLOT_CLICKED, function(p)
		local s = self._sm:getState()
		if s == CONST.S_GROUP_SELECTION and p.mode == "group" then
			local g = self._groups[p.index]
			if g then
				self._curGroup = g
				self._sm:transition(CONST.S_TAB_SELECTION, { groupName = g.name })
			end
		elseif s == CONST.S_TAB_SELECTION and p.mode == "tab" then
			local t = self._curGroup and self._curGroup.tabs[p.index]
			if t then
				self._curTab = t
				self._sm:transition(CONST.S_WORKSPACE_OPENING, { tabName = t.name })
			end
		elseif s == CONST.S_WORKSPACE_ACTIVE and p.mode == "tab" then
			local t = self._curGroup and self._curGroup.tabs[p.index]
			if t then
				self._curTab = t
				self._sm:transition(CONST.S_WORKSPACE_ACTIVE, { tabName = t.name })
			end
		end
	end)

	self._bus:on(CONST.E_HEADER_CLOSE, function()
		self._sm:transition(CONST.S_GROUP_SELECTION)
	end)

	self._bus:on(CONST.E_STATE_ENTER, function(p)
		local s = p.state
		self._toggle:setVisible(s == CONST.S_IDLE)
		if s == CONST.S_GROUP_SELECTION then
			self._radial:setVisible(true)
			self._radial:animateToCenter()
			self._radial:showSlots(self._groups, "group")
			self._workspace:hide()
		elseif s == CONST.S_TAB_SELECTION then
			self._radial:showSlots(self._curGroup and self._curGroup.tabs or {}, "tab")
		elseif s == CONST.S_IDLE then
			self._radial:setVisible(false)
			self._workspace:hide()
		elseif s == CONST.S_WORKSPACE_OPENING then
			if self._curGroup and self._curTab then
				self._workspace:createTab(self._curTab.name, self._curTab.sections)
			end
			self._radial:animateToLeft(function()
				self._bus:emit(CONST.E_RADIAL_ANIMATION_DONE)
			end)
		elseif s == CONST.S_WORKSPACE_ACTIVE then
			self._workspace:show()
			if self._curGroup and self._curTab then
				self._workspace:setHeaderInfo(self._curGroup.name, self._curTab.name)
				self._workspace:setActiveTab(self._curTab.name)
			end
			self._radial:showSlots(self._curGroup and self._curGroup.tabs or {}, "tab")
		end
	end)

	self._bus:on(CONST.E_RADIAL_ANIMATION_DONE, function()
		if self._sm:getState() == CONST.S_WORKSPACE_OPENING then
			self._sm:transition(CONST.S_WORKSPACE_ACTIVE, { tabName = self._curTab and self._curTab.name })
		end
	end)
end

function NoirUI:addGroup(name, icon)
	local g = Group.new(name, icon)
	g._cfg = self._cfg
	g._anim = self._anim
	table.insert(self._groups, g)
	return g
end

function NoirUI:getState()
	return self._sm:getState()
end

function NoirUI:destroy()
	self._bus:emit("system:destroying")
	self._toggle:destroy()
	self._radial:destroy()
	self._workspace:destroy()
	self._motion:destroy()
	self._sm:destroy()
	self._layers:unmount()
	self._bus:destroy()
end

return NoirUI
