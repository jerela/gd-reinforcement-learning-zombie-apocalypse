extends "res://Agent.gd"

#func _ready():
#	pass
	
#func _process

#- reinforcement learning zombies & survivors
#   - each survivor has three shots
#   - it takes three shots to kill a zombie, with each shot slowing it down
#   - it takes two shots to kill a survivor, but just one shot will slow the survivor down
#   - survivors are rated based on how long they survive
#   - zombies are rated based on how many they infect/kill and how quickly
#   - if a survivor dies with ammo, that ammo will carry on to the zombie
#   - survivors can see other survivors, zombies, and the health and ammo of themselves, other survivors and zombies
#   - zombies can see other survivors, zombies, and the health of themselves, other survivors, and zombies
#   - if a zombie kills a survivor, it will become dormant for a moment --> incentivices survivors to shoot others to slow zombies?
#   - zombies may learn to prioritize attacking wounded survivors, because they are slower?
#   - survivors have stamina that will deplete when they run and regenerate otherwise; zombies move at constant medium speed
#   - survivors walk slowly and run fast

#- sweeping raycast that reports relative angle and distance?

#- objects: survivor, zombie, corpse

#survivor network
#- 8 inputs: own stamina, own ammo, own health, distance to/angle to/health/ammo/type of nearest object
#- 5 outputs: turn amount, forward movement, sideways movement, run effort, shoot/not

#zombie network
#- 5 inputs: distance to/angle to/health of nearest survivor, distance/angle to nearest zombie
#- x outputs: turn amount, forward movement, sideways movement

func control(delta_modified):
	var inputs = [angles_forward[0], angles_forward[1], angles_side[0], angles_side[1]]
	var outputs = $Network.propagate(inputs)
	outputs[2] = clamp(outputs[2],1.0,-0.5)
	rotation_degrees += outputs[0]*delta_modified*100
	var collision = move_and_collide(Vector2(outputs[1]*delta_modified*10,outputs[2]*delta_modified*100).rotated(deg_to_rad(rotation_degrees)))
	resolve_collision(collision)

func resolve_collision(collision):
	if collision == null:
		return
		
	var collider = collision.get_collider()
		
	if collider.type == AGENT_TYPE.SURVIVOR:
		var death = collider.update_health(-1)
		# 3 points for killing someone, 1 for just damaging them
		if death:
			score += 3
			$StunTimer.start(3.0/speed_multiplier)
		else:
			score += 1
			$StunTimer.start(1.0/speed_multiplier)


func sweep_raycast(delta_modified):
	
	proximities = [0, 0, 0]
	angles_forward = [0, 0, 0]
	angles_side = [0, 0, 0]
	healths = [0, 0, 0]
	ammos = [0, 0, 0]
	
	vision_angle = -vision_fov

	var zombie_detections = []
	var survivor_detections = []
	var zombie_proximities = []
	var survivor_proximities = []
	
	var corpse_detections = []
	var corpse_proximities = []
	
	for i in range(vision_fov/raycast_sweep_increment*2):

		$VisionRay.set_rotation_degrees(vision_angle)
		#$VisionLine.rotation_degrees = vision_angle
	
		vision_angle += raycast_sweep_increment
			
		$VisionRay.force_raycast_update()
	
		
		if $VisionRay.is_colliding():
			#var current_angle = vision_angle
			var distance = get_position().distance_to($VisionRay.get_collision_point()) - $CollisionShape.shape.radius/2
			var proximity = proximity(distance)
			var collider = $VisionRay.get_collider()
			var collider_type = collider.type
			#var collider_ammo = collider.ammo
			#var collider_health = collider.health
			if collider.type == AGENT_TYPE.SURVIVOR:
				survivor_detections.append(collider.get_global_position())
				survivor_proximities.append(proximity)
			elif collider.type == AGENT_TYPE.ZOMBIE:
				zombie_detections.append(collider.get_global_position())
				zombie_proximities.append(proximity)
			elif collider_type == AGENT_TYPE.CORPSE:
				corpse_detections.append(collider.get_global_position())
				corpse_proximities.append(proximity)
			#if proximity > proximities[collider_type]:
			#	proximities[collider_type] = proximity # already normalized between 0 and 1 in the proximity function
			#	angles_forward[collider_type] = cos(deg_to_rad(current_angle))#current_angle/vision_fov # normalize between -1 and 1
			#	angles_side[collider_type] = sin(deg_to_rad(current_angle))
			#	healths[collider_type] = collider_health/collider.max_health # normalize between 0 and 1
			#	ammos[collider_type] = collider_ammo/max_ammo # normalize between 0 and 1
			#	if verbose:
			#		print("type: " + var_to_str(collider_type) + ", proximity: " + var_to_str(proximity) + ", angle: " + var_to_str(current_angle))
	

	if len(zombie_detections) > 0:
		target_position_zombies = target_position_zombies.lerp(mean_vec2(zombie_detections,zombie_proximities),delta_modified)
	if len(survivor_detections) > 0:
		target_position_survivors = target_position_survivors.lerp(mean_vec2(survivor_detections,survivor_proximities),delta_modified)
	if len(corpse_detections) > 0:
		target_position_corpses = target_position_corpses.lerp(mean_vec2(corpse_detections,corpse_proximities),delta_modified)
	
	var target_position_zombies_local = target_position_zombies.rotated(deg_to_rad(-rotation_degrees))
	var target_position_survivors_local = target_position_survivors.rotated(deg_to_rad(-rotation_degrees))
	var target_position_corpses_local = target_position_corpses.rotated(deg_to_rad(-rotation_degrees))

	$LineToZombies.points[1] = target_position_zombies_local
	$LineToSurvivors.points[1] = target_position_survivors_local
	
	var angle_zombies = target_position_zombies_local.angle()-PI/2
	var angle_survivors = target_position_survivors_local.angle()-PI/2
	angles_forward[AGENT_TYPE.SURVIVOR] = cos(angle_survivors)
	angles_forward[AGENT_TYPE.ZOMBIE] = cos(angle_zombies)
	angles_side[AGENT_TYPE.SURVIVOR] = sin(angle_survivors)
	angles_side[AGENT_TYPE.ZOMBIE] = sin(angle_zombies)
