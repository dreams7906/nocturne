--[[
	Maid
	Collects connections, instances and cleanup functions so a component
	can release everything it created in one call.
]]

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(item)
	table.insert(self._tasks, item)
	return item
end

local function cleanup(item)
	local kind = typeof(item)
	if kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "function" then
		item()
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "table" then
		if item.Disconnect then
			item.Disconnect(item)
		elseif item.Destroy then
			item:Destroy()
		end
	end
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for index = #tasks, 1, -1 do
		cleanup(tasks[index])
	end
end

-- Cleans automatically when the given instance is destroyed.
function Maid:LinkTo(instance)
	self:Give(instance.Destroying:Connect(function()
		self:Clean()
	end))
	return self
end

Maid.Destroy = Maid.Clean

return Maid
