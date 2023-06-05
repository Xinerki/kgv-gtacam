

print("started kgv-GTACAM")

function ResetCamera()
    x = 0.0
    z = GetEntityHeading(PlayerPedId())
end

Citizen.CreateThread(function()
	while true do Wait(0)
		if IsGameplayCamRendering() then
            print("rendering")
            if DoesCamExist(mainCam) then
                DestroyCam(mainCam)
            end

            ResetCamera()

            mainCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
			N_0x661b5c8654add825(mainCam, true)
			RenderScriptCams(true, false, 0, true,  true)
		end
		
		if DoesCamExist(mainCam) then
			processCustomTPCam(mainCam)
		end
	end
end)

fov = 45.0 
distance = 4.0
height = 0.25
xoffset = 0.1

zoom = 0
lastVel = vector3(0.0, 0.0, 0.0)
gforce = vector3(0.0, 0.0, 0.0)
rotshake = 0
aimingScale = 0.0
vehicleScale = 0.0

settings = json.decode(LoadResourceFile(GetCurrentResourceName(), 'settings.json'))
	
-- cam info
fov_def = settings.cameras.ONFOOT.fov
distance_def = settings.cameras.ONFOOT.distance
height_def = settings.cameras.ONFOOT.height
xoffset_def = settings.cameras.ONFOOT.xoffset

-- local height_def = 0.25
-- local xoffset_def = 0.1

-- local fov_def = 58.0 -- sr2
-- local height_def = 0.63 -- sr2

height_set = height_def
xoffset_set = xoffset_def
distance_set = distance_def
vel = vector3(0.0, 0.0, 0.0)
speed = 0
flinch = vector3(0.0, 0.0, 0.0)
flinchtarget = vector3(0.0, 0.0, 0.0)
x_shoulder = 0.0
easetype = 1

function pain()
	-- print('game event ' .. name .. ' (' .. json.encode(args) .. ')')
	-- ShakeCam(cam, "JOLT_SHAKE", 0.1)
	local x = ((math.random() - 0.5) * 2.0) * 5.0
	local y = ((math.random() - 0.5) * 2.0) * 5.0
	flinch = flinch + vector3(x, y, 0.0)
end

AddEventHandler('gameEventTriggered', function(name, args)
	if name == 'CEventNetworkEntityDamage' then
		if args[1] == PlayerPedId() then
			pain()
		end
	end
end)

bloom = 0
c_shake = 0

c_thickness = 0.001
c_length = 0.005
c_gap = 0.0075
c_outlinethickness = 0.0015
c_dot = false
c_outline = true
c_c = {r = 220, g = 220, b = 220, a = 255}
c_o = {r = 0, g = 0, b = 0, a = 128}

-- this reads the custom crosshair convars lol
function UpdateConvars()
	-- c_thickness = tonumber(GetConvar("cl_crosshairthickness")) * 0.0015
	-- c_length = tonumber(GetConvar("cl_crosshairsize")) * 0.0012
	-- c_gap = 0.005 + tonumber(GetConvar("cl_crosshairgap")) * 0.0005
	-- c_outlinethickness = tonumber(GetConvar("cl_crosshair_outlinethickness")) * 0.001
	c_dot = GetConvar("cl_crosshairdot") == 'true'
	-- c_outline = GetConvar("cl_crosshair_drawoutline") == 'true'
	-- c_c = {r = GetConvarInt("cl_crosshaircolor_r"), g = GetConvarInt("cl_crosshaircolor_g"), b = GetConvarInt("cl_crosshaircolor_b"), a = GetConvarInt("cl_crosshairalpha")}
	-- c_o = {r = 0, g = 0, b = 0, a = GetConvarInt("cl_crosshairalpha")}
end

r = GetAspectRatio()

