print("started kgv-GTACAM")

GetVehicleSize = GetVehicleSuspensionBounds

function ResetCamera()
	x = -settings.default_pitch
	z = 180.0 + GetEntityHeading(PlayerPedId())
end

function CloneGameplayCamera()
	x = GetEntityPitch(PlayerPedId()) + GetGameplayCamRelativePitch()
	z = 180.0 + GetEntityHeading(PlayerPedId()) + GetGameplayCamRelativeHeading()
end

CreateThread(function()
	while true do Wait(0)
		if IsGameplayCamRendering() and DoesEntityExist(PlayerPedId()) then
			if DoesCamExist(mainCam) then
				DestroyCam(mainCam)
			end

			CloneGameplayCamera()

			mainCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
			N_0x661b5c8654add825(mainCam, true)
			RenderScriptCams(true, false, 0, true, true)
		end
		
		if DoesCamExist(mainCam) then
			processCustomTPCam(mainCam)
		end
	end
end)

zoom = 0
lastVel = vector3(0.0, 0.0, 0.0)
gforce_frame = vector3(0.0, 0.0, 0.0)
gforce = vector3(0.0, 0.0, 0.0)
rotshake = 0
transitionScale = 0.0

settings = json.decode(LoadResourceFile(GetCurrentResourceName(), 'settings.json'))

default_mode = 2 -- MEDIUM
current_mode = default_mode
previous_mode = current_mode

current_cam = settings.cameras[current_mode].ONFOOT
next_cam = settings.cameras[current_mode].ONFOOT
	
-- cam info
fov_def = settings.cameras[current_mode].ONFOOT.fov
distance_def = settings.cameras[current_mode].ONFOOT.distance
height_def = settings.cameras[current_mode].ONFOOT.height
xoffset_def = settings.cameras[current_mode].ONFOOT.xoffset

fov = fov_def
distance = distance_def
height = height_def
xoffset = xoffset_def

-- local height_def = 0.25
-- local xoffset_def = 0.1

-- local fov_def = 58.0 -- sr2
-- local height_def = 0.63 -- sr2

camPos = vector3(0.0, 0.0, 0.0)
camRot = vector3(0.0, 0.0, 0.0)

height_set = height_def
xoffset_set = xoffset_def
distance_set = distance_def
vel = vector3(0.0, 0.0, 0.0)
speed = 0
flinch = vector3(0.0, 0.0, 0.0)
flinchtarget = vector3(0.0, 0.0, 0.0)
x_shoulder = 0.0
dist_scale = 1.0

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
hipfiring = false
last_aim = 0
last_explosion = 0
explosion_shake = 0.0
accel = 0
input = vec(0.0, 0.0)
lastInput = 0

function TransitionCamera(from, to)
	current_cam = from
	next_cam = to
	-- transitionScale = 0.0
	transitionScale = 1.0 - transitionScale -- if interrupted, continue from where it left off
	enteringVehicle = false
	exitingVehicle = false
end

function UpdateCameraMode()
	if inVehicle then
		if aiming then
			TransitionCamera(settings.cameras[previous_mode].AIMING_VEHICLE, settings.cameras[current_mode].AIMING_VEHICLE)
		else
			TransitionCamera(settings.cameras[previous_mode].VEHICLE, settings.cameras[current_mode].VEHICLE)
		end
	else
		if inInterior then
			TransitionCamera(settings.cameras[previous_mode].INTERIOR, settings.cameras[current_mode].INTERIOR)
		elseif aiming then
			if hipfiring then
				TransitionCamera(settings.cameras[previous_mode].AIMING_ONFOOT_HIP, settings.cameras[current_mode].AIMING_ONFOOT_HIP)
			else
				TransitionCamera(settings.cameras[previous_mode].AIMING_ONFOOT, settings.cameras[current_mode].AIMING_ONFOOT)
			end
		else
			TransitionCamera(settings.cameras[previous_mode].ONFOOT, settings.cameras[current_mode].ONFOOT)
		end
	end
end

function CycleCameraMode()
	previous_mode = current_mode
	current_mode += 1
	
	if current_mode > #settings.cameras then
		current_mode = 1
	end
	
	UpdateCameraMode()
end

RegisterKeyMapping('gtacam_swapshoulder', 'Swap Shoulder', 'KEYBOARD', 'X')
RegisterKeyMapping('~!gtacam_swapshoulder', 'Swap Shoulder', 'PAD_DIGITALBUTTON', 'LDOWN_INDEX')
RegisterCommand('gtacam_swapshoulder', function()
	target_shoulder = not target_shoulder
end, false)

