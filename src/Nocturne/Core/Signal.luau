--[[
	Signal
	Minimal event object. Handlers run through task.spawn so one failing
	listener never breaks the caller or the other listeners.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _entries = {} }, Signal)
end

function Signal:Connect(fn)
	local entries = self._entries
	local entry = { fn = fn, connected = true }
	table.insert(entries, entry)

	local connection = { Connected = true }
	function connection.Disconnect()
		if not entry.connected then
			return
		end
		entry.connected = false
		connection.Connected = false
		local index = table.find(entries, entry)
		if index then
			table.remove(entries, index)
		end
	end
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Fire(...)
	for _, entry in ipairs(table.clone(self._entries)) do
		if entry.connected then
			task.spawn(entry.fn, ...)
		end
	end
end

function Signal:Destroy()
	for _, entry in ipairs(self._entries) do
		entry.connected = false
	end
	table.clear(self._entries)
end

return Signal
