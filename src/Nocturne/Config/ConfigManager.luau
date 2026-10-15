--[[
	ConfigManager
	Saves / loads the values of every flagged control.

	Storage
	- If ReplicatedStorage has a RemoteFunction named "NocturneConfigs"
	  (created by Server/ConfigPersistence.server.luau) configs persist per
	  player through DataStoreService.
	- Otherwise configs live in memory for the session; export / import
	  still lets players move them around as JSON text.

	All methods yield when a remote is used; call them from callbacks
	(already spawned) or task.spawn.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(script.Parent.Parent.Core.Signal)

local ConfigManager = {}
ConfigManager.__index = ConfigManager

local REMOTE_NAME = "NocturneConfigs"
local MAX_NAME = 32
local FORMAT = 1

function ConfigManager.new(state)
	local self = setmetatable({
		State = state,
		_store = {}, -- name -> { Data = table, Saved = unix time }
		Changed = Signal.new(),
		Persistent = false,
	}, ConfigManager)

	local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
	if remote and remote:IsA("RemoteFunction") then
		self._remote = remote
		self.Persistent = true
		task.spawn(function()
			local ok, result = pcall(remote.InvokeServer, remote, "fetch")
			if ok and type(result) == "table" then
				for name, json in pairs(result) do
					local decoded = self:_decode(json)
					if decoded then
						self._store[name] = decoded
					end
				end
				self.Changed:Fire()
			end
		end)
	end
	return self
end

function ConfigManager.sanitize(name)
	if type(name) ~= "string" then
		return nil
	end
	name = string.gsub(name, "[^%w%s%-_%.]", "")
	name = string.match(name, "^%s*(.-)%s*$")
	if name == "" then
		return nil
	end
	return string.sub(name, 1, MAX_NAME)
end

function ConfigManager:_decode(json)
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
	if ok and type(decoded) == "table" and type(decoded.Flags) == "table" then
		return { Data = decoded.Flags, Saved = tonumber(decoded.Saved) or 0 }
	end
	return nil
end

function ConfigManager:_encode(entry)
	return HttpService:JSONEncode({ Format = FORMAT, Saved = entry.Saved, Flags = entry.Data })
end

function ConfigManager:_push(action, name, json)
	if not self._remote then
		return true
	end
	local ok, result = pcall(self._remote.InvokeServer, self._remote, action, name, json)
	return ok and result == true, ok and result or "Storage unavailable"
end

function ConfigManager:List()
	local names = {}
	for name in pairs(self._store) do
		table.insert(names, name)
	end
	table.sort(names, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	return names
end

function ConfigManager:Info(name)
	local entry = self._store[name]
	if not entry then
		return nil
	end
	local count = 0
	for _ in pairs(entry.Data) do
		count += 1
	end
	return { Name = name, Flags = count, Saved = entry.Saved, Size = #self:_encode(entry) }
end

-- Returns ok, message
function ConfigManager:Save(name)
	name = ConfigManager.sanitize(name)
	if not name then
		return false, "Enter a config name first."
	end
	local entry = { Data = self.State:Serialize(), Saved = os.time() }
	local ok, err = self:_push("save", name, self:_encode(entry))
	if not ok then
		return false, tostring(err)
	end
	self._store[name] = entry
	self.Changed:Fire()
	return true, ("Saved '%s'."):format(name)
end

function ConfigManager:Load(name)
	local entry = self._store[name]
	if not entry then
		return false, "Select a config to load."
	end
	local applied = self.State:Apply(entry.Data)
	return true, ("Loaded '%s' (%d settings)."):format(name, applied)
end

function ConfigManager:Delete(name)
	if not self._store[name] then
		return false, "Select a config to delete."
	end
	local ok, err = self:_push("delete", name)
	if not ok then
		return false, tostring(err)
	end
	self._store[name] = nil
	self.Changed:Fire()
	return true, ("Deleted '%s'."):format(name)
end

function ConfigManager:Rename(old, new)
	new = ConfigManager.sanitize(new)
	if not self._store[old] then
		return false, "Select a config to rename."
	elseif not new then
		return false, "Enter the new name in the name field."
	elseif self._store[new] then
		return false, ("'%s' already exists."):format(new)
	end
	local entry = self._store[old]
	local ok, err = self:_push("save", new, self:_encode(entry))
	if not ok then
		return false, tostring(err)
	end
	self:_push("delete", old)
	self._store[new] = entry
	self._store[old] = nil
	self.Changed:Fire()
	return true, ("Renamed to '%s'."):format(new)
end

-- Current settings (not a stored config) as portable JSON.
function ConfigManager:Export()
	return self:_encode({ Data = self.State:Serialize(), Saved = os.time() })
end

function ConfigManager:Import(json)
	if type(json) ~= "string" or json == "" then
		return false, "Paste exported JSON into the field first."
	end
	local entry = self:_decode(json)
	if not entry then
		return false, "That text isn't a valid Nocturne config."
	end
	local applied = self.State:Apply(entry.Data)
	return true, ("Imported %d settings."):format(applied)
end

return ConfigManager
