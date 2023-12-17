extends "res://Agent.gd"

# visible trace of a shot bullet, drawn as a 2D line
var trace = load("res://BulletTrace.tscn")

# whether the survivor is currently reloading their gun
var reloading = false

# when the node is ready, we set the raycast checking for hit agents to the desired length (vision_range)
func call_on_ready():
	$ShootingRay.target_position = Vector2(0,vision_range)

# survivors bumping into agents will have no effect
func resolve_collision(collision):
	pass
	
# this function controls the actions and movement of the agents
func control(delta_modified):

	# check if we're still reloading (if the timer is still running)
	reloading = !$ReloadTimer.is_stopped()
	# by default, we assume we're not able to fire yet, but if we're not reloading and we have ammo left, then we're able to fire
	var able_to_fire = false
	if reloading == false and ammo > 0:
		able_to_fire = true
	
	# give inputs to the network; including whether we're able to fire now (the network will decide if we are going to fire)
	var inputs = [angles_forward[0], angles_forward[1], angles_side[0], angles_side[1], proximities[0], proximities[1], int(able_to_fire)]
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
	# fire if the network so decides and we're able to fire
	if outputs[3] > 0 and able_to_fire:
		fire()
	resolve_collision(collision)

# when the survivor fires a gun, see if it hits anything, start the reload timer to prevent the survivor from shooting all their ammo in an instant
func fire():

	var dist = vision_range
	ammo -= 1
	$ShootingRay.force_raycast_update()
	if $VisionRay.is_colliding():
		var collider = $ShootingRay.get_collider()
		if collider != null:
			#print(var_to_str(collider))
			var result = collider.get_shot()
			score += result
			dist = $ShootingRay.get_collision_point().length()
	reloading = true
	$ReloadTimer.start(1.0/speed_multiplier)
	
	# create a visual trace of the bullet
	var bullet_trace = trace.instantiate()
	bullet_trace.set_global_position(get_global_position())
	bullet_trace.set_rotation(get_rotation())
	bullet_trace.set_target(Vector2(0,dist))
	get_parent().add_child(bullet_trace)

# scan around the agent for other agents; this lets the agent observe others
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
	
	proximities[AGENT_TYPE.SURVIVOR] = proximity(target_position_survivors_local.length())
	proximities[AGENT_TYPE.ZOMBIE] = proximity(target_position_zombies_local.length())
	proximities[AGENT_TYPE.CORPSE] = proximity(target_position_corpses_local.length())
	
	var angle_zombies = target_position_zombies_local.angle()-PI/2
	var angle_survivors = target_position_survivors_local.angle()-PI/2
	angles_forward[AGENT_TYPE.SURVIVOR] = cos(angle_survivors)
	angles_forward[AGENT_TYPE.ZOMBIE] = cos(angle_zombies)
	angles_side[AGENT_TYPE.SURVIVOR] = sin(angle_survivors)
	angles_side[AGENT_TYPE.ZOMBIE] = sin(angle_zombies)


