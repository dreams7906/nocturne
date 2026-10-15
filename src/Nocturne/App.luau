--[[
	App
	Low-level application object: ScreenGui, theme, toolbar, window, pages,
	overlays and configs. The public Library API (init.luau) wraps this;
	use it directly only if you want the raw component calls.

	local app = App.new({ Title = "Nocturne", Theme = "Midnight" })
	local page = app:Page({ Name = "Combat", Icon = "combat" })
	page:Section({ Title = "Feedback" }):Toggle({ Text = "Hit markers", Flag = "HitMarkers" })
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Util = require(script.Parent.Core.Util)
local Signal = require(script.Parent.Core.Signal)
local State = require(script.Parent.Core.State)
local Keybinds = require(script.Parent.Core.Keybinds)
local Popups = require(script.Parent.Core.Popups)
local Motion = require(script.Parent.Animations.Motion)
local Theme = require(script.Parent.Themes.Theme)
local Presets = require(script.Parent.Themes.Presets)
local Icons = require(script.Parent.Icons.Icons)
local Tooltip = require(script.Parent.Components.Tooltip)
local Notifications = require(script.Parent.Components.Notifications)
local Window = require(script.Parent.Navigation.Window)
local Toolbar = require(script.Parent.Navigation.Toolbar)
local Page = require(script.Parent.Navigation.Page)
local Watermark = require(script.Parent.Overlays.Watermark)
local KeybindList = require(script.Parent.Overlays.KeybindList)
local ConfigManager = require(script.Parent.Config.ConfigManager)

local Nocturne = {
	Version = "1.0.0",
	Icons = Icons,
	Presets = Presets,
	Motion = Motion,
}

local App = {}
App.__index = App

function Nocturne.new(options)
	options = options or {}
	local player = Players.LocalPlayer
	local parent = options.Parent or player:WaitForChild("PlayerGui")
	local name = options.Name or "Nocturne"

	local previous = parent:FindFirstChild(name)
	if previous then
		previous:Destroy()
	end

	local gui = Util.new("ScreenGui", {
		Name = name,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		Enabled = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = options.DisplayOrder or 50,
		Parent = parent,
	})
	local overlay = Util.frame({
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 100,
		Parent = gui,
	})

	local theme = Theme.new(options.Theme or "Midnight")
	if options.Accent then
		theme.Values.Accent = options.Accent
		theme:Refresh(true)
	end

	-- Shared context handed to every component.
	local ctx = {
		Gui = gui,
		Overlay = overlay,
		Theme = theme,
		State = State.new(),
		Keybinds = Keybinds.new(),
		Popups = Popups.new(),
		NotifyDuration = 4,
		_scale = 1,
		_gloss = {},
	}
	function ctx:GetScale()
		return self._scale
	end
	function ctx:RegisterGloss(instance)
		self._gloss[instance] = true
		instance.Destroying:Once(function()
			self._gloss[instance] = nil
		end)
		local on = self.Theme.Values.Gloss
		if instance:IsA("UIGradient") then
			instance.Enabled = on
		else
			instance.Visible = on
		end
		return instance
	end

	ctx.Tooltip = Tooltip.new(ctx)
	local notifications = Notifications.new(ctx)
	ctx.Notify = function(opts)
		return notifications:Push(opts)
	end

	local self = setmetatable({
		ctx = ctx,
		Gui = gui,
		Theme = theme,
		Flags = ctx.State,
		Keybinds = ctx.Keybinds,
		Notifications = notifications,
		Pages = {},
		Windows = {},
		_windowOptions = options,
		PrivacyMode = options.PrivacyMode == true,
		UserScale = options.Scale or 1,
		BlurEnabled = options.Blur == true,
		CollapseOnReselect = options.CollapseOnReselect ~= false,
		Opened = Signal.new(),
		Closed = Signal.new(),
		_connections = {},
		_interfaceVisible = true,
		_visibilityVersion = 0,
	}, App)
	ctx.IsInterfaceVisible = function() return self._interfaceVisible end

	self.Toolbar = Toolbar.new(ctx)
	ctx.ToolbarBottom = function()
		return self.Toolbar:Bottom()
	end
	self.Window = Window.new(ctx, options)
	self:_attachWindow(self.Window)
	self.Watermark = Watermark.new(ctx, options)
	self.KeybindList = KeybindList.new(ctx)
	self.Configs = ConfigManager.new(ctx.State)
	gui.Destroying:Once(function()
		self:Destroy()
	end)

	self.Toolbar.Clicked:Connect(function(page)
		self:_fromToolbar(page)
	end)
	self._menuBind = ctx.Keybinds:Register({
		Name = "Menu",
		Key = options.MenuKey and (typeof(options.MenuKey) == "EnumItem" and options.MenuKey.Name or options.MenuKey)
			or "RightControl",
		Locked = true,
		OnPress = function()
			self:Toggle()
		end,
	})

	notifications:SetScale(1)
	table.insert(self._connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_applyScale()
	end))
	task.defer(function()
		self:_applyScale()
	end)

	return self
end

-- Navigation ----------------------------------------------------------------

function App:Page(opts)
	local window = self.Windows[1]
	if #self.Pages > 0 then
		local options = table.clone(self._windowOptions)
		options.Subtitle = opts.Name
		options.PrivacyMode = self.PrivacyMode
		window = Window.new(self.ctx, options)
		self:_attachWindow(window)
		window:SetScale(self.ctx:GetScale())
	end
	local page = Page.new(self.ctx, window.PageHolder, opts)
	page.Window = window
	page.RootPage = page
	table.insert(self.Pages, page)
	window:AddPage(page)
	self.Toolbar:AddItem(page)
	window:Select(page, true)
	return page
end

function App:SubPage(parent, opts)
	local root = parent.RootPage or parent
	local window = root.Window
	local page = Page.new(self.ctx, window.PageHolder, {
		Name = parent.Name .. "." .. opts.Title,
		DisplayName = opts.Title,
		Icon = opts.Icon or root.Icon,
		Columns = opts.Columns,
	})
	page.Window, page.RootPage = window, root
	if not root.DisplayName then
		root.DisplayName = "General"
		window._tabs[root].Label.Text = root.DisplayName
	end
	window:AddPage(page)
	return page
end

function App:_attachWindow(window)
	table.insert(self.Windows, window)
	window.Index = #self.Windows
	window.Focused:Connect(function()
		self:_focusWindow(window)
	end)
	window.Closed:Connect(function()
		self:_refreshDock()
		self:_applyBlur(self:IsOpen())
		self.Closed:Fire()
	end)
	window.PageChanged:Connect(function() self:_refreshDock() end)
end

function App:_focusWindow(window)
	self.Window = window
	-- Keep the focused window above its siblings without overtaking the dock.
	for _, sibling in ipairs(self.Windows) do
		sibling.Holder.ZIndex = sibling == window and 12 or 10
	end
	self:_refreshDock()
end

function App:_refreshDock()
	local opened = {}
	for _, window in ipairs(self.Windows) do
		if window.IsOpen and window.Current then
			opened[window.Current.RootPage or window.Current] = true
		end
	end
	self.Toolbar:SetOpenPages(opened)
	local current = self.Window.Current
	self.Toolbar:SetActive(self.Window.IsOpen and current and (current.RootPage or current) or nil)
end

function App:GetPage(name)
	for _, window in ipairs(self.Windows) do
		for _, page in ipairs(window.Pages) do
			if page.Name == name then return page end
		end
	end
	return nil
end

function App:_fromToolbar(page)
	local window = page.Window
	if window.IsOpen and not window.Minimized then
		if self.CollapseOnReselect then
			window:Close()
		end
		return
	end
	if window.Minimized then
		window:SetMinimized(false)
	end
	self:_focusWindow(window)
	self:Open()
end

function App:SelectPage(name)
	local page = type(name) == "table" and name or self:GetPage(name)
	if page then
		self:_focusWindow(page.Window)
		page.Window:Select(page)
	end
end

function App:Open(pageName)
	self:_setInterfaceVisible(true)
	if pageName then
		self:SelectPage(pageName)
	end
	self.Window:Open()
	self:_refreshDock()
	self:_applyBlur(true)
	self.Opened:Fire()
end

function App:Close()
	self:_setInterfaceVisible(false)
end

function App:_setInterfaceVisible(shown)
	if self._interfaceVisible == shown then return end
	self._interfaceVisible = shown
	self._visibilityVersion += 1
	local version = self._visibilityVersion
	self.ctx.Popups:CloseAll()
	self.ctx.Tooltip:Hide()
	if shown then self.Gui.Enabled = true end
	self.Toolbar:SetPresented(shown)
	for _, window in ipairs(self.Windows) do
		window:SetPresented(shown)
	end
	self:_applyBlur(shown and self:IsOpen())
	if not shown then
		local function finish()
			if not self._destroyed and version == self._visibilityVersion then
				self.Gui.Enabled = false
			end
		end
		local duration = Motion.info("Normal").Time
		if duration <= 0 then finish() else task.delay(duration, finish) end
	end
end

function App:Toggle()
	self:_setInterfaceVisible(not self._interfaceVisible)
end

function App:IsOpen()
	if not self._interfaceVisible or not self.Gui.Enabled then return false end
	for _, window in ipairs(self.Windows) do
		if window.IsOpen then return true end
	end
	return false
end

function App:Notify(opts)
	return self.ctx.Notify(opts)
end

-- Appearance ----------------------------------------------------------------

function App:SetTheme(name)
	self.Theme:SetPreset(name)
end

function App:SetAccent(color)
	self.Theme:SetAccent(color)
end

function App:SetTransparency(value)
	self.Theme:Set("Transparency", math.clamp(value, 0, 0.6))
end

function App:SetGloss(enabled)
	self.Theme:Set("Gloss", enabled)
	for instance in pairs(self.ctx._gloss) do
		if instance:IsA("UIGradient") then
			instance.Enabled = enabled
		else
			instance.Visible = enabled
		end
	end
end

function App:SetReducedMotion(enabled)
	Motion.Reduced = enabled
end

function App:SetAnimationSpeed(speed)
	Motion.Speed = math.clamp(speed, 0.25, 3)
end

function App:SetScale(scale)
	self.UserScale = math.clamp(scale, 0.6, 1.4)
	self:_applyScale()
end

function App:SetPrivacyMode(enabled)
	self.PrivacyMode = enabled == true
	for _, window in ipairs(self.Windows) do
		window:SetPrivacyMode(self.PrivacyMode)
	end
	local player = Players.LocalPlayer
	self.Watermark.Name.Text = self.PrivacyMode and "User" or (player and player.DisplayName or "Player")
	self.Watermark:_resize()
end

-- Fits the window on small screens (phones) on top of the user's choice.
function App:_applyScale()
	local viewport = self.Gui.AbsoluteSize
	if viewport.X <= 0 or viewport.Y <= 0 then
		return
	end
	local width, height = Window.Width, Window.Height
	for _, window in ipairs(self.Windows) do
		width = math.max(width, window.Width)
		height = math.max(height, window.Height)
	end
	local fit = math.min((viewport.X - 32) / width, (viewport.Y - 96) / height)
	local scale = math.max(0.1, math.min(self.UserScale, fit))
	local chrome = self.UserScale * math.clamp(viewport.X / 520, 0.7, 1)
	self.ctx._scale = scale
	for _, window in ipairs(self.Windows) do
		window:SetScale(scale)
	end
	self.Toolbar:SetScale(chrome)
	self.Notifications:SetScale(chrome)
	self.Watermark:SetScale(chrome)
	self.KeybindList:SetScale(chrome)
	self.ctx.Popups:CloseAll()
end

function App:SetBlur(enabled)
	self.BlurEnabled = enabled
	self:_applyBlur(enabled and self:IsOpen())
end

function App:_applyBlur(on)
	if not self.BlurEnabled then
		on = false
	end
	local blur = self._blur
	if on then
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "NocturneBlur"
			blur.Size = 0
			blur.Parent = Lighting
			self._blur = blur
		end
		Motion.tween(blur, "Smooth", { Size = 12 })
	elseif blur then
		Motion.tween(blur, "Normal", { Size = 0 }, function()
			if self._blur == blur and not (self.BlurEnabled and self:IsOpen()) then
				blur:Destroy()
				self._blur = nil
			end
		end)
	end
end

function App:SetMenuKey(key)
	local name = typeof(key) == "EnumItem" and key.Name or key
	self.ctx.Keybinds:Assign(self._menuBind, name)
end

function App:GetMenuBind()
	return self._menuBind
end

function App:SetNotifications(opts)
	if opts.Enabled ~= nil then
		self.Notifications.Enabled = opts.Enabled
	end
	if opts.Duration then
		self.ctx.NotifyDuration = opts.Duration
	end
	if opts.Position then
		self.Notifications:SetPosition(opts.Position)
	end
	if opts.Sound ~= nil then
		if opts.Sound then
			self.ctx.NotifySound = function()
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
				sound.Volume = 0.35
				SoundService:PlayLocalSound(sound)
				task.delay(2, function()
					sound:Destroy()
				end)
			end
		else
			self.ctx.NotifySound = nil
		end
	end
end

function App:SetTooltips(enabled)
	self.ctx.Tooltip.Enabled = enabled
	if not enabled then
		self.ctx.Tooltip:Hide()
	end
end

function App:ResetPosition()
	for _, window in ipairs(self.Windows) do
		window:Center()
	end
end

function App:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	self.ctx.Keybinds:Destroy()
	self.ctx.Popups:Destroy()
	for _, window in ipairs(self.Windows) do
		window:Destroy()
	end
	if self._blur then
		self._blur:Destroy()
	end
	self.Gui:Destroy()
	self.Opened:Destroy()
	self.Closed:Destroy()
end

return Nocturne
