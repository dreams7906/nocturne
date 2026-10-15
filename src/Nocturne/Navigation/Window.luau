--[[
	Window
	The main panel: header (brand, badge, profile, minimise / close),
	category tabs with a sliding indicator, the page area and a footer.
	Draggable by the header; opens and closes with a scale + fade.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Parent.Core.Util)
local Signal = require(script.Parent.Parent.Core.Signal)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)
local Maid = require(script.Parent.Parent.Core.Maid)

local Window = {}
Window.__index = Window

local WIDTH, HEIGHT = 680, 520
local HEADER, TABS, FOOTER = 44, 36, 28

Window.Width, Window.Height = WIDTH, HEIGHT

local function iconButton(ctx, parent, iconName, order)
	local theme = ctx.Theme
	local button = Util.button({
		Name = iconName,
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	local maid = Maid.new():LinkTo(button)
	Util.corner(button, 6)
	theme:Bind(button, { BackgroundColor3 = "Hover" })
	-- `ref.Icon` can be swapped later (minimise <-> restore glyph).
	local ref = {}
	ref.Icon = Icons.create(iconName, 14, theme.Tokens.TextMuted, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = button,
	})
	local hovered = false
	local function render(instant)
		local t = theme.Tokens
		Motion.tween(button, instant and "Instant" or "Fast", { BackgroundTransparency = hovered and 0 or 1 })
		Icons.tween(ref.Icon, instant and "Instant" or "Fast", hovered and t.Text or t.TextMuted)
	end
	ref.Render = render
	button.MouseEnter:Connect(function()
		hovered = true
		render(false)
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		render(false)
	end)
	maid:Give(theme.Changed:Connect(render))
	return button, ref
end

function Window.new(ctx, opts)
	local theme = ctx.Theme
	local self = setmetatable({
		ctx = ctx,
		Pages = {},
		Current = nil,
		IsOpen = false,
		Minimized = false,
		_tabs = {},
		_version = 0,
		PageChanged = Signal.new(),
		Closed = Signal.new(),
		Focused = Signal.new(),
		Maid = Maid.new(),
		Width = opts.Width or WIDTH,
		Height = opts.Height or HEIGHT,
	}, Window)

	local surface = Util.surface(ctx, {
		Name = "Window",
		Radius = 12,
		Size = UDim2.fromOffset(self.Width, self.Height),
		ShadowLayers = 3,
		ShadowSpread = 3,
		ShadowOffset = 5,
		ShadowTransparency = 0.96,
		GlossStrength = 0.16,
		ZIndex = 10,
		Parent = ctx.Gui,
	})
	local holder, body = surface.Holder, surface.Body
	holder.Visible = false
	self.Surface, self.Holder, self.Body = surface, holder, body
	self.Scale = Util.new("UIScale", { Parent = holder })
	self.BodyScale = Util.new("UIScale", { Parent = body })
	body.Active = true
	body.InputBegan:Connect(function(input)
		if Util.isPress(input) then self.Focused:Fire() end
	end)

	-- Header ---------------------------------------------------------------
	local header = Util.frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER),
		Active = true,
		ZIndex = 2,
		Parent = body,
	})
	self.Header = header

	local brand = Util.frame({
		Name = "Brand",
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		ZIndex = 2,
		Parent = header,
	})
	Util.list(brand, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 8,
	})

	local mark = Icons.create("nocturne", 19, theme.Tokens.Accent, { Parent = brand })
	mark.LayoutOrder = 0
	self.Maid:Give(theme.Changed:Connect(function()
		Icons.tint(mark, theme.Tokens.Accent)
	end))

	local title = Util.text({
		Text = opts.Title or "Nocturne",
		FontFace = Util.Fonts.Bold,
		TextSize = 14,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		LayoutOrder = 1,
		Parent = brand,
	})
	theme:Bind(title, { TextColor3 = "Text" })

	local subtitle = Util.text({
		Text = opts.Subtitle or "Interface",
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		LayoutOrder = 2,
		Parent = brand,
	})
	theme:Bind(subtitle, { TextColor3 = "TextMuted" })

	local badge = Util.text({
		Text = opts.Badge or "Plus",
		FontFace = Util.Fonts.Bold,
		TextSize = 10,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		BackgroundTransparency = 0,
		LayoutOrder = 3,
		Parent = brand,
	})
	Util.corner(badge, UDim.new(1, 0))
	Util.padding(badge, 0, 8)
	local badgeStroke = Util.stroke(badge, { Transparency = 0.2 })
	theme:Bind(badge, { BackgroundColor3 = "Surface2", TextColor3 = "Text" })
	theme:Bind(badgeStroke, { Color = "BorderStrong" })
	ctx:RegisterGloss(Util.gloss(badge, 0.2))

	local right = Util.frame({
		Name = "Right",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
		ZIndex = 3,
		Parent = header,
	})
	Util.list(right, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 4,
	})

	local player = Players.LocalPlayer
	if opts.ShowProfile ~= false and player then
		local profile = Util.frame({
			Name = "Profile",
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 24),
			LayoutOrder = 1,
			Parent = right,
		})
		Util.list(profile, {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = 7,
		})
		Util.padding(profile, 0, 8, 0, 0)
		local avatar = Util.new("ImageLabel", {
			Name = "Avatar",
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 0,
			Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48"):format(math.max(player.UserId, 1)),
			LayoutOrder = 2,
			Parent = profile,
		})
		Util.corner(avatar, UDim.new(1, 0))
		local avatarStroke = Util.stroke(avatar, { Transparency = 0.2 })
		theme:Bind(avatar, { BackgroundColor3 = "Surface2" })
		theme:Bind(avatarStroke, { Color = "BorderStrong" })
		local name = Util.text({
			Name = "Username",
			Text = opts.Profile or player.DisplayName,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			LayoutOrder = 1,
			Parent = profile,
		})
		theme:Bind(name, { TextColor3 = "TextDim" })
		local anonymous = Icons.create("player", 20, theme.Tokens.TextDim, { Parent = profile })
		anonymous.Name = "AnonymousAvatar"
		anonymous.LayoutOrder = 2
		self.ProfileName, self.ProfileAvatar, self.AnonymousAvatar = name, avatar, anonymous
		self._profileText, self._profileImage = name.Text, avatar.Image
		self:SetPrivacyMode(opts.PrivacyMode == true)
		self.Maid:Give(theme.Changed:Connect(function()
			Icons.tint(anonymous, theme.Tokens.TextDim)
		end))

		local separator = Util.frame({
			Size = UDim2.fromOffset(1, 14),
			BackgroundTransparency = 0,
			LayoutOrder = 2,
			Parent = right,
		})
		theme:Bind(separator, { BackgroundColor3 = "Border" })
	end

	local minimize, minimizeRef = iconButton(ctx, right, "minimize", 3)
	local close = iconButton(ctx, right, "close", 4)
	self._minimizeRef = minimizeRef
	minimize.Activated:Connect(function()
		self:SetMinimized(not self.Minimized)
	end)
	close.Activated:Connect(function()
		self:Close()
	end)

	-- Tabs -----------------------------------------------------------------
	local tabs = Util.frame({
		Name = "Tabs",
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 0, TABS),
		ZIndex = 2,
		Parent = body,
	})
	local tabList = Util.frame({
		Name = "List",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		ZIndex = 3,
		Parent = tabs,
	})
	Util.list(tabList, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 2,
	})
	local indicator = Util.frame({
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(60, 26),
		BackgroundTransparency = 0,
		ZIndex = 2,
		Parent = tabs,
	})
	Util.corner(indicator, 7)
	local indicatorStroke = Util.stroke(indicator, { Transparency = 0.1 })
	theme:Bind(indicator, { BackgroundColor3 = "Surface2" })
	theme:Bind(indicatorStroke, { Color = "BorderStrong" })
	ctx:RegisterGloss(Util.gloss(indicator, 0.16))
	ctx:RegisterGloss(Util.sheen(indicator, 6, 0.86))
	self.TabList, self.Indicator, self.Tabs = tabList, indicator, tabs

	local tabsLine = Util.frame({
		Position = UDim2.fromOffset(0, HEADER + TABS),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.25,
		ZIndex = 2,
		Parent = body,
	})
	theme:Bind(tabsLine, { BackgroundColor3 = "Border" })
	local headerLine = Util.frame({
		Position = UDim2.fromOffset(14, HEADER),
		Size = UDim2.new(1, -28, 0, 1),
		BackgroundTransparency = 0.6,
		ZIndex = 2,
		Parent = body,
	})
	theme:Bind(headerLine, { BackgroundColor3 = "Border" })

	-- Pages ----------------------------------------------------------------
	local pages = Util.frame({
		Name = "Pages",
		Position = UDim2.fromOffset(0, HEADER + TABS + 1),
		Size = UDim2.new(1, 0, 1, -(HEADER + TABS + 1 + FOOTER)),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = body,
	})
	self.PageHolder = pages

	-- Footer ---------------------------------------------------------------
	local footer = Util.frame({
		Name = "Footer",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, FOOTER),
		BackgroundTransparency = 0.5,
		ZIndex = 2,
		Parent = body,
	})
	theme:Bind(footer, { BackgroundColor3 = "Surface" })
	local footerLine = Util.frame({ Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.25, Parent = footer })
	theme:Bind(footerLine, { BackgroundColor3 = "Border" })

	local status = Util.frame({
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0.33, 0, 1, 0),
		Parent = footer,
	})
	Util.list(status, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 6,
	})
	local dot = Util.frame({ Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 0, Parent = status })
	Util.corner(dot, UDim.new(1, 0))
	theme:Bind(dot, { BackgroundColor3 = "Success" })
	local online = Util.text({
		TextSize = 11,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		LayoutOrder = 1,
		Parent = status,
	})
	theme:Bind(online, { TextColor3 = "TextMuted" })
	local function updateCount()
		local count = #Players:GetPlayers()
		online.Text = ("%d %s in server"):format(count, count == 1 and "player" or "players")
	end
	self.Maid:Give(Players.PlayerAdded:Connect(updateCount))
	self.Maid:Give(Players.PlayerRemoving:Connect(function()
		task.defer(updateCount)
	end))
	updateCount()

	local center = Util.text({
		Text = opts.FooterCenter or "nocturne.ui",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.34, 0, 1, 0),
		Parent = footer,
	})
	theme:Bind(center, { TextColor3 = "TextMuted" })
	local version = Util.text({
		Text = opts.FooterRight or "Build 1.0.0",
		TextSize = 11,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -34, 0, 0),
		Size = UDim2.new(0.33, 0, 1, 0),
		Parent = footer,
	})
	theme:Bind(version, { TextColor3 = "TextMuted" })

	self:_setupDrag()
	if opts.Resizable ~= false then self:_setupResize() end
	self.Maid:Give(theme.Changed:Connect(function(instant)
		self:_renderTabs(instant)
	end))
	return self
