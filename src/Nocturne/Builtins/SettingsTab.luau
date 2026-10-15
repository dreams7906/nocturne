--[[
	Built-in Settings tab
	Themes, accent colour, transparency, gloss, UI scale, motion, menu key,
	notifications and overlays, all applied live through the app API.
	Disable with CreateWindow({ SettingsTab = false }).
]]

local Presets = require(script.Parent.Parent.Themes.Presets)

return function(app)
	local page = app:Page({ Name = "Settings", Icon = "settings" })

	local theme = page:Section({ Title = "Theme" })
	local accent
	theme:Dropdown({
		Text = "Preset",
		Options = Presets.Order,
		Default = app.Theme.Name,
		Flag = "UI.Theme",
		Callback = function(name)
			app:SetTheme(name)
			-- Without a custom accent, the swatch follows the preset's accent.
			if not app.Theme.Values.Accent then
				accent:Set(app.Theme.Tokens.Accent, true)
			end
		end,
	})
	accent = theme:ColorPicker({
		Text = "Accent color",
		Default = app.Theme.Tokens.Accent,
		Flag = "UI.Accent",
		Presets = Presets.Accents,
		Callback = function(color)
			app:SetAccent(color)
		end,
	})
	theme:Slider({
		Text = "Window transparency",
		Min = 0,
		Max = 40,
		Default = 4,
		Suffix = "%",
		Flag = "UI.Transparency",
		Callback = function(v)
			app:SetTransparency(v / 100)
		end,
	})
	theme:Switch({
		Text = "Glossy effects",
		Default = true,
		Flag = "UI.Gloss",
		Callback = function(v)
			app:SetGloss(v)
		end,
	})
	theme:Switch({
		Text = "Blur world behind window",
		Flag = "UI.Blur",
		Callback = function(v)
			app:SetBlur(v)
		end,
	})
	theme:Button({
		Text = "Use theme accent",
		Callback = function()
			app:SetAccent(nil)
			accent:Set(app.Theme.Tokens.Accent, true)
		end,
	})

	local interface = page:Section({ Title = "Interface" })
	interface:Slider({
		Text = "UI scale",
		Min = 70,
		Max = 130,
		Step = 5,
		Default = 100,
		Suffix = "%",
		Flag = "UI.Scale",
		Callback = function(v)
			app:SetScale(v / 100)
		end,
	})
	interface:Keybind({
		Text = "Menu key",
		Bind = app:GetMenuBind(),
		Flag = "UI.MenuKey",
		Tooltip = "Toggles the window. Backspace can't clear this one.",
	})
	interface:Switch({
		Text = "Tooltips",
		Default = true,
		Flag = "UI.Tooltips",
		Callback = function(v)
			app:SetTooltips(v)
		end,
	})
	interface:Switch({
		Text = "Collapse on reselect",
		Default = true,
		Flag = "UI.CollapseOnReselect",
		Tooltip = "Clicking the active dock icon again closes the window.",
		Callback = function(v)
			app.CollapseOnReselect = v
		end,
	})
	interface:Button({
		Text = "Re-centre window",
		Callback = function()
			app:ResetPosition()
		end,
	})

	local motion = page:Section({ Title = "Animations", Side = "Right" })
	motion:Switch({
		Text = "Reduced motion",
		Flag = "UI.ReducedMotion",
		Tooltip = "Applies every change instantly, without transitions.",
		Callback = function(v)
			app:SetReducedMotion(v)
		end,
	})
	motion:Slider({
		Text = "Animation speed",
		Min = 50,
		Max = 200,
		Step = 10,
		Default = 100,
		Suffix = "%",
		Flag = "UI.AnimationSpeed",
		Callback = function(v)
			app:SetAnimationSpeed(v / 100)
		end,
	})
	motion:Label("Transitions use quint easing and stay under 350 ms at 100%.", "Muted")

	local notify = page:Section({ Title = "Notifications", Side = "Right" })
	notify:Switch({
		Text = "Show notifications",
		Default = true,
		Flag = "UI.Notifications",
		Callback = function(v)
			app:SetNotifications({ Enabled = v })
		end,
	})
	notify:Dropdown({
		Text = "Position",
		Options = { "Bottom Right", "Top Right" },
		Default = "Bottom Right",
		Flag = "UI.NotifyPosition",
		Callback = function(v)
			app:SetNotifications({ Position = v })
		end,
	})
	notify:Slider({
		Text = "Duration",
		Min = 2,
		Max = 10,
		Step = 0.5,
		Default = 4,
		Suffix = " s",
		Flag = "UI.NotifyDuration",
		Callback = function(v)
			app:SetNotifications({ Duration = v })
		end,
	})
	notify:Switch({
		Text = "Notification sound",
		Flag = "UI.NotifySound",
		Callback = function(v)
			app:SetNotifications({ Sound = v })
		end,
	})
	notify:Button({
		Text = "Send test notification",
		Icon = "bell",
		Callback = function()
			app:Notify({ Title = "Test notification", Text = "This is how notifications look with your settings." })
		end,
	})

	local overlays = page:Section({ Title = "Overlays", Side = "Right" })
	overlays:Switch({
		Text = "Watermark",
		Flag = "UI.Watermark",
		Callback = function(v)
			app.Watermark:SetEnabled(v)
		end,
	})
	overlays:Dropdown({
		Text = "Watermark style",
		Options = { "Single Row", "Two Row" },
		Default = "Single Row",
		Flag = "UI.WatermarkStyle",
		Callback = function(v)
			app.Watermark:SetStyle(v)
		end,
	})
	overlays:Switch({
		Text = "Keybind list",
		Flag = "UI.KeybindList",
		Tooltip = "Shows every bound key and whether its toggle is on.",
		Callback = function(v)
			app.KeybindList:SetEnabled(v)
		end,
	})
end
