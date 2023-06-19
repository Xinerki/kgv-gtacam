function lerp(x1, x2, t)
    return x1 + (x2 - x1) * t
end

function math.clamp(value, minClamp, maxClamp)
	return math.min(maxClamp, math.max(value, minClamp))
end

function InOutQuad(x1, x2, t)
    local angle = (t) * 180.0
    local wave = 1.0-((math.cos(math.rad(angle)) + 1.0) / 2.0)
    return x1 + (x2 - x1) * wave
end

function DrawGameText(x, y, text, r, g, b, a, scale)
  SetTextFont(13)
  SetTextProportional(1)
  SetTextScale(scale, scale)
  SetTextColour(r, g, b, a)
  SetTextDropShadow()
  SetTextEntry("STRING")
  AddTextComponentString(tostring(text))
  DrawText(x, y)
end

function DebugText(i, ...)
  DrawGameText(0.01, 0.05 + (i * 0.015), table.concat({...}, ' '), 255, 255, 255, 255, 0.25, 0.25)
end

function IsController()
	return not IsInputDisabled(2)
end

local last_print = ""

function printonce(s)
	local str = tostring(s)
	if str ~= last_print then
		print(str)
		last_print = str
	end
end