end

-- Dragging ---------------------------------------------------------------

function Window:_clamp(position)
	local viewport = self.ctx.Gui.AbsoluteSize
	local scale = self.Scale.Scale
	local width = self.Width * scale
	local height = (self.Minimized and HEADER or self.Height) * scale
	local x = math.clamp(position.X, 8, math.max(8, viewport.X - width - 8))
	local y = math.clamp(position.Y, 8, math.max(8, viewport.Y - height - 8))
	return Vector2.new(x, y)
end

function Window:_setupDrag()
	local dragging, startPointer, startPosition
	self.Header.InputBegan:Connect(function(input)
		if Util.isPress(input) then
			self.Focused:Fire()
			dragging = true
			startPointer = Util.pointer(input)
			startPosition = Vector2.new(self.Holder.Position.X.Offset, self.Holder.Position.Y.Offset)
			self.ctx.Popups:CloseAll()
		end
	end)
	self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and Util.isMove(input) then
			local target = self:_clamp(startPosition + (Util.pointer(input) - startPointer))
			self.Holder.Position = UDim2.fromOffset(target.X, target.Y)
		end
	end))
	self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
		if Util.isPress(input) then
			dragging = false
		end
	end))
end

function Window:SetPrivacyMode(enabled)
	self.PrivacyMode = enabled
	if self.ProfileName then
		self.ProfileName.Text = enabled and "User" or self._profileText
		self.ProfileAvatar.Visible = not enabled
		self.ProfileAvatar.Image = enabled and "" or self._profileImage
		self.AnonymousAvatar.Visible = enabled
	end