function DrawCrosshair()
	UpdateConvars()
	
	local gap = c_gap + (bloom / 100)
	
	local x = 0.5 + (((math.random() - 0.5) * 2.0) * c_shake/10 * 0.075)
	local y = 0.5 + (((math.random() - 0.5) * 2.0) * c_shake/10 * 0.075)

	if c_dot then
		-- dot
		DrawRect(x, y, c_thickness + c_outlinethickness, c_thickness * r + c_outlinethickness * r, c_o.r, c_o.g, c_o.b, c_o.a)
		DrawRect(x, y, c_thickness, c_thickness * r, c_c.r, c_c.g, c_c.b, c_c.a)
	end
	
	-- bottom
	-- top
	-- right
	-- left
	
	local _, wep = GetCurrentPedWeapon(PlayerPedId())
	
	if c_outline then
		DrawRect(x, y + gap * r, c_thickness + c_outlinethickness, c_length * r + c_outlinethickness * r, c_o.r, c_o.g, c_o.b, c_o.a)
		if GetWeapontypeGroup(wep) ~= 416676503 then 
			DrawRect(x, y - gap * r, c_thickness + c_outlinethickness, c_length * r + c_outlinethickness * r, c_o.r, c_o.g, c_o.b, c_o.a)
		end
		DrawRect(x + gap, y, c_length + c_outlinethickness, c_thickness * r + c_outlinethickness * r, c_o.r, c_o.g, c_o.b, c_o.a)
		DrawRect(x - gap, y, c_length + c_outlinethickness, c_thickness * r + c_outlinethickness * r, c_o.r, c_o.g, c_o.b, c_o.a)
	end
	
	DrawRect(x, y + gap * r, c_thickness, c_length * r, c_c.r, c_c.g, c_c.b, c_c.a)
	if GetWeapontypeGroup(wep) ~= 416676503 then 
		DrawRect(x, y - gap * r, c_thickness, c_length * r, c_c.r, c_c.g, c_c.b, c_c.a)
	end
	DrawRect(x + gap, y, c_length, c_thickness * r, c_c.r, c_c.g, c_c.b, c_c.a)
	DrawRect(x - gap, y, c_length, c_thickness * r, c_c.r, c_c.g, c_c.b, c_c.a)
end

aiming = false
accel = 1
input = vec(0.0, 0.0)

