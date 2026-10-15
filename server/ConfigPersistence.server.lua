--[[
	Nocturne config persistence (optional)
	Put this Script in ServerScriptService. It creates the RemoteFunction
	ReplicatedStorage.NocturneConfigs, and the library then saves configs
	per player with DataStoreService instead of only for the session.

	Studio: enable "Game Settings > Security > Enable Studio Access to API
	Services" to test DataStores. Without it, configs still work for the
	session and a warning is printed.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STORE_NAME = "NocturneConfigs_v1"
local MAX_CONFIGS = 20
local MAX_NAME = 32
local MAX_JSON = 30000
local MIN_INTERVAL = 0.4 -- seconds between requests per player

local store = DataStoreService:GetDataStore(STORE_NAME)

local remote = ReplicatedStorage:FindFirstChild("NocturneConfigs") or Instance.new("RemoteFunction")
remote.Name = "NocturneConfigs"
remote.Parent = ReplicatedStorage

local sessions = {} -- player -> { configs = {name = json}, dirty = bool, last = clock }

local function key(player)
	return "u_" .. player.UserId
end

local function load(player)
	local session = sessions[player]
	if session then
		return session
	end
	session = { configs = {}, dirty = false, last = 0, loaded = false }
	sessions[player] = session
	local ok, data = pcall(store.GetAsync, store, key(player))
	if ok then
		if type(data) == "table" and type(data.configs) == "table" then
			session.configs = data.configs
		end
		session.loaded = true
	else
		warn("[Nocturne] Could not load configs for " .. player.Name .. ": " .. tostring(data))
	end
	return session
end

local function save(player)
	local session = sessions[player]
	if not session or not session.dirty or not session.loaded then
		return
	end
	local configs = session.configs
	local ok, err = pcall(store.UpdateAsync, store, key(player), function()
		return { configs = configs, version = 1 }
	end)
	if ok then
		session.dirty = false
	else
		warn("[Nocturne] Could not save configs for " .. player.Name .. ": " .. tostring(err))
	end
end

local function validName(name)
	return type(name) == "string" and #name > 0 and #name <= MAX_NAME and not string.find(name, "[^%w%s%-_%.]")
end

local function count(configs)
	local n = 0
	for _ in pairs(configs) do
		n += 1
	end
	return n
end

remote.OnServerInvoke = function(player, action, name, json)
	local session = load(player)
	local now = os.clock()
	if now - session.last < MIN_INTERVAL then
		return "Slow down a little."
	end
	session.last = now

	if action == "fetch" then
		return session.configs
	elseif action == "save" then
		if not validName(name) then
			return "Invalid config name."
		elseif type(json) ~= "string" or #json > MAX_JSON then
			return "Config is too large."
		elseif not session.configs[name] and count(session.configs) >= MAX_CONFIGS then
			return ("You can keep up to %d configs."):format(MAX_CONFIGS)
		end
		session.configs[name] = json
		session.dirty = true
		task.defer(save, player)
		return true
	elseif action == "delete" then
		if not validName(name) then
			return "Invalid config name."
		end
		session.configs[name] = nil
		session.dirty = true
		task.defer(save, player)
		return true
	end
	return "Unknown action."
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	sessions[player] = nil
end)

game:BindToClose(function()
	for player in pairs(sessions) do
		task.spawn(save, player)
	end
	task.wait(2)
end)
