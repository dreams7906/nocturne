--[[
	Keybinds
	Central registry for every bindable key, so bindings can be listened for
	with one input connection and conflicting assignments can be refused.

	bind = {
		Name    = "Ability 1",
		Key     = "Q" | "MB2" | nil,     -- stored as a string id
		OnPress = fn(), OnRelease = fn()?,
		Locked  = boolean?               -- e.g. the menu key cannot be cleared
	}

	While a pill is capturing, every other binding is suspended.
	Escape cancels, Backspace / Delete clears, a left click elsewhere cancels.
]]

local UserInputService = game:GetService("UserInputService")

local Signal = require(script.Parent.Signal)

local Keybinds = {}
Keybinds.__index = Keybinds

local SHORT = {
	LeftShift = "LShift", RightShift = "RShift",
	LeftControl = "LCtrl", RightControl = "RCtrl",
	LeftAlt = "LAlt", RightAlt = "RAlt",
	Return = "Enter", Backquote = "`", Minus = "-", Equals = "=",
	LeftBracket = "[", RightBracket = "]", Semicolon = ";", Quote = "'",
	Comma = ",", Period = ".", Slash = "/", BackSlash = "\\",
	Zero = "0", One = "1", Two = "2", Three = "3", Four = "4",
	Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
	PageUp = "PgUp", PageDown = "PgDn", Insert = "Ins", CapsLock = "Caps",
	MB2 = "M2", MB3 = "M3",
}

-- Keys that would fight Roblox core controls or break text input.
local RESERVED = {
	Escape = true, Tab = true, Slash = true,
	F9 = true, F11 = true, Unknown = true,
}

function Keybinds.display(key)
	if not key then
		return "none"
	end
	return SHORT[key] or key
end

local function keyFromInput(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode.Name
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		return "MB2"
	elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
		return "MB3"
	end
	return nil
end

function Keybinds.new()
	local self = setmetatable({
		_binds = {},
		_capture = nil,
		Changed = Signal.new(),
		Pressed = Signal.new(),
		Enabled = true,
	}, Keybinds)

	self._began = UserInputService.InputBegan:Connect(function(input, processed)
		self:_onBegan(input, processed)
	end)
	self._ended = UserInputService.InputEnded:Connect(function(input)
		local key = keyFromInput(input)
		if not key or self._capture then
			return
		end
		for _, bind in ipairs(self._binds) do
			if bind.Key == key and bind.OnRelease then
				task.spawn(bind.OnRelease)
			end
		end
	end)
	return self
end

function Keybinds:Register(bind)
	table.insert(self._binds, bind)
	self.Changed:Fire()
	return bind
end

function Keybinds:Unregister(bind)
	local index = table.find(self._binds, bind)
	if index then
		table.remove(self._binds, index)
		self.Changed:Fire()
	end
end

function Keybinds:All()
	return self._binds
end

function Keybinds:FindConflict(key, except)
	if not key then
		return nil
	end
	for _, bind in ipairs(self._binds) do
		if bind ~= except and bind.Key == key then
			return bind
		end
	end
	return nil
end

function Keybinds:IsCapturing()
	return self._capture ~= nil
end

--[[
	Starts listening for a new key for `bind`.
	onDone(result, detail) where result is
		"set"      detail = key
		"cleared"
		"cancel"
		"conflict" detail = other bind
		"reserved" detail = key
]]
function Keybinds:Capture(bind, onDone)
	if self._capture then
		self:_finish("cancel")
	end
	self._capture = { bind = bind, onDone = onDone }
end

function Keybinds:CancelCapture()
	if self._capture then
		self:_finish("cancel")
	end
end

function Keybinds:_finish(result, detail)
	local capture = self._capture
	self._capture = nil
	if capture then
		task.spawn(capture.onDone, result, detail)
	end
end

function Keybinds:Assign(bind, key)
	bind.Key = key
	self.Changed:Fire()
end

function Keybinds:_onBegan(input, processed)
	if self._capture then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self:_finish("cancel")
			return
		end
		local key = keyFromInput(input)
		if not key then
			return
		end
		local bind = self._capture.bind
		if key == "Escape" then
			self:_finish("cancel")
		elseif key == "Backspace" or key == "Delete" then
			if bind.Locked then
				self:_finish("cancel")
			else
				self:Assign(bind, nil)
				self:_finish("cleared")
			end
		elseif RESERVED[key] then
			self:_finish("reserved", key)
		else
			local other = self:FindConflict(key, bind)
			if other then
				self:_finish("conflict", other)
			else
				self:Assign(bind, key)
				self:_finish("set", key)
			end
		end
		return
	end

	if not self.Enabled then
		return
	end
	-- Ignore keys typed into text boxes / chat.
	if processed and input.UserInputType == Enum.UserInputType.Keyboard then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	local key = keyFromInput(input)
	if not key then
		return
	end
	for _, bind in ipairs(table.clone(self._binds)) do
		if bind.Key == key and bind.OnPress then
			task.spawn(bind.OnPress)
			self.Pressed:Fire(bind)
		end
	end
end

function Keybinds:Destroy()
	self._began:Disconnect()
	self._ended:Disconnect()
	self.Changed:Destroy()
	self.Pressed:Destroy()
end

return Keybinds