end

function Window:SetSize(width, height)
	local viewport = self.ctx.Gui.AbsoluteSize
	local scale = math.max(self.Scale.Scale, 0.01)
	local position = self.Holder.Position
	local maxWidth = math.max(200, (viewport.X - position.X.Offset - 8) / scale)
	local maxHeight = math.max(180, (viewport.Y - position.Y.Offset - 8) / scale)
	self.Width = math.clamp(width, math.min(480, maxWidth), maxWidth)
	self.Height = math.clamp(height, math.min(320, maxHeight), maxHeight)
	self.Holder.Size = UDim2.fromOffset(self.Width, self.Minimized and HEADER or self.Height)
	self.ctx.Popups:CloseAll()
	self:_renderTabs(true)
end

function Window:_setupResize()
	local handle = Util.button({
		Name = "ResizeHandle", AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -5, 1, -5), Size = UDim2.fromOffset(24, 24),
		ZIndex = 60, Parent = self.Body,
	})
	local glyph = Icons.create("resize", 18, Color3.new(1, 1, 1), {
		Position = UDim2.fromOffset(5, 5), ZIndex = 60, Transparency = 0.45, Parent = handle,
	})
	self.ResizeHandle = handle
	local dragging, startPointer, startSize
	handle.MouseEnter:Connect(function() Icons.tween(glyph, "Fast", Color3.new(1, 1, 1), 0.05) end)
	handle.MouseLeave:Connect(function()
		if not dragging then Icons.tween(glyph, "Fast", Color3.new(1, 1, 1), 0.45) end
	end)
	handle.InputBegan:Connect(function(input)
		if Util.isPress(input) then
			dragging = true
			startPointer = Util.pointer(input)
			startSize = Vector2.new(self.Width, self.Height)
			self.Focused:Fire()
			self.ctx.Popups:CloseAll()
		end
	end)
	self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and Util.isMove(input) then
			local delta = (Util.pointer(input) - startPointer) / math.max(self.Scale.Scale, 0.01)
			self:SetSize(startSize.X + delta.X, startSize.Y + delta.Y)
		end
	end))
	self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
		if dragging and Util.isPress(input) then
			dragging = false
			Icons.tween(glyph, "Fast", Color3.new(1, 1, 1), 0.45)
		end
	end))
