

print("started kgv-GTACAM")

function ResetCamera()
	x = -settings.default_pitch
	z = 180.0 + GetEntityHeading(PlayerPedId())
end

Citizen.CreateThread(function()
	while true do Wait(0)
		if IsGameplayCamRendering() and DoesEntityExist(PlayerPedId()) then
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
transitionScale = 0.0

settings = json.decode(LoadResourceFile(GetCurrentResourceName(), 'settings.json'))

current_cam = settings.cameras.ONFOOT
next_cam = settings.cameras.ONFOOT
	
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
dist_scale = 1.0
easetype = settings.easetype

function pain()
	-- print('game event ' .. name .. ' (' .. json.encode(args) .. ')')
	-- ShakeCam(cam, "JOLT_SHAKE", 0.1)
	local x = ((math.random() - 0.5) * 2.0) * 5.0
	local y = ((math.random() - 0.5) * 2.0) * 5.0
	flinch += vector3(x, y, 0.0)
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

-- c_thickness = 0.001
-- c_length = 0.005
-- c_gap = 0.0075
-- c_outlinethickness = 0.0015
-- c_dot = false
-- c_outline = true
-- c_c = {r = 220, g = 220, b = 220, a = 255}
-- c_o = {r = 0, g = 0, b = 0, a = 128}

c_thickness = settings.crosshair.c_thickness
c_length = settings.crosshair.c_length
c_gap = settings.crosshair.c_gap
c_outlinethickness = settings.crosshair.c_outlinethickness
c_dot = settings.crosshair.c_dot
c_outline = settings.crosshair.c_outline
c_pistol = settings.crosshair.c_pistol
c_c = settings.crosshair.c_c
c_o = settings.crosshair.c_o

-- this reads the custom crosshair convars lol
function UpdateConvars()
	if settings.crosshair_convar.c_thickness then
		c_thickness = tonumber(GetConvar("cl_crosshairthickness")) * 0.0015
	end
	if settings.crosshair_convar.c_length then
		c_length = tonumber(GetConvar("cl_crosshairsize")) * 0.0012
	end
	if settings.crosshair_convar.c_gap then
		c_gap = 0.005 + tonumber(GetConvar("cl_crosshairgap")) * 0.0005
	end
	if settings.crosshair_convar.c_outlinethickness then
		c_outlinethickness = tonumber(GetConvar("cl_crosshair_outlinethickness")) * 0.001
	end
	if settings.crosshair_convar.c_dot then
		c_dot = GetConvar("cl_crosshairdot") == 'true'
	end
	if settings.crosshair_convar.c_outline then
		c_outline = GetConvar("cl_crosshair_drawoutline") == 'true'
	end
	if settings.crosshair_convar.c_c then
		c_c = {r = GetConvarInt("cl_crosshaircolor_r"), g = GetConvarInt("cl_crosshaircolor_g"), b = GetConvarInt("cl_crosshaircolor_b"), a = GetConvarInt("cl_crosshairalpha")}
		c_o = {r = 0, g = 0, b = 0, a = GetConvarInt("cl_crosshairalpha")}
	end
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
		if not (c_pistol and GetWeapontypeGroup(wep) == 416676503) then 
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
accel = 0
input = vec(0.0, 0.0)
lastInput = 0

function TransitionCamera(from, to)
	current_cam = from
	next_cam = to
	transitionScale = 0.0
	enteringVehicle = false
	exitingVehicle = false
end

function processCustomTPCam(cam)
	-- RenderScriptCams(true, false, 1, false, false, 0)
	-- StopCutsceneCamShaking()
	
	local pos = GetEntityCoords(PlayerPedId())
	-- local vel = GetEntityVelocity(PlayerPedId())
	vel = lerp(vel, IsPedInAnyVehicle(PlayerPedId(), false) and GetEntitySpeedVector(GetVehiclePedIsIn(PlayerPedId(), false), true) or GetEntitySpeedVector(PlayerPedId(), true), 10.0 * GetFrameTime())
	local world_vel = GetEntityVelocity(PlayerPedId())
	gforce = lerp(gforce, lastVel - world_vel, GetFrameTime() * 2.0)
	local _, sx, sy = GetPedCurrentMovementSpeed(PlayerPedId())
			
	local cr = GetCamRot(cam).z + (IsControlPressed(0, 26) and 180.0 or 0.0)
	-- local pr = GetEntityRotation(PlayerPedId()).z
	local pr = -math.deg(math.atan2(world_vel.x, world_vel.y))
	local delta_heading = math.deg(math.atan2(math.sin(math.rad(cr-pr)), math.cos(math.rad(cr-pr))))
	local delta_pitch = x - math.deg(math.atan2(world_vel.z, 50.0)) + settings.default_pitch
	-- delta_heading = math.abs(d) > 5.0 and d or 0.0
	
	-- TODO: this delta_pitch calculation is goofy, should find a better way to do that bit

	if aiming or GetGameTimer() < lastInput + settings.reset_delay then
		delta_heading = 0.0
		delta_pitch = 0.0
	end
	
	if IsControlPressed(0, 19) and IsControlPressed(0, 20) and settings.live_adjust then
		local mouseX = GetControlUnboundNormal(0, 1) * 0.05 * x_shoulder
		local mouseY = GetControlUnboundNormal(0, 2) * -0.1
		local mouseZ = (GetControlNormal(0, 14) - GetControlNormal(0, 15)) * 0.1
		
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
		-- local mouseX = GetControlNormal(0, 1) * (sensitivity * GetFrameTime())
		-- local mouseY = GetControlNormal(0, 2) * (sensitivity * GetFrameTime())
		local mouseX = GetControlUnboundNormal(0, 1) * sensitivity * (fov/50.0)
		local mouseY = GetControlUnboundNormal(0, 2) * sensitivity * (fov/50.0)
		
		-- local d = 0.0
	
		if IsController() then
			-- local vel = GetEntitySpeedVector(PlayerPedId(), true)
		
			local sensitivity = 0.5 + accel
			
			local x = GetControlUnboundNormal(0, 1)
			local y = GetControlUnboundNormal(0, 2)
			
			input = lerp(input, vec(x, y), GetFrameTime() * 20.0)
			
			if #vec(x, y) > 0.25 then
				accel = math.min(accel + GetFrameTime() * 2.0, 2.0)
			else
				accel = 0
			end
			
			x = input.x
			y = input.y
			
			mouseX = x * sensitivity * (fov/50.0) * (GetFrameTime() * 100.0)
			mouseY = y * sensitivity * (fov/50.0) * (GetFrameTime() * 100.0)
		else
			if #vec(mouseX, mouseY) > 0.0 then
				lastInput = GetGameTimer()
			end
		end
		
		bloom = math.min(bloom + (#vec(mouseX, mouseY) * 0.05), 10.0)

		-- TODO: this is really poor naming of these globals
		if not x then
			x = 0.0
		end
		
		if not z then
			z = 0.0
		end
		
		if (not IsControlPressed(0, 37) or inVehicle) and not IsFrontendReadyForControl() then
			local limits = inVehicle and settings.pitch_limits.VEHICLE or settings.pitch_limits.ONFOOT
			x = math.clamp(x - mouseY, limits.min, limits.max)
			-- x = math.clamp(x - mouseY, -65.0, 37.5) -- sr2
			z -= mouseX
		end

		local adjust_scale = ((math.min(math.max(0.0, #vel.xy-2.0)/10.0, 1.0) * settings.adjust_speed) * GetFrameTime()) * 10.0
		x -= (delta_pitch * adjust_scale)
		z -= (delta_heading * adjust_scale)
	end
	
	bloom = math.max(0.0, bloom - GetFrameTime() * 5.0)
	c_shake = math.max(0.0, c_shake - GetFrameTime() * 10.0)
	
	local towerAngle = settings.tower_angle
	local tower = (math.max(x - towerAngle, 0.0) / towerAngle) * settings.tower_fov
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
		zoom -= 0.5
		x += (math.random() * 0.5)
		z += ((math.random() * 2.0) - 1.0) * 0.25
		rotshake += 5
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
		
	if not IsPedRagdoll(PlayerPedId()) and IsPlayerFreeAiming(PlayerId()) and IsPedArmed(PlayerPedId(), 2 | 4) then
		if not aiming then
			bloom = 1
			c_shake = 0
			aiming = true
			if inVehicle then
				TransitionCamera(settings.cameras.VEHICLE, settings.cameras.VEHICLE_DRIVEBY)
			else
				TransitionCamera(settings.cameras.ONFOOT, settings.cameras.ONFOOT_AIM)
			end
		end
		
		-- targetfov = fov_aim + zoom
		targetdistance = distance_aim
		targetheight = height_aim
		targetxoffset = xoffset_aim
		rotZ += math.sin(GetGameTimer()/1000) * 0.5
		rotX += math.sin(GetGameTimer()/500) * 0.25
		rotY += sx
		
		-- DisplaySniperScopeThisFrame()
		DrawCrosshair()
	else
		if aiming then
			aiming = false
			if inVehicle then
				TransitionCamera(settings.cameras.VEHICLE_DRIVEBY, settings.cameras.VEHICLE)
			else
				TransitionCamera(settings.cameras.ONFOOT_AIM, settings.cameras.ONFOOT)
			end
		end
	end

	if (settings.early_vehicle_transition and IsPedGettingIntoAVehicle(PlayerPedId())) or IsPedInAnyVehicle(PlayerPedId(), true) then
		if not inVehicle then
			inVehicle = true
			TransitionCamera(settings.cameras.ONFOOT, settings.cameras.VEHICLE)
			enteringVehicle = true
		end
	else
		if inVehicle then
			inVehicle = false
			TransitionCamera(settings.cameras.VEHICLE, settings.cameras.ONFOOT)
			exitingVehicle = true
		end
	end
	
	transitionScale = math.min(transitionScale + GetFrameTime() * 5.0, 1.0)

	-- current_fov = targetfov
	current_fov = current_cam.fov
	current_distance = current_cam.distance
	current_height = current_cam.height
	current_xoffest = current_cam.xoffset

	target_fov = next_cam.fov + zoom + (10.0 * math.min(speed/15.0, 1.0)) + (aiming and 0.0 or tower)
	target_distance = next_cam.distance
	target_height = next_cam.height
	target_xoffest = next_cam.xoffset
	
	local veh = GetVehiclePedIsEntering(PlayerPedId())
	veh = veh ~= 0 and veh or GetVehiclePedIsIn(PlayerPedId(), true)	-- FUCK YOU!

	-- extra calculation necessary for vehicles
	if inVehicle or enteringVehicle or exitingVehicle then
		local model = GetEntityModel(veh)
		local min, max = GetModelDimensions(model)

		local length = #(max-min).xy
		local height = max.z*0.25
		
		if IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAQuadbike(model) or IsThisModelAJetski(model) then
			length *= settings.bike_cam_mult
		end
		
		if enteringVehicle then
			target_distance *= length
			target_height += height
		elseif exitingVehicle then
			current_distance *= length
			current_height += height
		else -- inVehicle
			current_distance *= length
			current_height += height
			target_distance *= length
			target_height += height
		end
	end
	
	if easetype == 1 then
		x_shoulder = lerp(x_shoulder, IsPedInCoverFacingLeft(PlayerPedId()) == 1 and -1.0 or 1.0, GetFrameTime() * 10.0)
	else
		if IsPedInCoverFacingLeft(PlayerPedId()) == 1 then
			x_shoulder = math.max(-1.0, x_shoulder - GetFrameTime() * 10.0)
		else
			x_shoulder = math.min(x_shoulder + GetFrameTime() * 10.0, 1.0)
		end
	end
	
	if easetype == 1 then
		fov = InOutQuad(current_fov, target_fov, transitionScale)
		distance = InOutQuad(current_distance, target_distance, transitionScale)
		height = InOutQuad(current_height, target_height, transitionScale)
		xoffset = InOutQuad(current_xoffest, target_xoffest, transitionScale)
		
		if enteringVehicle then
			pos = InOutQuad(GetEntityCoords(PlayerPedId()), GetEntityCoords(veh), transitionScale)
		elseif exitingVehicle then
			pos = InOutQuad(GetEntityCoords(veh), GetEntityCoords(PlayerPedId()), transitionScale)
		end
	elseif easetype == 2 then
		fov = lerp(fov, targetfov, 10.0 * GetFrameTime())
		distance = lerp(distance, targetdistance, 10.0 * GetFrameTime())
		height = lerp(height, targetheight, 10.0 * GetFrameTime())
		xoffset = lerp(xoffset, targetxoffset, 10.0 * GetFrameTime())
	end
	
	local xoff = math.sin(math.rad(-z + (IsControlPressed(0, 26) and 180.0 or 0.0))) * math.cos(math.rad(-x)) + (math.sin(math.rad(-z-90.0)) * xoffset * x_shoulder)
	local yoff = math.cos(math.rad(-z + (IsControlPressed(0, 26) and 180.0 or 0.0))) * math.cos(math.rad(-x)) + (math.cos(math.rad(-z-90.0)) * xoffset * x_shoulder)
	local zoff = height + (math.sin(math.rad(-x)) * distance) -- + (shake * 0.05)

	rotZ += (IsControlPressed(0, 26) and 180.0 or 0.0)
	
	local flinch_pos = vec(0.0, 0.0, flinchtarget.y * -0.025)

	if inVehicle then
		pos += gforce * settings.gforce_mult
		fov += math.clamp((#vel-10.0) / 50.0, 0.0, 1.0) * settings.speed_fov
		rotY -= ((math.deg(math.atan2(vel.x, math.abs(vel.y))) / 90.0) * settings.angle_roll) * math.min(#vel / 50.0, 1.0)
	end
	
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
	
	local ray = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, camPos.x, camPos.y, camPos.z, 1 | 2 | 16, (inVehicle or enteringVehicle or exitingVehicle) and veh or PlayerPedId(), 0)
	local _, hit, _end, _, hitEnt = GetShapeTestResult(ray)
	
	dist = math.min(#(pos - _end) / #(pos - camPos), 1.0)
	
	if dist > dist_scale then
		-- dist_scale = math.min(dist_scale + GetFrameTime() * 2.0, 1.0)
		dist_scale = lerp(dist_scale, 1.0, GetFrameTime() * 2.0)
	else
		dist_scale = dist
	end
	
	-- TODO: still a little jittery
	
	-- if hit ~= 0 and hitEnt ~= PlayerPedId() then
		SetCamCoord(cam, lerp(pos, camPos+vec(0.0, 0.0, 1.0-dist_scale), dist_scale * 0.99))
	-- else
		-- SetCamCoord(cam, camPos)
	-- end
	
	-- SetCamCoord(cam, camPos)
	SetCamRot(cam, camRot)
	SetCamFov(cam, fov)

	lastVel = world_vel
end