--[[
	Section
	Rounded panel inside a page column. Optional header tabs switch between
	several control groups inside the same panel.

	page:Section({ Title = "Movement", Side = "Left" | "Right" })        -> container
	page:Section({ Tabs = { "General", "Advanced" }, Side = "Right" })   -> container (first tab)
		section:Tab("Advanced") -> container
]]

local Util = require(script.Parent.Parent.Core.Util)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Container = require(script.Parent.Container)

local Section = {}

function Section.new(ctx, parent, opts, order)
	local theme = ctx.Theme
	local frame = Util.frame({
		Name = "Section_" .. (opts.Title or (opts.Tabs and opts.Tabs[1]) or "Untitled"),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		LayoutOrder = order,
		Parent = parent,
	})
	Util.corner(frame, 10)
	Util.glassStroke(ctx, frame, "BorderStrong", 0.56)
	theme:Bind(frame, { BackgroundColor3 = "Surface", BackgroundTransparency = function(t) return 0.08 + t.Transparency * 0.5 end })
	ctx:RegisterGloss(Util.gloss(frame, 0.12))
	Util.list(frame, {})
	if opts.Title and opts.Tabs then
		local titleRow = Util.frame({ Name = "Title", Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 0, Parent = frame })
		local title = Util.text({
			Text = opts.Title, FontFace = Util.Fonts.Bold, TextSize = 12,
			Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 1, -4), Parent = titleRow,
		})
		theme:Bind(title, { TextColor3 = "Text" })
	end

	local header = Util.new("ScrollingFrame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = frame,
	})
	Util.padding(header, 0, 12)
	Util.list(header, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 5,
	})

	local divider = Util.frame({
		Name = "Divider",
		Size = UDim2.new(1, -24, 0, 1),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 0.35,
		LayoutOrder = 2,
		Parent = frame,
	})
	theme:Bind(divider, { BackgroundColor3 = "Border" })
	-- UIListLayout ignores Position, so centre the divider with a wrapper.
	local dividerRow = Util.frame({ Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 2, Parent = frame })
	divider.Parent = dividerRow

	local tabNames = opts.Tabs or { opts.Title or "Section" }
	local bodies, containers, buttons = {}, {}, {}
	local active
	local count = 0

	local function renderTabs(instant)
		local t = theme.Tokens
		for name, button in pairs(buttons) do
			local isActive = name == active
			Motion.tween(button, instant and "Instant" or "Fast", {
				TextColor3 = isActive and t.Text or (button:GetAttribute("Hovered") and t.TextDim or t.TextMuted),
				BackgroundColor3 = t.Text,
				BackgroundTransparency = count > 1 and (isActive and 0.89 or (button:GetAttribute("Hovered") and 0.96 or 1)) or 1,
			})
			button.FontFace = isActive and Util.Fonts.Bold or Util.Fonts.SemiBold
		end
	end

	local function select(name)
		if not bodies[name] then return end
		if active == name then
			return
		end
		active = name
		for tabName, body in pairs(bodies) do
			body.Visible = tabName == name
		end
		renderTabs(false)
	end

	local addTab
	addTab = function(name)
		if containers[name] then return containers[name] end
		count += 1
		local index = count
		local button = Util.button({
			Name = name,
			Text = name,
			BackgroundTransparency = 1,
			FontFace = Util.Fonts.Bold,
			TextSize = 12,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 24),
			LayoutOrder = index,
			Parent = header,
		})
		Util.corner(button, 6)
		Util.padding(button, 0, 8)
		do
			button.AutoButtonColor = false
			button.Activated:Connect(function()
				select(name)
			end)
			button.MouseEnter:Connect(function()
				button:SetAttribute("Hovered", true)
				renderTabs(false)
			end)
			button.MouseLeave:Connect(function()
				button:SetAttribute("Hovered", false)
				renderTabs(false)
			end)
		end
		buttons[name] = button

		local body = Util.frame({
			Name = "Body_" .. name,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			Visible = index == 1,
			Parent = frame,
		})
		Util.padding(body, 6, 12, 10, 12)
		Util.list(body, { Padding = 2 })
		bodies[name] = body
		containers[name] = Container.new(ctx, body)
		local container = containers[name]
		container.Section = frame
		function container:Tab(tabName) return containers[tabName] end
		function container:AddTab(tabName) return addTab(tabName) end
		function container:SelectTab(tabName) select(tabName) end
		if not active then active = name end
		renderTabs(true)
		return container
	end
	for _, name in ipairs(tabNames) do
		addTab(name)
	end
	active = tabNames[1]
	theme.Changed:Connect(renderTabs)
	renderTabs(true)

	return containers[tabNames[1]]
end

return Section
