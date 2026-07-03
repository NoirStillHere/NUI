--============================================================================
-- NOIRUI v1.0.0
-- Phase 1: Foundation (Core systems only)
-- Single-file until architecture stabilizes.
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
	-- Z-Index stacking order
	Z_BACKGROUND = 100,
	Z_WORKSPACE = 200,
	Z_HEADER = 300,
	Z_RADIAL = 400,
	Z_OVERLAY = 500,
	Z_FLOATING = 600,
	Z_TOAST = 700,
	Z_MODAL = 800,
	Z_CONTEXT_MENU = 900,
	Z_TOOLTIP = 1000,

	-- States
	S_IDLE = "IDLE",
	S_RADIAL_OPENING = "RADIAL_OPENING",
	S_GROUP_SELECTION = "GROUP_SELECTION",
	S_TAB_SELECTION = "TAB_SELECTION",
	S_WORKSPACE_OPENING = "WORKSPACE_OPENING",
	S_WORKSPACE_ACTIVE = "WORKSPACE_ACTIVE",
	S_WORKSPACE_RESUME = "WORKSPACE_RESUME",

	-- Events
	E_STATE_ENTER = "state:enter",
	E_STATE_EXIT = "state:exit",
	E_SYSTEM_STARTED = "system:started",
	E_SYSTEM_DESTROYING = "system:destroying",
	E_INPUT_CLICK = "input:click",
	E_INPUT_DOUBLE_CLICK = "input:doubleClick",
	E_INPUT_RIGHT_CLICK = "input:rightClick",
	E_INPUT_CONFIRM = "input:confirm",
}

--============================================================================
-- CONFIG
--============================================================================
local DEFAULT_CONFIG = {
	autoStart = true,
	debug = false,
	inputDebounceMs = 100,

	toggleSize = 44,
	toggleDefaultPosX = 0.95,
	toggleDefaultPosY = 0.9,

	radialMaxGroups = 8,
	radialMaxTabs = 8,
	radialRadius = 120,
	radialSlotSize = 48,
	radialLogoSize = 56,
	radialVisibleRatio = 0.4,

	timeOpen = 0.2,
	timeClose = 0.15,
	timeRotate = 0.35,
	timeToWorkspace = 0.3,
	timeToGroup = 0.25,
	timeTabSwitch = 0.15,
	timeResume = 0.25,

	headerHeight = 36,
	workspaceWidth = 400,
	componentPoolSize = 30,

	colorBg = Color3.fromRGB(18, 18, 18),
	colorSurface = Color3.fromRGB(28, 28, 28),
	colorSurfaceHover = Color3.fromRGB(42, 42, 42),
	colorAccent = Color3.fromRGB(180, 180, 180),
	colorText = Color3.fromRGB(240, 240, 240),
	colorTextSecondary = Color3.fromRGB(160, 160, 160),
	colorBorder = Color3.fromRGB(50, 50, 50),
	colorRadialSlot = Color3.fromRGB(35, 35, 35),
	colorRadialHover = Color3.fromRGB(55, 55, 55),

	font = Enum.Font.Gotham,
	fontSizeSmall = 12,
	fontSizeDefault = 14,
	fontSizeLarge = 16,

	spacingXS = 4,
	spacingSM = 8,
	spacingMD = 12,
	spacingLG = 16,
	spacingXL = 24,
	cornerRadius = 6,
}

--============================================================================
-- UTILITIES
--============================================================================
local Util = {}

function Util.mergeConfig(userConfig)
	local merged = {}
	for k, v in pairs(DEFAULT_CONFIG) do
		merged[k] = (userConfig and userConfig[k] ~= nil) and userConfig[k] or v
	end
	return merged
end

function Util.clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

function Util.radialPosition(cx, cy, radius, angleRad, size)
	local x = cx + math.cos(angleRad) * radius - size / 2
	local y = cy + math.sin(angleRad) * radius - size / 2
	return x, y
end

function Util.slotAngle(index, total)
	return math.rad((360 / total) * index - 90)
end

function Util.angleDelta(fromRad, toRad)
	local twoPi = math.pi * 2
	local delta = (toRad - fromRad) % twoPi
	if delta > math.pi then delta = delta - twoPi end
	if delta < -math.pi then delta = delta + twoPi end
	return delta
end

--============================================================================
-- EVENT BUS
--============================================================================
local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
	return setmetatable({
		_listeners = {},
		_destroyed = false,
	}, EventBus)
end

function EventBus:on(eventName, callback)
	if self._destroyed then return function() end end
	if not self._listeners[eventName] then
		self._listeners[eventName] = {}
	end
	table.insert(self._listeners[eventName], callback)
	local bus = self
	return function()
		bus:off(eventName, callback)
	end
end

function EventBus:off(eventName, callback)
	if self._destroyed then return end
	local list = self._listeners[eventName]
	if not list then return end
	for i = #list, 1, -1 do
		if list[i] == callback then
			table.remove(list, i)
			break
		end
	end
	if #list == 0 then
		self._listeners[eventName] = nil
	end
