--[[
	Theme presets
	Every preset defines the same token set. Components only ever read
	tokens, so adding a preset here is enough to theme the whole UI.

	Backdrop     window / toolbar fill
	Surface      section panels
	Surface2     inputs, fields, inactive controls
	Hover        hovered controls, active indicators
	Elevated     popups, dropdown lists, tooltips
	Border       hairlines and panel strokes
	BorderStrong control outlines, glass edges
	Text / TextDim / TextMuted   three-step type hierarchy
	Accent       highlights; AccentText sits on top of Accent
]]

local rgb = Color3.fromRGB
local hex = Color3.fromHex

local Presets = {}

Presets.Order = { "Midnight", "Graphite", "Obsidian", "Nord", "Mocha", "Tokyo Night", "Rose Pine" }

Presets.Themes = {
	Midnight = {
		Backdrop = hex("202125"),
		Surface = hex("2A2B31"),
		Surface2 = hex("36373E"),
		Hover = hex("46474F"),
		Elevated = hex("292A30"),
		Border = hex("41424A"),
		BorderStrong = hex("555660"),
		Text = hex("ECEDF1"),
		TextDim = hex("B4B5BE"),
		TextMuted = hex("8C8E9A"),
		Accent = hex("E1E2E8"),
		AccentText = hex("121317"),
		Success = hex("7BD3A0"),
		Warning = hex("E8C47F"),
		Danger = hex("E77A82"),
		Shadow = rgb(0, 0, 0),
	},

	Graphite = {
		Backdrop = hex("18181A"),
		Surface = hex("1F1F22"),
		Surface2 = hex("28282C"),
		Hover = hex("313136"),
		Elevated = hex("222225"),
		Border = hex("2F2F34"),
		BorderStrong = hex("3E3E45"),
		Text = hex("EEEEEF"),
		TextDim = hex("A9A9AF"),
		TextMuted = hex("6F6F76"),
		Accent = hex("9DB4FF"),
		AccentText = hex("10131C"),
		Success = hex("7FD1A1"),
		Warning = hex("E6C27D"),
		Danger = hex("EC7F86"),
		Shadow = rgb(0, 0, 0),
	},

	Obsidian = {
		Backdrop = hex("0E0E11"),
		Surface = hex("141418"),
		Surface2 = hex("1B1B21"),
		Hover = hex("24242C"),
		Elevated = hex("17171C"),
		Border = hex("222229"),
		BorderStrong = hex("303038"),
		Text = hex("E9E7F1"),
		TextDim = hex("9E9BAC"),
		TextMuted = hex("625F6F"),
		Accent = hex("B19CFF"),
		AccentText = hex("120E1F"),
		Success = hex("78D3A4"),
		Warning = hex("E8C27E"),
		Danger = hex("EE7D8B"),
		Shadow = rgb(0, 0, 0),
	},

	Nord = {
		Backdrop = hex("232831"),
		Surface = hex("2A2F3A"),
		Surface2 = hex("323845"),
		Hover = hex("3B4252"),
		Elevated = hex("2D3240"),
		Border = hex("373D4A"),
		BorderStrong = hex("4A5366"),
		Text = hex("ECEFF4"),
		TextDim = hex("B5BDCC"),
		TextMuted = hex("7A8396"),
		Accent = hex("88C0D0"),
		AccentText = hex("1D222B"),
		Success = hex("A3BE8C"),
		Warning = hex("EBCB8B"),
		Danger = hex("BF616A"),
		Shadow = hex("0B0D11"),
	},

	Mocha = {
		Backdrop = hex("17171F"),
		Surface = hex("1E1E2B"),
		Surface2 = hex("272737"),
		Hover = hex("313244"),
		Elevated = hex("212130"),
		Border = hex("2E2E40"),
		BorderStrong = hex("45475A"),
		Text = hex("CDD6F4"),
		TextDim = hex("A6ADC8"),
		TextMuted = hex("6C7086"),
		Accent = hex("CBA6F7"),
		AccentText = hex("1B1A26"),
		Success = hex("A6E3A1"),
		Warning = hex("F9E2AF"),
		Danger = hex("F38BA8"),
		Shadow = hex("07070B"),
	},

	["Tokyo Night"] = {
		Backdrop = hex("15161E"),
		Surface = hex("1A1B26"),
		Surface2 = hex("222334"),
		Hover = hex("2A2F45"),
		Elevated = hex("1D1E2B"),
		Border = hex("272A3C"),
		BorderStrong = hex("3B4261"),
		Text = hex("C8D0F5"),
		TextDim = hex("9AA5CE"),
		TextMuted = hex("5D6590"),
		Accent = hex("7AA2F7"),
		AccentText = hex("11131C"),
		Success = hex("9ECE6A"),
		Warning = hex("E0AF68"),
		Danger = hex("F7768E"),
		Shadow = hex("06070B"),
	},

	["Rose Pine"] = {
		Backdrop = hex("18161F"),
		Surface = hex("1F1D2B"),
		Surface2 = hex("272438"),
		Hover = hex("302C45"),
		Elevated = hex("221F31"),
		Border = hex("2C2940"),
		BorderStrong = hex("423E58"),
		Text = hex("E0DEF4"),
		TextDim = hex("A9A5C6"),
		TextMuted = hex("6E6A86"),
		Accent = hex("EBBCBA"),
		AccentText = hex("1C1824"),
		Success = hex("9CCFD8"),
		Warning = hex("F6C177"),
		Danger = hex("EB6F92"),
		Shadow = hex("07060A"),
	},
}

-- Curated accent swatches offered in the accent picker.
Presets.Accents = {
	hex("CDD3E0"), -- Silver
	hex("9DB4FF"), -- Periwinkle
	hex("88C0D0"), -- Frost
	hex("7FD1B9"), -- Mint
	hex("B19CFF"), -- Lavender
	hex("EBBCBA"), -- Rose
	hex("E8C47F"), -- Sand
	hex("F2A07B"), -- Apricot
}

return Presets
