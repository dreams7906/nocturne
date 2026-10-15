--[[
	Theme
	Holds the active token table and keeps every bound instance in sync.

	Theme:Bind(instance, { BackgroundColor3 = "Surface", TextColor3 = "Text" })
		Static bindings. A token can also be a function(tokens) -> value.

	Theme.Changed(instant)
		Fired after every refresh so stateful components (toggles, tabs, ...)
		can recolour themselves from their current state.

	Runtime values (Accent override, Transparency, Gloss) live alongside the
	preset colours and are composed into Tokens on every change.
]]

local Signal = require(script.Parent.Parent.Core.Signal)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Presets = require(script.Parent.Presets)

local Theme = {}
Theme.__index = Theme

local function luminance(color)
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

function Theme.new(presetName)
	local self = setmetatable({}, Theme)
	self.Presets = Presets
	self.Name = Presets.Themes[presetName] and presetName or "Midnight"
	self.Values = {
		Accent = nil,
		Transparency = 0.04,
		Gloss = true,
	}
	self.Tokens = {}
	self.Changed = Signal.new()
	self._bindings = {}
	self:_compose()
	return self
end

function Theme:_compose()
	local tokens = table.clone(self.Presets.Themes[self.Name])
	if self.Values.Accent then
		tokens.Accent = self.Values.Accent
		tokens.AccentText = luminance(self.Values.Accent) > 0.55 and tokens.Backdrop:Lerp(Color3.new(0, 0, 0), 0.4)
			or Color3.new(1, 1, 1)
	end
	tokens.AccentSoft = tokens.Surface2:Lerp(tokens.Accent, 0.16)
	tokens.AccentGlow = tokens.Accent
	tokens.Transparency = self.Values.Transparency
	tokens.Gloss = self.Values.Gloss
	self.Tokens = tokens
end

function Theme:Get(token)
	if type(token) == "function" then
		return token(self.Tokens)
	end
	return self.Tokens[token]
end

local function apply(instance, property, value, instant)
	local kind = typeof(value)
	if not instant and (kind == "Color3" or kind == "number") then
		Motion.tween(instance, "Smooth", { [property] = value })
	else
		instance[property] = value
	end
end

function Theme:Bind(instance, map)
	local existing = self._bindings[instance]
	if not existing then
		existing = {}
		self._bindings[instance] = existing
		instance.Destroying:Once(function()
			self._bindings[instance] = nil
		end)
	end
	for property, token in pairs(map) do
		existing[property] = token
		instance[property] = self:Get(token)
	end
	return instance
end

function Theme:Unbind(instance, property)
	local existing = self._bindings[instance]
	if existing then
		existing[property] = nil
	end
end

function Theme:Refresh(instant)
	self:_compose()
	for instance, map in pairs(self._bindings) do
		for property, token in pairs(map) do
			apply(instance, property, self:Get(token), instant)
		end
	end
	self.Changed:Fire(instant)
end

function Theme:SetPreset(name)
	if not self.Presets.Themes[name] or name == self.Name then
		return
	end
	self.Name = name
	self:Refresh(false)
end

function Theme:SetAccent(color)
	self.Values.Accent = color
	self:Refresh(false)
end

function Theme:Set(key, value)
	if self.Values[key] == value then
		return
	end
	self.Values[key] = value
	self:Refresh(false)
end

return Theme
