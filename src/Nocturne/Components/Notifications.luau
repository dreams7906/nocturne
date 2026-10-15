local RunService = game:GetService("RunService")
local Util = require(script.Parent.Parent.Core.Util)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)
local Maid = require(script.Parent.Parent.Core.Maid)

local Notifications = {}
Notifications.__index = Notifications
local WIDTH, MAX_VISIBLE = 280, 5
local TYPES = {
	info = { icon = "info", token = "Accent" },
	success = { icon = "success", token = "Success" },
	warning = { icon = "warning", token = "Warning" },
	error = { icon = "warning", token = "Danger" },
}

function Notifications.new(ctx)
	local self = setmetatable({ ctx = ctx, _toasts = {}, Enabled = true, Position = "Bottom Right" }, Notifications)
	local stack = Util.frame({
		Name = "Notifications", AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18), Size = UDim2.new(0, WIDTH, 1, -120),
		ZIndex = 150, Parent = ctx.Overlay,
	})
	self._layout = Util.list(stack, {
		Padding = 8, VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})
	self._scale = Util.new("UIScale", { Parent = stack })
	self.Stack, self._order = stack, 0
	return self
end

function Notifications:SetScale(scale)
	self._scale.Scale = scale
end

function Notifications:SetPosition(where)
	self.Position = where
	if where == "Top Right" then
		self.Stack.AnchorPoint = Vector2.new(1, 0)
		self.Stack.Position = UDim2.new(1, -18, 0, 72)
		self._layout.VerticalAlignment = Enum.VerticalAlignment.Top
	else
		self.Stack.AnchorPoint = Vector2.new(1, 1)
		self.Stack.Position = UDim2.new(1, -18, 1, -18)
		self._layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end
end

