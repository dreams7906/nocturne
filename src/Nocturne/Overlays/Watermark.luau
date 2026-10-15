--[[
	Watermark
	Compact status pill: brand, FPS, ping, session time and player name.
	"Single Row" or "Two Row" layout. Updates twice per second only while
	visible; the frame counter runs on RenderStepped only while enabled.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Util = require(script.Parent.Parent.Core.Util)
local Motion = require(script.Parent.Parent.Animations.Motion)

local Watermark = {}
Watermark.__index = Watermark

function Watermark.new(ctx, opts)
	local theme = ctx.Theme
	local self = setmetatable({ ctx = ctx, Enabled = false, Style = "Single Row", _start = os.clock() }, Watermark)

	local surface = Util.surface(ctx, {
		Name = "Watermark",
		Radius = 9,
		Position = UDim2.fromOffset(16, 66),
		Size = UDim2.fromOffset(10, 30),
		ShadowLayers = 4,
		ShadowSpread = 2,
		ShadowOffset = 3,
		ZIndex = 15,
		Parent = ctx.Gui,
	})
	surface.Holder.Visible = false
	self.Surface = surface
	self.Scale = Util.new("UIScale", { Parent = surface.Holder })

	local content = Util.frame({
		Name = "Content",
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = 2,
		Parent = surface.Body,
	})
	Util.list(content, { Padding = 2, VerticalAlignment = Enum.VerticalAlignment.Center })
	self.Content = content

	local function line(order)
		local frame = Util.frame({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 16),
			LayoutOrder = order,
			ZIndex = 2,
			Parent = content,
		})
		Util.list(frame, {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = 8,
		})
		return frame
	end

	local function segment(parent, order, bold, token)
		local label = Util.text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			FontFace = bold and Util.Fonts.Bold or Util.Fonts.SemiBold,
			TextSize = 12,
			LayoutOrder = order,
			ZIndex = 2,
			Parent = parent,
		})
		theme:Bind(label, { TextColor3 = token or "Text" })
		return label
	end

	local function divider(parent, order)
		local bar = Util.frame({
			Size = UDim2.fromOffset(1, 11),
			BackgroundTransparency = 0,
			LayoutOrder = order,
			ZIndex = 2,
			Parent = parent,
		})
		theme:Bind(bar, { BackgroundColor3 = "BorderStrong" })
		return bar
	end

	self._top = line(1)
	self._bottom = line(2)
	local dot = Util.frame({ Size = UDim2.fromOffset(6, 6), BackgroundTransparency = 0, ZIndex = 2, Parent = self._top })
	Util.corner(dot, UDim.new(1, 0))
	theme:Bind(dot, { BackgroundColor3 = "Accent" })
	self.Brand = segment(self._top, 1, true)
	self.Brand.Text = opts.Title or "Nocturne"
	self._divider1 = divider(self._top, 2)
	self.Fps = segment(self._top, 3)
	self._divider2 = divider(self._top, 4)
	self.Ping = segment(self._top, 5)
	self._divider3 = divider(self._top, 6)
	self.Time = segment(self._top, 7)
	self._divider4 = divider(self._top, 8)
	self.Name = segment(self._top, 9, false, "TextDim")
	local player = Players.LocalPlayer
	self.Name.Text = opts.PrivacyMode and "User" or (player and player.DisplayName or "Player")

	self._frames, self._elapsed, self._fps = 0, 0, 60
	return self
end

function Watermark:SetScale(scale)
	self.Scale.Scale = scale
end

function Watermark:SetStyle(style)
	self.Style = style
	local twoRow = style == "Two Row"
	local top, bottom = self._top, self._bottom
	-- Two Row keeps the brand on top and moves the live stats underneath.
	for _, item in ipairs({ self._divider1, self.Fps, self._divider2, self.Ping, self._divider3, self.Time, self._divider4, self.Name }) do
		item.Parent = twoRow and bottom or top
	end
	self._divider1.Visible = not twoRow
	bottom.Visible = twoRow
	self:_resize()
end

function Watermark:_resize()
	task.defer(function()
		local scale = math.max(self.Scale.Scale, 0.01)
		local size = self.Content.AbsoluteSize / scale
		self.Surface.Holder.Size = UDim2.fromOffset(math.ceil(size.X) + 24, math.ceil(size.Y) + 14)
		self.Content.Position = UDim2.fromOffset(12, 7)
	end)
end

function Watermark:_update()
	local player = Players.LocalPlayer
	local ping = player and math.floor(player:GetNetworkPing() * 1000 + 0.5) or 0
	local seconds = math.floor(os.clock() - self._start)
	self.Fps.Text = ("%d fps"):format(self._fps)
	self.Ping.Text = ("%d ms"):format(ping)
	self.Time.Text = ("%02d:%02d:%02d"):format(seconds // 3600, seconds // 60 % 60, seconds % 60)
	self:_resize()
end

function Watermark:SetEnabled(enabled)
	if self.Enabled == enabled then
		return
	end
	self.Enabled = enabled
	local holder = self.Surface.Holder
	if enabled then
		holder.Visible = true
		self:_update()
		self.Surface.SetAlpha(1, "Instant")
		self.Surface.SetAlpha(0, "Smooth")
		self._render = RunService.RenderStepped:Connect(function(dt)
			self._frames += 1
			self._elapsed += dt
			if self._elapsed >= 0.5 then
				self._fps = math.floor(self._frames / self._elapsed + 0.5)
				self._frames, self._elapsed = 0, 0
				self:_update()
			end
		end)
	else
		if self._render then
			self._render:Disconnect()
			self._render = nil
		end
		self.Surface.SetAlpha(1, "Normal")
		task.delay(Motion.info("Normal").Time, function()
			if not self.Enabled then
				holder.Visible = false
			end
		end)
	end
end

return Watermark
