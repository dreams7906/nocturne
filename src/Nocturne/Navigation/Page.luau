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
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		CanvasSize = UDim2.new(),
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		Parent = canvas,
	})
	ctx.Theme:Bind(scroller, { ScrollBarImageColor3 = "BorderStrong" })

	local columns = Util.frame({
		Name = "Columns",
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.new(1, -28, 0, 0),
		Parent = scroller,
	})

	local single = opts.Columns == 1
	local function column(name, order)
		local frame = Util.frame({
			Name = name,
			Size = single and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -GAP / 2, 0, 0),
			LayoutOrder = order,
			Position = UDim2.new(single and 0 or (order - 1) * 0.5, order == 2 and GAP / 2 or 0, 0, 0),
			Parent = columns,
		})
		Util.list(frame, { Padding = GAP })
		return frame
	end
	self.Left = column("Left", 1)
	self.Right = single and self.Left or column("Right", 2)
	local function resize()
		local scale = math.max(ctx:GetScale(), 0.01)
		local left = self.Left:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y / scale
		local right = self.Right:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y / scale
		self.Left.Size = UDim2.new(single and 1 or 0.5, single and 0 or -GAP / 2, 0, left)
		if not single then
			self.Right.Size = UDim2.new(0.5, -GAP / 2, 0, right)
		end
		local height = math.max(left, right)
		columns.Size = UDim2.new(1, -28, 0, height)
		scroller.CanvasSize = UDim2.fromOffset(0, height + 26)
	end
	self.Left:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
	if not single then
		self.Right:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	task.defer(resize)

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
