--[[
	Nocturne · dark glass interface library for Roblox

	local Library = require(ReplicatedStorage.Nocturne)

	local Window = Library:CreateWindow({ Title = "Nocturne", SubTitle = "My Game" })
	local Main = Window:AddTab({ Title = "Main", Icon = "combat" })
	local Section = Main:AddSection({ Title = "General", Side = "Left" })
	Section:AddToggle("MyToggle", { Title = "Do something", Callback = function(v) end })

	Every tab gets a button on the floating dock at the top of the screen.
	See README.md for the full API.
]]

local App = require(script.App)
local Presets = require(script.Themes.Presets)
local Icons = require(script.Icons.Icons)
local Motion = require(script.Animations.Motion)
local SettingsTab = require(script.Builtins.SettingsTab)
local ConfigsTab = require(script.Builtins.ConfigsTab)

local Library = {
	Version = "1.0.0",
	Flags = {},
	Options = {},
	Unloaded = false,
	Icons = Icons,
	Presets = Presets,
	Motion = Motion,
	App = nil,
	_unload = {},
}

local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

-- Helpers --------------------------------------------------------------------

local function call(fn, ...)
	if fn then
		task.spawn(fn, ...)
	end
end

local function slug(text)
	return (string.gsub(tostring(text or ""), "[^%w]", ""))
end

-- Accepts (flag, options) or (options) with options.Flag. Generates a flag
-- from tab / section / title when none is given so the element still saves.
local function args(self, flag, opts)
	if type(flag) == "table" then
		opts, flag = flag, flag.Flag
	end
	opts = opts or {}
	if not flag then
		flag = ("%s.%s.%s"):format(slug(self.TabTitle), slug(self.Title), slug(opts.Title or opts.Text or "Element"))
		local base, n = flag, 1
		while Library.Options[flag] do
			n += 1
			flag = base .. n
		end
	end
	return flag, opts
end

local function keyName(key)
	if typeof(key) == "EnumItem" then
		if key.EnumType == Enum.UserInputType then
			return key == Enum.UserInputType.MouseButton2 and "MB2" or (key == Enum.UserInputType.MouseButton3 and "MB3" or nil)
		end
		return key ~= Enum.KeyCode.Unknown and key.Name or nil
	elseif type(key) == "string" then
		if key == "MouseButton2" then
			return "MB2"
		elseif key == "MouseButton3" then
			return "MB3"
		elseif key == "" or key == "None" or key == "none" then
			return nil
		end
		return key
	end
	return nil
end

-- Shared element shape: .Value, :SetValue, :OnChanged, :SetVisible, :Destroy
local function element(self, flag, value, row)
	local el = { Flag = flag, Value = value, Row = row, _listeners = {} }
	function el:OnChanged(fn)
		table.insert(self._listeners, fn)
		return self
	end
	function el:SetVisible(visible)
		if self.Row then
			self.Row.Visible = visible
		end
	end
	function el:Destroy()
		if self.Row then
			self.Row:Destroy()
		end
		Library.Options[flag] = nil
		Library.Flags[flag] = nil
	end
	Library.Options[flag] = el
	Library.Flags[flag] = value
	return el
end

local function changed(el, value, callback)
	el.Value = value
	Library.Flags[el.Flag] = value
	call(callback, value)
	for _, fn in ipairs(el._listeners) do
		call(fn, value)
	end
end

local function lastRow(container)
	return container.Frame:FindFirstChild("Row" .. container._order)
end

-- Library --------------------------------------------------------------------

