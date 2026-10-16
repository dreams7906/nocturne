--[[
	Nocturne example
	Builds demo categories plus the built-in Configs and Settings tabs and uses
	every element type. Each tab gets an icon on the floating dock.

	Run this file directly. It downloads the library below.
	Right Ctrl hides or shows the interface.

	To add your own tab later, copy one of the blocks below:
		local MyTab = Window:AddTab({ Title = "My Tab", Icon = "sparkle" })
		local Box = MyTab:AddSection({ Title = "Stuff", Side = "Left" })
		Box:AddToggle("MyFlag", { Title = "My toggle", Callback = function(on) end })
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dreams7906/nocturne/refs/heads/main/ui.lua?v=7dee1cab2743"))()
local Options = Library.Options

local Window = Library:CreateWindow({
	Title = "Nocturne",
	SubTitle = "Interface",
	Badge = "Plus",
	Theme = "Midnight", -- Midnight, Graphite, Obsidian, Nord, Mocha, Tokyo Night, Rose Pine
	ToggleKey = Enum.KeyCode.RightControl,
	Footer = "nocturne.ui",
	Build = "Build <b>1.0.0</b>",
})

--------------------------------------------------------------------------------
-- Combat: lock-on, ability keys, hit feedback and a live crosshair
--------------------------------------------------------------------------------
local Combat = Window:AddTab({ Title = "Combat", Icon = "combat" })

local Bosses = Combat:AddTab({ Title = "Bosses" })
local BossTracking = Bosses:AddSection({ Title = "Bosses", Tabs = { "Tracking", "Alerts" }, Side = "Left" })
BossTracking:AddLabel("Demo controls: connect these to your own boss system.", "Muted")
BossTracking:AddDropdown("BossTarget", {
	Title = "Example target", Values = { "Training Golem", "Frost Guardian", "All bosses" }, Default = "Training Golem",
})
BossTracking:AddToggle("BossMarker", { Title = "Show boss marker", Default = true })
BossTracking:AddSlider("BossDistance", { Title = "Marker distance", Min = 50, Max = 1000, Default = 350, Suffix = " studs" })
BossTracking:Tab("Alerts"):AddToggle("BossAlerts", { Title = "Boss spawn alerts", Default = true })
local BossPreview = Bosses:AddSection({ Title = "Preview", Side = "Right" })
BossPreview:AddParagraph({ Title = "Combat / Bosses", Content = "This is a sub-tab inside the Combat window. Tracking and Alerts are sub-tabs inside the Bosses section." })
BossPreview:AddButton({ Title = "Test boss notification", Callback = function()
	Library:Notify({ Title = "Bosses", Content = "Example boss notification", Type = "Info" })
end })

local LockOn = Combat:AddSection({ Tabs = { "Lock-On", "Priority" }, Side = "Left" })
LockOn:AddToggle("LockOn", {
	Title = "Enable lock-on",
	Default = true,
	Tooltip = "Keeps the camera centred on the selected enemy NPC.",
}):AddKeybind("LockOnKey", { Default = Enum.KeyCode.Q })
LockOn:AddToggle("ScrollCycle", { Title = "Cycle targets with scroll", Default = true })
LockOn:AddToggle("SprintRelease", { Title = "Release when sprinting" })
LockOn:AddSlider("LockRange", { Title = "Lock range", Min = 10, Max = 200, Default = 80, Suffix = " studs" })
LockOn:AddSlider("Stickiness", { Title = "Camera stickiness", Min = 0, Max = 1, Default = 0.4, Increment = 0.05 })
LockOn:AddDropdown("TargetPriority", {
	Title = "Target priority",
	Values = { "Nearest", "Lowest health", "Centre of screen", "Last attacker" },
	Default = "Nearest",
})

local Priority = LockOn:Tab("Priority")
Priority:AddToggle("PreferBosses", { Title = "Prefer bosses", Default = true })
Priority:AddToggle("SkipDowned", { Title = "Skip downed enemies", Default = true })
Priority:AddDropdown("Indicator", { Title = "Indicator style", Values = { "Ring", "Brackets", "Arrow", "Hidden" }, Default = 2 })

local Abilities = Combat:AddSection({ Title = "Abilities", Tabs = { "Bindings", "Behavior" }, Side = "Left" })
Abilities:AddKeybind("Ability1", { Title = "Primary ability", Default = Enum.KeyCode.E })
Abilities:AddKeybind("Ability2", { Title = "Secondary ability", Default = Enum.KeyCode.R })
Abilities:AddKeybind("Ultimate", {
	Title = "Ultimate",
	Default = Enum.KeyCode.F,
	Mode = "Hold",
	Callback = function(held)
		print("Ultimate charging:", held)
	end,
})
Abilities:AddKeybind("Dodge", {
	Title = "Dodge roll",
	Default = Enum.KeyCode.V,
	Tooltip = "Try binding Q: lock-on already uses it, so the key is refused.",
})
local AbilityBehavior = Abilities:Tab("Behavior")
AbilityBehavior:AddToggle("QuickCast", { Title = "Quick cast", Description = "Cast on key press instead of release." })

local Feedback = Combat:AddSection({ Title = "Feedback", Side = "Right" })
Feedback:AddToggle("HitMarkers", { Title = "Hit markers", Default = true })
	:AddColorPicker("HitMarkerColor", { Default = Color3.fromRGB(240, 240, 245) })
Feedback:AddToggle("DamageNumbers", { Title = "Damage numbers", Default = true })
	:AddColorPicker("DamageColor", { Default = Color3.fromHex("E8C47F") })
Feedback:AddDropdown("HitSound", { Title = "Hit sound", Values = { "Soft click", "Crisp", "Thud", "Chime", "None" } })
Feedback:AddSlider("ScreenShake", { Title = "Screen shake", Min = 0, Max = 100, Default = 35, Suffix = "%" })

-- A real crosshair, so you can see controls driving live behaviour.
local crosshair = Instance.new("ScreenGui")
crosshair.Name = "ExampleCrosshair"
crosshair.IgnoreGuiInset = true
crosshair.ResetOnSpawn = false
crosshair.Enabled = false
crosshair.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local bars = {}
for index = 1, 5 do
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.Transparency = 0.4
	stroke.Parent = bar
	if index == 5 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = bar
	end
	bar.Parent = crosshair
	bars[index] = bar
end

local function drawCrosshair()
	local flags = Library.Flags
	local size, gap, thick = flags.CrossLength or 8, flags.CrossGap or 3, flags.CrossThickness or 2
	local color = flags.CrossColor or Color3.new(1, 1, 1)
	local half = gap + size / 2
	local spots = { { 0, -half, thick, size }, { 0, half, thick, size }, { -half, 0, size, thick }, { half, 0, size, thick } }
	crosshair.Enabled = flags.Crosshair == true
	for index, bar in ipairs(bars) do
		local spot = spots[index] or { 0, 0, thick + 1, thick + 1 }
		bar.Position = UDim2.new(0.5, spot[1], 0.5, spot[2])
		bar.Size = UDim2.fromOffset(spot[3], spot[4])
		bar.BackgroundColor3 = color
		bar.Visible = index < 5 or flags.CrossDot ~= false
	end
end

local Cross = Combat:AddSection({ Tabs = { "Crosshair", "Color" }, Side = "Right" })
Cross:AddToggle("Crosshair", { Title = "Show crosshair", Callback = drawCrosshair })
Cross:AddSlider("CrossLength", { Title = "Length", Min = 2, Max = 24, Default = 8, Callback = drawCrosshair })
Cross:AddSlider("CrossGap", { Title = "Gap", Min = 0, Max = 12, Default = 3, Callback = drawCrosshair })
Cross:AddSlider("CrossThickness", { Title = "Thickness", Min = 1, Max = 4, Default = 2, Increment = 0.5, Callback = drawCrosshair })
Cross:AddToggle("CrossDot", { Title = "Centre dot", Default = true, Callback = drawCrosshair })
local CrossColor = Cross:Tab("Color")
CrossColor:AddColorPicker("CrossColor", { Title = "Crosshair color", Default = Color3.new(1, 1, 1), Callback = drawCrosshair })
CrossColor:AddLabel("Changes apply live. Close the window to see the crosshair.", "Muted")

--------------------------------------------------------------------------------
-- Visuals: field of view is live; the rest are stored settings
--------------------------------------------------------------------------------
local Visuals = Window:AddTab({ Title = "Visuals", Icon = "visuals" })

local Display = Visuals:AddSection({ Title = "Display", Side = "Left" })
Display:AddSlider("FieldOfView", {
	Title = "Field of view",
	Min = 50,
	Max = 110,
	Default = 70,
	Suffix = "°",
	Callback = function(value)
		Workspace.CurrentCamera.FieldOfView = value
	end,
})
Display:AddDropdown("GraphicsPreset", { Title = "Graphics preset", Values = { "Performance", "Balanced", "Quality", "Ultra" }, Default = 2 })
Display:AddToggle("MotionBlur", { Title = "Motion blur" })
Display:AddToggle("Bloom", { Title = "Bloom", Default = true })
Display:AddSlider("Particles", { Title = "Particle density", Min = 0, Max = 100, Default = 75, Suffix = "%" })

local Nameplates = Visuals:AddSection({ Tabs = { "Nameplates", "Style" }, Side = "Left" })
Nameplates:AddToggle("Nameplates", { Title = "Show nameplates", Default = true })
	:AddColorPicker("NameplateColor", { Default = Color3.fromHex("ECEDF1") })
Nameplates:AddToggle("HealthBars", { Title = "Show health bars", Default = true })
	:AddColorPicker("HealthColor", { Default = Color3.fromHex("7BD3A0") })
Nameplates:AddSlider("FadeDistance", { Title = "Fade distance", Min = 25, Max = 300, Default = 120, Suffix = " studs" })
local NameStyle = Nameplates:Tab("Style")
NameStyle:AddDropdown("NameFormat", { Title = "Name format", Values = { "Display name", "Username", "Both" } })
NameStyle:AddToggle("NameBackground", { Title = "Text background", Default = true })

local Hud = Visuals:AddSection({ Title = "HUD", Side = "Right" })
Hud:AddSlider("HudOpacity", { Title = "HUD opacity", Min = 20, Max = 100, Default = 100, Suffix = "%" })
Hud:AddSlider("HudScale", { Title = "HUD scale", Min = 70, Max = 130, Default = 100, Suffix = "%" })
Hud:AddToggle("Minimap", { Title = "Minimap", Default = true })
Hud:AddDropdown("MinimapShape", { Title = "Minimap shape", Values = { "Round", "Square" } })
Hud:AddColorPicker("HudAccent", { Title = "HUD accent", Default = Color3.fromHex("CDD3E0") })

local Party = Visuals:AddSection({ Title = "Party highlights", Side = "Right" })
Party:AddToggle("PartyOutline", { Title = "Outline party members", Default = true })
	:AddColorPicker("PartyOutlineColor", { Default = Color3.fromHex("9DB4FF") })
Party:AddSlider("PartyFill", { Title = "Fill transparency", Min = 0, Max = 100, Default = 75, Suffix = "%" })

--------------------------------------------------------------------------------
-- World: client-side lighting, applied live
--------------------------------------------------------------------------------
local World = Window:AddTab({ Title = "World", Icon = "world" })
local original = { Clock = Lighting.ClockTime, Exposure = Lighting.ExposureCompensation }

local LightingSection = World:AddSection({ Title = "Lighting", Side = "Left" })
LightingSection:AddSlider("TimeOfDay", {
	Title = "Time of day",
	Min = 0,
	Max = 24,
	Increment = 0.25,
	Default = math.floor(Lighting.ClockTime * 4 + 0.5) / 4,
	Suffix = "h",
	Callback = function(value)
		Lighting.ClockTime = value
	end,
})
LightingSection:AddSlider("Exposure", {
	Title = "Exposure",
	Min = -2,
	Max = 2,
	Increment = 0.1,
	Default = 0,
	Callback = function(value)
		Lighting.ExposureCompensation = value
	end,
})
LightingSection:AddToggle("Shadows", {
	Title = "Global shadows",
	Default = Lighting.GlobalShadows,
	Callback = function(value)
		Lighting.GlobalShadows = value
	end,
})
LightingSection:AddButton({
	Title = "Restore lighting",
	Callback = function()
		Options.TimeOfDay:SetValue(original.Clock)
		Options.Exposure:SetValue(original.Exposure)
		Library:Notify({ Title = "Lighting restored", Content = "Original values are back.", Type = "Success" })
	end,
})

local Weather = World:AddSection({ Title = "Weather", Side = "Right" })
Weather:AddDropdown("Weather", { Title = "Weather", Values = { "Clear", "Overcast", "Rain", "Snow", "Storm" } })
Weather:AddSlider("WeatherIntensity", { Title = "Intensity", Min = 0, Max = 100, Default = 50, Suffix = "%" })
Weather:AddSlider("Wind", { Title = "Wind speed", Min = 0, Max = 40, Default = 8, Suffix = " m/s" })
Weather:AddDropdown("Biomes", {
	Title = "Visible biomes (multi-select)",
	Values = { "Forest", "Desert", "Tundra", "Swamp", "Canyon", "Coast" },
	Multi = true,
	Default = { "Forest", "Coast" },
})

--------------------------------------------------------------------------------
-- Player: movement / camera / input preferences
--------------------------------------------------------------------------------
local PlayerTab = Window:AddTab({ Title = "Player", Icon = "player" })

local Movement = PlayerTab:AddSection({ Title = "Movement", Side = "Left" })
Movement:AddDropdown("SprintMode", { Title = "Sprint mode", Values = { "Hold", "Toggle", "Automatic" } })
Movement:AddKeybind("SprintKey", { Title = "Sprint", Default = Enum.KeyCode.LeftShift })
Movement:AddKeybind("CrouchKey", { Title = "Crouch", Default = Enum.KeyCode.C })
Movement:AddSwitch("SmoothTurning", { Title = "Smooth turning", Default = true })

local CameraSection = PlayerTab:AddSection({ Title = "Camera", Side = "Left" })
CameraSection:AddDropdown("CameraMode", { Title = "Camera mode", Values = { "Classic", "Follow", "Over shoulder" } })
CameraSection:AddSlider("Sensitivity", { Title = "Look sensitivity", Min = 0.1, Max = 3, Default = 1, Increment = 0.05, Suffix = "x" })
CameraSection:AddSwitch("InvertY", { Title = "Invert vertical look" })

local Access = PlayerTab:AddSection({ Title = "Accessibility", Side = "Right" })
Access:AddSwitch("Subtitles", { Title = "Subtitles", Default = true })
Access:AddDropdown("ColorFilter", { Title = "Color filter", Values = { "None", "Protanopia", "Deuteranopia", "Tritanopia" } })
Access:AddSlider("SubtitleSize", { Title = "Subtitle size", Min = 80, Max = 150, Default = 100, Suffix = "%" })

local Profile = PlayerTab:AddSection({ Title = "Profile", Side = "Right" })
Profile:AddInput("Nickname", { Title = "Nickname", Placeholder = "Shown above your character", MaxLength = 20, Finished = true })
Profile:AddInput("Level", { Title = "Starting level", Default = 1, Numeric = true, Min = 1, Max = 100, Finished = true })

--------------------------------------------------------------------------------
-- Utilities: live diagnostics and notification tests
--------------------------------------------------------------------------------
local Utilities = Window:AddTab({ Title = "Utilities", Icon = "utilities" })

local Diagnostics = Utilities:AddSection({ Title = "Diagnostics", Side = "Left" })
local fpsInfo = Diagnostics:AddInfo({ Title = "Frame rate", Value = "-" })
local pingInfo = Diagnostics:AddInfo({ Title = "Ping", Value = "-" })
local memoryInfo = Diagnostics:AddInfo({ Title = "Client memory", Value = "-" })
Diagnostics:AddInfo({ Title = "Place ID", Value = game.PlaceId, Accent = true })

task.spawn(function()
	local frames, last = 0, os.clock()
	local counter = game:GetService("RunService").RenderStepped:Connect(function()
		frames += 1
	end)
	Library:OnUnload(function()
		counter:Disconnect()
	end)
	while not Library.Unloaded do
		task.wait(1)
		local now = os.clock()
		fpsInfo:Set(("%d fps"):format(frames / (now - last)))
		frames, last = 0, now
		pingInfo:Set(("%d ms"):format(Players.LocalPlayer:GetNetworkPing() * 1000))
		memoryInfo:Set(("%.0f MB"):format(Stats:GetTotalMemoryUsageMb()))
	end
end)

local Notifications = Utilities:AddSection({ Title = "Notifications", Side = "Right" })
Notifications:AddButton({
	Title = "Info",
	Callback = function()
		Library:Notify({ Title = "Heads up", Content = "This is an info notification." })
	end,
}):AddButton({
	Title = "Success",
	Callback = function()
		Library:Notify({ Title = "Saved", Content = "Everything went fine.", Type = "Success" })
	end,
})
Notifications:AddButton({
	Title = "Warning",
	Callback = function()
		Library:Notify({ Title = "Careful", Content = "Something needs attention.", Type = "Warning" })
	end,
}):AddButton({
	Title = "Reset all",
	Style = "Danger",
	Confirm = true,
	Callback = function()
		for _, option in pairs(Options) do
			if option.Reset then
				option:Reset()
			end
		end
		Library:Notify({ Title = "Reset", Content = "Toggles and sliders are back to defaults.", Type = "Error" })
	end,
})

--------------------------------------------------------------------------------
-- Misc: text elements and reacting to changes
--------------------------------------------------------------------------------
local Misc = Window:AddTab({ Title = "Misc", Icon = "misc" })

local About = Misc:AddSection({ Title = "About", Side = "Left" })
About:AddParagraph({
	Title = "Nocturne " .. Library.Version,
	Content = "Use the dock at the top of the screen to switch tabs. Click the active icon again to close the window.",
})
About:AddDivider("status")
local status = About:AddLabel("Lock-on: <b>enabled</b>")
About:AddInfo({ Title = "Theme", Value = "Settings tab" })

local Audio = Misc:AddSection({ Title = "Audio", Side = "Right" })
Audio:AddSlider("MasterVolume", { Title = "Master", Min = 0, Max = 100, Default = 80, Suffix = "%" })
Audio:AddSlider("MusicVolume", { Title = "Music", Min = 0, Max = 100, Default = 50, Suffix = "%" })
Audio:AddSlider("EffectsVolume", { Title = "Effects", Min = 0, Max = 100, Default = 70, Suffix = "%" })
Audio:AddSwitch("MuteUnfocused", { Title = "Mute when unfocused", Default = true })

-- React to changes anywhere through Options.
Options.LockOn:OnChanged(function(on)
	status:SetText("Lock-on: <b>" .. (on and "enabled" or "disabled") .. "</b>")
end)

Library:OnUnload(function()
	crosshair:Destroy()
end)

-- Browse the built-in expansion icons; these buttons only show their icon names.
local IconGallery = Window:AddTab({ Title = "Icons", Icon = "inventory" })
local IconSamples = IconGallery:AddSection({
 Title = "Icon library", Tabs = { "Navigation", "Gameplay", "Progression", "Extras" }, Side = "Left",
})
local IconGroups = {
 { Title = "Navigation", Names = { "travel", "teleport", "map", "home", "boat", "islands", "movement", "servers" } },
 { Title = "Gameplay", Names = { "bosses", "farming", "fishing", "dungeons", "sword", "shield", "target", "radar" } },
 { Title = "Progression", Names = { "quests", "inventory", "shop", "stats", "fruit", "trophy", "chest", "rewards" } },
 { Title = "Extras", Names = { "trading", "tools", "party", "pets", "crown", "automation", "lightning", "code" } },
}
for _, group in ipairs(IconGroups) do
 local section = IconSamples:Tab(group.Title)
 local function iconButton(name)
  return {
   Title = name:sub(1, 1):upper() .. name:sub(2), Icon = name,
   Callback = function()
    Library:Notify({ Title = "Icon: " .. name, Content = 'Use Icon = "' .. name .. '" on a category or button.', Type = "Info" })
   end,
  }
 end
 for index = 1, #group.Names, 2 do
  section:AddButton(iconButton(group.Names[index])):AddButton(iconButton(group.Names[index + 1]))
 end
end
local IconUsage = IconGallery:AddSection({ Title = "Using icons", Side = "Right" })
IconUsage:AddParagraph({
 Title = "32 new icons",
 Content = 'Use Icon = "travel", Icon = "bosses", or any name shown here. Icons match the theme color automatically.',
})
IconUsage:AddParagraph({
 Title = "Category and button icons",
 Content = "Add icons to dock categories and buttons. Inner tabs remain text-only so you can add any feature name.",
})
IconUsage:AddInfo({ Title = "Files", Value = "SVG + PNG on GitHub" })

-- The Configs and Settings tabs are added automatically after this script.
return Library