end

function Window:Center()
	local viewport = self.ctx.Gui.AbsoluteSize
	local scale = self.Scale.Scale
	local x = (viewport.X - self.Width * scale) / 2
	local top = self.ctx.ToolbarBottom and self.ctx.ToolbarBottom() + 14 or 72
	local y = math.max(top, (viewport.Y - self.Height * scale) / 2)
	local offset = ((self.Index or 1) - 1) % 5 * 28
	x += offset
	y += offset
	local target = self:_clamp(Vector2.new(x, y))
	self.Holder.Position = UDim2.fromOffset(target.X, target.Y)
end

function Window:SetScale(scale)
	self.Scale.Scale = scale
	local position = self.Holder.Position
	local target = self:_clamp(Vector2.new(position.X.Offset, position.Y.Offset))
	self.Holder.Position = UDim2.fromOffset(target.X, target.Y)
	task.defer(function()
		self:_renderTabs(true)
	end)
end

-- Tabs -------------------------------------------------------------------

function Window:_renderTabs(instant)
	local t = self.ctx.Theme.Tokens
	for page, tab in pairs(self._tabs) do
		local active = page == self.Current
		local preset = instant and "Instant" or "Fast"
		Motion.tween(tab.Label, preset, {
			TextColor3 = active and t.Text or (tab.Hovered and t.TextDim or t.TextMuted),
		})
		Icons.tween(tab.Icon, preset, active and t.Text or (tab.Hovered and t.TextDim or t.TextMuted))
	end

	local tab = self.Current and self._tabs[self.Current]
	if not tab then
		self.Indicator.BackgroundTransparency = 1
		return
	end
	-- Convert absolute coordinates back into unscaled window space.
	local ratio = self.Tabs.AbsoluteSize.X / self.Width
	if ratio <= 0 then
		return
	end
	local x = (tab.Button.AbsolutePosition.X - self.Tabs.AbsolutePosition.X) / ratio
	local width = tab.Button.AbsoluteSize.X / ratio
	Motion.tween(self.Indicator, instant and "Instant" or "Smooth", {
		Position = UDim2.new(0, x, 0.5, 0),
		Size = UDim2.fromOffset(width, 26),
		BackgroundTransparency = 0,
	})
