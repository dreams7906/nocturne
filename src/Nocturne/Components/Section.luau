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
	Util.corner(frame, 8)
	local stroke = Util.stroke(frame, { Transparency = 0.05 })
	theme:Bind(frame, { BackgroundColor3 = "Surface" })
	theme:Bind(stroke, { Color = "Border" })
	ctx:RegisterGloss(Util.gloss(frame, 0.07))
	ctx:RegisterGloss(Util.sheen(frame, 10, 0.94))
	Util.list(frame, {})

	local header = Util.frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 1,
		Parent = frame,
	})
	Util.padding(header, 0, 12)
	Util.list(header, {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 14,
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

	local function renderTabs(instant)
		local t = theme.Tokens
		for name, button in pairs(buttons) do
			local isActive = name == active
			Motion.tween(button, instant and "Instant" or "Fast", {
				TextColor3 = isActive and t.Text or (button:GetAttribute("Hovered") and t.TextDim or t.TextMuted),
			})
			button.FontFace = isActive and Util.Fonts.Bold or Util.Fonts.SemiBold
		end
	end

	local function select(name)
		if active == name then
			return
		end
		active = name
		for tabName, body in pairs(bodies) do
			body.Visible = tabName == name
		end
		renderTabs(false)
	end

	for index, name in ipairs(tabNames) do
		local isTabbed = opts.Tabs ~= nil
		local button = Util.new(isTabbed and "TextButton" or "TextLabel", {
			Name = name,
			Text = name,
			BackgroundTransparency = 1,
			FontFace = Util.Fonts.Bold,
			TextSize = 12,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			LayoutOrder = index,
			Parent = header,
		})
		if isTabbed then
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
	end
	active = tabNames[1]
	theme.Changed:Connect(renderTabs)
	renderTabs(true)

	local section = containers[tabNames[1]]
	section.Section = frame
	function section:Tab(name)
		return containers[name]
	end
	function section:SelectTab(name)
		select(name)
	end
	return section
end

return Section
