--[[
	Drives the UI built by Example.lua: switches every tab, clicks every
	button, drags sliders, types into fields, rebinds keys, round-trips
	configs and cycles every theme. Any Lua error is recorded by the mock.
]]

local Mock, Library = ...
local UIS = Mock.UIS

local function step(label, fn)
	local ok, err = pcall(fn)
	if not ok then
		table.insert(Mock.errors, label .. ": " .. tostring(err))
	end
	Mock.run(0.6)
end

local function fire(inst, event, ...)
	local signal = inst[event]
	if signal then
		signal:Fire(...)
	end
end

local function click(button)
	fire(button, "MouseEnter")
	fire(button, "MouseButton1Down")
	fire(button, "MouseButton1Up")
	fire(button, "Activated")
	fire(button, "MouseLeave")
end

Mock.run(2) -- deferred built-in tabs + window open
local gui = Mock.PlayerGui:FindFirstChild("Nocturne")
assert(gui, "ScreenGui 'Nocturne' was not created")
local app = Library.App
assert(app, "Library.App missing")

print(("tabs: %d (dock items: %d)"):format(#app.Pages, #app.Toolbar.Items))
print("window open after start: " .. tostring(app:IsOpen()))

step("Combat has a Bosses sub-tab without a second dock window", function()
	local combat = Library.Window.Tabs[1]
	local bosses = combat.SubTabs and combat.SubTabs[1]
	assert(bosses and bosses.Title == "Bosses", "Bosses example sub-tab missing")
	local windows, dockItems = #app.Windows, #app.Toolbar.Items
	combat:SelectTab("Bosses")
	assert(app.Window.Current == bosses.Page and bosses.Page.Canvas.Visible, "Bosses did not open inside Combat")
	assert(not combat.Page.Canvas.Visible, "General remained visible beneath Bosses")
	for page, tab in pairs(combat.Page.Window._tabs) do
		assert(not tab.Icon, "inner tab still stores an icon")
		for _, child in ipairs(tab.Button:GetDescendants()) do
			assert(not child:IsA("ImageLabel") and not string.match(child.Name, "^Icon_"), "inner tab contains an icon")
		end
		assert(tab.Label.TextSize == 13, "inner tab label size regressed")
		assert(tab.Label.FontFace[2] == (page == bosses.Page and Enum.FontWeight.Bold or Enum.FontWeight.SemiBold), "inner tab emphasis did not follow selection")
	end
	assert(app.Toolbar.OpenPages[combat.Page] and app.Toolbar.Active == combat.Page, "nested tab lost Combat's dock state")
	assert(#app.Windows == windows and #app.Toolbar.Items == dockItems, "sub-tab created a separate window")
	assert(Library.Options.BossTarget and Library.Options.BossMarker, "Bosses controls missing")
	local bossSection = bosses.Page.Left.Section_Bosses
	click(bossSection.Header.Alerts)
	assert(bossSection.Body_Alerts.Visible and not bossSection.Body_Tracking.Visible, "Bosses section sub-tab did not switch")
	click(bossSection.Header.Tracking)
	click(bosses.Page.Canvas:FindFirstChild("Test boss notification", true))
	combat:SelectTab("General")
	assert(app.Window.Current == combat.Page and not bosses.Page.Canvas.Visible, "General did not restore")
end)

-- Dock: every icon, then the active icon again (collapse), then reopen.
for _, item in ipairs(app.Toolbar.Items) do
	step("dock " .. item.Page.Name, function()
		if item.Page.Window.IsOpen then
			item.Page.Window:Close()
			Mock.run(0.5)
		end
		click(item.Button)
		assert(app.Window.Current == item.Page, "dock did not switch to " .. item.Page.Name)
		assert(app:IsOpen(), "window not open after dock click")
		assert(item.Page.Window.IsOpen, "category window not open")
	end)
end
step("dock reselect collapses", function()
	click(app.Toolbar.Items[#app.Toolbar.Items].Button)
	assert(not app.Pages[#app.Pages].Window.IsOpen, "reselecting should close only that window")
	assert(app.Pages[1].Window.IsOpen, "another category window should remain open")
	assert(app.Toolbar.Active == nil, "dock highlight should clear when closed")
end)
step("menu key hides and restores all windows and dock", function()
	local first = app.Pages[1].Window
	local position = first.Holder.Position
	UIS.InputBegan:Fire(Mock.input("Keyboard", "RightControl"), false)
	assert(not app:IsOpen(), "hiding should update visibility before the exit animation finishes")
	Mock.run(0.4)
	assert(not gui.Enabled, "menu key must hide the entire ScreenGui, including the dock")
	assert(first.IsOpen, "hiding should preserve each window's open state")
	UIS.InputBegan:Fire(Mock.input("Keyboard", "RightControl"), false)
	assert(gui.Enabled and app:IsOpen(), "menu key did not restore the windows")
	assert(first.Holder.Position == position, "hide/show moved the window")
end)

step("empty dock stays empty across menu hide and show", function()
	for _, window in ipairs(app.Windows) do window:Close() end
	Mock.run(0.4)
	app:Toggle()
	Mock.run(0.4)
	app:Toggle()
	Mock.run(0.4)
	assert(gui.Enabled and not app:IsOpen(), "showing an empty dock reopened a category")
	for _, window in ipairs(app.Windows) do assert(not window.IsOpen, "closed category reopened") end
	assert(app.Toolbar.Active == nil and not next(app.Toolbar.OpenPages), "empty dock has a selected category")
	app:Open("Combat")
end)

step("rapid menu toggles cannot finish a stale hide", function()
	local first = app.Pages[1].Window
	local position = first.Holder.Position
	app:Toggle()
	app:Toggle()
	Mock.run(0.5)
	assert(gui.Enabled and app:IsOpen() and first.IsOpen, "stale hide disabled the restored UI")
	assert(first.BodyScale.Scale == 1 and app.Toolbar.BodyScale.Scale == 1, "pop animation did not restore scale")
	assert(app.Toolbar.Holder.Position.Y.Offset == 12, "dock did not return to its top position")
	assert(first.Holder.Position == position, "pop animation moved the saved window position")
	app:Toggle(); app:Toggle(); app:Toggle()
	Mock.run(0.4)
	assert(not gui.Enabled, "rapid toggles did not finish hidden")
	app:Toggle()
end)

step("notification countdown freezes on hover and resumes without restarting", function()
	local toast = Library:Notify({ Title = "Hover test", Content = "Pause here", Duration = 2, Silent = true })
	Mock.Run.Heartbeat:Fire(0.5)
	local remaining, width = toast.Remaining, toast.Bar.Size.X.Scale
	assert(math.abs(remaining - 1.5) < 0.001, "notification countdown did not advance")
	toast.Card.MouseEnter:Fire()
	Mock.Run.Heartbeat:Fire(3)
	assert(not toast.Dismissed and toast.Remaining == remaining and toast.Bar.Size.X.Scale == width, "hover changed the remaining time or progress")
	toast.Card.MouseLeave:Fire()
	Mock.Run.Heartbeat:Fire(0.5)
	assert(math.abs(toast.Remaining - 1) < 0.001, "notification restarted instead of resuming")
	app:Close()
	Mock.Run.Heartbeat:Fire(3)
	assert(toast.Remaining == 1 and not toast.Dismissed, "hidden notification expired")
	app:Toggle()
	Mock.Run.Heartbeat:Fire(1.1)
	assert(toast.Dismissed, "notification did not expire after resumed time elapsed")
	local final = toast.Remaining
	Mock.Run.Heartbeat:Fire(0.5)
	assert(toast.Remaining == final, "dismissed notification retained its heartbeat")
end)

step("notification dismissal works while paused and cleanup stops its clock", function()
	local toast = Library:Notify({ Title = "Dismiss test", Duration = 4, Silent = true })
	toast.Card.MouseEnter:Fire()
	click(toast.Card.Dismiss)
	assert(toast.Dismissed, "hover blocked manual dismissal")
	toast.Dismiss()
	local removed = Library:Notify({ Title = "Cleanup test", Duration = 4, Silent = true })
	removed.Card.Parent:Destroy()
	Mock.Run.Heartbeat:Fire(1)
	assert(removed.Dismissed and removed.Remaining == 4, "destroyed notification kept ticking")
end)

step("minimize and restore full content", function()
	local window = app.Pages[1].Window
	window:SetMinimized(true)
	assert(not window.PageHolder.Visible and not window.Body.Footer.Visible, "minimized content overlaps the header")
	window:SetMinimized(false)
	assert(window.Holder.Size.Y.Offset == 520 and window.PageHolder.Visible, "restored window is cropped")
end)

step("color picker tracks exact screen position at reduced scale", function()
	app:SetScale(0.7)
	local swatch = Library.Options.HudAccent.Row:FindFirstChild("Swatch", true)
	assert(swatch, "HUD accent swatch missing")
	click(swatch)
	Mock.run(0.4)
	local popup = gui.Overlay:FindFirstChild("ColorPopup")
	local sv = popup.Body.SaturationValue
	sv.AbsoluteSize = Vector2.new(126, 78.4)
	local point = sv.AbsolutePosition + Vector2.new(sv.AbsoluteSize.X * 0.25, sv.AbsoluteSize.Y * 0.75)
	sv.InputBegan:Fire(Mock.input("MouseButton1", nil, point))
	assert(math.abs(sv.Cursor.Position.X.Scale - 0.25) < 1e-6, "saturation cursor offset")
	assert(math.abs(sv.Cursor.Position.Y.Scale - 0.75) < 1e-6, "value cursor offset: GUI inset was added")
	local moved = sv.AbsolutePosition + Vector2.new(sv.AbsoluteSize.X * 0.8, sv.AbsoluteSize.Y * 0.2)
	UIS.InputChanged:Fire(Mock.input("MouseMovement", nil, moved))
	assert(math.abs(sv.Cursor.Position.X.Scale - 0.8) < 1e-6 and math.abs(sv.Cursor.Position.Y.Scale - 0.2) < 1e-6, "drag cursor drift")
	UIS.InputEnded:Fire(Mock.input("MouseButton1"))
	local hue = popup.Body.Hue
	local huePoint = hue.AbsolutePosition + Vector2.new(hue.AbsoluteSize.X * 0.6, 0)
	hue.InputBegan:Fire(Mock.input("Touch", nil, huePoint))
	assert(math.abs(hue.Cursor.Position.X.Scale - 0.6) < 1e-6, "touch hue cursor offset")
	UIS.InputEnded:Fire(Mock.input("Touch"))
	app.ctx.Popups:CloseAll()
	app:SetScale(1)
end)

step("UI scale can grow and still fits a small viewport", function()
	app:SetScale(1.3)
	assert(math.abs(app.ctx:GetScale() - 1.3) < 1e-6, "large-screen scale was capped at 100%")
	gui.AbsoluteSize = Vector2.new(640, 480)
	app:_applyScale()
	assert(680 * app.ctx:GetScale() <= 608 and 520 * app.ctx:GetScale() <= 384, "window exceeds the viewport")
	gui._props.AbsoluteSize = nil
	app:SetScale(1)
end)

step("resize handle changes only its own window", function()
	local window = app.Pages[1].Window
	window.ResizeHandle.InputBegan:Fire(Mock.input("MouseButton1", nil, Vector2.new(700, 600)))
	UIS.InputChanged:Fire(Mock.input("MouseMovement", nil, Vector2.new(800, 680)))
	UIS.InputEnded:Fire(Mock.input("MouseButton1"))
	assert(window.Width == 780 and window.Height == 600, "resize drag did not match pointer movement")
	assert(app.Pages[2].Window.Width == 680, "resizing changed another window")
	window:SetMinimized(true)
	assert(not window.ResizeHandle.Visible, "resize handle visible while minimized")
	window:SetMinimized(false)
	assert(window.Holder.Size.X.Offset == 780 and window.Holder.Size.Y.Offset == 600, "restore lost the resized dimensions")
	window:SetSize(10000, 10000)
	local viewport = gui.AbsoluteSize
	assert(window.Width <= viewport.X and window.Height <= viewport.Y, "resize exceeded screen bounds")
	window:SetSize(680, 520)
end)

step("privacy masks every profile and restores it", function()
	local original = app.Windows[1].ProfileName.Text
	app:SetPrivacyMode(true)
	for _, window in ipairs(app.Windows) do
		assert(window.ProfileName.Text == "User" and window.ProfileAvatar.Image == "" and window.AnonymousAvatar.Visible, "profile not anonymous")
	end
	assert(app.Watermark.Name.Text == "User", "watermark exposed the username")
	app:SetPrivacyMode(false)
	assert(app.Windows[1].ProfileName.Text == original and app.Windows[1].ProfileAvatar.Visible, "profile not restored")
end)

step("all generated icons map to uploaded assets and keep loading fallbacks", function()
	local Icons = Library.Icons
	local count = 0
	for name in pairs(Icons.Glyphs) do
		local asset = Icons.Assets[name]
		assert(asset and string.match(asset.Image, "^rbxassetid://%d+$"), "missing uploaded asset for " .. name)
		local icon = Icons.create(name, 20, Color3.new(1, 1, 1), { Parent = gui.Overlay })
		assert(icon:IsA("ImageLabel") and icon.Image == asset.Image, "icon did not use image asset")
		assert(icon.Fallback.Visible, "unloaded icon has no fallback")
		Icons.tint(icon, Color3.fromRGB(120, 180, 240), 0.2)
		assert(icon.ImageTransparency == 1, "pending image must stay hidden behind its fallback")
		if asset.SheetSize then
			icon.ContentImageSize = asset.SheetSize / 2
		end
		icon._props.IsLoaded = true -- Roblox can finish loading without a property signal.
		Mock.Run.Heartbeat:Fire(0.2)
		assert(not icon:FindFirstChild("Fallback"), "fallback remained over the loaded artwork")
		assert(icon.ImageTransparency == 0.2, "loaded image lost its requested transparency")
		if asset.SheetSize then
			assert(icon.ImageRectSize == asset.RectSize / 2, "sprite region did not follow decoded texture size")
		end
		icon:Destroy()
		count += 1
	end
	assert(count == 29, "unexpected generated icon count")
end)

step("section sub-tabs can be created and selected dynamically", function()
	local section = Library.Window.Tabs[1]:AddSection({ Title = "Groups", Tabs = { "General", "Advanced" } })
	section:Tab("Advanced"):AddToggle("NestedExample", { Title = "Nested toggle" })
	local extra = section:AddTab("Extra")
	extra:AddSlider("NestedSlider", { Title = "Nested slider", Min = 0, Max = 10 })
	section:SelectTab("Extra")
	assert(extra.Container.Frame.Visible and not section.Container.Frame.Visible, "sub-tab selection did not isolate content")
	section:SelectTab("missing")
	assert(extra.Container.Frame.Visible, "unknown sub-tab hid the content")
	section:SelectTab("General")
end)

-- Click every button on every page.
local clicked = 0
for _, page in ipairs(app.Pages) do
	step("select " .. page.Name, function()
		app:SelectPage(page)
	end)
	for _, inst in ipairs(page.Canvas:GetDescendants()) do
		if inst:IsA("GuiButton") and inst.Parent then
			clicked += 1
			step(("click %s/%s"):format(page.Name, inst.Name), function()
				click(inst)
			end)
		end
	end
	-- Close anything a click left open.
	step("close popups " .. page.Name, function()
		app.ctx.Popups:CloseAll()
		app.ctx.Keybinds:CancelCapture()
	end)
end
print("buttons clicked: " .. clicked)

-- Dropdown option rows live in the overlay once opened; click them too.
local optionClicks = 0
for _, inst in ipairs(gui.Overlay:GetDescendants()) do
	if inst:IsA("GuiButton") and inst.Parent then
		optionClicks += 1
		step("overlay click " .. inst.Name, function()
			click(inst)
		end)
	end
end
print("popup buttons clicked: " .. optionClicks)

-- Slider drag on every slider hit area.
local drags = 0
for _, inst in ipairs(gui:GetDescendants()) do
	if inst.Name == "Hit" and inst:IsA("GuiButton") and inst.Parent and inst.Parent.Parent then
		drags += 1
		step("drag slider", function()
			inst.InputBegan:Fire(Mock.input("MouseButton1", nil, Vector2.new(450, 300)))
			UIS.InputChanged:Fire(Mock.input("MouseMovement", nil, Vector2.new(700, 300)))
			UIS.InputEnded:Fire(Mock.input("MouseButton1"))
		end)
	end
end
print("slider/hit drags: " .. drags)

-- Type into every text box.
local typed = 0
for _, inst in ipairs(gui:GetDescendants()) do
	if inst.ClassName == "TextBox" and inst.Parent then
		typed += 1
		step("type " .. inst.Name, function()
			fire(inst, "Focused")
			inst.Text = "42"
			fire(inst, "FocusLost", true)
		end)
	end
end
print("text boxes typed: " .. typed)

-- Keybinds: capture a free key, a conflicting key, Escape and Backspace.
step("keybind capture", function()
	local pill
	for _, inst in ipairs(gui:GetDescendants()) do
		if inst.Name == "Keybind" and inst:IsA("GuiButton") then
			pill = inst
			break
		end
	end
	assert(pill, "no keybind pill found")
	click(pill)
	UIS.InputBegan:Fire(Mock.input("Keyboard", "K"), false)
	Mock.run(0.1)
	click(pill)
	UIS.InputBegan:Fire(Mock.input("Keyboard", "E"), false) -- used by Primary ability
	Mock.run(0.1)
	click(pill)
	UIS.InputBegan:Fire(Mock.input("Keyboard", "Escape"), false)
	Mock.run(0.1)
	click(pill)
	UIS.InputBegan:Fire(Mock.input("Keyboard", "Backspace"), false)
end)
step("press bound keys", function()
	for _, key in ipairs({ "Q", "E", "F", "V", "LeftShift" }) do
		UIS.InputBegan:Fire(Mock.input("Keyboard", key), false)
		UIS.InputEnded:Fire(Mock.input("Keyboard", key), false)
	end
end)

-- Options API.
local set = 0
for flag, option in pairs(Library.Options) do
	if option.SetValue then
		step("SetValue " .. flag, function()
			local value = option.Value
			if type(value) == "boolean" then
				option:SetValue(not value)
			elseif type(value) == "number" then
				option:SetValue(value + 1)
			elseif typeof(value) == "Color3" then
				option:SetValue(Color3.fromRGB(10, 200, 120))
			elseif type(value) == "table" then
				option:SetValue({})
			elseif type(value) == "string" then
				option:SetValue(value)
			end
			set += 1
		end)
	end
end
print("options set: " .. set)

-- Behaviour checks.
step("state checks", function()
	local options = Library.Options
	options.LockOn:SetValue(true)
	Mock.run(0.1)
	assert(Library.Flags.LockOn == true, "flag did not follow SetValue")
	options.Biomes:SetValue({ "Desert", "Tundra" })
	Mock.run(0.1)
	local biomes = Library.Flags.Biomes
	assert(biomes.Desert and biomes.Tundra and not biomes.Forest, "multi dropdown value wrong")
	options.LockRange:SetValue(999)
	Mock.run(0.1)
	assert(Library.Flags.LockRange == 200, "slider not clamped to Max")
	options.Stickiness:SetValue(0.437)
	Mock.run(0.1)
	assert(math.abs(Library.Flags.Stickiness - 0.45) < 1e-6, "slider not snapped to step: " .. tostring(Library.Flags.Stickiness))

	-- Conflict: binding Dodge to Q (lock-on's key) must be refused.
	options.LockOnKey:SetValue(Enum.KeyCode.Q)
	options.Dodge:SetValue(Enum.KeyCode.V)
	Mock.run(0.1)
	assert(Library.Flags.LockOnKey == "Q", "LockOnKey SetValue failed: " .. tostring(Library.Flags.LockOnKey))
	local dodge = options.Dodge
	local before = dodge.Value
	local pill
	for _, bind in ipairs(app.ctx.Keybinds:All()) do
		if bind.Name == "Dodge roll" then
			pill = bind
		end
	end
	assert(pill, "dodge bind missing")
	local refused
	app.ctx.Keybinds:Capture(pill, function(result)
		refused = result
	end)
	UIS.InputBegan:Fire(Mock.input("Keyboard", "Q"), false)
	Mock.run(0.1)
	assert(refused == "conflict", "conflicting key was not refused: " .. tostring(refused))
	assert(pill.Key == before, "conflicting key was assigned anyway")

	-- Hold-mode toggle keybind via the lock-on key.
	local wasOn = Library.Flags.LockOn
	UIS.InputBegan:Fire(Mock.input("Keyboard", "Q"), false)
	Mock.run(0.1)
	assert(Library.Flags.LockOn == not wasOn, "toggle keybind did not flip the toggle")
end)

-- Configs round trip.
step("configs", function()
	local ok, message = Library:SaveConfig("smoke")
	assert(ok, message)
	assert(table.find(Library:GetConfigs(), "smoke"), "saved config not listed")
	local saved = Library.Flags.LockOn
	Library.Options.LockOn:SetValue(not saved)
	Mock.run(0.1)
	ok, message = Library:LoadConfig("smoke")
	assert(ok, message)
	Mock.run(0.1)
	assert(Library.Flags.LockOn == saved, "loading a config did not restore the toggle")
	local json = Library:ExportConfig()
	ok, message = Library:ImportConfig(json)
	assert(ok, message)
	ok = Library:ImportConfig("not json")
	assert(not ok, "invalid import should fail")
	ok, message = Library:DeleteConfig("smoke")
	assert(ok, message)
end)

-- Appearance.
for _, name in ipairs(Library.Presets.Order) do
	step("theme " .. name, function()
		Library:SetTheme(name)
	end)
end
step("appearance", function()
	Library:SetAccent(Color3.fromRGB(240, 120, 90))
	app:SetGloss(false)
	app:SetGloss(true)
	app:SetTransparency(0.3)
	app:SetScale(0.8)
	app:SetBlur(true)
	app:SetReducedMotion(true)
	app.Window:SetMinimized(true)
	app.Window:SetMinimized(false)
	app:SetReducedMotion(false)
	app.Watermark:SetEnabled(true)
	app.Watermark:SetStyle("Two Row")
	app.KeybindList:SetEnabled(true)
	Mock.Run.RenderStepped:Fire(0.016)
end)
step("notify", function()
	for _, kind in ipairs({ "Info", "Success", "Warning", "Error" }) do
		Library:Notify({ Title = kind, Content = "test", Type = kind, Duration = 1 })
	end
	for index = 1, 7 do
		Library:Notify("overflow " .. index, 1)
	end
end)
Mock.run(12)

step("unload", function()
	Library:Unload()
	assert(Mock.PlayerGui:FindFirstChild("Nocturne") == nil, "gui still present after unload")
end)
step("recreate", function()
	local window = Library:CreateWindow({ Title = "Again" })
	window:AddTab({ Title = "Solo", Icon = "sparkle" }):AddSection({ Title = "S" }):AddToggle({ Title = "T" })
end)
Mock.run(3)
