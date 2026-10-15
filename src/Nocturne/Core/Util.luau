--[[
	Util
	Instance construction helpers plus the shared "glass surface" used by the
	toolbar, window, popups and overlays.
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Motion = require(script.Parent.Parent.Animations.Motion)

local Util = {}

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"

Util.Fonts = {
	Regular = Font.new(FAMILY, Enum.FontWeight.Regular),
	Medium = Font.new(FAMILY, Enum.FontWeight.Medium),
	SemiBold = Font.new(FAMILY, Enum.FontWeight.SemiBold),
	Bold = Font.new(FAMILY, Enum.FontWeight.Bold),
}

function Util.new(className, props, children)
	local instance = Instance.new(className)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Util.frame(props, children)
	local defaults = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}
	for key, value in pairs(props or {}) do
		defaults[key] = value
	end
	return Util.new("Frame", defaults, children)
end

function Util.text(props)
	local defaults = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Util.Fonts.Medium,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	}
	for key, value in pairs(props or {}) do
		defaults[key] = value
	end
	return Util.new("TextLabel", defaults)
end

function Util.button(props)
	local defaults = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		Selectable = true,
	}
	for key, value in pairs(props or {}) do
		defaults[key] = value
	end
	return Util.new("TextButton", defaults)
end

function Util.corner(parent, radius)
	return Util.new("UICorner", {
		CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 6),
		Parent = parent,
	})
end

function Util.stroke(parent, props)
	local defaults = {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Parent = parent,
	}
	for key, value in pairs(props or {}) do
		defaults[key] = value
	end
	return Util.new("UIStroke", defaults)
end

-- CSS-style padding: (all) | (vertical, horizontal) | (top, right, bottom, left)
function Util.padding(parent, top, right, bottom, left)
	right = right or top
	bottom = bottom or top
	left = left or right
	return Util.new("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		Parent = parent,
	})
end

function Util.list(parent, props)
	local defaults = {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = parent,
	}
	for key, value in pairs(props or {}) do
		if key == "Padding" and type(value) == "number" then
			value = UDim.new(0, value)
		end
		defaults[key] = value
	end
	return Util.new("UIListLayout", defaults)
end

-- Vertical top-lit gradient that gives fills their soft glossy depth.
function Util.gloss(parent, strength)
	strength = strength or 0.1
	local low = 1 - strength
	return Util.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.55, Color3.new(1 - strength * 0.45, 1 - strength * 0.45, 1 - strength * 0.45)),
			ColorSequenceKeypoint.new(1, Color3.new(low, low, low)),
		}),
		Parent = parent,
	})
end

-- 1px highlight just inside the top edge, faded towards the corners.
function Util.sheen(parent, inset, transparency)
	inset = inset or 8
	local line = Util.frame({
		Name = "Sheen",
		BackgroundTransparency = transparency or 0.9,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromOffset(inset, 1),
		Size = UDim2.new(1, -inset * 2, 0, 1),
		ZIndex = 9,
		Parent = parent,
	})
	Util.new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = line,
	})
	return line
end

-- Stroke that is brighter on the top edge than on the bottom edge.
function Util.glassStroke(ctx, parent, token, transparency)
	local stroke = Util.stroke(parent, { Transparency = transparency or 0 })
	ctx.Theme:Bind(stroke, { Color = token or "BorderStrong" })
	Util.new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.62, 0.62, 0.62)),
		Parent = stroke,
	})
	return stroke
end

-- Converts an InputObject position to ScreenGui space (IgnoreGuiInset = true).
function Util.pointer(input)
	local inset = GuiService:GetGuiInset()
	if input then
		return Vector2.new(input.Position.X, input.Position.Y) + inset
	end
	return UserInputService:GetMouseLocation()
end

