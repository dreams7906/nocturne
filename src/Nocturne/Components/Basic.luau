--[[
	Basic
	Small presentational pieces: labels, paragraphs, key/value info rows,
	dividers and the "?" help icon used for tooltips.
]]

local Util = require(script.Parent.Parent.Core.Util)
local Motion = require(script.Parent.Parent.Animations.Motion)

local Basic = {}

function Basic.HelpIcon(ctx, parent, text)
	local icon = Util.text({
		Name = "Help",
		Text = "?",
		Size = UDim2.fromOffset(16, 16),
		TextSize = 10,
		FontFace = Util.Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 0,
		ZIndex = 6,
		Parent = parent,
	})
	Util.corner(icon, UDim.new(1, 0))
	local stroke = Util.stroke(icon, { Transparency = 0.3 })
	ctx.Theme:Bind(icon, { BackgroundColor3 = "Surface2", TextColor3 = "TextMuted" })
	ctx.Theme:Bind(stroke, { Color = "Border" })
	icon.MouseEnter:Connect(function()
		Motion.tween(icon, "Fast", { TextColor3 = ctx.Theme.Tokens.Text, BackgroundColor3 = ctx.Theme.Tokens.Hover })
	end)
	icon.MouseLeave:Connect(function()
		Motion.tween(icon, "Fast", { TextColor3 = ctx.Theme.Tokens.TextMuted, BackgroundColor3 = ctx.Theme.Tokens.Surface2 })
	end)
	ctx.Tooltip:Attach(icon, text)
	return icon
end

-- Wrapping text line. Style = "Dim" | "Muted" | "Text"
function Basic.Label(container, text, style)
	local ctx = container.ctx
	local row = container:Row(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	local label = Util.text({
		Text = text or "",
		TextWrapped = true,
		RichText = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 18),
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.15,
		Parent = row,
	})
	ctx.Theme:Bind(label, { TextColor3 = style == "Text" and "Text" or (style == "Muted" and "TextMuted" or "TextDim") })
	Util.padding(row, 3, 0)
	return {
		Instance = label,
		Set = function(_, value)
			label.Text = value
		end,
	}
end

function Basic.Paragraph(container, title, text)
	local ctx = container.ctx
	local row = container:Row(0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	Util.padding(row, 4, 0, 6, 0)
	Util.list(row, { Padding = 3 })
	local heading = Util.text({
		Text = title or "",
		FontFace = Util.Fonts.SemiBold,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 1,
		Parent = row,
	})
	local body = Util.text({
		Text = text or "",
		TextWrapped = true,
		RichText = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 14),
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.15,
		LayoutOrder = 2,
		Parent = row,
	})
	ctx.Theme:Bind(heading, { TextColor3 = "Text" })
	ctx.Theme:Bind(body, { TextColor3 = "TextDim" })
	return {
		Set = function(_, newTitle, newText)
			heading.Text = newTitle or heading.Text
			body.Text = newText or body.Text
		end,
	}
end

-- "Key ............ Value" row, like a properties sheet.
function Basic.Info(container, opts)
	local ctx = container.ctx
	local row = container:Row(24)
	local key = Util.text({
		Text = opts.Text or "",
		Size = UDim2.new(0.5, 0, 1, 0),
		Parent = row,
	})
	local value = Util.text({
		Text = tostring(opts.Value or ""),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.5, 0, 1, 0),
		FontFace = Util.Fonts.SemiBold,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	ctx.Theme:Bind(key, { TextColor3 = "TextMuted" })
	ctx.Theme:Bind(value, { TextColor3 = opts.Accent and "Accent" or "Text" })
	return {
		Set = function(_, newValue)
			value.Text = tostring(newValue)
		end,
	}
end

function Basic.Divider(container, text)
	local ctx = container.ctx
	local row = container:Row(text and 22 or 11)
	local line = Util.frame({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.2,
		Parent = row,
	})
	ctx.Theme:Bind(line, { BackgroundColor3 = "Border" })
	if text then
		local label = Util.text({
			Text = string.upper(text),
			TextSize = 10,
			FontFace = Util.Fonts.Bold,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			Parent = row,
		})
		ctx.Theme:Bind(label, { TextColor3 = "TextMuted" })
		local function fit()
			local width = label.AbsoluteSize.X / math.max(ctx:GetScale(), 0.01) + 8
			line.Position = UDim2.new(0, width, 0.5, 0)
			line.Size = UDim2.new(1, -width, 0, 1)
		end
		label:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		task.defer(fit)
	end
	return row
end

return Basic