end

function EventBus:emit(eventName, payload)
	if self._destroyed then return end
	local list = self._listeners[eventName]
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

-- Valid transitions from each state
local function makeTransitions()
	local S = CONST
	return {
		[S.S_IDLE]              = { S.S_RADIAL_OPENING, S.S_WORKSPACE_RESUME },
		[S.S_RADIAL_OPENING]    = { S.S_GROUP_SELECTION, S.S_IDLE },
		[S.S_GROUP_SELECTION]   = { S.S_TAB_SELECTION, S.S_IDLE },
		[S.S_TAB_SELECTION]     = { S.S_WORKSPACE_OPENING, S.S_GROUP_SELECTION, S.S_IDLE },
		[S.S_WORKSPACE_OPENING] = { S.S_WORKSPACE_ACTIVE, S.S_IDLE },
		[S.S_WORKSPACE_ACTIVE]  = { S.S_GROUP_SELECTION, S.S_IDLE, S.S_WORKSPACE_ACTIVE },
		[S.S_WORKSPACE_RESUME]  = { S.S_WORKSPACE_ACTIVE },
	}
end

function StateMachine.new(eventBus, config)
	return setmetatable({
		_bus = eventBus,
		_config = config,
		_transitions = makeTransitions(),
		_current = CONST.S_IDLE,
		_previous = nil,
		_history = {},
		_lastTab = nil,
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
	if not allowed then return false end

	local valid = false
	for _, s in ipairs(allowed) do
		if s == newState then
			valid = true
			break
		end
	end

	if not valid then
		if self._config.debug then
			warn(string.format(
				"NoirUI: Invalid state transition %s -> %s",
				self._current,
				newState
			))
		end
		return false
	end

	-- Push to history for back navigation
	if newState == CONST.S_GROUP_SELECTION or newState == CONST.S_TAB_SELECTION then
		table.insert(self._history, self._current)
	end

	-- Exit current state
	self._bus:emit(CONST.E_STATE_EXIT, { state = self._current })

	-- Transition
	self._previous = self._current
	self._current = newState

	-- Track last workspace tab for resume
	if newState == CONST.S_WORKSPACE_ACTIVE and data and data.tabName then
		self._lastTab = data.tabName
	end

	-- Enter new state
	self._bus:emit(CONST.E_STATE_ENTER, { state = newState, data = data })

	return true
end

function StateMachine:getState()
	return self._current
end

function StateMachine:getPreviousState()
	return self._previous
end

function StateMachine:getLastTab()
	return self._lastTab
end

function StateMachine:back()
	if #self._history == 0 then return false end
	return self:transition(table.remove(self._history))
end

function StateMachine:destroy()
	self._history = {}
	self._started = false
end

function StateMachine:_emitEnter(state)
	self._bus:emit(CONST.E_STATE_ENTER, { state = state })
end

--============================================================================
-- MOTION CONTROLLER
--============================================================================
local MotionController = {}
MotionController.__index = MotionController

function MotionController.new(eventBus)
	return setmetatable({
		_bus = eventBus,
		_tweens = {},
	}, MotionController)
end

function MotionController:play(actorId, instance, props, duration, easingStyle, easingDir, onComplete)
	self:stop(actorId)

	local tweenInfo = TweenInfo.new(
		duration,
		easingStyle or Enum.EasingStyle.Quad,
		easingDir or Enum.EasingDirection.Out,
		0, false, 0
	)
	local tween = TweenService:Create(instance, tweenInfo, props)
	self._tweens[actorId] = tween
	tween:Play()

	tween.Completed:Connect(function(playbackState)
		self._tweens[actorId] = nil
		if playbackState == Enum.PlaybackState.Completed and onComplete then
			onComplete()
		end
	end)
end

function MotionController:stop(actorId)
	local tween = self._tweens[actorId]
	if tween then
		tween:Cancel()
		self._tweens[actorId] = nil
	end
end

function MotionController:cancelAll()
	for id, tween in pairs(self._tweens) do
		tween:Cancel()
	end
	self._tweens = {}
end

function MotionController:isPlaying(actorId)
	return self._tweens[actorId] ~= nil
end

function MotionController:destroy()
	self:cancelAll()
end

--============================================================================
-- INPUT ROUTER
--============================================================================
local InputRouter = {}
InputRouter.__index = InputRouter

function InputRouter.new(eventBus, stateMachine, config)
	return setmetatable({
		_bus = eventBus,
		_sm = stateMachine,
		_config = config,
		_connections = {},
		_lastClickTime = 0,
	}, InputRouter)
end

function InputRouter:start()
	if #self._connections > 0 then return end

	local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		self:_handleInput(input, gameProcessed)
	end)
	table.insert(self._connections, conn)
end

function InputRouter:stop()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
end

function InputRouter:_handleInput(input, gameProcessed)
	if gameProcessed then return end

	local state = self._sm:getState()

	-- Keyboard
	if input.UserInputType == Enum.UserInputType.Keyboard then
		self:_handleKeyboard(input, state)
		return
	end

	-- Mouse
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		self:_handleLeftClick(state)
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		self:_handleRightClick(state)
		return
	end
end

function InputRouter:_handleKeyboard(input, state)
	if input.KeyCode == Enum.KeyCode.Escape then
		if state == CONST.S_GROUP_SELECTION then
			self._sm:transition(CONST.S_IDLE)
		elseif state == CONST.S_TAB_SELECTION then
			self._sm:transition(CONST.S_GROUP_SELECTION)
		elseif state == CONST.S_WORKSPACE_ACTIVE then
			self._sm:transition(CONST.S_IDLE)
		end
	elseif input.KeyCode == Enum.KeyCode.Return then
		self._bus:emit(CONST.E_INPUT_CONFIRM, { state = state })
	end
end

function InputRouter:_handleLeftClick(state)
	local now = tick()
	local elapsed = now - self._lastClickTime
	self._lastClickTime = now

	if elapsed < (self._config.inputDebounceMs / 1000) then
		return -- Debounced
	end

	if elapsed < 0.3 then
		self._bus:emit(CONST.E_INPUT_DOUBLE_CLICK, { state = state })
	else
		self._bus:emit(CONST.E_INPUT_CLICK, { state = state })
	end
end

function InputRouter:_handleRightClick(state)
	self._bus:emit(CONST.E_INPUT_RIGHT_CLICK, { state = state })
end

--============================================================================
-- LAYER MANAGER
--============================================================================
local LayerManager = {}
LayerManager.__index = LayerManager

local LAYER_DEFS = {
	{ "Background",   CONST.Z_BACKGROUND },
	{ "Workspace",    CONST.Z_WORKSPACE },
	{ "Header",       CONST.Z_HEADER },
	{ "Radial",       CONST.Z_RADIAL },
	{ "Overlay",      CONST.Z_OVERLAY },
	{ "Floating",     CONST.Z_FLOATING },
	{ "Toast",        CONST.Z_TOAST },
	{ "Modal",        CONST.Z_MODAL },
	{ "ContextMenu",  CONST.Z_CONTEXT_MENU },
	{ "Tooltip",      CONST.Z_TOOLTIP },
}

function LayerManager.new(eventBus)
	return setmetatable({
		_bus = eventBus,
		_layers = {},
		_parent = nil,
		_mounted = false,
	}, LayerManager)
end

function LayerManager:mount()
	if self._mounted then return end

	local player = Players.LocalPlayer
	if not player then
		error("NoirUI LayerManager: No LocalPlayer found. Call mount() after player is loaded.")
	end

	local playerGui = player:WaitForChild("PlayerGui")
	self._parent = playerGui

	for _, def in ipairs(LAYER_DEFS) do
		local name, zIndex = def[1], def[2]
		local gui = Instance.new("ScreenGui")
		gui.Name = "NoirUI_" .. name
		gui.DisplayOrder = zIndex
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = playerGui
		self._layers[name] = gui
	end

	self._mounted = true
end

function LayerManager:get(name)
	if not self._mounted then
		error("NoirUI LayerManager: Cannot get layer '" .. name .. "' before mount()")
	end
	return self._layers[name]
end

function LayerManager:isMounted()
	return self._mounted
end

function LayerManager:unmount()
	for _, gui in pairs(self._layers) do
		gui:Destroy()
	end
	self._layers = {}
	self._parent = nil
	self._mounted = false
end

--============================================================================
-- NOIRUI PUBLIC API
--============================================================================
local NoirUI = {}
NoirUI.__index = NoirUI

function NoirUI.new(userConfig)
	local self = setmetatable({}, NoirUI)

	-- Config
	self._config = Util.mergeConfig(userConfig or {})

	-- Core systems (order matters: bus first, then dependents)
	self._bus = EventBus.new()
	self._sm = StateMachine.new(self._bus, self._config)
	self._motion = MotionController.new(self._bus)
	self._input = InputRouter.new(self._bus, self._sm, self._config)
	self._layers = LayerManager.new(self._bus)

	-- Auto-start if configured
	if self._config.autoStart then
		self:start()
	end

	return self
end

function NoirUI:start()
	if not self._layers:isMounted() then
		self._layers:mount()
	end
	self._sm:start()
	self._input:start()
	self._bus:emit(CONST.E_SYSTEM_STARTED)
end

function NoirUI:destroy()
	self._bus:emit(CONST.E_SYSTEM_DESTROYING)
	self._input:stop()
	self._motion:destroy()
	self._sm:destroy()
	self._layers:unmount()
	self._bus:destroy()
end

-- Internal accessors (for debugging and future modules)
function NoirUI:getConfig()       return self._config end
function NoirUI:getBus()         return self._bus end
function NoirUI:getState()       return self._sm end
function NoirUI:getMotion()      return self._motion end
function NoirUI:getInput()       return self._input end
function NoirUI:getLayers()      return self._layers end

return NoirUI
