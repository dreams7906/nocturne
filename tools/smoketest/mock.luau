--[[
	Minimal headless Roblox mock for smoke-testing Nocturne with luau.exe.
	It is not a renderer: it fakes instances, signals, datatypes, services
	and the task scheduler well enough to run the library and Example.lua,
	then fuzz every button and control while recording any Lua errors.
]]

local Mock = { errors = {}, clock = 0 }

local function record(where, err)
	table.insert(Mock.errors, where .. ": " .. tostring(err))
end

---------------------------------------------------------------- scheduler
local queue = {}
local function push(at, co, ...)
	table.insert(queue, { at = at, co = co, args = table.pack(...) })
end
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		record("thread", debug.traceback(co, tostring(err)))
	end
end
local function toThread(fn)
	if type(fn) == "thread" then
		return fn
	end
	return coroutine.create(fn)
end

task = {}
function task.spawn(fn, ...)
	local co = toThread(fn)
	resume(co, ...)
	return co
end
function task.defer(fn, ...)
	local co = toThread(fn)
	push(Mock.clock, co, ...)
	return co
end
function task.delay(t, fn, ...)
	local co = toThread(fn)
	push(Mock.clock + (t or 0), co, ...)
	return co
end
function task.wait(t)
	local co = coroutine.running()
	push(Mock.clock + (t or 0.016), co)
	coroutine.yield()
	return t or 0.016
end
function task.cancel() end

function Mock.run(seconds)
	local limit = Mock.clock + (seconds or 1)
	while true do
		table.sort(queue, function(a, b)
			return a.at < b.at
		end)
		local item = queue[1]
		if not item or item.at > limit then
			break
		end
		table.remove(queue, 1)
		Mock.clock = math.max(Mock.clock, item.at)
		if coroutine.status(item.co) == "suspended" then
			resume(item.co, table.unpack(item.args, 1, item.args.n))
		end
	end
	Mock.clock = limit
end

local nativeOs = os
os = setmetatable({
	clock = function()
		return Mock.clock
	end,
}, { __index = nativeOs })

---------------------------------------------------------------- typeof
local TYPE = setmetatable({}, { __mode = "k" })
local nativeTypeof = typeof
typeof = function(v)
	if type(v) == "table" and TYPE[v] then
		return TYPE[v]
	end
	if type(v) == "table" and rawget(v, "__instance") then
		return "Instance"
	end
	return nativeTypeof(v)
end
local function tag(v, name)
	TYPE[v] = name
	return v
end

---------------------------------------------------------------- datatypes
local V2 = {}
V2.__index = V2
local function v2(x, y)
	local v = setmetatable({ X = x or 0, Y = y or 0 }, V2)
	v.Magnitude = math.sqrt(v.X * v.X + v.Y * v.Y)
	return tag(v, "Vector2")
end
V2.__add = function(a, b)
	return v2(a.X + b.X, a.Y + b.Y)
end
V2.__sub = function(a, b)
	return v2(a.X - b.X, a.Y - b.Y)
end
V2.__mul = function(a, b)
	if type(b) == "number" then
		return v2(a.X * b, a.Y * b)
	end
	return v2(a.X * b.X, a.Y * b.Y)
end
V2.__div = function(a, b)
	if type(b) == "number" then
		return v2(a.X / b, a.Y / b)
	end
	return v2(a.X / b.X, a.Y / b.Y)
end
V2.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y
end
Vector2 = { new = v2, zero = v2(0, 0), one = v2(1, 1) }
Vector3 = {
	new = function(x, y, z)
		return tag({ X = x or 0, Y = y or 0, Z = z or 0 }, "Vector3")
	end,
}

local function udim(s, o)
	return tag({ Scale = s or 0, Offset = o or 0 }, "UDim")
end
UDim = { new = udim }
UDim2 = {
	new = function(xs, xo, ys, yo)
		return tag({ X = udim(xs, xo), Y = udim(ys, yo), Width = udim(xs, xo), Height = udim(ys, yo) }, "UDim2")
	end,
}
UDim2.fromOffset = function(x, y)
	return UDim2.new(0, x or 0, 0, y or 0)
end
UDim2.fromScale = function(x, y)
	return UDim2.new(x or 0, 0, y or 0, 0)
end