--[[
	Library:CreateWindow({
		Title = "Nocturne", SubTitle = "Interface", Badge = "Plus",
		Theme = "Midnight", Accent = Color3?, ToggleKey = Enum.KeyCode.RightControl,
		Footer = "nocturne.ui", Build = "Build <b>1.0.0</b>",
		Scale = 1, Blur = false, OpenOnStart = true,
		SettingsTab = true, ConfigsTab = true,
	})
]]
function Library:CreateWindow(opts)
	opts = opts or {}
	if self.App then
		self:Unload()
	end
	self.Unloaded = false

	local app = App.new({
		Title = opts.Title,
		Subtitle = opts.SubTitle or opts.Subtitle,
		Badge = opts.Badge,
		Profile = opts.Profile,
		ShowProfile = opts.ShowProfile,
		PrivacyMode = opts.PrivacyMode,
		Width = opts.Width,
		Height = opts.Height,
		Resizable = opts.Resizable,
		Theme = opts.Theme,
		Accent = opts.Accent,
		MenuKey = opts.ToggleKey or opts.MenuKey,
		FooterCenter = opts.Footer,
		FooterRight = opts.Build,
		Scale = opts.Scale,
		Blur = opts.Blur,
		Parent = opts.Parent,
	})
	self.App = app

	local window = setmetatable({ App = app, Tabs = {}, _builtins = false }, Window)
	self.Window = window

	-- Built-in tabs go after the script's own tabs: deferred until the
	-- creating script finishes its synchronous setup.
	task.defer(function()
		window:_addBuiltins(opts)
		if opts.OpenOnStart ~= false and not self.Unloaded then
			app:Open()
		end
	end)
	return window
end

function Library:Notify(opts, duration)
	if not self.App then
		return
	end
	if type(opts) == "string" then
		opts = { Title = opts, Duration = duration }
	end
	return self.App:Notify({
		Title = opts.Title,
		Text = opts.Content or opts.Text,
		Type = string.lower(opts.Type or "info"),
		Duration = opts.Duration,
	})
end

function Library:Toggle()
	if self.App then
		self.App:Toggle()
	end
end

function Library:SetTheme(name)
	if self.App then
		self.App:SetTheme(name)
	end
end

function Library:SetAccent(color)
	if self.App then
		self.App:SetAccent(color)
	end
end

function Library:SaveConfig(name)
	return self.App.Configs:Save(name)
end

function Library:LoadConfig(name)
	return self.App.Configs:Load(name)
end

function Library:DeleteConfig(name)
	return self.App.Configs:Delete(name)
end

function Library:GetConfigs()
	return self.App.Configs:List()
end

function Library:ExportConfig()
	return self.App.Configs:Export()
end

function Library:ImportConfig(json)
	return self.App.Configs:Import(json)
end

function Library:OnUnload(fn)
	table.insert(self._unload, fn)
end

function Library:Unload()
	if not self.App then
		return
	end
	for _, fn in ipairs(self._unload) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[Nocturne] OnUnload callback failed: " .. tostring(err))
		end
	end
	table.clear(self._unload)
	self.App:Destroy()
	self.App = nil
	self.Window = nil
	table.clear(self.Options)
	self.Unloaded = true
end

-- Window ---------------------------------------------------------------------

