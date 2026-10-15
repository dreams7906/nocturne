--[[
	Toolbar
	Floating glass dock at the top centre of the screen. One icon per page.

	- Clicking an icon opens the window on that page.
	- Clicking the active icon again collapses the window; the toolbar stays.
	- A soft highlight pill glides between icons and carries an accent dot.
	- Hover lifts the icon slightly and shows a small label under the dock.
]]

local Util = require(script.Parent.Parent.Core.Util)
local Signal = require(script.Parent.Parent.Core.Signal)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)

local Toolbar = {}
Toolbar.__index = Toolbar

local BUTTON = 34
local GAP = 7
local PAD = 10
local TOP = 12
local ICON = 20

function Toolbar.new(ctx)
	local theme = ctx.Theme
	local self = setmetatable({
		ctx = ctx,
		Items = {},
		Active = nil,
		OpenPages = {},
		Clicked = Signal.new(),
	}, Toolbar)

	local surface = Util.surface(ctx, {
		Name = "Toolbar",
		Radius = 14,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, TOP),
		Size = UDim2.fromOffset(PAD * 2, BUTTON + PAD * 2),
		ShadowLayers = 2,
		ShadowSpread = 3,
		ShadowOffset = 6,
		ShadowTransparency = 0.97,
		GlossStrength = 0.03,
		FillTransparency = function(tokens)
			return math.clamp(tokens.Transparency + 0.16, 0, 0.6)
		end,
		ZIndex = 20,
		Parent = ctx.Gui,
	})
	self.Surface, self.Holder = surface, surface.Holder
	self.Scale = Util.new("UIScale", { Parent = surface.Holder })

	-- Highlight pill that slides to the active icon.
	local indicator = Util.frame({
		Name = "Indicator",
		Position = UDim2.fromOffset(PAD, PAD),
		Size = UDim2.fromOffset(BUTTON, BUTTON),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = surface.Body,
	})
	Util.corner(indicator, 10)
	local indicatorStroke = Util.stroke(indicator, { Transparency = 1 })
	theme:Bind(indicator, { BackgroundColor3 = "Hover" })
	theme:Bind(indicatorStroke, { Color = "BorderStrong" })
	local indicatorGloss = Util.gloss(indicator, 0.22)
	ctx:RegisterGloss(indicatorGloss)

	local dot = Util.frame({
		Name = "Dot",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -3),
		Size = UDim2.fromOffset(4, 4),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = indicator,
	})
	Util.corner(dot, UDim.new(1, 0))
	theme:Bind(dot, { BackgroundColor3 = "Accent" })
	self.Indicator, self.IndicatorStroke, self.Dot = indicator, indicatorStroke, dot

	local row = Util.frame({
		Name = "Buttons",
		Position = UDim2.fromOffset(PAD, PAD),
		Size = UDim2.new(1, -PAD * 2, 0, BUTTON),
		ZIndex = 3,
		Parent = surface.Body,
	})
	Util.list(row, {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = GAP,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	self.Row = row

	-- Hover label shown beneath the dock.
	local hint = Util.text({
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0, 0, 1, 10),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		TextSize = 11,
		FontFace = Util.Fonts.SemiBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 1,
		TextTransparency = 1,
		ZIndex = 30,
		Parent = surface.Holder,
	})
	Util.corner(hint, 6)
	Util.padding(hint, 0, 8)
	local hintStroke = Util.stroke(hint, { Transparency = 1 })
	theme:Bind(hint, { BackgroundColor3 = "Elevated", TextColor3 = "TextDim" })
	theme:Bind(hintStroke, { Color = "BorderStrong" })
	self.Hint, self.HintStroke = hint, hintStroke
	self._hintToken = 0

	theme.Changed:Connect(function(instant)
		self:_render(instant)
	end)

	-- Entrance: drop in from above.
	surface.Holder.Position = UDim2.new(0.5, 0, 0, TOP - 14)
	surface.SetAlpha(1, "Instant")
	task.defer(function()
		Motion.tween(surface.Holder, "Slow", { Position = UDim2.new(0.5, 0, 0, TOP) })
		surface.SetAlpha(0, "Slow")
	end)
	return self
end

function Toolbar:Bottom()
	return (TOP + BUTTON + PAD * 2) * self.Scale.Scale
end

function Toolbar:SetScale(scale)
	self._requestedScale = scale
	local width = self.Holder.Size.X.Offset
	self.Scale.Scale = math.min(scale, math.max(0.1, (self.ctx.Gui.AbsoluteSize.X - 24) / math.max(width, 1)))
end

function Toolbar:_offset(index)
	return PAD + (index - 1) * (BUTTON + GAP)
end

function Toolbar:_render(instant)
	local t = self.ctx.Theme.Tokens
	for _, item in ipairs(self.Items) do
		local active = self.OpenPages[item.Page] == true
		local color = active and t.Text or (item.Hovered and t.TextDim or t.TextMuted)
		Icons.tween(item.Icon, instant and "Instant" or "Fast", color)
		Motion.tween(item.Dot, instant and "Instant" or "Fast", { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = t.Text })
		Motion.tween(item.Button, instant and "Instant" or "Fast", { BackgroundColor3 = t.Hover, BackgroundTransparency = item.Hovered and 0.45 or 1 })
	end
end

function Toolbar:SetOpenPages(pages)
	self.OpenPages = pages
	self:_render(false)
end

function Toolbar:_showHint(item)
	self._hintToken += 1
	local hint = self.Hint
	hint.Text = item.Page.Name
	local x = self:_offset(item.Index) + BUTTON / 2
	hint.Position = UDim2.new(0, x, 1, 6)
	Motion.tween(hint, "Fast", {
		Position = UDim2.new(0, x, 1, 10),
		BackgroundTransparency = 0.04,
		TextTransparency = 0,
	})
	Motion.tween(self.HintStroke, "Fast", { Transparency = 0.25 })
end

function Toolbar:_hideHint()
	self._hintToken += 1
	Motion.tween(self.Hint, "Fast", { BackgroundTransparency = 1, TextTransparency = 1 })
	Motion.tween(self.HintStroke, "Fast", { Transparency = 1 })
end

function Toolbar:AddItem(page)
	local index = #self.Items + 1
	local button = Util.button({
		Name = page.Name,
		Size = UDim2.fromOffset(BUTTON, BUTTON),
		LayoutOrder = index,
		ZIndex = 3,
		Parent = self.Row,
	})
	local scale = Util.new("UIScale", { Parent = button })
	Util.corner(button, 8)
	local icon = Icons.create(page.Icon, ICON, self.ctx.Theme.Tokens.TextMuted, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -2),
		ZIndex = 3,
		Parent = button,
	})
	local dot = Util.frame({
		Name = "OpenDot", AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -1), Size = UDim2.fromOffset(3, 3),
		BackgroundTransparency = 1, ZIndex = 4, Parent = button,
	})
	Util.corner(dot, UDim.new(1, 0))
	local item = { Page = page, Button = button, Icon = icon, Dot = dot, Scale = scale, Index = index, Hovered = false }
	table.insert(self.Items, item)

	button.MouseEnter:Connect(function()
		item.Hovered = true
		Motion.tween(scale, "Fast", { Scale = 1.08 })
		self:_render(false)
		self:_showHint(item)
	end)
	button.MouseLeave:Connect(function()
		item.Hovered = false
		Motion.tween(scale, "Normal", { Scale = 1 })
		self:_render(false)
		self:_hideHint()
	end)
	button.MouseButton1Down:Connect(function()
		Motion.tween(scale, "Micro", { Scale = 0.9 })
	end)
	button.MouseButton1Up:Connect(function()
		Motion.tween(scale, "Normal", { Scale = item.Hovered and 1.08 or 1 })
	end)
	button.Activated:Connect(function()
		self.Clicked:Fire(page)
	end)

	local width = PAD * 2 + index * BUTTON + (index - 1) * GAP
	self.Holder.Size = UDim2.fromOffset(width, BUTTON + PAD * 2)
	self:SetScale(self._requestedScale or 1)
	self:_render(true)
	return item
