--[[
	State
	Registry of flagged controls. Every control created with a `Flag`
	registers a getter/setter here, which is what configs save and load.
]]

local Signal = require(script.Parent.Signal)

local State = {}
State.__index = State

function State.new()
	return setmetatable({
		_flags = {},
		Changed = Signal.new(),
	}, State)
end

-- handle = { Get = fn() -> value, Set = fn(value), Save = boolean? }
function State:Register(flag, handle)
	if self._flags[flag] then
		warn(("[Nocturne] Flag '%s' registered twice; the newest control wins."):format(flag))
	end
	self._flags[flag] = handle
end

function State:Unregister(flag, handle)
	if self._flags[flag] == handle then
		self._flags[flag] = nil
	end
end

function State:Get(flag)
	local handle = self._flags[flag]
	return handle and handle.Get()
end

function State:Set(flag, value)
	local handle = self._flags[flag]
	if handle then
		handle.Set(value)
	end
end

function State:Notify(flag, value)
	self.Changed:Fire(flag, value)
end

local function encode(value)
	if typeof(value) == "Color3" then
		return { Color = value:ToHex() }
	end
	return value
end

local function decode(value)
	if type(value) == "table" and type(value.Color) == "string" then
		local ok, color = pcall(Color3.fromHex, value.Color)
		return ok and color or nil
	end
	return value
end

function State:Serialize()
	local out = {}
	for flag, handle in pairs(self._flags) do
		if handle.Save ~= false then
			out[flag] = encode(handle.Get())
		end
	end
	return out
end

-- Applies saved values. Unknown flags are ignored; returns the count applied.
function State:Apply(data)
	local applied = 0
	if type(data) ~= "table" then
		return applied
	end
	for flag, raw in pairs(data) do
		local handle = self._flags[flag]
		local value = decode(raw)
		if handle and handle.Save ~= false and value ~= nil then
			local ok, err = pcall(handle.Set, value)
			if ok then
				applied += 1
			else
				warn(("[Nocturne] Could not apply flag '%s': %s"):format(flag, tostring(err)))
			end
		end
	end
	return applied
end

return State