function Window:AddTab(opts)
	opts = opts or {}
	local title = opts.Title or opts.Name or ("Tab " .. (#self.Tabs + 1))
	local page = self.App:Page({ Name = title, Icon = opts.Icon or "misc" })
	local tab = setmetatable({ Window = self, Page = page, Title = title }, Tab)
	table.insert(self.Tabs, tab)
	return tab
end

function Window:SelectTab(which)
	local tab = which
	if type(which) == "number" then
		tab = self.Tabs[which]
	elseif type(which) == "string" then
		for _, candidate in ipairs(self.Tabs) do
			if candidate.Title == which then
				tab = candidate
			end
		end
		if type(tab) == "string" then
			self.App:SelectPage(which) -- built-in tabs
			return
		end
	end
	if type(tab) == "table" and tab.Page then
		self.App:SelectPage(tab.Page)
	end
end

function Window:Open()
	self.App:Open()
end

function Window:Close()
	self.App:Close()
end

function Window:Toggle()
	self.App:Toggle()
end

function Window:SetScale(scale)
	self.App:SetScale(scale)
end

function Window:_addBuiltins(opts)
	if self._builtins or Library.Unloaded then
		return
	end
	self._builtins = true
	if opts.ConfigsTab ~= false then
		ConfigsTab(self.App)
	end
	if opts.SettingsTab ~= false then
		SettingsTab(self.App)
	end
end

-- Tab ------------------------------------------------------------------------

function Tab:Open()
	self.Window.App:Open(self.Page.Name)
end

function Tab:Close()
	self.Page.Window:Close()
end

function Tab:Toggle()
	if self.Page.Window.IsOpen then
		self:Close()
	else
		self:Open()
	end
end

function Tab:IsOpen()
	return self.Window.App.Gui.Enabled and self.Page.Window.IsOpen
end

function Tab:SetSize(width, height)
	self.Page.Window:SetSize(width, height)
end

--[[
	Tab:AddSection({ Title = "Main", Side = "Left" | "Right", Tabs = { "A", "B" } })
	With Tabs, the section header becomes small tabs; use section:Tab("B").
]]
function Tab:AddSection(opts)
	opts = opts or {}
	local side = opts.Side
	if side == 2 or side == "Right" then
		side = "Right"
	elseif side == 1 or side == "Left" then
		side = "Left"
	else
		-- Default: alternate so both columns fill evenly.
		local orders = self.Page._orders
		side = orders.Left > orders.Right and "Right" or "Left"
	end
	local container = self.Page:Section({ Title = opts.Title, Side = side, Tabs = opts.Tabs })
	return setmetatable({
		Container = container,
		Title = opts.Title or (opts.Tabs and opts.Tabs[1]) or "Section",
		TabTitle = self.Title,
	}, Section)
end

-- Section --------------------------------------------------------------------

function Section:Tab(name)
	local container = self.Container:Tab(name)
	if not container then
		return nil
	end
	return setmetatable({ Container = container, Title = name, TabTitle = self.TabTitle }, Section)
end

function Section:AddTab(name)
	local container = self.Container:AddTab(name)
	return setmetatable({ Container = container, Title = self.Title .. "." .. name, TabTitle = self.TabTitle }, Section)
end

function Section:SelectTab(name)
	self.Container:SelectTab(name)
end

function Section:SetVisible(visible)
	local frame = self.Container.Section or self.Container.Frame
	frame.Visible = visible
end

function Section:AddToggle(flag, opts)
	flag, opts = args(self, flag, opts)
	local section = self
	local el
	local toggle = self.Container:Toggle({
		Text = opts.Title or opts.Text,
		Default = opts.Default == true,
		Flag = opts.Save ~= false and flag or nil,
		Tooltip = opts.Tooltip or opts.Description,
		Style = opts.Style,
		Callback = function(value)
			changed(el, value, opts.Callback)
		end,
	})
	el = element(self, flag, opts.Default == true, toggle.Row)
	el.Default = opts.Default == true
	function el:SetValue(value)
		toggle:Set(value)
	end
	function el:Reset()
		toggle:Set(self.Default)
	end
	-- Presses flip the toggle ("Toggle") or hold it on while held ("Hold").
	function el:AddKeybind(keyFlag, keyOpts)
		if type(keyFlag) == "table" or keyFlag == nil then
			keyOpts = keyFlag or {}
			keyFlag = keyOpts.Flag or (flag .. "Key")
		end
		keyOpts = keyOpts or {}
		local keyEl
		local pill = toggle:AddKeybind({
			Default = keyName(keyOpts.Default),
			Flag = keyOpts.Save ~= false and keyFlag or nil,
			Mode = keyOpts.Mode,
			Changed = function(key)
				changed(keyEl, key, keyOpts.ChangedCallback)
			end,
		})
		keyEl = element(section, keyFlag, pill:Get(), nil)
		function keyEl:SetValue(key)
			pill:Set(keyName(key))
			changed(keyEl, pill:Get())
		end
		return self
	end
	function el:AddColorPicker(colorFlag, colorOpts)
		if type(colorFlag) == "table" or colorFlag == nil then
			colorOpts = colorFlag or {}
			colorFlag = colorOpts.Flag or (flag .. "Color")
		end
		colorOpts = colorOpts or {}
		local colorEl
		local swatch = toggle:AddColor({
			Default = colorOpts.Default,
			Flag = colorOpts.Save ~= false and colorFlag or nil,
			Callback = function(color)
				changed(colorEl, color, colorOpts.Callback)
			end,
		})
		colorEl = element(section, colorFlag, swatch:Get(), nil)
		function colorEl:SetValue(color)
			swatch:Set(color)
		end
		return self
	end
	el.AddColor = el.AddColorPicker
	return el
end

function Section:AddSwitch(flag, opts)
	flag, opts = args(self, flag, opts)
	local copy = table.clone(opts)
	copy.Style = "Switch"
	return self:AddToggle(flag, copy)
end

function Section:AddSlider(flag, opts)
	flag, opts = args(self, flag, opts)
	local step = opts.Increment or opts.Step or (opts.Rounding and 10 ^ -opts.Rounding) or 1
	local min, max = opts.Min or 0, opts.Max or 100
	local default = math.clamp(opts.Default or min, min, max)
	local el
	local slider = self.Container:Slider({
		Text = opts.Title or opts.Text,
		Min = min,
		Max = max,
		Step = step,
		Default = default,
		Suffix = opts.Suffix,
		Flag = opts.Save ~= false and flag or nil,
		Tooltip = opts.Tooltip or opts.Description,
		Callback = function(value)
			changed(el, value, opts.Callback)
		end,
	})
	el = element(self, flag, slider:Get(), lastRow(self.Container))
	el.Default = default
	function el:SetValue(value)
		slider:Set(value)
	end
	function el:Reset()
		slider:Set(self.Default)
	end
	return el
end

function Section:AddDropdown(flag, opts)
	flag, opts = args(self, flag, opts)
	local values = opts.Values or opts.Options or {}
	local default = opts.Default
	if type(default) == "number" and not opts.Multi then
		default = values[default]
	end
	local el
	local dropdown = self.Container:Dropdown({
		Text = opts.Title or opts.Text,
		Options = values,
		Default = default,
		Multi = opts.Multi,
		AllowNull = opts.AllowNull,
		Placeholder = opts.Placeholder,
		Flag = opts.Save ~= false and flag or nil,
		Tooltip = opts.Tooltip or opts.Description,
		Callback = function(value)
			changed(el, value, opts.Callback)
		end,
	})
	el = element(self, flag, dropdown:Get(), lastRow(self.Container))
	function el:SetValue(value)
		dropdown:Set(value)
	end
	function el:SetValues(newValues)
		values = table.clone(newValues)
		dropdown:SetOptions(values, true)
		el.Value = dropdown:Get()
		Library.Flags[flag] = el.Value
	end
	el.Refresh = el.SetValues
	function el:AddValue(value)
		table.insert(values, value)
		el:SetValues(values)
	end
	function el:RemoveValue(value)
		local index = table.find(values, value)
		if index then
			table.remove(values, index)
			el:SetValues(values)
		end
	end
	function el:GetSelected()
		return dropdown:GetSelected()
	end
	return el
end

function Section:AddInput(flag, opts)
	flag, opts = args(self, flag, opts)
	local function parse(text)
		if not opts.Numeric then
			return text
		end
		local number = tonumber(text)
		if not number then
			return nil
		end
		return math.clamp(number, opts.Min or -math.huge, opts.Max or math.huge)
	end
	local el
	local input
	input = self.Container:Input({
		Text = opts.Title or opts.Text,
		Placeholder = opts.Placeholder,
		Default = opts.Default ~= nil and tostring(opts.Default) or "",
		MaxLength = opts.MaxLength,
		Live = not opts.Finished,
		Flag = opts.Save ~= false and flag or nil,
		Tooltip = opts.Tooltip or opts.Description,
		Callback = function(text)
			local value = parse(text)
			if value == nil then
				if opts.Numeric and text ~= "" and text ~= "-" then
					input:Set(tostring(el.Value or ""), true)
				end
				return
			end
			if opts.Numeric and tostring(value) ~= text and not opts.Finished then
				return
			end
			changed(el, value, opts.Callback)
		end,
	})
	el = element(self, flag, parse(input:Get()), lastRow(self.Container))
	function el:SetValue(value)
		input:Set(tostring(value))
	end
	return el
end

function Section:AddKeybind(flag, opts)
	flag, opts = args(self, flag, opts)
	local mode = opts.Mode or "Toggle"
	local state = mode == "Always"
	local clicks = {}
	local el
	local function setState(value)
		if state == value then
			return
		end
		state = value
		call(opts.Callback, state)
	end
	local pill = self.Container:Keybind({
		Text = opts.Title or opts.Text,
		Default = keyName(opts.Default),
		Flag = opts.Save ~= false and flag or nil,
		Tooltip = opts.Tooltip or opts.Description,
		Callback = function()
			for _, fn in ipairs(clicks) do
				call(fn)
			end
			if mode == "Toggle" then
				setState(not state)
			elseif mode == "Hold" then
				setState(true)
			end
		end,
		OnRelease = function()
			if mode == "Hold" then
				setState(false)
			end
		end,
		Changed = function(key)
			changed(el, key, opts.ChangedCallback)
		end,
	})
	el = element(self, flag, pill:Get(), lastRow(self.Container))
	function el:SetValue(key, newMode)
		if newMode then
			mode = newMode
			state = mode == "Always"
		end
		pill:Set(keyName(key))
	end
	function el:GetState()
		return state
	end
	function el:OnClick(fn)
		table.insert(clicks, fn)
		return self
	end
	return el
end

function Section:AddColorPicker(flag, opts)
	flag, opts = args(self, flag, opts)
	local el
	local swatch = self.Container:ColorPicker({
		Text = opts.Title or opts.Text,
		Default = opts.Default or Color3.new(1, 1, 1),
		Flag = opts.Save ~= false and flag or nil,
		Tooltip = opts.Tooltip or opts.Description,
		Callback = function(color)
			changed(el, color, opts.Callback)
		end,
	})
	el = element(self, flag, swatch:Get(), lastRow(self.Container))
	function el:SetValue(color)
		swatch:Set(color)
	end
	return el
end

--[[
	Section:AddButton({ Title, Callback, Confirm = true, Style = "Primary" | "Danger", Icon })
		:AddButton({ ... })   -- adds another button to the same row
]]
function Section:AddButton(opts)
	opts = opts or {}
	local container = self.Container
	local group = { list = {}, row = nil }

	local function build()
		local order
		if group.row then
			order = group.row.LayoutOrder
			group.row:Destroy()
		end
		local specs = {}
		local buttons
		for index, spec in ipairs(group.list) do
			local armedAt = 0
			specs[index] = {
				Text = spec.Title or spec.Text,
				Icon = spec.Icon,
				Style = spec.Style,
				Tooltip = spec.Tooltip,
				Callback = function()
					if spec.Confirm then
						local button = buttons[index]
						if os.clock() - armedAt > 2.5 then
							armedAt = os.clock()
							button:SetText(type(spec.Confirm) == "string" and spec.Confirm or "Click again to confirm")
							task.delay(2.5, function()
								if os.clock() - armedAt >= 2.4 and button.Root.Parent then
									button:SetText(spec.Title or spec.Text)
								end
							end)
							return
						end
						armedAt = 0
						button:SetText(spec.Title or spec.Text)
					end
					call(spec.Callback)
				end,
			}
		end
		buttons = container:Buttons(specs)
		group.row = lastRow(container)
		if order then
			group.row.LayoutOrder = order
		end
	end

	local handle = {}
	function handle:AddButton(nextOpts)
		table.insert(group.list, nextOpts or {})
		build()
		return handle
	end
	function handle:SetVisible(visible)
		group.row.Visible = visible
	end
	table.insert(group.list, opts)
	build()
	return handle
end

function Section:AddLabel(text, style)
	local label = self.Container:Label(text, style)
	local row = lastRow(self.Container)
	return {
		SetText = function(_, value)
			label:Set(value)
		end,
		SetVisible = function(_, visible)
			row.Visible = visible
		end,
	}
end

function Section:AddParagraph(opts)
	opts = opts or {}
	local title, content = opts.Title or "", opts.Content or opts.Text or ""
	local paragraph = self.Container:Paragraph(title, content)
	local row = lastRow(self.Container)
	return {
		SetTitle = function(_, value)
			paragraph:Set(value, nil)
		end,
		SetContent = function(_, value)
			paragraph:Set(nil, value)
		end,
		SetVisible = function(_, visible)
			row.Visible = visible
		end,
	}
end

function Section:AddInfo(opts)
	return self.Container:Info({ Text = opts.Title or opts.Text, Value = opts.Value, Accent = opts.Accent })
end

function Section:AddDivider(text)
	self.Container:Divider(text)
end

return Library
