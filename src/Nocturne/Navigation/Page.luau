--[[
	Page
	One main section of the window (Combat, Visuals, ...). A page is a
	CanvasGroup so it can cross-fade, with a scrolling two-column body.

	app:Page({ Name = "Combat", Icon = "combat", Columns = 2 }) -> page
		page:Section({ Title, Side = "Left" | "Right", Tabs })
]]

local Util = require(script.Parent.Parent.Core.Util)
local Section = require(script.Parent.Parent.Components.Section)

local Page = {}
Page.__index = Page

local GAP = 10

function Page.new(ctx, parent, opts)
	local self = setmetatable({
		ctx = ctx,
		Name = opts.Name or "Page",
		Icon = opts.Icon or "misc",
		Description = opts.Description,
		_orders = { Left = 0, Right = 0 },
	}, Page)

	local canvas = Util.new("CanvasGroup", {
		Name = "Page_" .. self.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		Parent = parent,
	})

	local scroller = Util.new("ScrollingFrame", {
		Name = "Scroller",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		Parent = canvas,
	})
	ctx.Theme:Bind(scroller, { ScrollBarImageColor3 = "BorderStrong" })
	Util.padding(scroller, 12, 14, 14, 12)

	local columns = Util.frame({
		Name = "Columns",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = scroller,
	})
	Util.list(columns, { FillDirection = Enum.FillDirection.Horizontal, Padding = GAP })

	local single = opts.Columns == 1
	local function column(name, order)
		local frame = Util.frame({
			Name = name,
			Size = single and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -GAP / 2, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
			Parent = columns,
		})
		Util.list(frame, { Padding = GAP })
		return frame
	end
	self.Left = column("Left", 1)
	self.Right = single and self.Left or column("Right", 2)

	-- Floating popups would drift away from their fields while scrolling.
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		ctx.Popups:CloseAll()
	end)

	self.Canvas = canvas
	self.Scroller = scroller
	return self
end

function Page:Section(opts)
	opts = opts or {}
	local side = opts.Side == "Right" and "Right" or "Left"
	self._orders[side] += 1
	return Section.new(self.ctx, side == "Right" and self.Right or self.Left, opts, self._orders[side])
end

return Page
