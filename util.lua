function math.clamp(value, minClamp, maxClamp)
	return math.min(maxClamp, math.max(value, minClamp))
end

function InOutQuad(x1, x2, t)
    local angle = (t) * 180.0
    local wave = 1.0-((math.cos(math.rad(angle)) + 1.0) / 2.0)
    return x1 + (x2 - x1) * wave
end

function DrawGameText(x, y, text, r, g, b, a, scale)
	SetTextProportional(1)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropShadow()
	SetTextEntry("STRING")
	AddTextComponentString(tostring(text))
	DrawText(x, y)
end

function DebugText(text)
	SetTextCentre(1)
	SetTextFont(13)
	DrawGameText(0.5, 0.25, text, 255, 255, 255, 255, 0.5)
end

function IsController()
	return not IsInputDisabled(2)
end