function processCustomTPCam(cam)
	-- RenderScriptCams(true, false, 1, false, false, 0)
	-- StopCutsceneCamShaking()
	
	local pos = GetEntityCoords(PlayerPedId())
	
	if IsControlPressed(0, 19) and IsControlPressed(0, 20) and settings.live_adjust then
		local mouseX = GetDisabledControlUnboundNormal(0, 1) * 0.05 * x_shoulder
		local mouseY = GetDisabledControlUnboundNormal(0, 2) * -0.1
		local mouseZ = (GetDisabledControlNormal(0, 14) - GetDisabledControlNormal(0, 15)) * 0.1
		
		height_set = math.clamp(height_set + mouseY, -0.25, 1.0)
		xoffset_set = math.clamp(xoffset_set + mouseX, -0.5, 0.5)
		distance_set = math.clamp(distance_set + mouseZ, 1.0, 5.0)
		
		if IsControlJustPressed(0, 45) then
			height_set = height_def
			xoffset_set = xoffset_def
			distance_set = distance_def
		end
		
		HideHudAndRadarThisFrame()
	else
		-- local sensitivity = 250
		local sensitivity = 4 + (GetConvarInt("profile_mouseOnFootScale", 0) / 200 * 8)
		-- local mouseX = GetDisabledControlNormal(0, 1) * (sensitivity * GetFrameTime())
		-- local mouseY = GetDisabledControlNormal(0, 2) * (sensitivity * GetFrameTime())
		local mouseX = GetDisabledControlUnboundNormal(0, 1) * sensitivity * (fov/50.0)
		local mouseY = GetDisabledControlUnboundNormal(0, 2) * sensitivity * (fov/50.0)
		
		-- local d = 0.0
			
		local cr = GetCamRot(cam).z
		-- local pr = GetEntityRotation(PlayerPedId()).z
		local v = GetEntityVelocity(PlayerPedId())
		local pr = -math.deg(math.atan2(v.x, v.y))
		local d = aiming and 0.0 or math.deg(math.atan2(math.sin(math.rad(cr-pr)), math.cos(math.rad(cr-pr))))
		-- d = math.abs(d) > 5.0 and d or 0.0
	
		if IsController() then
			-- local vel = GetEntitySpeedVector(PlayerPedId(), true)
		
			local sensitivity = 0.5 + accel
			
			local x = GetDisabledControlUnboundNormal(0, 1)
			local y = GetDisabledControlUnboundNormal(0, 2)
			
			input = lerp(input, vec(x, y), GetFrameTime() * 20.0)
			
			if #vec(x, y) > 0.0 then
				accel = math.min(accel + GetFrameTime() * 2.0, 2.0)
			else
				accel = 0
			end
			
			x = input.x
			y = input.y
			
			mouseX = x * sensitivity * (fov/50.0)
			mouseY = y * sensitivity * (fov/50.0)
		end
		
		bloom = math.min(bloom + (#vec(mouseX, mouseY) * 0.05), 10.0)
		
		if not x then
			x = 0.0
		end
		
		if not z then
			z = 0.0
		end
		
		if not IsControlPressed(0, 37) and not IsFrontendReadyForControl() then
			x = math.clamp(x - mouseY, -75.0, 45.0)
			-- x = math.clamp(x - mouseY, -65.0, 37.5) -- sr2
			z = z - mouseX
			z = z - (d * ((math.min((math.max(0.0, #vel.xy-2.0)^2)/10.0, 1.0) * 0.25) * GetFrameTime()) * 10.0)
		end
	end
	
	bloom = math.max(0.0, bloom - GetFrameTime() * 5.0)
	c_shake = math.max(0.0, c_shake - GetFrameTime() * 10.0)
	
	local towerAngle = 25.0
	local tower = (math.max(x - towerAngle, 0.0) / towerAngle) * 25.0
	
	-- local vel = GetEntityVelocity(PlayerPedId())
	vel = lerp(vel, IsPedInAnyVehicle(PlayerPedId(), false) and GetEntitySpeedVector(GetVehiclePedIsIn(PlayerPedId(), false), true) or GetEntitySpeedVector(PlayerPedId(), true), 10.0 * GetFrameTime())
	local _, sx, sy = GetPedCurrentMovementSpeed(PlayerPedId())
	speed = lerp(speed, sy, 10.0 * GetFrameTime())
	local velScale = #vel/10.0
	local speedScale = #vel/10.0
	local shake_fall = (math.sin(GetGameTimer()/100)^2) * velScale
	local shake_move = (math.sin(GetGameTimer()/100)^2) * (speed/10.0)
	
	flinch = lerp(flinch, vector3(0.0, 0.0, 0.0), GetFrameTime() * 3.0)
	flinchtarget = lerp(flinchtarget, flinch, GetFrameTime() * 10.0)
	
	-- local sx = math.sin(GetGameTimer()/100) * velScale * 0.1
	-- local sy = math.cos(GetGameTimer()/50) * velScale * 0.1
	
	-- fov_aim = fov_def
	-- distance_aim = distance_def
	-- height_aim = height_set
	-- xoffset_aim = xoffset_def
	
	targetfov = fov_def + (10.0 * math.min(speed/15.0, 1.0)) + tower
	targetdistance = distance_set
	targetheight = height_set
	targetxoffset = xoffset_set
	
	if IsPedShooting(PlayerPedId()) then
		zoom = zoom - 0.5
		x = x + (math.random() * 0.5)
		z = z + ((math.random() * 2.0) - 1.0) * 0.25
		rotshake = rotshake + 5
		bloom = math.min(bloom + 1, 10)
		c_shake = math.min(c_shake + 1, 10)
		ShakeCam(cam, "GRENADE_EXPLOSION_SHAKE", -0.1)
	end
	
	rotshake = math.clamp(rotshake - (100.0 * GetFrameTime()), 0.0, 20.0)

	-- zoom = math.clamp(zoom - 5 * GetFrameTime(), 0, 20)
	zoom = lerp(zoom, 0.0, 5.0 * GetFrameTime())
	
	local rotX = x + 5.0
	local rotY = shake_move + (math.sin(GetGameTimer()/10) * (rotshake / 10.0))
	local rotZ = z + 180.0 + (math.cos(GetGameTimer()/10) * (rotshake / 30.0))
	
	if IsPedRagdoll(PlayerPedId()) or IsEntityInAir(PlayerPedId()) then
		shake_move = 0
		
		targetfov = fov_def + (10.0 * math.min(#vel/15.0, 1.0)) + tower
	
		local fallScale = math.min(math.max(#vel - 8.0, 0.0) / 30.0, 1.0) * 0.5
		targetheight = 0.0
		targetxoffset = 0.0
	
		rotX = x + 5.0 + (math.sin(GetGameTimer()/(80/2)) * fallScale)
		rotY = (math.cos(GetGameTimer()/80) * 5.0 * fallScale)
		rotZ = z + 180.0 + (math.cos(GetGameTimer()/(80/2)) * fallScale)
	end
		
	if not IsPedRagdoll(PlayerPedId()) and IsPlayerFreeAiming(PlayerId()) then
		if not aiming then
			bloom = 1
			c_shake = 0
			aiming = true
		end
		
		-- targetfov = fov_aim + zoom
		targetdistance = distance_aim
		targetheight = height_aim
		targetxoffset = xoffset_aim
		rotZ = rotZ + math.sin(GetGameTimer()/1000) * 0.5
		rotX = rotX + math.sin(GetGameTimer()/500) * 0.25
		rotY = rotY + sx
		
		-- DisplaySniperScopeThisFrame()
		DrawCrosshair()
	else
		if aiming then
			aiming = false
		end
	end
	
	if aiming then
		aimingScale = math.min(aimingScale + GetFrameTime() * 5.0, 1.0)
	else
		aimingScale = math.max(0.0, aimingScale - GetFrameTime() * 5.0)
	end

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        if not inVehicle then
            inVehicle = true
        end
    else
        if inVehicle then
            inVehicle = false
        end
    end
	
	if inVehicle then
		vehicleScale = math.min(vehicleScale + GetFrameTime() * 5.0, 1.0)
	else
		vehicleScale = math.max(0.0, vehicleScale - GetFrameTime() * 5.0)
	end
	
	idle_fov = targetfov
	idle_distance = distance_set
	idle_height = height_set
	idle_xoffset = xoffset_set
	
    vehicle_fov = settings.cameras.VEHICLE.fov
    vehicle_distance = settings.cameras.VEHICLE.distance
    vehicle_height = settings.cameras.VEHICLE.height
    vehicle_xoffset = settings.cameras.VEHICLE.xoffset

	aim_fov = settings.cameras.ONFOOT_AIM.fov + zoom
	aim_distance = settings.cameras.ONFOOT_AIM.distance
	aim_height = settings.cameras.ONFOOT_AIM.height
	aim_xoffset = settings.cameras.ONFOOT_AIM.xoffset
	
	if easetype == 1 then
		if IsPedInCoverFacingLeft(PlayerPedId()) == 1 then
			x_shoulder = lerp(x_shoulder, -1.0, GetFrameTime() * 10.0)
		else
			x_shoulder = lerp(x_shoulder, 1.0, GetFrameTime() * 10.0)
		end
	else
		if IsPedInCoverFacingLeft(PlayerPedId()) == 1 then
			x_shoulder = math.max(-1.0, x_shoulder - GetFrameTime() * 10.0)
		else
			x_shoulder = math.min(x_shoulder + GetFrameTime() * 10.0, 1.0)
		end
	end
	
	if easetype == 1 then
        if inVehicle then
            fov = InOutQuad(idle_fov, vehicle_fov, vehicleScale)
            distance = InOutQuad(idle_distance, vehicle_distance, vehicleScale)
            height = InOutQuad(idle_height, vehicle_height, vehicleScale)
            xoffset = InOutQuad(idle_xoffset, vehicle_xoffest, vehicleScale)
        else
            fov = InOutQuad(idle_fov, aim_fov, aimingScale)
            distance = InOutQuad(idle_distance, aim_distance, aimingScale)
            height = InOutQuad(idle_height, aim_height, aimingScale)
            xoffset = InOutQuad(idle_xoffset, aim_xoffset, aimingScale)
        end
	elseif easetype == 2 then
		fov = lerp(fov, targetfov, 10.0 * GetFrameTime())
		distance = lerp(distance, targetdistance, 10.0 * GetFrameTime())
		height = lerp(height, targetheight, 10.0 * GetFrameTime())
		xoffset = lerp(xoffset, targetxoffset, 10.0 * GetFrameTime())
	end
	
	local xoff = math.sin(math.rad(-z)) * math.cos(math.rad(-x)) + (math.sin(math.rad(-z-90.0)) * xoffset * x_shoulder)
	local yoff = math.cos(math.rad(-z)) * math.cos(math.rad(-x)) + (math.cos(math.rad(-z-90.0)) * xoffset * x_shoulder)
	-- local zoff = height + (math.sin(math.rad(-x)) * distance) + (shake * 0.05)
	local zoff = height + (math.sin(math.rad(-x)) * distance)
	
	local flinch_pos = vec(0.0, 0.0, flinchtarget.y * -0.025)
	
	local camPos = vector3(
		pos.x + xoff * distance, 
		pos.y + yoff * distance, 
		pos.z + zoff
	) -- + flinch_pos
	
	local camRot = vector3(
		rotX, 
		rotY, 
		rotZ) + flinchtarget
	
	SetGameplayCamRelativeHeading(camRot.z - GetEntityRotation(PlayerPedId()).z)
	-- DrawRect(0.5 + sx, 0.5 + sy, 0.01, 0.01, 255, 255, 255, 128)
	
	local ray = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, camPos.x, camPos.y, camPos.z, -1, PlayerPedId(), 0)
	local _, hit, _end, _, hitEnt = GetShapeTestResult(ray)
	
	if hit ~= 0 and hitEnt ~= veh and hitEnt ~= PlayerPedId() then
		SetCamCoord(cam, lerp(pos, _end, 0.9))
	else
		SetCamCoord(cam, camPos)
	end
	
	-- SetCamCoord(cam, camPos)
	SetCamRot(cam, camRot)
	SetCamFov(cam, fov)
end