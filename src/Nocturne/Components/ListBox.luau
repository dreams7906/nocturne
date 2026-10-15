--[[
	ListBox
	Scrollable, selectable list (used for the config list). Shows a quiet
	empty state when there are no items.

	container:ListBox({ Height = 150, Items = {}, Empty = "Nothing here", Callback = fn(item) })
		-> list  (:SetItems(items, keepSelection), :GetSelected(), :Select(item), .Selected)
]]

local Util = require(script.Parent.Parent.Core.Util)
local Signal = require(script.Parent.Parent.Core.Signal)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)

local ROW = 28

return function(container, opts)
	local ctx = container.ctx
	local theme = ctx.Theme
	local height = opts.Height or 150
	local row = container:Row(height)
	local maid = Maid.new():LinkTo(row)

	local box = Util.frame({
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		Parent = row,
	})
	Util.corner(box, 7)
	local stroke = Util.stroke(box, { Transparency = 0.1 })
	theme:Bind(box, { BackgroundColor3 = "Backdrop" })
	theme:Bind(stroke, { Color = "Border" })

	local scroller = Util.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = box,
	})
	theme:Bind(scroller, { ScrollBarImageColor3 = "TextMuted" })
	Util.padding(scroller, 5)
	Util.list(scroller, { Padding = 2 })

	local empty = Util.text({
		Text = opts.Empty or "Nothing here yet",
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = box,
	})
	theme:Bind(empty, { TextColor3 = "TextMuted" })

	local list = { Selected = Signal.new() }
	local items, entries, selected = {}, {}, nil

	local function renderEntry(entry, instant)
		local t = theme.Tokens
		local isSelected = entry.item == selected
		local preset = instant and "Instant" or "Fast"
		Motion.tween(entry.button, preset, {
			BackgroundColor3 = isSelected and t.AccentSoft or t.Hover,
			BackgroundTransparency = (isSelected or entry.hovered) and 0 or 1,
		})
		Motion.tween(entry.label, preset, { TextColor3 = (isSelected or entry.hovered) and t.Text or t.TextDim })
		Icons.tween(entry.icon, preset, isSelected and t.Accent or t.TextMuted)
	end

	local function rebuild()
		for _, entry in ipairs(entries) do
			entry.button:Destroy()
		end
		table.clear(entries)
		for index, item in ipairs(items) do
			local button = Util.button({
				Size = UDim2.new(1, 0, 0, ROW),
				BackgroundTransparency = 1,
				LayoutOrder = index,
				Parent = scroller,
			})
			Util.corner(button, 5)
			local icon = Icons.create(opts.Icon or "configs", 13, theme.Tokens.TextMuted, {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 9, 0.5, 0),
				Parent = button,
			})
			local label = Util.text({
				Text = tostring(item),
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -38, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = button,
			})
			local entry = { item = item, button = button, label = label, icon = icon, hovered = false }
			button.MouseEnter:Connect(function()
				entry.hovered = true
				renderEntry(entry)
			end)
			button.MouseLeave:Connect(function()
				entry.hovered = false
				renderEntry(entry)
			end)
			button.Activated:Connect(function()
				list:Select(item)
			end)
			table.insert(entries, entry)
			renderEntry(entry, true)
		end
		empty.Visible = #items == 0
	end

	function list:SetItems(newItems, keepSelection)
		items = table.clone(newItems)
		if not keepSelection or not table.find(items, selected) then
			selected = nil
		end
		rebuild()
	end

	function list:Select(item)
		selected = item
		for _, entry in ipairs(entries) do
			renderEntry(entry)
		end
		list.Selected:Fire(item)
		if opts.Callback then
			task.spawn(opts.Callback, item)
		end
	end

	function list:GetSelected()
		return selected
	end

	maid:Give(theme.Changed:Connect(function(instant)
		for _, entry in ipairs(entries) do
			renderEntry(entry, instant)
		end
	end))

	list:SetItems(opts.Items or {})
	return list
end