function Util.contains(guiObject, point, margin)
	if not guiObject or not guiObject.Parent then
		return false
	end
	margin = margin or 0
	local position = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return point.X >= position.X - margin
		and point.X <= position.X + size.X + margin
		and point.Y >= position.Y - margin
		and point.Y <= position.Y + size.Y + margin
end

function Util.isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Util.isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

function Util.decimals(step)
	local text = string.format("%.6g", step)
	local fraction = string.match(text, "%.(%d+)$")
	return fraction and #fraction or 0
end

function Util.round(value, step)
	if step <= 0 then
		return value
	end
	return math.floor(value / step + 0.5) * step
end

--[[
	Glass surface: a holder Frame containing layered soft shadows and a
	rounded CanvasGroup body. The CanvasGroup clips children to its rounded
	corners and lets the whole surface fade through GroupTransparency.

	Returns { Holder, Body, Fill, Shadows, SetAlpha(alpha, preset) }
]]
function Util.surface(ctx, opts)
	opts = opts or {}
	local radius = opts.Radius or 10
	local layers = opts.ShadowLayers or 5
	local spread = opts.ShadowSpread or 3
	local shadowAlpha = opts.ShadowTransparency or 0.92
	local fillToken = opts.Fill or "Backdrop"

	local holder = Util.frame({
		Name = opts.Name or "Surface",
		Size = opts.Size or UDim2.fromOffset(100, 100),
		Position = opts.Position or UDim2.new(),
		AnchorPoint = opts.AnchorPoint or Vector2.zero,
		ZIndex = opts.ZIndex or 1,
		Parent = opts.Parent,
	})

	local shadows = {}
	for index = layers, 1, -1 do
		local grow = index * spread
		local shadow = Util.frame({
			Name = "Shadow" .. index,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, opts.ShadowOffset or 4),
			Size = UDim2.new(1, grow * 2, 1, grow * 2),
			BackgroundTransparency = shadowAlpha,
			ZIndex = 0,
			Parent = holder,
		})
		Util.corner(shadow, radius + grow)
		ctx.Theme:Bind(shadow, { BackgroundColor3 = "Shadow" })
		table.insert(shadows, shadow)
	end

	local body = Util.new("CanvasGroup", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = holder,
	})
	Util.corner(body, radius)

	local fill = Util.frame({
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		ZIndex = 0,
		Parent = body,
	})
	Util.corner(fill, radius)
	local fillMap = { BackgroundColor3 = fillToken }
	if type(opts.FillTransparency) == "number" then
		fill.BackgroundTransparency = opts.FillTransparency
	else
		fillMap.BackgroundTransparency = opts.FillTransparency or function(tokens)
			return tokens.Transparency
		end
	end
	ctx.Theme:Bind(fill, fillMap)
	local gloss = Util.gloss(fill, opts.GlossStrength or 0.12)
	ctx:RegisterGloss(gloss)

	-- Inner edge: a frame inset by 1px whose outside stroke lands exactly on
	-- the body's outermost pixel, so it survives CanvasGroup clipping.
	local edge = Util.frame({
		Name = "Edge",
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 50,
		Parent = body,
	})
	Util.corner(edge, math.max(radius - 1, 0))
	Util.glassStroke(ctx, edge, opts.EdgeToken or "BorderStrong", opts.EdgeTransparency or 0.15)

	local sheen = Util.sheen(body, radius + 4, 0.88)
	sheen.ZIndex = 51
	ctx:RegisterGloss(sheen)

	local surface = {
		Holder = holder,
		Body = body,
		Fill = fill,
		Edge = edge,
		Shadows = shadows,
	}

	function surface.SetAlpha(alpha, preset)
		Motion.tween(body, preset or "Normal", { GroupTransparency = alpha })
		for _, shadow in ipairs(shadows) do
			local target = 1 - (1 - shadowAlpha) * (1 - alpha)
			Motion.tween(shadow, preset or "Normal", { BackgroundTransparency = target })
		end
	end

	return surface
end

return Util
