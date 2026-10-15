--[[
	Icons
	Line icons drawn with native GUI primitives on an 18x18 grid, so they
	scale crisply, tint with the theme and need no uploaded image assets.

	Shapes
		{"line", x1, y1, x2, y2}           stroked segment with round caps
		{"ring", cx, cy, r}                stroked circle
		{"rect", x, y, w, h, radius}       stroked rounded rectangle
		{"dot", cx, cy, r}                 filled circle
		{"clip", x, y, w, h, {shapes}}     shapes clipped to a box

	Tools/build_assets.py parses the Glyphs table below to export matching
	SVG files into Assets/Icons, so keep one shape per line.
]]

local Motion = require(script.Parent.Parent.Animations.Motion)

local Icons = {}

local GRID = 18

Icons.Glyphs = {
	combat = {
		{"ring", 9, 9, 6},
		{"line", 9, 1.5, 9, 5},
		{"line", 9, 13, 9, 16.5},
		{"line", 1.5, 9, 5, 9},
		{"line", 13, 9, 16.5, 9},
		{"dot", 9, 9, 1.3},
	},
	visuals = {
		{"rect", 1.5, 4.5, 15, 9, 4.5},
		{"ring", 9, 9, 2.6},
	},
	world = {
		{"ring", 9, 9, 7.25},
		{"rect", 6, 1.75, 6, 14.5, 3},
		{"line", 2, 9, 16, 9},
	},
	player = {
		{"ring", 9, 5.75, 3.25},
		{"clip", 0, 11, 18, 7, {
			{"rect", 3.25, 11.25, 11.5, 10, 5},
		}},
	},
	settings = {
		{"line", 2, 5.5, 16, 5.5},
		{"line", 2, 12.5, 16, 12.5},
		{"dot", 6, 5.5, 2.2},
		{"dot", 12, 12.5, 2.2},
	},
	configs = {
		{"rect", 3.5, 1.75, 11, 14.5, 2.5},
		{"line", 6.5, 6, 11.5, 6},
		{"line", 6.5, 9, 11.5, 9},
		{"line", 6.5, 12, 9.5, 12},
	},
	utilities = {
		{"rect", 2, 2, 6, 6, 1.8},
		{"rect", 10, 2, 6, 6, 1.8},
		{"rect", 2, 10, 6, 6, 1.8},
		{"ring", 13, 13, 3},
	},
	misc = {
		{"rect", 1.75, 1.75, 14.5, 14.5, 4},
		{"dot", 5.75, 9, 1.25},
		{"dot", 9, 9, 1.25},
		{"dot", 12.25, 9, 1.25},
	},
	chevron = {
		{"line", 5, 7, 9, 11},
		{"line", 9, 11, 13, 7},
	},
	check = {
		{"line", 4, 9.5, 7.5, 13},
		{"line", 7.5, 13, 14, 5.5},
	},
	close = {
		{"line", 5, 5, 13, 13},
		{"line", 13, 5, 5, 13},
	},
	minimize = {
		{"line", 4.5, 9, 13.5, 9},
	},
	maximize = {
		{"rect", 4.5, 4.5, 9, 9, 2},
	},
	search = {
		{"ring", 8, 8, 5},
		{"line", 11.75, 11.75, 15.5, 15.5},
	},
	keyboard = {
		{"rect", 1.5, 4.5, 15, 9, 2.5},
		{"dot", 5, 8, 0.8},
		{"dot", 7.7, 8, 0.8},
		{"dot", 10.3, 8, 0.8},
		{"dot", 13, 8, 0.8},
		{"line", 6, 11, 12, 11},
	},
	save = {
		{"line", 9, 2.5, 9, 11},
		{"line", 5.5, 7.5, 9, 11},
		{"line", 9, 11, 12.5, 7.5},
		{"line", 3, 15.5, 15, 15.5},
	},
	load = {
		{"line", 9, 11, 9, 2.5},
		{"line", 5.5, 6, 9, 2.5},
		{"line", 9, 2.5, 12.5, 6},
		{"line", 3, 15.5, 15, 15.5},
	},
	trash = {
		{"line", 3, 4.75, 15, 4.75},
		{"line", 7.25, 2.25, 10.75, 2.25},
		{"rect", 4.75, 4.75, 8.5, 11.5, 2},
	},
	pencil = {
		{"line", 3, 15, 4, 11.5},
		{"line", 4, 11.5, 12, 3.5},
		{"line", 12, 3.5, 14.5, 6},
		{"line", 14.5, 6, 6.5, 14},
		{"line", 6.5, 14, 3, 15},
		{"line", 10.25, 5.25, 12.75, 7.75},
	},
	plus = {
		{"line", 9, 3.5, 9, 14.5},
		{"line", 3.5, 9, 14.5, 9},
	},
	copy = {
		{"rect", 6, 6, 10, 10, 2},
		{"clip", 0, 0, 6, 18, {
			{"rect", 2, 2, 10, 10, 2},
		}},
		{"clip", 0, 0, 18, 6, {
			{"rect", 2, 2, 10, 10, 2},
		}},
	},
	bell = {
		{"clip", 0, 0, 18, 12.75, {
			{"rect", 4.25, 2.25, 9.5, 14, 4.75},
		}},
		{"line", 2.75, 12.75, 15.25, 12.75},
		{"line", 7.5, 15.5, 10.5, 15.5},
	},
	info = {
		{"ring", 9, 9, 7.25},
		{"line", 9, 8.25, 9, 12.5},
		{"dot", 9, 5.6, 1},
	},
	warning = {
		{"ring", 9, 9, 7.25},
		{"line", 9, 5, 9, 9.75},
		{"dot", 9, 12.6, 1},
	},
	success = {
		{"ring", 9, 9, 7.25},
		{"line", 5.75, 9.25, 8, 11.5},
		{"line", 8, 11.5, 12.5, 6.75},
	},
	palette = {
		{"ring", 9, 9, 7.25},
		{"dot", 6, 7, 1.2},
		{"dot", 9.5, 5.25, 1.2},
		{"dot", 12.5, 8, 1.2},
	},
	sparkle = {
		{"line", 9, 2, 9, 16},
		{"line", 2, 9, 16, 9},
		{"line", 5, 5, 13, 13},
		{"line", 13, 5, 5, 13},
	},
}

