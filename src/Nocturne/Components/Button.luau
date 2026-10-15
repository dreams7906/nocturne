--[[
	Button
	Slightly glossy button with hover brightening and a subtle press scale.

	container:Button({ Text, Icon, Style = "Default" | "Primary" | "Danger", Tooltip, Callback })
	container:Buttons({ {Text, ...}, {Text, ...} })  -- equal-width row
]]

local Util = require(script.Parent.Parent.Core.Util)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)

local Button = {}

local STYLES = {
	Default = { fill = "Surface2", hover = "Hover", text = "Text", stroke = "Border" },
	Primary = { fill = "Accent", hover = "Accent", text = "AccentText", stroke = "Accent" },
	Danger = { fill = "Surface2", hover = "Hover", text = "Danger", stroke = "Border" },
}

function Button.create(ctx, parent, opts)
	local theme = ctx.Theme
	local style = STYLES[opts.Style or "Default"] or STYLES.Default

	local root = Util.button({
		Name = opts.Text or "Button",
		Size = opts.Size or UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 0,
		LayoutOrder = opts.LayoutOrder or 0,
		Parent = parent,
	})
	Util.corner(root, 6)
	local stroke = Util.stroke(root, { Transparency = 0.05 })
	ctx:RegisterGloss(Util.gloss(root, 0.14))
	local sheen = Util.sheen(root, 6, 0.9)
	ctx:RegisterGloss(sheen)
	local scale = Util.new("UIScale", { Parent = root })

	local content = Util.frame({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = root,
	})
	Util.list(content, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 6,
	})
	local icon
	if opts.Icon then
		icon = Icons.create(opts.Icon, 14, theme:Get(style.text), { Parent = content })
		icon.LayoutOrder = 1
	end
	local label = Util.text({
		Text = opts.Text or "Button",
		FontFace = Util.Fonts.SemiBold,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		LayoutOrder = 2,
		Parent = content,
	})

	local maid = Maid.new():LinkTo(root)
	local hovered, pressed = false, false
	local button = { Root = root, Label = label }

	local function render(instant)
		local t = theme.Tokens
		local preset = instant and "Instant" or "Fast"
		local fill = t[hovered and style.hover or style.fill]
		if hovered and opts.Style == "Primary" then
			fill = fill:Lerp(Color3.new(1, 1, 1), 0.12)
		end
		Motion.tween(root, preset, { BackgroundColor3 = fill })
		Motion.tween(stroke, preset, {
			Color = hovered and opts.Style ~= "Primary" and t.BorderStrong or t[style.stroke],
		})
		Motion.tween(label, preset, { TextColor3 = t[style.text] })
		if icon then
			Icons.tween(icon, preset, t[style.text])
		end
	end

	function button:SetText(text)
		label.Text = text
	end

	maid:Give(root.MouseEnter:Connect(function()
		hovered = true
		render(false)
	end))
	maid:Give(root.MouseLeave:Connect(function()
		hovered = false
		pressed = false
		Motion.tween(scale, "Fast", { Scale = 1 })
		render(false)
	end))
	maid:Give(root.MouseButton1Down:Connect(function()
		pressed = true
		Motion.tween(scale, "Micro", { Scale = 0.97 })
	end))
	maid:Give(root.MouseButton1Up:Connect(function()
		if pressed then
			pressed = false
			Motion.tween(scale, "Normal", { Scale = 1 })
		end
	end))
	maid:Give(root.Activated:Connect(function()
		if opts.Callback then
			task.spawn(opts.Callback)
		end
	end))
	maid:Give(theme.Changed:Connect(function(instant)
		render(instant)
	end))
	if opts.Tooltip then
		ctx.Tooltip:Attach(root, opts.Tooltip)
	end

	render(true)
	return button
end

function Button.Single(container, opts)
	local row = container:Row(28)
	return Button.create(container.ctx, row, opts)
end

function Button.Row(container, list)
	local row = container:Row(28)
	Util.list(row, { FillDirection = Enum.FillDirection.Horizontal, Padding = 8 })
	local count = #list
	local buttons = {}
	for index, opts in ipairs(list) do
		local copy = table.clone(opts)
		copy.Size = UDim2.new(1 / count, -8 * (count - 1) / count, 1, 0)
		copy.LayoutOrder = index
		table.insert(buttons, Button.create(container.ctx, row, copy))
	end
	return buttons
end

return Button
