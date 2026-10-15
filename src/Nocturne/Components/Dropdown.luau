--[[
	Dropdown
	Field + floating option list rendered in the overlay layer, so it is
	never clipped by scrolling pages. Opens downward (or upward near the
	bottom of the screen), animates height and fade, highlights the
	selected option with an accent check and closes on outside clicks.

	container:Dropdown({
		Text, Options = {"A", "B"}, Default = "A", Flag, Tooltip,
		Multi = false,            -- true: value is a set { A = true }
		Placeholder = "None",
		Callback = function(option) end,
	}) -> dropdown   (:Set, :Get, :SetOptions, .Changed)
]]

local Util = require(script.Parent.Parent.Core.Util)
local Signal = require(script.Parent.Parent.Core.Signal)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Icons = require(script.Parent.Parent.Icons.Icons)

local OPTION_HEIGHT = 26
local OPTION_GAP = 2
local LIST_PADDING = 4
local MAX_VISIBLE = 7

return function(container, opts)
	local ctx = container.ctx
	local theme = ctx.Theme
	local options = table.clone(opts.Options or {})
	local multi = opts.Multi == true

	local function toSet(input)
		local set = {}
		if type(input) == "table" then
			for key, item in pairs(input) do
				if type(key) == "number" then
					set[item] = true
				elseif item then
					set[key] = true
				end
			end
		elseif input ~= nil then
			set[input] = true
		end
		return set
	end

	local value
	if multi then
		value = toSet(opts.Default)
	else
		value = opts.Default
		if value == nil and not opts.AllowNull then
			value = options[1]
		end
	end

	local function isSelected(option)
		if multi then
			return value[option] == true
		end
		return option == value
	end

	local function display()
		if multi then
			local picked = {}
			for _, option in ipairs(options) do
				if value[option] then
					table.insert(picked, tostring(option))
				end
			end
			return #picked > 0 and table.concat(picked, ", ") or (opts.Placeholder or "None")
		end
		return value ~= nil and tostring(value) or (opts.Placeholder or "Select...")
	end
	local hasLabel = opts.Text ~= nil and opts.Text ~= ""

	local row = container:Row(hasLabel and 50 or 30)
	local maid = Maid.new():LinkTo(row)

	if hasLabel then
		local label = Util.text({
			Text = opts.Text,
			Size = UDim2.new(1, 0, 0, 18),
			Parent = row,
		})
		theme:Bind(label, { TextColor3 = "TextDim" })
		if opts.Tooltip then
			ctx.Tooltip:Attach(label, opts.Tooltip)
		end
	end

	local field = Util.button({
		Name = "Field",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 0,
		Parent = row,
	})
	Util.corner(field, 6)
	local fieldStroke = Util.stroke(field, { Transparency = 0.1 })
	local fieldGloss = Util.gloss(field, 0.08)
	ctx:RegisterGloss(fieldGloss)

	local current = Util.text({
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -34, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = field,
	})
	theme:Bind(current, { TextColor3 = "Text" })

	local chevron = Icons.create("chevron", 14, theme.Tokens.TextMuted, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -9, 0.5, 0),
		Parent = field,
	})

	local dropdown = { Changed = Signal.new() }
	local open = false
	local hovered = false
	local popup -- built lazily on first open
	local optionRows = {}

	local function renderField(instant)
		local t = theme.Tokens
		local preset = instant and "Instant" or "Fast"
		Motion.tween(field, preset, { BackgroundColor3 = (hovered or open) and t.Hover or t.Surface2 })
		Motion.tween(fieldStroke, preset, { Color = open and t.Accent or t.Border, Transparency = open and 0.45 or 0.1 })
		Icons.tween(chevron, preset, open and t.Text or t.TextMuted)
		Motion.tween(chevron, instant and "Instant" or "Normal", { Rotation = open and 180 or 0 })
		current.Text = display()
	end

	local function renderOption(entry, instant)
		local t = theme.Tokens
		local selected = isSelected(entry.option)
		local preset = instant and "Instant" or "Fast"
		Motion.tween(entry.button, preset, {
			BackgroundColor3 = selected and t.AccentSoft or t.Hover,
			BackgroundTransparency = selected and 0 or (entry.hovered and 0 or 1),
		})
		Motion.tween(entry.label, preset, {
			TextColor3 = (selected or entry.hovered) and t.Text or t.TextDim,
		})
		Icons.tween(entry.check, preset, t.Accent, selected and 0 or 1)
	end

	local function listHeight()
		local count = math.min(#options, MAX_VISIBLE)
		return count * OPTION_HEIGHT + math.max(count - 1, 0) * OPTION_GAP + LIST_PADDING * 2
	end

	local function buildOptions()
		for _, entry in ipairs(optionRows) do
			entry.button:Destroy()
		end
		table.clear(optionRows)
		if not popup then
			return
		end
		for index, option in ipairs(options) do
			local button = Util.button({
				Name = "Option",
				Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
				BackgroundTransparency = 1,
				LayoutOrder = index,
				Parent = popup.List,
			})
			Util.corner(button, 5)
			local label = Util.text({
				Text = tostring(option),
				Position = UDim2.fromOffset(9, 0),
				Size = UDim2.new(1, -36, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = button,
			})
			local check = Icons.create("check", 13, theme.Tokens.Accent, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Transparency = 1,
				Parent = button,
			})
			local entry = { option = option, button = button, label = label, check = check, hovered = false }
			button.MouseEnter:Connect(function()
				entry.hovered = true
				renderOption(entry)
			end)
			button.MouseLeave:Connect(function()
				entry.hovered = false
				renderOption(entry)
			end)
			button.Activated:Connect(function()
				if multi then
					local nextValue = table.clone(value)
					nextValue[option] = not nextValue[option] or nil
					dropdown:Set(nextValue)
				else
					dropdown:Set(option)
					ctx.Popups:Close(popup.Handle)
				end
			end)
			table.insert(optionRows, entry)
			renderOption(entry, true)
		end
		popup.List.CanvasSize = UDim2.fromOffset(0, #options * (OPTION_HEIGHT + OPTION_GAP))
	end

	local function buildPopup()
		local surface = Util.surface(ctx, {
			Name = "DropdownPopup",
			Radius = 8,
			Fill = "Elevated",
			FillTransparency = 0,
			ShadowLayers = 4,
			ShadowSpread = 3,
			ShadowTransparency = 0.9,
			ZIndex = 100,
			Parent = ctx.Overlay,
		})
		surface.Holder.Visible = false
		local scale = Util.new("UIScale", { Parent = surface.Holder })

		local list = Util.new("ScrollingFrame", {
			Name = "List",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(),
			ZIndex = 2,
			Parent = surface.Body,
		})
		theme:Bind(list, { ScrollBarImageColor3 = "TextMuted" })
		Util.padding(list, LIST_PADDING)
		Util.list(list, { Padding = OPTION_GAP })

		popup = { Surface = surface, Scale = scale, List = list }
		popup.Handle = {
			Close = function()
				dropdown:Close()
			end,
			Contains = function(point)
				return Util.contains(surface.Holder, point, 2) or Util.contains(field, point, 2)
			end,
		}
		maid:Give(surface.Holder)
		buildOptions()
	end

	function dropdown:Open()
		if open then
			return
		end
		if not popup then
			buildPopup()
		end
		open = true
		ctx.Popups:Open(popup.Handle)
		local scale = ctx:GetScale()
		local holder = popup.Surface.Holder
		local height = listHeight()
		local width = field.AbsoluteSize.X / scale
		local fieldPos = field.AbsolutePosition
		local viewport = ctx.Gui.AbsoluteSize
		local below = fieldPos.Y + field.AbsoluteSize.Y + 4 + height * scale <= viewport.Y - 8

		popup.Scale.Scale = scale
		holder.AnchorPoint = Vector2.new(0, below and 0 or 1)
		holder.Position = UDim2.fromOffset(fieldPos.X, below and (fieldPos.Y + field.AbsoluteSize.Y + 4) or (fieldPos.Y - 4))
		holder.Size = UDim2.fromOffset(width, math.max(height - 14, 0))
		popup.Surface.Body.GroupTransparency = 1
		holder.Visible = true
		Motion.tween(holder, "Normal", { Size = UDim2.fromOffset(width, height) })
		popup.Surface.SetAlpha(0, "Normal")

		for _, entry in ipairs(optionRows) do
			entry.hovered = false
			renderOption(entry, true)
		end
		-- Bring the selected option into view in long lists.
		local index = not multi and table.find(options, value)
		if index then
			local y = (index - 1) * (OPTION_HEIGHT + OPTION_GAP)
			popup.List.CanvasPosition = Vector2.new(0, math.max(0, y - (height / 2 - OPTION_HEIGHT)))
		end
		renderField(false)
	end

	function dropdown:Close()
		if not open then
			return
		end
		open = false
		ctx.Popups:Released(popup.Handle)
		local holder = popup.Surface.Holder
		local width = holder.Size.X.Offset
		Motion.tween(holder, "Fast", { Size = UDim2.fromOffset(width, math.max(listHeight() - 10, 0)) })
		popup.Surface.SetAlpha(1, "Fast")
		task.delay(Motion.info("Fast").Time + 0.02, function()
			if not open then
				holder.Visible = false
			end
		end)
		renderField(false)
	end

	function dropdown:Get()
		if multi then
			return table.clone(value)
		end
		return value
	end

	-- Selected options as an array in list order (multi) or { value }.
	function dropdown:GetSelected()
		local list = {}
		for _, option in ipairs(options) do
			if isSelected(option) then
				table.insert(list, option)
			end
		end
		return list
	end

	function dropdown:Set(option, silent)
		if multi then
			option = toSet(option)
		elseif option == value then
			return
		end
		value = option
		renderField(false)
		for _, entry in ipairs(optionRows) do
			renderOption(entry)
		end
		if not silent then
			local out = dropdown:Get()
			dropdown.Changed:Fire(out)
			if opts.Callback then
				task.spawn(opts.Callback, out)
			end
			if opts.Flag then
				ctx.State:Notify(opts.Flag, out)
			end
		end
	end

	function dropdown:SetOptions(newOptions, keepValue)
		options = table.clone(newOptions)
		if multi then
			for option in pairs(value) do
				if not table.find(options, option) then
					value[option] = nil
				end
			end
		elseif not keepValue or not table.find(options, value) then
			value = if opts.AllowNull then nil else options[1]
		end
		buildOptions()
		renderField(true)
	end

	maid:Give(field.Activated:Connect(function()
		if open then
			ctx.Popups:Close(popup.Handle)
		else
			dropdown:Open()
		end
	end))
	maid:Give(field.MouseEnter:Connect(function()
		hovered = true
		renderField(false)
	end))
	maid:Give(field.MouseLeave:Connect(function()
		hovered = false
		renderField(false)
	end))
	maid:Give(theme.Changed:Connect(function(instant)
		renderField(instant)
		for _, entry in ipairs(optionRows) do
			renderOption(entry, instant)
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
				-- Arrays serialise cleanly to JSON; sets with string keys do too,
				-- but arrays keep the saved file readable.
				return multi and dropdown:GetSelected() or value
			end,
			Set = function(v)
				if multi or table.find(options, v) then
					dropdown:Set(v)
				end
			end,
		}
		ctx.State:Register(opts.Flag, handle)
		maid:Give(function()
			ctx.State:Unregister(opts.Flag, handle)
		end)
	end

	renderField(true)
	return dropdown
end
