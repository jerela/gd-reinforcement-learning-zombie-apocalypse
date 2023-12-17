extends "res://Agent.gd"

func control(delta_modified):
	var inputs = [angles_forward[0], angles_forward[1], angles_side[0], angles_side[1]]
	var outputs = $Network.propagate(inputs)

	# clamp forward acceleration between -0.5 and 1.0 to encourage the agents running forward rather than backward
	var forward_motion = clamp(outputs[2],-0.5,1.0)*delta_modified*100
	# limit strafe motion to tenth of what forward motion is
	var strafe_motion = outputs[1]*delta_modified*10
	var rotation_motion = outputs[0]*delta_modified*80
	# make the agent move slower if it's below max health
	if health < max_health:
		rotation_motion *= health/max_health
		forward_motion += health/max_health
	
	# rotate the agent
	rotation_degrees += rotation_motion	
	
	# apply translation
	var collision = move_and_collide(Vector2(strafe_motion,forward_motion).rotated(deg_to_rad(rotation_degrees)))
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
