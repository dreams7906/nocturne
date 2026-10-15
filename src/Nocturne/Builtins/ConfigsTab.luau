--[[
	Built-in Configs tab
	Save, load, rename and delete named configs, plus JSON export / import.
	Uses DataStore persistence when Server/ConfigPersistence is installed,
	otherwise configs last for the session.
]]

return function(app)
	local configs = app.Configs
	local page = app:Page({ Name = "Configs", Icon = "configs" })

	local manage = page:Section({ Title = "Configs" })
	local nameInput = manage:Input({
		Text = "Config name",
		Placeholder = "e.g. ranked, casual, streaming",
		MaxLength = 32,
	})
	local list = manage:ListBox({ Height = 150, Empty = "No configs saved yet", Icon = "configs" })

	local details -- filled in below
	local function refresh(keep)
		list:SetItems(configs:List(), keep)
		details.update(list:GetSelected())
	end

	local function report(ok, message)
		app:Notify({ Title = ok and "Configs" or "Couldn't complete that", Text = message, Type = ok and "success" or "warning" })
	end

	manage:Buttons({
		{
			Text = "Save",
			Icon = "save",
			Style = "Primary",
			Callback = function()
				local name = nameInput:Get()
				if name == "" and list:GetSelected() then
					name = list:GetSelected()
				end
				local ok, message = configs:Save(name)
				report(ok, message)
				if ok then
					refresh(true)
				end
			end,
		},
		{
			Text = "Load",
			Icon = "load",
			Callback = function()
				report(configs:Load(list:GetSelected()))
			end,
		},
	})
	manage:Buttons({
		{
			Text = "Rename",
			Icon = "pencil",
			Callback = function()
				local ok, message = configs:Rename(list:GetSelected(), nameInput:Get())
				report(ok, message)
				if ok then
					nameInput:Set("", true)
					refresh(false)
				end
			end,
		},
		{
			Text = "Delete",
			Icon = "trash",
			Style = "Danger",
			Callback = function()
				local ok, message = configs:Delete(list:GetSelected())
				report(ok, message)
				if ok then
					refresh(false)
				end
			end,
		},
	})

	local selected = page:Section({ Title = "Selected", Side = "Right" })
	local nameInfo = selected:Info({ Text = "Name", Value = "-" })
	local countInfo = selected:Info({ Text = "Settings", Value = "-" })
	local savedInfo = selected:Info({ Text = "Saved", Value = "-" })
	local sizeInfo = selected:Info({ Text = "Size", Value = "-" })
	selected:Info({ Text = "Storage", Value = configs.Persistent and "Cloud (DataStore)" or "This session", Accent = true })
	details = {
		update = function(name)
			local info = name and configs:Info(name)
			nameInfo:Set(info and info.Name or "-")
			countInfo:Set(info and info.Flags or "-")
			savedInfo:Set(info and os.date("%b %d, %H:%M", info.Saved) or "-")
			sizeInfo:Set(info and ("%.1f KB"):format(info.Size / 1024) or "-")
		end,
	}
	list.Selected:Connect(function(name)
		details.update(name)
	end)

	local transfer = page:Section({ Title = "Share", Side = "Right" })
	local json = transfer:Input({
		Text = "Config JSON",
		Placeholder = "Export, then select the text to copy",
		Save = false,
	})
	transfer:Buttons({
		{
			Text = "Export",
			Icon = "copy",
			Callback = function()
				json:Set(configs:Export(), true)
				json.Box:CaptureFocus()
				json.Box.SelectionStart = 1
				json.Box.CursorPosition = #json.Box.Text + 1
				app:Notify({ Title = "Exported", Text = "Current settings are in the field, selected for copying.", Type = "success" })
			end,
		},
		{
			Text = "Import",
			Icon = "load",
			Callback = function()
				report(configs:Import(json:Get()))
			end,
		},
	})
	transfer:Label("Export copies your current settings, not the selected config. Paste JSON and press Import to apply it.", "Muted")

	configs.Changed:Connect(function()
		refresh(true)
	end)
	refresh(false)
end
