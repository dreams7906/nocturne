--[[
	Popups
	Ensures only one floating popup (dropdown list, colour picker) is open
	at a time and closes it when the user presses anywhere outside of it.

	popup = { Close = fn(), Contains = fn(point: Vector2) -> boolean }
]]

local UserInputService = game:GetService("UserInputService")

local Util = require(script.Parent.Util)

local Popups = {}
Popups.__index = Popups

function Popups.new()
	local self = setmetatable({ Current = nil }, Popups)
	self._connection = UserInputService.InputBegan:Connect(function(input)
		local current = self.Current
		if not current or not Util.isPress(input) then
			return
		end
		if not current.Contains(Util.pointer(input)) then
			self:Close(current)
		end
	end)
	return self
end

function Popups:Open(popup)
	if self.Current and self.Current ~= popup then
		self:Close(self.Current)
	end
	self.Current = popup
end

function Popups:Close(popup)
	popup = popup or self.Current
	if not popup then
		return
	end
	if self.Current == popup then
		self.Current = nil
	end
	popup.Close()
end

function Popups:Released(popup)
	if self.Current == popup then
		self.Current = nil
	end
end

function Popups:CloseAll()
	self:Close(self.Current)
end

function Popups:Destroy()
	self._connection:Disconnect()
end

return Popups