end

function Toolbar:SetActive(page)
	self.Active = page
	local item
	for _, candidate in ipairs(self.Items) do
		if candidate.Page == page then
			item = candidate
		end
	end
	local indicator = self.Indicator
	if item then
		local target = UDim2.fromOffset(self:_offset(item.Index), PAD)
		self._lastIndex = item.Index
		if not self._shown then
			-- Appear in place rather than sliding in from the last position.
			indicator.Size = UDim2.fromOffset(BUTTON - 6, BUTTON - 6)
			indicator.Position = UDim2.fromOffset(self:_offset(item.Index) + 3, PAD + 3)
		end
		Motion.tween(indicator, "Smooth", {
			Position = target,
			Size = UDim2.fromOffset(BUTTON, BUTTON),
			BackgroundTransparency = 0.7,
		})
		Motion.tween(self.IndicatorStroke, "Smooth", { Transparency = 0.85 })
		self._shown = true
	elseif self._shown then
		self._shown = false
		Motion.tween(indicator, "Normal", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(BUTTON - 6, BUTTON - 6),
			Position = UDim2.fromOffset(self:_offset(self._lastIndex or 1) + 3, PAD + 3),
		})
		Motion.tween(self.IndicatorStroke, "Normal", { Transparency = 1 })
		Motion.tween(self.Dot, "Normal", { BackgroundTransparency = 1 })
	end
	self:_render(false)
end

return Toolbar