local function addLine(parent, a, b, unit, thickness, z)
	local delta = b - a
	local length = delta.Magnitude * unit
	local center = (a + b) / 2 * unit
	local frame = Instance.new("Frame")
	frame.Name = "Line"
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromOffset(center.X, center.Y)
	frame.Size = UDim2.fromOffset(length + thickness, thickness)
	frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	frame.ZIndex = z
	frame:SetAttribute("IconFill", true)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	frame.Parent = parent
end

local function addRound(parent, x, y, w, h, radius, unit, thickness, filled, z)
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.ZIndex = z
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius * unit)
	corner.Parent = frame
	if filled then
		frame.Name = "Dot"
		frame.Position = UDim2.fromOffset(x * unit, y * unit)
		frame.Size = UDim2.fromOffset(w * unit, h * unit)
		frame:SetAttribute("IconFill", true)
	else
		-- UIStroke grows outward, so shrink by half the stroke to keep the
		-- visual stroke centred on the path like an SVG stroke.
		local half = thickness / 2
		frame.Name = "Outline"
		frame.BackgroundTransparency = 1
		frame.Position = UDim2.fromOffset(x * unit + half, y * unit + half)
		frame.Size = UDim2.fromOffset(w * unit - thickness, h * unit - thickness)
		corner.CornerRadius = UDim.new(0, math.max(radius * unit - half, 0))
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = thickness
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = frame
	end
	frame.Parent = parent
end

local function draw(parent, shapes, unit, thickness, z)
	for _, shape in ipairs(shapes) do
		local kind = shape[1]
		if kind == "line" then
			addLine(parent, Vector2.new(shape[2], shape[3]), Vector2.new(shape[4], shape[5]), unit, thickness, z)
		elseif kind == "ring" then
			local r = shape[4]
			addRound(parent, shape[2] - r, shape[3] - r, r * 2, r * 2, r, unit, thickness, false, z)
		elseif kind == "dot" then
			local r = shape[4]
			addRound(parent, shape[2] - r, shape[3] - r, r * 2, r * 2, r, unit, thickness, true, z)
		elseif kind == "rect" then
			addRound(parent, shape[2], shape[3], shape[4], shape[5], shape[6] or 0, unit, thickness, false, z)
		elseif kind == "clip" then
			local clip = Instance.new("Frame")
			clip.Name = "Clip"
			clip.BackgroundTransparency = 1
			clip.ClipsDescendants = true
			clip.Position = UDim2.fromOffset(shape[2] * unit, shape[3] * unit)
			clip.Size = UDim2.fromOffset(shape[4] * unit, shape[5] * unit)
			clip.ZIndex = z
			clip.Parent = parent
			local inner = Instance.new("Frame")
			inner.BackgroundTransparency = 1
			inner.Position = UDim2.fromOffset(-shape[2] * unit, -shape[3] * unit)
			inner.Size = UDim2.fromOffset(GRID * unit, GRID * unit)
			inner.ZIndex = z
			inner.Parent = clip
			draw(inner, shape[6], unit, thickness, z)
		end
	end
end

--[[
	Icons.create(name, size, color, props?) -> Frame
	props.Thickness overrides the stroke weight (defaults to 1.5 at 18px).
]]
function Icons.create(name, size, color, props)
	props = props or {}
	size = size or 18
	local shapes = Icons.Glyphs[name] or Icons.Glyphs.misc
	local unit = size / GRID
	local thickness = props.Thickness or math.max(1, 1.5 * unit)
	local z = props.ZIndex or 1

	local icon = Instance.new("Frame")
	icon.Name = "Icon_" .. name
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Size = UDim2.fromOffset(size, size)
	icon.AnchorPoint = props.AnchorPoint or Vector2.zero
	icon.Position = props.Position or UDim2.new()
	icon.ZIndex = z
	draw(icon, shapes, unit, thickness, z)
	Icons.tint(icon, color or Color3.new(1, 1, 1), props.Transparency or 0)
	if props.Parent then
		icon.Parent = props.Parent
	end
	return icon
end

local function each(icon, fn)
	for _, child in ipairs(icon:GetDescendants()) do
		if child:IsA("UIStroke") then
			fn(child, "Color", "Transparency")
		elseif child:IsA("Frame") and child:GetAttribute("IconFill") then
			fn(child, "BackgroundColor3", "BackgroundTransparency")
		end
	end
end

function Icons.tint(icon, color, transparency)
	each(icon, function(part, colorKey, alphaKey)
		part[colorKey] = color
		if transparency then
			part[alphaKey] = transparency
		end
	end)
end

function Icons.tween(icon, preset, color, transparency)
	each(icon, function(part, colorKey, alphaKey)
		local goal = { [colorKey] = color }
		if transparency then
			goal[alphaKey] = transparency
		end
		Motion.tween(part, preset, goal)
	end)
end

return Icons