end

function Window:AddPage(page)
	table.insert(self.Pages, page)
	local ctx = self.ctx
	local button = Util.button({
		Name = page.Name,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 26),
		LayoutOrder = #self.Pages,
		ZIndex = 3,
		Parent = self.TabList,
	})
	Util.padding(button, 0, 10)
	Util.list(button, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 6,
	})
	local icon = Icons.create(page.Icon, 13, ctx.Theme.Tokens.TextMuted, { ZIndex = 3, Parent = button })
	local label = Util.text({
		Text = page.Name,
		FontFace = Util.Fonts.SemiBold,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		LayoutOrder = 1,
		ZIndex = 3,
		Parent = button,
	})
	local tab = { Button = button, Icon = icon, Label = label, Hovered = false }
	self._tabs[page] = tab

	button.Activated:Connect(function()
		self:Select(page)
	end)
	button.MouseEnter:Connect(function()
		tab.Hovered = true
		self:_renderTabs(false)
	end)
	button.MouseLeave:Connect(function()
		tab.Hovered = false
		self:_renderTabs(false)
	end)
	button:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if self.Current == page then
			self:_renderTabs(true)
		end
	end)
	self:_renderTabs(true)
end

function Window:Select(page, instant)
	if self.Current == page then
		return
	end
	local previous = self.Current
	self.Current = page
	self.ctx.Popups:CloseAll()

	if previous then
		previous.Canvas.Visible = false
	end
	local canvas = page.Canvas
	canvas.Visible = true
	if instant or not self.IsOpen then
		canvas.GroupTransparency = 0
		canvas.Position = UDim2.new()
	else
		canvas.GroupTransparency = 1
		canvas.Position = UDim2.fromOffset(0, 8)
		Motion.tween(canvas, "Smooth", { GroupTransparency = 0, Position = UDim2.new() })
	end
	self:_renderTabs(instant)
	self.PageChanged:Fire(page)
end

-- Open / close / minimise --------------------------------------------------

function Window:Open()
	if self.IsOpen then
		return
	end
	self.IsOpen = true
	self.Focused:Fire()
	self._version += 1
	local holder = self.Holder
	if not self._placed then
		self._placed = true
		self:Center()
	end
	holder.Visible = true
	self.BodyScale.Scale = 0.965
	self.Surface.SetAlpha(1, "Instant")
	Motion.tween(self.BodyScale, "Smooth", { Scale = 1 })
	self.Surface.SetAlpha(0, "Smooth")
	task.defer(function()
		self:_renderTabs(true)
	end)
end

function Window:Close()
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	self._version += 1
	local version = self._version
	self.ctx.Popups:CloseAll()
	self.ctx.Tooltip:Hide()
	Motion.tween(self.BodyScale, "Normal", { Scale = 0.975 })
	self.Surface.SetAlpha(1, "Normal")
	task.delay(Motion.info("Normal").Time + 0.02, function()
		if version == self._version then
			self.Holder.Visible = false
		end
	end)
	self.Closed:Fire()
end

function Window:SetMinimized(minimized)
	self.Minimized = minimized
	self.ctx.Popups:CloseAll()
	-- Resize immediately: tweening a CanvasGroup's render target can leave it cropped.
	self.Holder.Size = UDim2.fromOffset(self.Width, minimized and HEADER or self.Height)
	if self.ResizeHandle then self.ResizeHandle.Visible = not minimized end
	self.Tabs.Visible = not minimized
	self.PageHolder.Visible = not minimized
	self.Body.Footer.Visible = not minimized
	-- Swap the glyph between "minimise" and "restore".
	local ref = self._minimizeRef
	local parent = ref.Icon.Parent
	ref.Icon:Destroy()
	ref.Icon = Icons.create(minimized and "maximize" or "minimize", 14, self.ctx.Theme.Tokens.TextMuted, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = parent,
	})
	ref.Render(true)
	local position = self.Holder.Position
	local target = self:_clamp(Vector2.new(position.X.Offset, position.Y.Offset))
	self.Holder.Position = UDim2.fromOffset(target.X, target.Y)
end

function Window:Destroy()
	self.Maid:Clean()
	self.Holder:Destroy()
	self.Focused:Destroy()
	self.Closed:Destroy()
	self.PageChanged:Destroy()
end

return Window
