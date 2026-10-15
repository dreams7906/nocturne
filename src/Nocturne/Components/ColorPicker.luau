--[[
	ColorPicker
	Rounded swatch that opens a floating picker: saturation/value square,
	hue bar, hex field and a row of curated presets.

	ColorPicker.Swatch(ctx, parent, { Default, Flag, Callback, Presets })
	container:ColorPicker({ Text, Default, Flag, Tooltip, Callback })
]]

local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Parent.Core.Util)
local Signal = require(script.Parent.Parent.Core.Signal)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Presets = require(script.Parent.Parent.Themes.Presets)

local ColorPicker = {}

local WIDTH = 200
local PAD = 10
local INNER = WIDTH - PAD * 2
local SV_HEIGHT = 112
local HEIGHT = PAD + SV_HEIGHT + 10 + 10 + 10 + 24 + 10 + 18 + PAD

local function hueSequence()
	local keys = {}
	for index = 0, 6 do
		local alpha = index / 6
		table.insert(keys, ColorSequenceKeypoint.new(alpha, Color3.fromHSV(alpha == 1 and 0.999 or alpha, 1, 1)))
	end
	return ColorSequence.new(keys)
end

function ColorPicker.Swatch(ctx, parent, opts)
	local theme = ctx.Theme
	local color = opts.Default or Color3.new(1, 1, 1)
	local hue, sat, val = color:ToHSV()

	local root = Util.button({
		Name = "Swatch",
		Size = UDim2.fromOffset(opts.Width or 16, 14),
		BackgroundTransparency = 0,
		BackgroundColor3 = color,
		ZIndex = 6,
		Parent = parent,
	})
	Util.corner(root, 4)
	local stroke = Util.stroke(root, { Transparency = 0.1 })
	theme:Bind(stroke, { Color = "BorderStrong" })
	Util.sheen(root, 2, 0.75).ZIndex = 7

	local maid = Maid.new():LinkTo(root)
	local swatch = { Root = root, Changed = Signal.new() }
	local popup, open = nil, false
	local dragging -- "sv" | "hue" | nil

	local function commit(silent)
		color = Color3.fromHSV(hue, sat, val)
		Motion.tween(root, "Fast", { BackgroundColor3 = color })
		if popup then
			popup.SV.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
			popup.SVCursor.Position = UDim2.fromScale(sat, 1 - val)
			popup.HueCursor.Position = UDim2.fromScale(hue, 0.5)
			popup.Preview.BackgroundColor3 = color
			if not popup.Hex:IsFocused() then
				popup.Hex.Text = "#" .. string.upper(color:ToHex())
			end
		end
		if not silent then
			swatch.Changed:Fire(color)
			if opts.Callback then
				task.spawn(opts.Callback, color)
			end
			if opts.Flag then
				ctx.State:Notify(opts.Flag, color)
			end
		end
	end

	local function build()
		local surface = Util.surface(ctx, {
			Name = "ColorPopup",
			Radius = 9,
			Fill = "Elevated",
			FillTransparency = 0,
			ShadowLayers = 4,
			ShadowTransparency = 0.9,
			Size = UDim2.fromOffset(WIDTH, HEIGHT),
			ZIndex = 100,
			Parent = ctx.Overlay,
		})
		surface.Holder.Visible = false
		local scale = Util.new("UIScale", { Parent = surface.Holder })
		local body = surface.Body

		local sv = Util.button({
			Name = "SaturationValue",
			Position = UDim2.fromOffset(PAD, PAD),
			Size = UDim2.fromOffset(INNER, SV_HEIGHT),
			BackgroundTransparency = 0,
			ZIndex = 2,
			Parent = body,
		})
		Util.corner(sv, 6)
		local white = Util.frame({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 2,
			Parent = sv,
		})
		Util.corner(white, 6)
		Util.new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
		local black = Util.frame({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.new(0, 0, 0),
			ZIndex = 3,
			Parent = sv,
		})
		Util.corner(black, 6)
		Util.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
		local svCursor = Util.frame({
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(10, 10),
			ZIndex = 5,
			Parent = sv,
		})
		Util.corner(svCursor, UDim.new(1, 0))
		Util.stroke(svCursor, { Color = Color3.new(1, 1, 1), Thickness = 2 })

		local hueBar = Util.button({
			Name = "Hue",
			Position = UDim2.fromOffset(PAD, PAD + SV_HEIGHT + 10),
			Size = UDim2.fromOffset(INNER, 10),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 2,
			Parent = body,
		})
		Util.corner(hueBar, UDim.new(1, 0))
		Util.new("UIGradient", { Color = hueSequence(), Parent = hueBar })
		local hueCursor = Util.frame({
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(6, 14),
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
			Parent = hueBar,
		})
		Util.corner(hueCursor, 3)
		Util.stroke(hueCursor, { Color = Color3.new(0, 0, 0), Transparency = 0.6 })

		local rowY = PAD + SV_HEIGHT + 10 + 10 + 10
		local preview = Util.frame({
			Position = UDim2.fromOffset(PAD, rowY),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 0,
			ZIndex = 2,
			Parent = body,
		})
		Util.corner(preview, 6)
		local previewStroke = Util.stroke(preview)
		theme:Bind(previewStroke, { Color = "BorderStrong" })

		local hexHolder = Util.frame({
			Position = UDim2.fromOffset(PAD + 32, rowY),
			Size = UDim2.fromOffset(INNER - 32, 24),
			BackgroundTransparency = 0,
			ZIndex = 2,
			Parent = body,
		})
		Util.corner(hexHolder, 6)
		theme:Bind(hexHolder, { BackgroundColor3 = "Surface2" })
		local hexStroke = Util.stroke(hexHolder)
		theme:Bind(hexStroke, { Color = "Border" })
		local hex = Util.new("TextBox", {
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -16, 1, 0),
			BackgroundTransparency = 1,
			ClearTextOnFocus = false,
			FontFace = Util.Fonts.Medium,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "",
			ZIndex = 3,
			Parent = hexHolder,
		})
		theme:Bind(hex, { TextColor3 = "Text", PlaceholderColor3 = "TextMuted" })

		local presetRow = Util.frame({
			Position = UDim2.fromOffset(PAD, rowY + 24 + 10),
			Size = UDim2.fromOffset(INNER, 18),
			ZIndex = 2,
			Parent = body,
		})
		Util.list(presetRow, {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = 4,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		})
		local presetColors = opts.Presets or Presets.Accents
		local chip = math.floor((INNER - (#presetColors - 1) * 4) / #presetColors)
		for index, presetColor in ipairs(presetColors) do
			local button = Util.button({
				Size = UDim2.fromOffset(chip, 18),
				BackgroundTransparency = 0,
				BackgroundColor3 = presetColor,
				LayoutOrder = index,
				ZIndex = 3,
				Parent = presetRow,
			})
			Util.corner(button, 5)
			local chipStroke = Util.stroke(button, { Transparency = 0.4 })
			theme:Bind(chipStroke, { Color = "BorderStrong" })
			button.Activated:Connect(function()
				hue, sat, val = presetColor:ToHSV()
				commit(false)
			end)
		end

		popup = {
			Surface = surface,
			Scale = scale,
			SV = sv,
			SVCursor = svCursor,
			HueBar = hueBar,
			HueCursor = hueCursor,
			Preview = preview,
			Hex = hex,
		}
		popup.Handle = {
			Close = function()
				swatch:Close()
			end,
			Contains = function(point)
				return Util.contains(surface.Holder, point, 2) or Util.contains(root, point, 2)
			end,
		}

		local function updateFrom(point)
			if not open then
				return
			end
			if dragging == "sv" then
				local position, size = sv.AbsolutePosition, sv.AbsoluteSize
				if size.X <= 0 or size.Y <= 0 then return end
				sat = math.clamp((point.X - position.X) / size.X, 0, 1)
				val = 1 - math.clamp((point.Y - position.Y) / size.Y, 0, 1)
			elseif dragging == "hue" then
				local position, size = hueBar.AbsolutePosition, hueBar.AbsoluteSize
				if size.X <= 0 then return end
				hue = math.clamp((point.X - position.X) / size.X, 0, 0.999)
			end
			commit(false)
		end

		sv.InputBegan:Connect(function(input)
			if Util.isPress(input) then
				dragging = "sv"
				updateFrom(Util.pointer(input))
			end
		end)
		hueBar.InputBegan:Connect(function(input)
			if Util.isPress(input) then
				dragging = "hue"
				updateFrom(Util.pointer(input))
			end
		end)
		maid:Give(UserInputService.InputChanged:Connect(function(input)
			if dragging and Util.isMove(input) then
				updateFrom(Util.pointer(input))
			end
		end))
		maid:Give(UserInputService.InputEnded:Connect(function(input)
			if Util.isPress(input) then
				dragging = nil
			end
		end))
		hex.FocusLost:Connect(function()
			local text = string.gsub(hex.Text, "[^%x]", "")
			if #text == 3 then
				text = string.gsub(text, "%x", "%0%0")
			end
			if #text == 6 then
				local ok, parsed = pcall(Color3.fromHex, text)
				if ok then
					hue, sat, val = parsed:ToHSV()
				end
			end
			commit(false)
		end)

		maid:Give(surface.Holder)
		commit(true)
	end

	function swatch:Open()
		if open then
			return
		end
		if not popup then
			build()
		end
		open = true
		ctx.Popups:Open(popup.Handle)
		local viewport = ctx.Gui.AbsoluteSize
		local scale = math.min(ctx:GetScale(), (viewport.X - 16) / WIDTH, (viewport.Y - 16) / HEIGHT)
		local holder = popup.Surface.Holder
		local position = root.AbsolutePosition - ctx.Overlay.AbsolutePosition
		local size = root.AbsoluteSize
		local below = position.Y + size.Y + 6 + HEIGHT * scale <= viewport.Y - 8
		local x = math.clamp(position.X + size.X - WIDTH * scale, 8, math.max(8, viewport.X - WIDTH * scale - 8))
		popup.Scale.Scale = scale
		holder.AnchorPoint = Vector2.new(0, below and 0 or 1)
		local y = below and (position.Y + size.Y + 6) or math.max(HEIGHT * scale + 8, position.Y - 6)
		holder.Position = UDim2.fromOffset(x, y)
		holder.Visible = true
		popup.Surface.Body.GroupTransparency = 1
		popup.Surface.SetAlpha(0, "Normal")
		commit(true)
	end

	function swatch:Close()
		if not open then
			return
		end
		open = false
		dragging = nil
		ctx.Popups:Released(popup.Handle)
		popup.Surface.SetAlpha(1, "Fast")
		task.delay(Motion.info("Fast").Time + 0.02, function()
			if not open then
				popup.Surface.Holder.Visible = false
			end
		end)
	end

	function swatch:Get()
		return color
	end

	function swatch:Set(newColor, silent)
		if typeof(newColor) ~= "Color3" then
			return
		end
		hue, sat, val = newColor:ToHSV()
		commit(silent)
	end

	maid:Give(root.Activated:Connect(function()
		if open then
			ctx.Popups:Close(popup.Handle)
		else
			swatch:Open()
		end
	end))
	maid:Give(function()
		if open and popup then
			ctx.Popups:Released(popup.Handle)
		end
	end)

	if opts.Flag then
		local handle = {
			Get = function()
				return color
			end,
			Set = function(v)
				swatch:Set(v)
			end,
		}
		ctx.State:Register(opts.Flag, handle)
		maid:Give(function()
			ctx.State:Unregister(opts.Flag, handle)
		end)
	end

	return swatch
end

function ColorPicker.Row(container, opts)
	local ctx = container.ctx
	local row = container:Row(26)
	local label = Util.text({
		Text = opts.Text or "Color",
		Size = UDim2.new(1, -60, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	ctx.Theme:Bind(label, { TextColor3 = "TextDim" })
	if opts.Tooltip then
		ctx.Tooltip:Attach(label, opts.Tooltip)
	end
	local holder = Util.frame({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(28, 14),
		Parent = row,
	})
	local swatch = ColorPicker.Swatch(ctx, holder, {
		Default = opts.Default,
		Flag = opts.Flag,
		Callback = opts.Callback,
		Presets = opts.Presets,
		Width = 28,
	})
	return swatch
end

return ColorPicker