function processCustomTPCam(cam)
	-- RenderScriptCams(true, false, 1, false, false, 0)
	-- StopCutsceneCamShaking()
	
	DisableFirstPersonCamThisFrame()
	DisableVehicleFirstPersonCamThisFrame()
	
	-- INPUT_NEXT_CAMERA
	DisableControlAction(0, 0, true)
	
	if IsDisabledControlJustPressed(0, 0) then
		CycleCameraMode()
	end
	
	local pos = GetEntityCoords(PlayerPedId())
	local heading = GetEntityPhysicsHeading(PlayerPedId())
	-- local vel = GetEntityVelocity(PlayerPedId())
	vel = lerp(vel, IsPedInAnyVehicle(PlayerPedId(), false) and GetEntitySpeedVector(GetVehiclePedIsIn(PlayerPedId(), false), true) or GetEntitySpeedVector(PlayerPedId(), true), 10.0 * GetFrameTime())
	local world_vel = GetEntityVelocity(PlayerPedId())
	-- gforce = lerp(gforce, lastVel - world_vel, GetFrameTime() * 2.0)
	gforce_frame = lastVel - world_vel
	gforce += gforce_frame * GetFrameTime() * 4.0
	gforce = lerp(gforce, vec(0.0, 0.0, 0.0), GetFrameTime() * 1.0)
	local _, sx, sy = GetPedCurrentMovementSpeed(PlayerPedId())
	
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		sx = 0.0
		sy = 0.0
	end
	
	local cr = camRot.z
	-- local pr = GetEntityRotation(PlayerPedId()).z
	local pr = -math.deg(math.atan2(world_vel.x, world_vel.y))
	local delta_heading = math.deg(math.atan2(math.sin(math.rad(cr-pr)), math.cos(math.rad(cr-pr))))
	local delta_pitch = x - ((IsControlPressed(0, 26) and -1.0 or 1.0) * math.deg(math.atan2(world_vel.z, #vel.xy))) + settings.default_pitch
	-- delta_heading = math.abs(d) > 5.0 and d or 0.0

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
			local maxScale = inVehicle and lerp(0.75, 1.0, math.abs(math.sin(math.rad(-z+heading)))) or 1.0
			x = math.clamp(x - mouseY, limits.min, limits.max * maxScale)
			-- x = math.clamp(x - mouseY, -65.0, 37.5) -- sr2
			z -= mouseX
		end

		local adjust_scale = ((math.min(math.max(0.0, #vel.xy-2.0)/10.0, 1.0) * settings.adjust_speed) * GetFrameTime()) * 10.0
		x -= (delta_pitch * adjust_scale)
		z -= (delta_heading * adjust_scale)
	end
	
	bloom = math.max(0.0, bloom - GetFrameTime() * 5.0)
	c_shake = math.max(0.0, c_shake - GetFrameTime() * 10.0)
	
	local tower = (math.max(x, 0.0) / settings.pitch_limits.ONFOOT.max) * settings.tower_fov
	speed = lerp(speed, sy, 10.0 * GetFrameTime())
	local velScale = #vel/10.0
	local speedScale = #vel/10.0
	local shake_fall = (math.sin(GetGameTimer()/100)^2) * velScale * settings.fall_shake_intensity
	local shake_move = (math.sin(GetGameTimer()/100)^2) * (speed/10.0) * settings.move_shake_intensity
	
	flinch = lerp(flinch, vector3(0.0, 0.0, 0.0), GetFrameTime() * 3.0)
	flinchtarget = lerp(flinchtarget, flinch, GetFrameTime() * 10.0)
	
	-- local sx = math.sin(GetGameTimer()/100) * velScale * 0.1
	-- local sy = math.cos(GetGameTimer()/50) * velScale * 0.1
	
	-- fov_aim = fov_def
	-- distance_aim = distance_def
	-- height_aim = height_set
	-- xoffset_aim = xoffset_def
	
	if IsPedShooting(PlayerPedId()) then
		zoom -= 0.5
		x += (math.random() * 0.5)
		z += ((math.random() * 2.0) - 1.0) * 0.25
		rotshake += 5
		bloom = math.min(bloom + 1, 10)
		c_shake = math.min(c_shake + 1, 10)
		ShakeCam(cam, "GRENADE_EXPLOSION_SHAKE", -0.1)
	end

	if IsExplosionInSphere(0xFFFFFFFF, GetEntityCoords(PlayerPedId()), 50.0) 
	and not IsExplosionInSphere(11, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(12, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(13, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(14, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(19, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(20, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(21, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(22, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(23, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(24, GetEntityCoords(PlayerPedId()), 50.0)
	and not IsExplosionInSphere(39, GetEntityCoords(PlayerPedId()), 50.0)
	and GetGameTimer() > last_explosion + 500 then
		last_explosion = GetGameTimer()

		explosion_shake += 5
		rotshake += 100
		-- ShakeCam(cam, "GRENADE_EXPLOSION_SHAKE", -0.5)
	end
	
	explosion_shake = lerp(explosion_shake, 0.0, GetFrameTime() * 4.0)
	rotshake = math.clamp(rotshake - (GetFrameTime() * 100.0), 0.0, 20.0)

	-- zoom = math.clamp(zoom - 5 * GetFrameTime(), 0, 20)
	zoom = lerp(zoom, 0.0, 5.0 * GetFrameTime())
	
	local rotX = x + 5.0 + (math.sin(GetGameTimer()/15) * explosion_shake * 0.25 * settings.explosion_shake_intensity)
	local rotY = shake_move + (math.sin(GetGameTimer()/10) * (rotshake / 10.0)) + (math.cos(GetGameTimer()/15) * explosion_shake * settings.explosion_shake_intensity)
	local rotZ = z + 180.0 + (math.cos(GetGameTimer()/10) * (rotshake / 30.0))
	
	if IsPedRagdoll(PlayerPedId()) or IsEntityInAir(PlayerPedId()) then
		shake_move = 0
	
		local fallScale = math.min(math.max(#vel - 8.0, 0.0) / 30.0, 1.0) * 0.5
	
		rotX = x + 5.0 + (math.sin(GetGameTimer()/(80/2)) * fallScale)
		rotY = (math.cos(GetGameTimer()/80) * 5.0 * fallScale)
		rotZ = z + 180.0 + (math.cos(GetGameTimer()/(80/2)) * fallScale)
	end
	
	if not IsControlPressed(0, 37) and IsControlPressed(0, 25) then
		last_aim = GetGameTimer() 
	end
	
	local hip_aim = GetGameTimer() > last_aim + 50
		
	if not IsPedRagdoll(PlayerPedId()) and ((IsPedInCover(PlayerPedId()) and IsPedAimingFromCover(PlayerPedId())) or (not IsPedInCover(PlayerPedId()) and not IsPedGoingIntoCover(PlayerPedId()) and IsAimCamActive())) and IsPedArmed(PlayerPedId(), 2 | 4) then
		if not aiming then
			if settings.reset_shoulder then
				target_shoulder = false
			end
			bloom = 1
			c_shake = 0

			-- ENTER AIMING
			if inVehicle then
				TransitionCamera(settings.cameras[current_mode].VEHICLE, settings.cameras[current_mode].AIMING_VEHICLE)
			else
				TransitionCamera(inInterior and settings.cameras[current_mode].INTERIOR or settings.cameras[current_mode].ONFOOT, hipfiring and settings.cameras[current_mode].AIMING_ONFOOT_HIP or settings.cameras[current_mode].AIMING_ONFOOT)
			end
			aiming = true
		end
		
		if not inVehicle and hipfiring ~= hip_aim then
			if hip_aim then
				TransitionCamera(settings.cameras[current_mode].AIMING_ONFOOT, settings.cameras[current_mode].AIMING_ONFOOT_HIP)
				hipfiring = true
			else
				TransitionCamera(settings.cameras[current_mode].AIMING_ONFOOT_HIP, settings.cameras[current_mode].AIMING_ONFOOT)
				hipfiring = false
			end
		end
		
		rotZ += math.sin(GetGameTimer()/1000) * settings.sway.x
		rotX += math.sin(GetGameTimer()/500) * settings.sway.y
		rotY += vel.x
		
		if GetRenderingCam() == mainCam then
			-- DisplaySniperScopeThisFrame()
			DrawCrosshair()
		end
	else

		-- EXIT AIMING
		if aiming then
			aiming = false
			if inVehicle then
				TransitionCamera(settings.cameras[current_mode].AIMING_VEHICLE, settings.cameras[current_mode].VEHICLE)
			else
				TransitionCamera(hipfiring and settings.cameras[current_mode].AIMING_ONFOOT_HIP or settings.cameras[current_mode].AIMING_ONFOOT, inInterior and settings.cameras[current_mode].INTERIOR or settings.cameras[current_mode].ONFOOT)
			end
		end
	end

	if (settings.early_vehicle_transition and IsPedGettingIntoAVehicle(PlayerPedId())) or IsPedInAnyVehicle(PlayerPedId(), true) then
		if not inVehicle then
			inVehicle = true
			if inInterior then
				TransitionCamera(settings.cameras[current_mode].INTERIOR, settings.cameras[current_mode].VEHICLE)
			else
				TransitionCamera(settings.cameras[current_mode].ONFOOT, settings.cameras[current_mode].VEHICLE)
			end
			enteringVehicle = true
		end
	else
		if inVehicle then
			inVehicle = false
			inInterior = GetInteriorFromEntity(PlayerPedId()) ~= 0
			if inInterior then
				TransitionCamera(settings.cameras[current_mode].VEHICLE, settings.cameras[current_mode].INTERIOR)
			else
				TransitionCamera(settings.cameras[current_mode].VEHICLE, settings.cameras[current_mode].ONFOOT)
			end
			exitingVehicle = true
		end
	end

	if not inVehicle then
		if (GetInteriorFromEntity(PlayerPedId()) ~= 0) then
			if not inInterior then
				inInterior = true
				TransitionCamera(settings.cameras[current_mode].ONFOOT, settings.cameras[current_mode].INTERIOR)
			end
		else
			if inInterior then
				inInterior = false
				TransitionCamera(settings.cameras[current_mode].INTERIOR, settings.cameras[current_mode].ONFOOT)
			end
		end
	end

	-- if settings.easetype == 1 then -- InOutQuad
	-- 	transitionScale = math.min(transitionScale + GetFrameTime() * settings.transition_speed, 1.0)
	-- elseif settings.easetype == 2 then -- Linear
	-- 	transitionScale = lerp(transitionScale, 1.0, GetFrameTime() * settings.transition_speed)
	-- else
	-- 	settings.easetype = 1 -- teehee
	-- end

	transitionScale = math.min(transitionScale + GetFrameTime() * settings.transition_speed, 1.0)

	-- current_fov = targetfov
	current_fov = current_cam.fov
	current_distance = current_cam.distance
	current_height = current_cam.height
	current_xoffset = current_cam.xoffset
	current_yoffset = current_cam.yoffset

	target_fov = next_cam.fov + zoom + (settings.onfoot_speed_fov * math.min(speed/15.0, 1.0)) + ((aiming or inVehicle) and 0.0 or tower)
	target_distance = next_cam.distance
	target_height = next_cam.height
	target_xoffset = next_cam.xoffset
	target_yoffset = next_cam.yoffset
	
	local veh = GetVehiclePedIsEntering(PlayerPedId())
	veh = veh ~= 0 and veh or GetVehiclePedIsIn(PlayerPedId(), true)	-- FUCK YOU!

	-- extra calculation necessary for vehicles
	if inVehicle or enteringVehicle or exitingVehicle then
		local model = GetEntityModel(veh)
		-- local min, max = GetModelDimensions(model)
		local min, max = GetVehicleSize(veh)

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
	
	if IsPedInCover(PlayerPedId()) == 1 then
		target_shoulder = IsPedInCoverFacingLeft(PlayerPedId()) == 1
	end
	x_shoulder = lerp(x_shoulder, target_shoulder and -1.0 or 1.0, GetFrameTime() * 10.0)
	
	if settings.easetype == 1 then -- InOutQuad
		fov = InOutQuad(current_fov, target_fov, transitionScale)
		distance = InOutQuad(current_distance, target_distance, transitionScale)
		height = InOutQuad(current_height, target_height, transitionScale)
		xoffset = InOutQuad(current_xoffset, target_xoffset, transitionScale)
		yoffset = InOutQuad(current_yoffset, target_yoffset, transitionScale)
	elseif settings.easetype == 2 then -- Linear
		fov = lerp(current_fov, target_fov, transitionScale)
		distance = lerp(current_distance, target_distance, transitionScale)
		height = lerp(current_height, target_height, transitionScale)
		xoffset = lerp(current_xoffset, target_xoffset, transitionScale)
		yoffset = lerp(current_yoffset, target_yoffset, transitionScale)
	else
		settings.easetype = 1 -- teehee
	end
	
	if enteringVehicle then
		local forward, right, up = GetEntityMatrix(veh)
		local cg = GetCgoffset(veh)
		
		forward *= cg.y
		right *= cg.x
		up *= cg.z
		
		pos = InOutQuad(GetEntityCoords(PlayerPedId()), GetEntityCoords(veh) + forward + right + up, transitionScale)
		heading = InOutQuad(GetEntityPhysicsHeading(PlayerPedId()), GetEntityPhysicsHeading(veh), transitionScale)
	elseif exitingVehicle then
		local forward, right, up = GetEntityMatrix(veh)
		local cg = GetCgoffset(veh)
		
		forward *= cg.y
		right *= cg.x
		up *= cg.z
		
		pos = InOutQuad(GetEntityCoords(veh) + forward + right + up, GetEntityCoords(PlayerPedId()), transitionScale)
		heading = InOutQuad(GetEntityPhysicsHeading(veh), GetEntityPhysicsHeading(PlayerPedId()), transitionScale)
	end
	
	local xoff = math.sin(math.rad(-z + (IsControlPressed(0, 26) and 180.0 or 0.0))) * math.cos(math.rad(-x)) + (math.sin(math.rad(-z-90.0)) * xoffset * x_shoulder) + (math.sin(math.rad(-heading)) * yoffset)
	local yoff = math.cos(math.rad(-z + (IsControlPressed(0, 26) and 180.0 or 0.0))) * math.cos(math.rad(-x)) + (math.cos(math.rad(-z-90.0)) * xoffset * x_shoulder) + (math.cos(math.rad(-heading)) * yoffset)
	local zoff = height + (math.sin(math.rad(-x)) * distance) -- + (shake * 0.05)
	
	local flinch_pos = vec(0.0, 0.0, flinchtarget.y * -0.025)

	if inVehicle then
		local mult = settings.gforce_mult
		pos += gforce * vec(mult.x, mult.y, mult.z)
		fov += math.clamp((#vel-10.0) / 50.0, 0.0, 1.0) * settings.vehicle_speed_fov
		rotY -= ((math.deg(math.atan2(vel.x, math.abs(vel.y))) / 90.0) * settings.angle_roll) * math.min(#vel / 50.0, 1.0)
	end
	
	camPos = vector3(
		pos.x + xoff * distance, 
		pos.y + yoff * distance, 
		pos.z + zoff
	) -- + flinch_pos
	
	camRot = vector3(
		rotX, 
		rotY, 
		rotZ) + flinchtarget
	
	SetGameplayCamRelativePitch(camRot.x, 1.0)
	SetGameplayCamRelativeHeading(camRot.z - GetEntityRotation(PlayerPedId()).z)
	-- DrawRect(0.5 + sx, 0.5 + sy, 0.01, 0.01, 255, 255, 255, 128)
	
	local ray = StartExpensiveSynchronousShapeTestLosProbe(pos.x, pos.y, pos.z, camPos.x, camPos.y, camPos.z, 1 | 2 | 16, (inVehicle or enteringVehicle or exitingVehicle) and veh or PlayerPedId(), 0)
	local _, hit, _end, _, hitEnt = GetShapeTestResult(ray)
	
	dist = math.min(#(pos - _end) / #(pos - camPos), 1.0)
	
	if dist > dist_scale then
		-- dist_scale = math.min(dist_scale + GetFrameTime() * 2.0, 1.0)
		dist_scale = lerp(dist_scale, 1.0, GetFrameTime() * 2.0)
	else
		dist_scale = lerp(dist_scale, dist, GetFrameTime() * 50.0)
	end
	
	-- if hit ~= 0 and hitEnt ~= PlayerPedId() then
		SetCamCoord(cam, lerp(pos, camPos+vec(0.0, 0.0, 1.0-dist_scale), dist_scale * 0.99))
	-- else
		-- SetCamCoord(cam, camPos)
	-- end
	
	-- SetCamCoord(cam, camPos)
	SetCamRot(cam, camRot + vec(0.0, 0.0, (IsControlPressed(0, 26) and 180.0 or 0.0)))
	SetCamFov(cam, fov)

	lastVel = world_vel
end

function debug_render()
	while true do Wait(0)
		debug_render = GlobalState.debug
		
		if debug_render then
			DebugStartFrame()
			
			DebugText("mainCam           ", mainCam)
			DebugText("camPos            ", camPos)
			DebugText("camRot            ", camRot)
			DebugText("fov               ", fov)
			DebugText("distance          ", distance)
			DebugText("height            ", height)
			DebugText("xoffset           ", xoffset)
			DebugText("yoffset           ", yoffset)
			DebugText("transitionScale   ", transitionScale)
			DebugText("current_cam       ", json.encode(current_cam))
			DebugText("next_cam          ", json.encode(next_cam))
			DebugText("previous_mode     ", previous_mode, settings.cameras[previous_mode].name)
			DebugText("current_mode      ", current_mode, settings.cameras[current_mode].name)
		end
	end
end

CreateThread(debug_render)