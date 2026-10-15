--[[
	Toggle
	Softly squared check toggle (default) or pill switch (Style = "Switch").
	Accessories (keybind pill, colour swatch, help icon) sit on the right.

	container:Toggle({
		Text, Default = false, Flag, Tooltip, Style = "Check" | "Switch",
		Callback = function(value) end,
	}) -> toggle
		toggle:Set(value), toggle:Get(), toggle.Changed
		toggle:AddKeybind({ Default = "F", Flag, Mode = "Toggle" })
		toggle:AddColor({ Default = Color3, Flag, Callback })
]]

local Util = require(script.Parent.Parent.Core.Util)
local Signal = require(script.Parent.Parent.Core.Signal)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)

return function(container, opts)
	local ctx = container.ctx
	local theme = ctx.Theme
	local isSwitch = opts.Style == "Switch"

	local row = container:Row(26)
	local maid = Maid.new():LinkTo(row)
	local value = opts.Default == true
	local hovered = false

	local hit = Util.button({ Name = "Hit", Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = row })

	local box, fill, check, glow, knob
	if isSwitch then
		box = Util.frame({
			Name = "Track",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(28, 16),
			BackgroundTransparency = 0,
			ZIndex = 2,
			Parent = row,
		})
		Util.corner(box, UDim.new(1, 0))
		knob = Util.frame({
			Name = "Knob",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundTransparency = 0,
			ZIndex = 3,
			Parent = box,
		})
		Util.corner(knob, UDim.new(1, 0))
	else
		glow = Util.frame({
			Name = "Glow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0),
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1,
			ZIndex = 1,
			Parent = row,
		})
		Util.corner(glow, 8)
		box = Util.frame({
			Name = "Box",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundTransparency = 0,
			ZIndex = 2,
			Parent = row,
		})
		Util.corner(box, 4)
		fill = Util.frame({
			Name = "Fill",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0, 0),
			BackgroundTransparency = 0,
			ZIndex = 3,
			Parent = box,
		})
		Util.corner(fill, 4)
		Util.gloss(fill, 0.18)
		check = Icons.create("check", 12, Color3.new(), {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Transparency = 1,
			ZIndex = 4,
			Thickness = 1.6,
			Parent = box,
		})
	end
	local stroke = Util.stroke(box, { Transparency = 0.1 })

	local label = Util.text({
		Text = opts.Text or "Toggle",
		Position = UDim2.fromOffset(isSwitch and 0 or 24, 0),
		Size = UDim2.new(1, isSwitch and -40 or -24, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = row,
	})

	-- Right-aligned accessory strip (keybinds, colours, help).
	local accessories = Util.frame({
		Name = "Accessories",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, isSwitch and -38 or 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = 5,
		Parent = row,
	})
	Util.list(accessories, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 6,
	})

	local toggle = { Changed = Signal.new(), Row = row, Accessories = accessories }

	local function render(instant)
		local t = theme.Tokens
		local preset = instant and "Instant" or "Fast"
		Motion.tween(label, preset, { TextColor3 = (value or hovered) and t.Text or t.TextDim })
		if isSwitch then
			Motion.tween(box, preset, { BackgroundColor3 = value and t.Accent or (hovered and t.Hover or t.Surface2) })
			Motion.tween(stroke, preset, { Color = value and t.Accent or t.BorderStrong })
			Motion.tween(knob, instant and "Instant" or "Normal", {
				Position = UDim2.new(0, value and 14 or 2, 0.5, 0),
				BackgroundColor3 = value and t.AccentText or t.TextDim,
			})
		else
			Motion.tween(box, preset, { BackgroundColor3 = hovered and t.Hover or t.Surface2 })
			Motion.tween(stroke, preset, { Color = value and t.Accent or t.BorderStrong })
			Motion.tween(fill, instant and "Instant" or "Normal", {
				Size = value and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 0),
				BackgroundColor3 = t.Accent,
			})
			Motion.tween(glow, preset, {
				BackgroundColor3 = t.Accent,
				BackgroundTransparency = value and 0.86 or 1,
			})
			Icons.tween(check, preset, t.AccentText, value and 0 or 1)
		end
	end

	function toggle:Get()
		return value
	end

	function toggle:Set(newValue, silent)
		newValue = newValue == true
		if newValue == value then
			return
		end
		value = newValue
		render(false)
		if not silent then
			toggle.Changed:Fire(value)
			if opts.Callback then
				task.spawn(opts.Callback, value)
			end
			if opts.Flag then
				ctx.State:Notify(opts.Flag, value)
			end
		end
	end

	maid:Give(hit.Activated:Connect(function()
		toggle:Set(not value)
	end))
	maid:Give(hit.MouseEnter:Connect(function()
		hovered = true
		render(false)
	end))
	maid:Give(hit.MouseLeave:Connect(function()
		hovered = false
		render(false)
	end))
	maid:Give(theme.Changed:Connect(function(instant)
		render(instant)
	end))

	if opts.Flag then
		local handle = {
			Get = function()
				return value
			end,
			Set = function(v)
				toggle:Set(v)
			end,
		}
		ctx.State:Register(opts.Flag, handle)
		maid:Give(function()
			ctx.State:Unregister(opts.Flag, handle)
		end)
	end

	function toggle:AddKeybind(keyOpts)
		keyOpts = keyOpts or {}
		local pill = container.Components.KeybindPill(ctx, accessories, {
			Name = opts.Text,
			Default = keyOpts.Default,
			Flag = keyOpts.Flag,
			Mode = keyOpts.Mode or "Toggle",
			OnPress = keyOpts.Callback or function()
				if keyOpts.Mode == "Hold" then
					toggle:Set(true)
				else
					toggle:Set(not value)
				end
			end,
			OnRelease = keyOpts.Mode == "Hold" and function()
				toggle:Set(false)
			end or nil,
			Changed = keyOpts.Changed,
			Toggle = toggle,
		})
		pill.Root.LayoutOrder = 2
		return pill
	end

	function toggle:AddColor(colorOpts)
		colorOpts = colorOpts or {}
		local swatch = container.Components.ColorSwatch(ctx, accessories, colorOpts)
		swatch.Root.LayoutOrder = 1
		return swatch
	end

	if opts.Tooltip then
		local help = container.Components.HelpIcon(ctx, accessories, opts.Tooltip)
		help.LayoutOrder = 3
	end

	-- Keep the label clear of whatever accessories were attached.
	local function fitLabel()
		local reserved = accessories.AbsoluteSize.X / math.max(ctx:GetScale(), 0.01)
		local left = isSwitch and 0 or 24
		local right = (isSwitch and 38 or 0) + (reserved > 0 and reserved + 8 or 0)
		label.Size = UDim2.new(1, -(left + right), 1, 0)
	end
	maid:Give(accessories:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitLabel))
	task.defer(fitLabel)

	render(true)
	return toggle
end
