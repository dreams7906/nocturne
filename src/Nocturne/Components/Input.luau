--[[
	Input
	Single-line text field with placeholder and an accent focus ring.

	container:Input({
		Text, Placeholder, Default, Flag, Tooltip, MaxLength,
		Live = false,                       -- fire Callback on every change
		Callback = function(text, enterPressed) end,
	}) -> input   (:Set, :Get, .Box)
]]

local Util = require(script.Parent.Parent.Core.Util)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)

return function(container, opts)
	local ctx = container.ctx
	local theme = ctx.Theme
	local hasLabel = opts.Text ~= nil and opts.Text ~= ""
	local row = container:Row(hasLabel and 50 or 30)
	local maid = Maid.new():LinkTo(row)

	if hasLabel then
		local label = Util.text({ Text = opts.Text, Size = UDim2.new(1, 0, 0, 18), Parent = row })
		theme:Bind(label, { TextColor3 = "TextDim" })
		if opts.Tooltip then
			ctx.Tooltip:Attach(label, opts.Tooltip)
		end
	end

	local field = Util.frame({
		Name = "Field",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 0,
		Parent = row,
	})
	Util.corner(field, 6)
	local stroke = Util.stroke(field, { Transparency = 0.1 })

	local offset = 10
	if opts.Icon then
		Icons.create(opts.Icon, 13, theme.Tokens.TextMuted, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 9, 0.5, 0),
			Parent = field,
		})
		offset = 28
	end

	local box = Util.new("TextBox", {
		Position = UDim2.fromOffset(offset, 0),
		Size = UDim2.new(1, -(offset + 10), 1, 0),
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		FontFace = Util.Fonts.Medium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		PlaceholderText = opts.Placeholder or "",
		Text = opts.Default or "",
		Parent = field,
	})
	theme:Bind(box, { TextColor3 = "Text", PlaceholderColor3 = "TextMuted" })

	local focused, hovered = false, false
	local input = { Box = box }

	local function render(instant)
		local t = theme.Tokens
		local preset = instant and "Instant" or "Fast"
		Motion.tween(field, preset, { BackgroundColor3 = (focused or hovered) and t.Hover or t.Surface2 })
		Motion.tween(stroke, preset, {
			Color = focused and t.Accent or t.Border,
			Transparency = focused and 0.4 or 0.1,
		})
	end

	local function fire(enter)
		if opts.Callback then
			task.spawn(opts.Callback, box.Text, enter)
		end
		if opts.Flag then
			ctx.State:Notify(opts.Flag, box.Text)
		end
	end

	function input:Get()
		return box.Text
	end

	function input:Set(text, silent)
		box.Text = tostring(text or "")
		if not silent then
			fire(false)
		end
	end

	maid:Give(box.Focused:Connect(function()
		focused = true
		render(false)
	end))
	maid:Give(box.FocusLost:Connect(function(enter)
		focused = false
		render(false)
		if not opts.Live then
			fire(enter)
		end
	end))
	maid:Give(box:GetPropertyChangedSignal("Text"):Connect(function()
		if opts.MaxLength and #box.Text > opts.MaxLength then
			box.Text = string.sub(box.Text, 1, opts.MaxLength)
			return
		end
		if opts.Live then
			fire(false)
		end
	end))
	maid:Give(field.MouseEnter:Connect(function()
		hovered = true
		render(false)
	end))
	maid:Give(field.MouseLeave:Connect(function()
		hovered = false
		render(false)
	end))
	maid:Give(theme.Changed:Connect(render))

	if opts.Flag then
		local handle = {
			Get = function()
				return box.Text
			end,
			Set = function(v)
				input:Set(v)
			end,
			Save = opts.Save,
		}
		ctx.State:Register(opts.Flag, handle)
		maid:Give(function()
			ctx.State:Unregister(opts.Flag, handle)
		end)
	end

	render(true)
	return input
end
