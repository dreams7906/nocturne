--[[
	KeybindList
	Small floating panel listing every assigned keybind. Bindings attached
	to toggles show their live on / off state.
]]

local Util = require(script.Parent.Parent.Core.Util)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Keybinds = require(script.Parent.Parent.Core.Keybinds)

local KeybindList = {}
KeybindList.__index = KeybindList

local WIDTH = 190
local ROW = 20

function KeybindList.new(ctx)
	local theme = ctx.Theme
	local self = setmetatable({ ctx = ctx, Enabled = false, _rows = {}, _watch = {} }, KeybindList)

	local surface = Util.surface(ctx, {
		Name = "KeybindList",
		Radius = 9,
		Position = UDim2.fromOffset(16, 112),
		Size = UDim2.fromOffset(WIDTH, 40),
		ShadowLayers = 4,
		ShadowSpread = 2,
		ShadowOffset = 3,
		ZIndex = 15,
		Parent = ctx.Gui,
	})
	surface.Holder.Visible = false
	self.Surface = surface
	self.Scale = Util.new("UIScale", { Parent = surface.Holder })

	local title = Util.text({
		Text = "Keybinds",
		FontFace = Util.Fonts.Bold,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 0, 30),
		ZIndex = 2,
		Parent = surface.Body,
	})
	theme:Bind(title, { TextColor3 = "Text" })
	local line = Util.frame({
		Position = UDim2.fromOffset(12, 30),
		Size = UDim2.new(1, -24, 0, 1),
		BackgroundTransparency = 0.3,
		ZIndex = 2,
		Parent = surface.Body,
	})
	theme:Bind(line, { BackgroundColor3 = "Border" })

	local list = Util.frame({
		Position = UDim2.fromOffset(12, 36),
		Size = UDim2.new(1, -24, 1, -42),
		ZIndex = 2,
		Parent = surface.Body,
	})
	Util.list(list, { Padding = 0 })
	self.List = list

	ctx.Keybinds.Changed:Connect(function()
		if self.Enabled then
			self:Rebuild()
		end
	end)
	theme.Changed:Connect(function()
		if self.Enabled then
			self:Rebuild()
		end
	end)
	return self
end

function KeybindList:SetScale(scale)
	self.Scale.Scale = scale
end

function KeybindList:Rebuild()
	local theme = self.ctx.Theme
	local t = theme.Tokens
	for _, row in ipairs(self._rows) do
		row:Destroy()
	end
	for _, connection in ipairs(self._watch) do
		connection.Disconnect()
	end
	table.clear(self._rows)
	table.clear(self._watch)

	local count = 0
	for _, bind in ipairs(self.ctx.Keybinds:All()) do
		if bind.Key and not bind.Hidden then
			count += 1
			local row = Util.frame({ Size = UDim2.new(1, 0, 0, ROW), LayoutOrder = count, ZIndex = 2, Parent = self.List })
			local name = Util.text({
				Text = bind.Name,
				Size = UDim2.new(1, -60, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextColor3 = t.TextDim,
				ZIndex = 2,
				Parent = row,
			})
			local key = Util.text({
				Text = "[" .. Keybinds.display(bind.Key) .. "]",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 60, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Util.Fonts.SemiBold,
				TextColor3 = t.TextMuted,
				ZIndex = 2,
				Parent = row,
			})
			if bind.Toggle then
				local function paint(value)
					Motion.tween(name, "Fast", { TextColor3 = value and t.Text or t.TextDim })
					Motion.tween(key, "Fast", { TextColor3 = value and t.Accent or t.TextMuted })
				end
				paint(bind.Toggle:Get())
				table.insert(self._watch, bind.Toggle.Changed:Connect(paint))
			end
			table.insert(self._rows, row)
		end
	end
	if count == 0 then
		local empty = Util.text({
			Text = "No keys bound",
			Size = UDim2.new(1, 0, 0, ROW),
			TextColor3 = t.TextMuted,
			ZIndex = 2,
			Parent = self.List,
		})
		table.insert(self._rows, empty)
		count = 1
	end
	Motion.tween(self.Surface.Holder, "Normal", { Size = UDim2.fromOffset(WIDTH, 44 + count * ROW) })
end

function KeybindList:SetEnabled(enabled)
	if self.Enabled == enabled then
		return
	end
	self.Enabled = enabled
	local holder = self.Surface.Holder
	if enabled then
		self:Rebuild()
		holder.Visible = true
		self.Surface.SetAlpha(1, "Instant")
		self.Surface.SetAlpha(0, "Smooth")
	else
		self.Surface.SetAlpha(1, "Normal")
		task.delay(Motion.info("Normal").Time, function()
			if not self.Enabled then
				holder.Visible = false
			end
		end)
	end
end

return KeybindList
