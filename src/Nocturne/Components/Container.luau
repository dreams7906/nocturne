--[[
	Container
	Anything controls can be added to (a section body or a section tab).
	Every builder appends a row in LayoutOrder, so call order = visual order.
]]

local Util = require(script.Parent.Parent.Core.Util)
local Toggle = require(script.Parent.Toggle)
local Slider = require(script.Parent.Slider)
local Dropdown = require(script.Parent.Dropdown)
local Keybind = require(script.Parent.Keybind)
local ColorPicker = require(script.Parent.ColorPicker)
local Button = require(script.Parent.Button)
local Input = require(script.Parent.Input)
local Basic = require(script.Parent.Basic)
local ListBox = require(script.Parent.ListBox)

local Container = {}
Container.__index = Container

Container.Components = {
	KeybindPill = Keybind.Pill,
	ColorSwatch = ColorPicker.Swatch,
	HelpIcon = Basic.HelpIcon,
}

function Container.new(ctx, frame)
	return setmetatable({ ctx = ctx, Frame = frame, _order = 0 }, Container)
end

function Container:Row(height)
	self._order += 1
	return Util.frame({
		Name = "Row" .. self._order,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = self._order,
		Parent = self.Frame,
	})
end

function Container:Toggle(opts)
	return Toggle(self, opts)
end

function Container:Switch(opts)
	local copy = table.clone(opts)
	copy.Style = "Switch"
	return Toggle(self, copy)
end

function Container:Slider(opts)
	return Slider(self, opts)
end

function Container:Dropdown(opts)
	return Dropdown(self, opts)
end

function Container:Keybind(opts)
	return Keybind.Row(self, opts)
end

function Container:ColorPicker(opts)
	return ColorPicker.Row(self, opts)
end

function Container:Button(opts)
	return Button.Single(self, opts)
end

function Container:Buttons(list)
	return Button.Row(self, list)
end

function Container:Input(opts)
	return Input(self, opts)
end

function Container:ListBox(opts)
	return ListBox(self, opts)
end

function Container:Label(text, style)
	return Basic.Label(self, text, style)
end

function Container:Paragraph(title, text)
	return Basic.Paragraph(self, title, text)
end

function Container:Info(opts)
	return Basic.Info(self, opts)
end

function Container:Divider(text)
	return Basic.Divider(self, text)
end

function Container:Spacer(height)
	return self:Row(height or 6)
end

return Container