local C3 = {}
C3.__index = C3
local function c3(r, g, b)
	return tag(setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3), "Color3")
end
function C3:Lerp(o, t)
	return c3(self.R + (o.R - self.R) * t, self.G + (o.G - self.G) * t, self.B + (o.B - self.B) * t)
end
function C3:ToHSV()
	local r, g, b = self.R, self.G, self.B
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v = 0, 0, max
	local d = max - min
	s = max == 0 and 0 or d / max
	if d ~= 0 then
		if max == r then
			h = (g - b) / d % 6
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h /= 6
	end
	return h, s, v
end
function C3:ToHex()
	return string.format("%02x%02x%02x", self.R * 255 + 0.5, self.G * 255 + 0.5, self.B * 255 + 0.5)
end
C3.__eq = function(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
Color3 = { new = c3 }
Color3.fromRGB = function(r, g, b)
	return c3(r / 255, g / 255, b / 255)
end
Color3.fromHex = function(hex)
	hex = string.gsub(hex, "#", "")
	assert(#hex == 6, "Unable to convert characters to hex value")
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end
Color3.fromHSV = function(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	local m = i % 6
	if m == 0 then
		return c3(v, t, p)
	elseif m == 1 then
		return c3(q, v, p)
	elseif m == 2 then
		return c3(p, v, t)
	elseif m == 3 then
		return c3(p, q, v)
	elseif m == 4 then
		return c3(t, p, v)
	end
	return c3(v, p, q)
end

local function plain(name)
	return {
		new = function(...)
			return tag({ ... }, name)
		end,
	}
end
ColorSequence = plain("ColorSequence")
ColorSequenceKeypoint = plain("ColorSequenceKeypoint")
NumberSequence = plain("NumberSequence")
NumberSequenceKeypoint = plain("NumberSequenceKeypoint")
Font = plain("Font")
TweenInfo = {
	new = function(t, style, dir, rep, rev)
		return tag({ Time = t or 1, EasingStyle = style, EasingDirection = dir, RepeatCount = rep, Reverses = rev }, "TweenInfo")
	end,
}

local enumCache = {}
Enum = setmetatable({}, {
	__index = function(_, typeName)
		local enumType = enumCache[typeName]
		if not enumType then
			local items = {}
			enumType = setmetatable({ __name = typeName }, {
				__index = function(self, itemName)
					local item = items[itemName]
					if not item then
						item = tag({ Name = itemName, EnumType = self, Value = 0 }, "EnumItem")
						items[itemName] = item
					end
					return item
				end,
			})
			enumCache[typeName] = enumType
		end
		return enumType
	end,
})

---------------------------------------------------------------- signals
local function newSignal()
	local signal = { handlers = {} }
	function signal:Connect(fn)
		local entry = { fn = fn, on = true }
		table.insert(self.handlers, entry)
		local conn = { Connected = true }
		function conn:Disconnect()
			entry.on = false
			self.Connected = false
		end
		return tag(conn, "RBXScriptConnection")
	end
	function signal:Once(fn)
		local conn
		conn = self:Connect(function(...)
			conn:Disconnect()
			fn(...)
		end)
		return conn
	end
	function signal:Fire(...)
		for _, entry in ipairs(table.clone(self.handlers)) do
			if entry.on then
				local co = coroutine.create(entry.fn)
				resume(co, ...)
			end
		end
	end
	function signal:Wait()
		local co = coroutine.running()
		self:Once(function(...)
			task.spawn(co, ...)
		end)
		return coroutine.yield()
	end
	return tag(signal, "RBXScriptSignal")
end
Mock.newSignal = newSignal

---------------------------------------------------------------- instances
local EVENTS = {
	MouseEnter = true, MouseLeave = true, Activated = true, MouseButton1Down = true, MouseButton1Up = true,
	MouseButton1Click = true, InputBegan = true, InputChanged = true, InputEnded = true, Destroying = true,
	FocusLost = true, Focused = true, Changed = true, Completed = true, PlayerAdded = true, PlayerRemoving = true,
	RenderStepped = true, Heartbeat = true, ChildAdded = true, OnClientInvoke = true,
}
local GUI = {
	Frame = true, TextLabel = true, TextButton = true, TextBox = true, ImageLabel = true, ImageButton = true,
	ScrollingFrame = true, CanvasGroup = true,
}
local DEFAULTS = {
	Visible = true, Text = "", BackgroundTransparency = 0, Rotation = 0, ZIndex = 1, LayoutOrder = 0,
	GroupTransparency = 0, Transparency = 0, Scale = 1, Enabled = true, TextTransparency = 0,
	CanvasPosition = v2(0, 0),
}

local Inst = {}
local methods = {}
local nextId = 0

function Mock.instance(className, props)
	nextId += 1
	local self = setmetatable({
		__instance = true,
		_class = className,
		_props = { Name = className },
		_children = {},
		_events = {},
		_changed = {},
		_attrs = {},
		_id = nextId,
	}, Inst)
	for k, v in pairs(props or {}) do
		self._props[k] = v
	end
	return self
end

Inst.__index = function(self, key)
	if key == "ClassName" then
		return rawget(self, "_class")
	end
	local method = methods[key]
	if method then
		return method
	end
	local props = rawget(self, "_props")
	if props[key] ~= nil then
		return props[key]
	end
	if EVENTS[key] then
		local events = rawget(self, "_events")
		events[key] = events[key] or newSignal()
		return events[key]
	end
	if key == "AbsoluteSize" then
		if rawget(self, "_class") == "ScreenGui" then
			return v2(1920, 1080)
		end
		local size = props.Size
		if size then
			return v2(size.X.Offset + size.X.Scale * 400, size.Y.Offset + size.Y.Scale * 30)
		end
		return v2(100, 20)
	end
	if key == "AbsolutePosition" then
		return v2(400, 300)
	end
	if key == "AbsoluteContentSize" then
		local height, width = 0, 0
		local parent = props.Parent
		for _, child in ipairs(parent and parent:GetChildren() or {}) do
			if child:IsA("GuiObject") and child.Visible ~= false then
				local size = child.AbsoluteSize
				height += size.Y
				width = math.max(width, size.X)
			end
		end
		return v2(width, height)
	end
	if DEFAULTS[key] ~= nil then
		return DEFAULTS[key]
	end
	for _, child in ipairs(rawget(self, "_children")) do
		if child._props.Name == key then
			return child
		end
	end
	return nil
end

Inst.__newindex = function(self, key, value)
	if key == "Parent" then
		local old = self._props.Parent
		if old == value then
			return
		end
		if old then
			local index = table.find(old._children, self)
			if index then
				table.remove(old._children, index)
			end
		end
		if value then
			assert(not rawget(value, "_destroyed"), "parent is locked (destroyed)")
			table.insert(value._children, self)
		end
		self._props.Parent = value
		return
	end
	if rawget(self, "_destroyed") and key ~= "Name" then
		-- Roblox allows property writes on destroyed instances.
	end
	if value == nil and (key == "BackgroundTransparency" or key == "Size" or key == "Position" or key == "BackgroundColor3" or key == "TextColor3" or key == "Color") then
		error(("Attempt to set %s.%s to nil"):format(self._class, key), 2)
	end
	self._props[key] = value
	local signal = self._changed[key]
	if signal then
		signal:Fire()
	end
end

Inst.__tostring = function(self)
	return self._props.Name
end

local HIERARCHY = {
	GuiObject = GUI,
	GuiButton = { TextButton = true, ImageButton = true },
	GuiBase2d = GUI,
	LayerCollector = { ScreenGui = true },
}
function methods:IsA(className)
	if self._class == className then
		return true
	end
	local set = HIERARCHY[className]
	return set ~= nil and set[self._class] == true
end
function methods:GetChildren()
	return table.clone(self._children)
end
function methods:GetDescendants()
	local out = {}
	local function walk(node)
		for _, child in ipairs(node._children) do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end
function methods:FindFirstChild(name, recursive)
	for _, child in ipairs(self._children) do
		if child._props.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in ipairs(self._children) do
			local found = child:FindFirstChild(name, true)
			if found then return found end
		end
	end
	return nil
end
function methods:FindFirstChildOfClass(className)
	for _, child in ipairs(self._children) do
		if child._class == className then
			return child
		end
	end
	return nil
end
function methods:WaitForChild(name)
	return self:FindFirstChild(name) or error("WaitForChild would hang: " .. tostring(name), 2)
end
function methods:GetPropertyChangedSignal(prop)
	self._changed[prop] = self._changed[prop] or newSignal()
	return self._changed[prop]
end
function methods:SetAttribute(k, v)
	self._attrs[k] = v
end
function methods:GetAttribute(k)
	return self._attrs[k]
end
function methods:Destroy()
	if rawget(self, "_destroyed") then
		return
	end
	rawset(self, "_destroyed", true)
	local destroying = rawget(self, "_events").Destroying
	if destroying then
		destroying:Fire()
	end
	for _, child in ipairs(table.clone(self._children)) do
		child:Destroy()
	end
	self.Parent = nil
end
function methods:ClearAllChildren()
	for _, child in ipairs(table.clone(self._children)) do
		child:Destroy()
	end
end
function methods:IsFocused()
	return false
end
function methods:CaptureFocus() end
function methods:ReleaseFocus() end
function methods:IsDescendantOf(other)
	local node = self._props.Parent
	while node do
		if node == other then
			return true
		end
		node = node._props.Parent
	end
	return false
end
function methods:GetFullName()
	return self._props.Name
end

Instance = {
	new = function(className, parent)
		local inst = Mock.instance(className)
		if parent then
			inst.Parent = parent
		end
		return inst
	end,
}

---------------------------------------------------------------- services
local services = {}
local function service(name, extra)
	local inst = Mock.instance(name, { Name = name })
	for k, v in pairs(extra or {}) do
		inst._props[k] = v
	end
	services[name] = inst
	return inst
end

local playerGui = Mock.instance("PlayerGui", { Name = "PlayerGui" })
local localPlayer = Mock.instance("Player", { Name = "Tester", DisplayName = "Tester", UserId = 12345 })
playerGui.Parent = localPlayer
localPlayer._props.GetNetworkPing = function()
	return 0.042
end

service("Players", {
	LocalPlayer = localPlayer,
	GetPlayers = function()
		return { localPlayer }
	end,
})
service("TweenService", {
	Create = function(_, inst, info, props)
		local tween = Mock.instance("Tween")
		tween._props.Play = function()
			for k, v in pairs(props) do
				inst[k] = v
			end
			task.delay(info.Time, function()
				tween.Completed:Fire(Enum.PlaybackState.Completed)
			end)
		end
		tween._props.Cancel = function() end
		tween._props.Pause = function() end
		return tween
	end,
})
local uis = service("UserInputService", {
	GetMouseLocation = function()
		return v2(500, 320)
	end,
	GetFocusedTextBox = function()
		return nil
	end,
	TouchEnabled = false,
})
Mock.UIS = uis
service("GuiService", {
	GetGuiInset = function()
		return v2(0, 58), v2(0, 0)
	end,
})
local run = service("RunService", {
	IsStudio = function()
		return true
	end,
})
Mock.Run = run
service("Lighting", { ClockTime = 14, ExposureCompensation = 0, GlobalShadows = true })
service("SoundService", { PlayLocalSound = function() end })
service("ReplicatedStorage")
service("Workspace", { CurrentCamera = Mock.instance("Camera", { FieldOfView = 70 }) })
service("Stats", {
	GetTotalMemoryUsageMb = function()
		return 512
	end,
})

local jsonStore, jsonId = {}, 0
local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = deepCopy(v)
	end
	return out
end
service("HttpService", {
	JSONEncode = function(_, value)
		jsonId += 1
		local key = "{\"__mockjson\":" .. jsonId .. "}"
		jsonStore[key] = deepCopy(value)
		return key
	end,
	JSONDecode = function(_, text)
		local value = jsonStore[text]
		if value == nil then
			error("Can't parse JSON", 2)
		end
		return deepCopy(value)
	end,
})

game = Mock.instance("DataModel", { Name = "Game", PlaceId = 1818 })
game._props.GetService = function(_, name)
	return services[name] or service(name)
end
workspace = services.Workspace

---------------------------------------------------------------- input helpers
function Mock.input(kind, keyCode, position)
	return {
		UserInputType = Enum.UserInputType[kind],
		KeyCode = keyCode and Enum.KeyCode[keyCode] or Enum.KeyCode.Unknown,
		Position = Vector3.new(position and position.X or 500, position and position.Y or 262, 0),
	}
end

Mock.PlayerGui = playerGui
Mock.LocalPlayer = localPlayer
return Mock
