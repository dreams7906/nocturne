--[[
	Slider
	Thin track with an accent fill, a knob that appears on hover / drag and
	an editable value field for typing exact numbers.

	container:Slider({
		Text, Min = 0, Max = 100, Default, Step = 1, Suffix = "",
		Flag, Tooltip, Callback = function(value) end,
	}) -> slider   (:Set, :Get, .Changed)
]]

local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Parent.Core.Util)
local Signal = require(script.Parent.Parent.Core.Signal)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)

return function(container, opts)
	local ctx = container.ctx
	local theme = ctx.Theme
	local min, max = opts.Min or 0, opts.Max or 100
	local step = opts.Step or 1
	local decimals = Util.decimals(step)
	local suffix = opts.Suffix or ""

	local row = container:Row(40)
	local maid = Maid.new():LinkTo(row)

	local label = Util.text({
		Text = opts.Text or "Slider",
		Size = UDim2.new(1, -70, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	theme:Bind(label, { TextColor3 = "TextDim" })

	local valueBox = Util.new("TextBox", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(64, 18),
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		FontFace = Util.Fonts.SemiBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
		Parent = row,
	})
	theme:Bind(valueBox, { TextColor3 = "Text" })

	local track = Util.frame({
		Name = "Track",
		Position = UDim2.fromOffset(0, 27),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundTransparency = 0,
		Parent = row,
	})
	Util.corner(track, UDim.new(1, 0))
	theme:Bind(track, { BackgroundColor3 = "Surface2" })
	local trackStroke = Util.stroke(track, { Transparency = 0.35 })
	theme:Bind(trackStroke, { Color = "Border" })

	local fill = Util.frame({
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 0,
		Parent = track,
	})
	Util.corner(fill, UDim.new(1, 0))
	theme:Bind(fill, { BackgroundColor3 = "Accent" })
	Util.new("UIGradient", {
		Transparency = NumberSequence.new(0.35, 0),
		Parent = fill,
	})

	local knob = Util.frame({
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 0,
		ZIndex = 3,
		Parent = track,
	})
	Util.corner(knob, UDim.new(1, 0))
	local knobScale = Util.new("UIScale", { Scale = 0, Parent = knob })
	local knobStroke = Util.stroke(knob, { Thickness = 2 })
	theme:Bind(knob, { BackgroundColor3 = "Text" })
	theme:Bind(knobStroke, { Color = "Accent" })

	local hit = Util.button({
		Name = "Hit",
		Position = UDim2.fromOffset(-6, 19),
		Size = UDim2.new(1, 12, 0, 20),
		ZIndex = 4,
		Parent = row,
	})

	local slider = { Changed = Signal.new() }
	local value = math.clamp(opts.Default or min, min, max)
	local dragging, hovered = false, false

	local function format(v)
		return string.format("%." .. decimals .. "f", v) .. suffix
	end

	local function render(preset)
		local alpha = max > min and (value - min) / (max - min) or 0
		Motion.tween(fill, preset, { Size = UDim2.fromScale(alpha, 1) })
		Motion.tween(knob, preset, { Position = UDim2.fromScale(alpha, 0.5) })
		if not valueBox:IsFocused() then
			valueBox.Text = format(value)
		end
	end

	local function setKnob(visible)
		Motion.tween(knobScale, "Fast", { Scale = visible and 1 or 0 })
		Motion.tween(label, "Fast", { TextColor3 = visible and theme.Tokens.Text or theme.Tokens.TextDim })
	end

	function slider:Get()
		return value
	end

	function slider:Set(newValue, silent, preset)
		newValue = tonumber(newValue)
		if not newValue then
			render("Fast")
			return
		end
		newValue = math.clamp(Util.round(newValue - min, step) + min, min, max)
		newValue = tonumber(string.format("%." .. decimals .. "f", newValue))
		if newValue == value then
			render(preset or "Fast")
			return
		end
		value = newValue
		render(preset or "Fast")
		if not silent then
			slider.Changed:Fire(value)
			if opts.Callback then
				task.spawn(opts.Callback, value)
			end
			if opts.Flag then
				ctx.State:Notify(opts.Flag, value)
			end
		end
	end

	local function fromPointer(point)
		local position, size = track.AbsolutePosition, track.AbsoluteSize
		local alpha = math.clamp((point.X - position.X) / math.max(size.X, 1), 0, 1)
		slider:Set(min + alpha * (max - min), false, "Micro")
	end

	maid:Give(hit.InputBegan:Connect(function(input)
		if Util.isPress(input) then
			dragging = true
			setKnob(true)
			fromPointer(Util.pointer(input))
		end
	end))
	maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and Util.isMove(input) then
			fromPointer(Util.pointer(input))
		end
	end))
	maid:Give(UserInputService.InputEnded:Connect(function(input)
		if dragging and Util.isPress(input) then
			dragging = false
			if not hovered then
				setKnob(false)
			end
		end
	end))
	maid:Give(hit.MouseEnter:Connect(function()
		hovered = true
		setKnob(true)
	end))
	maid:Give(hit.MouseLeave:Connect(function()
		hovered = false
		if not dragging then
			setKnob(false)
		end
	end))

	maid:Give(valueBox.Focused:Connect(function()
		valueBox.Text = string.format("%." .. decimals .. "f", value)
	end))
	maid:Give(valueBox.FocusLost:Connect(function()
		local typed = string.gsub(valueBox.Text, "[^%d%.%-]", "")
		slider:Set(typed)
		valueBox.Text = format(value)
	end))

	if opts.Flag then
		local handle = {
			Get = function()
				return value
			end,
			Set = function(v)
				slider:Set(v)
			end,
		}
		ctx.State:Register(opts.Flag, handle)
		maid:Give(function()
			ctx.State:Unregister(opts.Flag, handle)
		end)
	end

	if opts.Tooltip then
		ctx.Tooltip:Attach(label, opts.Tooltip)
	end

	render("Instant")
	return slider
end
