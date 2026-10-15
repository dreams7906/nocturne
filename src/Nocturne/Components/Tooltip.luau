--[[
	Tooltip
	One shared tooltip in the overlay layer. Elements opt in with
	Tooltip:Attach(guiObject, text). It appears after a short hover delay,
	is placed beside the element and clamped to the screen.
]]

local Util = require(script.Parent.Parent.Core.Util)
local Motion = require(script.Parent.Parent.Animations.Motion)

local Tooltip = {}
Tooltip.__index = Tooltip

local DELAY = 0.35
local MAX_WIDTH = 220

function Tooltip.new(ctx)
	local self = setmetatable({ ctx = ctx, _token = 0, Enabled = true }, Tooltip)

	local frame = Util.frame({
		Name = "Tooltip",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 200,
		Parent = ctx.Overlay,
	})
	Util.corner(frame, 6)
	Util.padding(frame, 6, 9)
	local stroke = Util.stroke(frame, { Transparency = 1 })
	local label = Util.text({
		AutomaticSize = Enum.AutomaticSize.XY,
		TextSize = 11,
		TextWrapped = true,
		TextTransparency = 1,
		ZIndex = 201,
		Parent = frame,
	})
	Util.new("UISizeConstraint", { MaxSize = Vector2.new(MAX_WIDTH, math.huge), Parent = label })
	self._scale = Util.new("UIScale", { Parent = frame })

	ctx.Theme:Bind(frame, { BackgroundColor3 = "Elevated" })
	ctx.Theme:Bind(stroke, { Color = "BorderStrong" })
	ctx.Theme:Bind(label, { TextColor3 = "TextDim" })

	self.Frame, self.Label, self.Stroke = frame, label, stroke
	return self
end

function Tooltip:Show(target, text)
	if not self.Enabled then
		return
	end
	self._token += 1
	local token = self._token
	task.delay(DELAY, function()
		if token ~= self._token or not target.Parent or not target.Visible then
			return
		end
		local frame = self.Frame
		self._scale.Scale = self.ctx:GetScale()
		self.Label.Text = text
		frame.Visible = true

		-- Measure after layout, then place to the right of the target,
		-- falling back below / left when the screen edge is near.
		task.defer(function()
			if token ~= self._token then
				return
			end
			local viewport = self.ctx.Gui.AbsoluteSize
			local size = frame.AbsoluteSize
			local position = target.AbsolutePosition - self.ctx.Overlay.AbsolutePosition
			local targetSize = target.AbsoluteSize
			local x = position.X + targetSize.X + 8
			local y = position.Y + targetSize.Y / 2 - size.Y / 2
			if x + size.X > viewport.X - 8 then
				x = position.X + targetSize.X - size.X
				y = position.Y + targetSize.Y + 6
			end
			x = math.clamp(x, 8, math.max(8, viewport.X - size.X - 8))
			y = math.clamp(y, 8, math.max(8, viewport.Y - size.Y - 8))
			frame.Position = UDim2.fromOffset(x, y + 3)
			Motion.tween(frame, "Fast", { Position = UDim2.fromOffset(x, y), BackgroundTransparency = 0.02 })
			Motion.tween(self.Label, "Fast", { TextTransparency = 0 })
			Motion.tween(self.Stroke, "Fast", { Transparency = 0.2 })
		end)
	end)
end

function Tooltip:Hide()
	self._token += 1
	local token = self._token
	Motion.tween(self.Frame, "Fast", { BackgroundTransparency = 1 })
	Motion.tween(self.Stroke, "Fast", { Transparency = 1 })
	Motion.tween(self.Label, "Fast", { TextTransparency = 1 }, function()
		if token == self._token then
			self.Frame.Visible = false
		end
	end)
end

function Tooltip:Attach(target, text)
	local enter = target.MouseEnter:Connect(function()
		self:Show(target, text)
	end)
	local leave = target.MouseLeave:Connect(function()
		self:Hide()
	end)
	target.Destroying:Once(function()
		enter:Disconnect()
		leave:Disconnect()
	end)
end

return Tooltip
