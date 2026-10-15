--[[
	Notifications
	Toast stack in the bottom-right corner. Toasts slide in, show a thin
	progress bar for their lifetime and collapse smoothly when dismissed.

	ctx.Notify({ Title, Text, Type = "info"|"success"|"warning"|"error", Duration })
]]

local Util = require(script.Parent.Parent.Core.Util)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)

local Notifications = {}
Notifications.__index = Notifications

local WIDTH = 270
local MAX_VISIBLE = 5

local TYPES = {
	info = { icon = "info", token = "Accent" },
	success = { icon = "success", token = "Success" },
	warning = { icon = "warning", token = "Warning" },
	error = { icon = "warning", token = "Danger" },
}

function Notifications.new(ctx)
	local self = setmetatable({ ctx = ctx, _toasts = {}, Enabled = true, Position = "Bottom Right" }, Notifications)
	local stack = Util.frame({
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -18),
		Size = UDim2.new(0, WIDTH, 1, -120),
		ZIndex = 150,
		Parent = ctx.Overlay,
	})
	self._layout = Util.list(stack, {
		Padding = 8,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})
	self._scale = Util.new("UIScale", { Parent = stack })
	self.Stack = stack
	self._order = 0
	return self
end

function Notifications:SetScale(scale)
	self._scale.Scale = scale
end

function Notifications:SetPosition(where)
	self.Position = where
	local stack = self.Stack
	if where == "Top Right" then
		stack.AnchorPoint = Vector2.new(1, 0)
		stack.Position = UDim2.new(1, -18, 0, 72)
		self._layout.VerticalAlignment = Enum.VerticalAlignment.Top
	else
		stack.AnchorPoint = Vector2.new(1, 1)
		stack.Position = UDim2.new(1, -18, 1, -18)
		self._layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end
end

function Notifications:Push(opts)
	if not self.Enabled then
		return
	end
	local ctx = self.ctx
	local theme = ctx.Theme
	local kind = TYPES[opts.Type or "info"] or TYPES.info
	local duration = opts.Duration or ctx.NotifyDuration or 4

	-- Oldest toasts leave first when the stack is full.
	if #self._toasts >= MAX_VISIBLE then
		self._toasts[1].Dismiss()
	end

	self._order += 1
	local bottomUp = self._layout.VerticalAlignment == Enum.VerticalAlignment.Bottom
	local slot = Util.frame({
		Name = "Toast",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = bottomUp and self._order or -self._order,
		ClipsDescendants = false,
		Parent = self.Stack,
	})

	local card = Util.new("TextButton", {
		Name = "Card",
		AutoButtonColor = false,
		Text = "",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(36, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = slot,
	})
	Util.corner(card, 9)
	Util.padding(card, 11, 12, 13, 14)
	local stroke = Util.stroke(card, { Transparency = 1 })
	theme:Bind(card, { BackgroundColor3 = "Elevated" })
	theme:Bind(stroke, { Color = "BorderStrong" })
	Util.gloss(card, 0.1)

	local accent = Util.frame({
		Name = "Accent",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, -8, 0, 1),
		Size = UDim2.new(0, 2, 1, -2),
		Parent = card,
	})
	Util.corner(accent, 1)
	theme:Bind(accent, { BackgroundColor3 = kind.token })

	local icon = Icons.create(kind.icon, 15, theme:Get(kind.token), {
		Position = UDim2.fromOffset(0, 1),
		Transparency = 1,
		Parent = card,
	})

	local title = Util.text({
		Text = opts.Title or "Notification",
		FontFace = Util.Fonts.Bold,
		TextSize = 12,
		Position = UDim2.fromOffset(23, 0),
		Size = UDim2.new(1, -23, 0, 16),
		TextTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})
	theme:Bind(title, { TextColor3 = "Text" })

	local body = Util.text({
		Text = opts.Text or "",
		TextSize = 12,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(23, 19),
		Size = UDim2.new(1, -23, 0, 0),
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = 1,
		Visible = (opts.Text or "") ~= "",
		Parent = card,
	})
	theme:Bind(body, { TextColor3 = "TextDim" })

	local track = Util.frame({
		Name = "Progress",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, -6, 1, 9),
		Size = UDim2.new(1, 6, 0, 2),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local bar = Util.frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = track,
	})
	Util.corner(bar, 1)
	theme:Bind(bar, { BackgroundColor3 = kind.token })

	local toast = { Dismissed = false }
	table.insert(self._toasts, toast)

	-- Enter
	Motion.tween(card, "Smooth", { Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.02 })
	Motion.tween(stroke, "Smooth", { Transparency = 0.25 })
	Motion.tween(title, "Smooth", { TextTransparency = 0 })
	Motion.tween(body, "Smooth", { TextTransparency = 0 })
	Motion.tween(accent, "Smooth", { BackgroundTransparency = 0 })
	Motion.tween(bar, "Smooth", { BackgroundTransparency = 0.35 })
	Icons.tween(icon, "Smooth", theme:Get(kind.token), 0)
	local timer = Motion.timer(bar, duration, { Size = UDim2.fromScale(0, 1) })

	function toast.Dismiss()
		if toast.Dismissed then
			return
		end
		toast.Dismissed = true
		timer:Cancel()
		local index = table.find(self._toasts, toast)
		if index then
			table.remove(self._toasts, index)
		end
		local height = slot.AbsoluteSize.Y / math.max(self._scale.Scale, 0.01)
		slot.AutomaticSize = Enum.AutomaticSize.None
		slot.Size = UDim2.new(1, 0, 0, height)
		slot.ClipsDescendants = true
		Motion.tween(card, "Normal", { Position = UDim2.fromOffset(36, 0), BackgroundTransparency = 1 })
		Motion.tween(stroke, "Normal", { Transparency = 1 })
		Motion.tween(title, "Fast", { TextTransparency = 1 })
		Motion.tween(body, "Fast", { TextTransparency = 1 })
		Motion.tween(accent, "Fast", { BackgroundTransparency = 1 })
		Motion.tween(bar, "Fast", { BackgroundTransparency = 1 })
		Icons.tween(icon, "Fast", theme:Get(kind.token), 1)
		Motion.tween(slot, "Normal", { Size = UDim2.new(1, 0, 0, 0) })
		task.delay(Motion.info("Normal").Time + 0.05, function()
			slot:Destroy()
		end)
	end

	card.Activated:Connect(toast.Dismiss)
	task.delay(duration, toast.Dismiss)

	if ctx.NotifySound and opts.Silent ~= true then
		ctx.NotifySound()
	end
	return toast
end

return Notifications