function Notifications:Push(opts)
	if not self.Enabled then return end
	local ctx, theme = self.ctx, self.ctx.Theme
	local toast
	local kind = TYPES[string.lower(opts.Type or "info")] or TYPES.info
	local duration = math.max(0.1, tonumber(opts.Duration or ctx.NotifyDuration) or 4)
	if #self._toasts >= MAX_VISIBLE then self._toasts[1].Dismiss() end
	self._order += 1
	local bottomUp = self._layout.VerticalAlignment == Enum.VerticalAlignment.Bottom
	local slot = Util.frame({
		Name = "Toast", Size = UDim2.new(1, 0, 0, 64),
		LayoutOrder = bottomUp and self._order or -self._order,
		ClipsDescendants = false, Parent = self.Stack,
	})
	local maid = Maid.new():LinkTo(slot)
	local card = Util.new("CanvasGroup", {
		Name = "Card", Active = true,
		Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(20, 0),
		BackgroundTransparency = 0.04, GroupTransparency = 1, BorderSizePixel = 0, Parent = slot,
	})
	Util.corner(card, 10)
	Util.padding(card, 10, 12, 20, 12)
	theme:Bind(card, { BackgroundColor3 = "Elevated" })
	local scale = Util.new("UIScale", { Scale = 0.96, Parent = card })
	local gloss = Util.gloss(card, 0.08)
	ctx:RegisterGloss(gloss)
	local edge = Util.frame({
		Name = "Edge", Position = UDim2.fromOffset(-11, -9),
		Size = UDim2.new(1, 22, 1, 28), ZIndex = 5, Parent = card,
	})
	Util.corner(edge, 9)
	local stroke = Util.glassStroke(ctx, edge, "BorderStrong", 0.45)
	local badge = Util.frame({
		Name = "Badge", Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 0.91, ZIndex = 2, Parent = card,
	})
	Util.corner(badge, 8)
	theme:Bind(badge, { BackgroundColor3 = kind.token })
	local badgeStroke = Util.stroke(badge, { Transparency = 0.86 })
	theme:Bind(badgeStroke, { Color = kind.token })
	local icon = Icons.create(kind.icon, 16, theme:Get(kind.token), {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 2, Parent = badge,
	})
	maid:Give(theme.Changed:Connect(function() Icons.tint(icon, theme:Get(kind.token)) end))
	local title = Util.text({
		Name = "Title", Text = opts.Title or "Notification", FontFace = Util.Fonts.Bold,
		TextSize = 13, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -62, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Parent = card,
	})
	theme:Bind(title, { TextColor3 = "Text" })
	local body = Util.text({
		Name = "Message", Text = opts.Text or "", TextSize = 12, TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(40, 21),
		Size = UDim2.new(1, -40, 0, 0), TextYAlignment = Enum.TextYAlignment.Top,
		Visible = (opts.Text or "") ~= "", ZIndex = 2, Parent = card,
	})
	theme:Bind(body, { TextColor3 = "TextDim" })
	local function fitContent()
		if toast and toast.Dismissed then return end
		local height = body.AbsoluteSize.Y / math.max(self._scale.Scale * scale.Scale, 0.01)
		slot.Size = UDim2.new(1, 0, 0, math.max(64, math.ceil(51 + height - 0.01)))
	end
	maid:Give(body:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitContent))
	task.defer(fitContent)
	local close = Util.button({
		Name = "Dismiss", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(16, 16), ZIndex = 6, Parent = card,
	})
	Util.corner(close, 6)
	theme:Bind(close, { BackgroundColor3 = "Hover" })
	local closeIcon = Icons.create("close", 10, theme.Tokens.TextMuted, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 6, Parent = close,
	})
	local track = Util.frame({
		Name = "Progress", AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 40, 1, 9), Size = UDim2.new(1, -40, 0, 2),
		BackgroundTransparency = 0.75, ZIndex = 2, Parent = card,
	})
	Util.corner(track, 2)
	theme:Bind(track, { BackgroundColor3 = "BorderStrong" })
	local bar = Util.frame({
		Name = "Remaining", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.08, ZIndex = 3, Parent = track,
	})
	Util.corner(bar, 2)
	theme:Bind(bar, { BackgroundColor3 = kind.token })
	Util.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.32), NumberSequenceKeypoint.new(1, 0) }), Parent = bar,
	})
	toast = { Dismissed = false, Hovered = false, Remaining = duration, Card = card, Bar = bar }
	table.insert(self._toasts, toast)
	Motion.tween(card, "Smooth", { Position = UDim2.new(), GroupTransparency = 0 })
	Motion.tween(scale, "Pop", { Scale = 1 })

	function toast.Dismiss()
		if toast.Dismissed then return end
		toast.Dismissed = true
		maid:Clean()
		local height = slot.AbsoluteSize.Y / math.max(self._scale.Scale, 0.01)
		slot.AutomaticSize = Enum.AutomaticSize.None
		slot.Size = UDim2.new(1, 0, 0, height)
		slot.ClipsDescendants = true
		Motion.tween(card, "Normal", { Position = UDim2.fromOffset(20, 0), GroupTransparency = 1 })
		Motion.tween(scale, "Normal", { Scale = 0.96 })
		Motion.tween(slot, "Normal", { Size = UDim2.new(1, 0, 0, 0) })
		task.delay(Motion.info("Normal").Time + 0.02, function() slot:Destroy() end)
	end
	maid:Give(card.MouseEnter:Connect(function()
		toast.Hovered = true
		Motion.tween(stroke, "Fast", { Transparency = 0.25 })
	end))
	maid:Give(card.MouseLeave:Connect(function()
		toast.Hovered = false
		Motion.tween(stroke, "Fast", { Transparency = 0.45 })
	end))
	maid:Give(close.MouseEnter:Connect(function()
		Motion.tween(close, "Fast", { BackgroundTransparency = 0.25 })
		Icons.tween(closeIcon, "Fast", theme.Tokens.Text)
	end))
	maid:Give(close.MouseLeave:Connect(function()
		Motion.tween(close, "Fast", { BackgroundTransparency = 1 })
		Icons.tween(closeIcon, "Fast", theme.Tokens.TextMuted)
	end))
	maid:Give(close.Activated:Connect(toast.Dismiss))
	maid:Give(RunService.Heartbeat:Connect(function(dt)
		if not ctx.Gui.Enabled or (ctx.IsInterfaceVisible and not ctx.IsInterfaceVisible()) then
			toast.Hovered = false
			return
		end
		if toast.Hovered then return end
		toast.Remaining = math.max(0, toast.Remaining - dt)
		bar.Size = UDim2.fromScale(toast.Remaining / duration, 1)
		if toast.Remaining <= 0 then toast.Dismiss() end
	end))
	maid:Give(function()
		toast.Dismissed = true
		local index = table.find(self._toasts, toast)
		if index then table.remove(self._toasts, index) end
	end)
	if ctx.NotifySound and opts.Silent ~= true then ctx.NotifySound() end
	return toast
end

return Notifications
