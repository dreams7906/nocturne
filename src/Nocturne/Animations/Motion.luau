--[[
	Motion
	Thin TweenService wrapper with named presets, a global speed multiplier
	and a reduced-motion switch.

	A new tween on a property overrides any running tween on that same
	property (TweenService behaviour), so rapid clicking never stacks
	animations. With reduced motion on, values are applied instantly and a
	zero-length tween is still played to cancel anything in flight.
]]

local TweenService = game:GetService("TweenService")

local Out = Enum.EasingDirection.Out
local InOut = Enum.EasingDirection.InOut

local Motion = {
	Reduced = false,
	Speed = 1,
}

Motion.Presets = {
	Instant = { 0, Enum.EasingStyle.Linear, Out },
	Micro = { 0.08, Enum.EasingStyle.Quad, Out },
	Fast = { 0.14, Enum.EasingStyle.Quad, Out },
	Normal = { 0.22, Enum.EasingStyle.Quint, Out },
	Smooth = { 0.32, Enum.EasingStyle.Quint, Out },
	Slow = { 0.45, Enum.EasingStyle.Quint, Out },
	Glide = { 0.38, Enum.EasingStyle.Cubic, InOut },
	Linear = { 1, Enum.EasingStyle.Linear, Out },
}

local function resolve(preset)
	if type(preset) == "number" then
		return preset, Enum.EasingStyle.Quint, Out
	end
	local data = Motion.Presets[preset] or Motion.Presets.Normal
	return data[1], data[2], data[3]
end

function Motion.info(preset)
	local duration, style, direction = resolve(preset)
	if Motion.Reduced then
		duration = 0
	else
		duration /= math.max(Motion.Speed, 0.05)
	end
	return TweenInfo.new(duration, style, direction)
end

-- Tweens `props` on `instance`. Returns the Tween (already playing).
function Motion.tween(instance, preset, props, onComplete)
	local info = Motion.info(preset)
	if info.Time <= 0 then
		for key, value in pairs(props) do
			instance[key] = value
		end
	end
	local tween = TweenService:Create(instance, info, props)
	if onComplete then
		tween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				onComplete()
			end
		end)
	end
	tween:Play()
	return tween
end

-- Linear tween with an explicit duration that ignores reduced motion
-- (used for timers such as notification progress bars).
function Motion.timer(instance, duration, props)
	local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Linear), props)
	tween:Play()
	return tween
end

return Motion
