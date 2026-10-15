--[[
	Keybind
	Small rounded pill showing the assigned key. Click to listen for a new
	key: Escape cancels, Backspace clears, and keys already used elsewhere
	are refused with a notification instead of silently stealing them.

	Keybind.Pill(ctx, parent, { Name, Default, Flag, OnPress, OnRelease, Locked, Changed })
	container:Keybind({ Text, Default = "Q", Flag, Callback, Tooltip })
]]

local Util = require(script.Parent.Parent.Core.Util)
local Maid = require(script.Parent.Parent.Core.Maid)
local Motion = require(script.Parent.Parent.Animations.Motion)
local Keybinds = require(script.Parent.Parent.Core.Keybinds)

local TweenService = game:GetService("TweenService")

local Keybind = {}

local function normalise(key)
	if typeof(key) == "EnumItem" then
		return key.Name
	elseif type(key) == "string" and key ~= "" and key ~= "none" then
		return key
	end
	return nil
end

function Keybind.Pill(ctx, parent, opts)
	local theme = ctx.Theme
	local root = Util.button({
		Name = "Keybind",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		BackgroundTransparency = 0,
		ZIndex = 6,
		Parent = parent,
	})
	Util.corner(root, UDim.new(1, 0))
	Util.padding(root, 0, 8)
	Util.new("UISizeConstraint", { MinSize = Vector2.new(30, 18), Parent = root })
	local stroke = Util.stroke(root, { Transparency = 0.1 })
	local label = Util.text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
		Parent = root,
	})
	Util.list(root, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
	local maid = Maid.new():LinkTo(root)

	-- opts.Bind reuses an existing binding (e.g. the app's menu key).
	local bind = opts.Bind
	if not bind then
		bind = ctx.Keybinds:Register({
			Name = opts.Name or "Keybind",
			Key = normalise(opts.Default),
			OnPress = opts.OnPress,
			OnRelease = opts.OnRelease,
			Locked = opts.Locked,
			Toggle = opts.Toggle,
			Mode = opts.Mode,
		})
		maid:Give(function()
			ctx.Keybinds:Unregister(bind)
		end)
	end

	local listening = false
	local hovered = false
	local pulse
	local lastEnded = 0

	local pill = { Root = root, Bind = bind }

	local function render(instant)
		local t = theme.Tokens
		local preset = instant and "Instant" or "Fast"
		label.Text = listening and "..." or Keybinds.display(bind.Key)
		Motion.tween(root, preset, {
			BackgroundColor3 = listening and t.AccentSoft or (hovered and t.Hover or t.Surface2),
		})
		Motion.tween(stroke, preset, { Color = listening and t.Accent or t.BorderStrong })
		Motion.tween(label, preset, {
			TextColor3 = listening and t.Accent or (bind.Key and t.Text or t.TextMuted),
		})
	end

	local function stopPulse()
		if pulse then
			pulse:Cancel()
			pulse = nil
		end
		stroke.Transparency = 0.1
	end

	local function flash(token)
		local t = theme.Tokens
		stroke.Color = t[token]
		label.TextColor3 = t[token]
		task.delay(0.6, function()
			if not listening then
				render(false)
			end
		end)
	end

	function pill:Set(key)
		ctx.Keybinds:Assign(bind, normalise(key))
		render(false)
		if opts.Changed then
			task.spawn(opts.Changed, bind.Key)
		end
	end

	function pill:Get()
		return bind.Key
	end

	maid:Give(root.Activated:Connect(function()
		-- The press that cancelled a capture also releases on this pill;
		-- don't let that same click immediately start a new capture.
		if listening or os.clock() - lastEnded < 0.3 then
			return
		end
		listening = true
		render(false)
		if not Motion.Reduced then
			pulse = TweenService:Create(stroke, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
				Transparency = 0.7,
			})
			pulse:Play()
		end
		ctx.Keybinds:Capture(bind, function(result, detail)
			listening = false
			lastEnded = os.clock()
			stopPulse()
			render(false)
			if result == "conflict" then
				flash("Danger")
				ctx.Notify({
					Title = "Key already in use",
					Text = ("%s is bound to %s. Clear it there first."):format(Keybinds.display(detail.Key), detail.Name),
					Type = "warning",
				})
			elseif result == "reserved" then
				flash("Warning")
				ctx.Notify({
					Title = "Reserved key",
					Text = ("%s is used by Roblox and can't be bound."):format(Keybinds.display(detail)),
					Type = "warning",
				})
			elseif result == "set" or result == "cleared" then
				if opts.Flag then
					ctx.State:Notify(opts.Flag, bind.Key or "")
				end
				if opts.Changed then
					task.spawn(opts.Changed, bind.Key)
				end
			end
		end)
	end))
	maid:Give(root.MouseEnter:Connect(function()
		hovered = true
		render(false)
	end))
	maid:Give(root.MouseLeave:Connect(function()
		hovered = false
		render(false)
	end))
	maid:Give(theme.Changed:Connect(function(instant)
		render(instant)
	end))
	maid:Give(ctx.Keybinds.Changed:Connect(function()
		if not listening then
			label.Text = Keybinds.display(bind.Key)
		end
	end))

	if opts.Flag then
		local handle = {
			Get = function()
				return bind.Key or ""
			end,
			Set = function(v)
				pill:Set(v)
			end,
		}
		ctx.State:Register(opts.Flag, handle)
		maid:Give(function()
			ctx.State:Unregister(opts.Flag, handle)
		end)
	end

	render(true)
	return pill
end

function Keybind.Row(container, opts)
	local ctx = container.ctx
	local row = container:Row(26)
	local label = Util.text({
		Text = opts.Text or "Keybind",
		Size = UDim2.new(1, -80, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	ctx.Theme:Bind(label, { TextColor3 = "TextDim" })

	local strip = Util.frame({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = row,
	})
	Util.list(strip, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = 6,
	})

	local pill = Keybind.Pill(ctx, strip, {
		Name = opts.Text,
		Default = opts.Default,
		Flag = opts.Flag,
		Locked = opts.Locked,
		Bind = opts.Bind,
		OnPress = opts.Callback,
		OnRelease = opts.OnRelease,
		Changed = opts.Changed,
	})
	pill.Root.LayoutOrder = 2
	if opts.Tooltip then
		container.Components.HelpIcon(ctx, strip, opts.Tooltip).LayoutOrder = 1
	end
	return pill
end

return Keybind
