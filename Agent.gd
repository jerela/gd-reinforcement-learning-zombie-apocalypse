extends CharacterBody2D



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



# there are three object types: survivor, zombie, and corpse (dead survivor, essentially just loot for survivors)
enum AGENT_TYPE {SURVIVOR, ZOMBIE, CORPSE}

var vision_angle = 0

# how many angles the raycast sweeps each iteration
@export var raycast_sweep_increment = 5
# object type of this agent
@export var type: AGENT_TYPE
# how many ammo this agent has: survivors can use it, zombies can still be looted after death
@export var max_ammo = 5
# how much health this agent has: 2 if survivor, 3 if zombie
@export var max_health = 2
# how many pixels away the vision raycast reaches
@export var vision_range = 1600
# what is the field of view of the vision raycast in one direction (e.g., 90 is a 180 degree FOV)
@export var vision_fov = 180
# whether this agent should print debug info to output log
@export var verbose: bool = false

@export var base_speed = 1

var health = max_health
var ammo = 3

var lifetime = 0

var proximity_survivor = 0
var proximity_zombie = 0
var proximity_corpse = 0
var angle_survivor = 0
var angle_zombie = 0
var angle_corpse = 0
var health_survivor = 0
var health_zombie = 0
var health_corpse = 0
var ammo_survivor = 0
var ammo_zombie = 0
var ammo_corpse = 0

var proximities = [proximity_survivor, proximity_zombie, proximity_corpse]
var angles_forward = [angle_survivor, angle_zombie, angle_corpse]
var angles_side = [0, 0, 0]
var healths = [health_survivor, health_zombie, health_corpse]
var ammos = [ammo_survivor, ammo_zombie, ammo_corpse]

var score = 0

@onready var network = $Network

var speed_multiplier = 1.0

var target_position_survivors = Vector2()
var target_position_zombies = Vector2()
var target_position_corpses = Vector2()

func set_speed_multiplier(amount):
	speed_multiplier = amount

# Called when the node enters the scene tree for the first time.
func _ready():
	# set vision ray and vision line lengths
	$VisionRay.target_position = Vector2(0,vision_range)
	#$VisionLine.points[1] = Vector2(0,vision_range)
	update_shader_param()

	call_on_ready()
	#$Network.mutate(0.10)
	#$Network.print_weights()

func call_on_ready():
	pass

func update_shader_param():
	$Sprite2D.material.set_shader_parameter("type",type)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# if survivor or zombie is dead (corpse), don't do anything
	if type==AGENT_TYPE.CORPSE:
		return
	
	# modify speed according to speed multiplier
	var delta_modified = delta*speed_multiplier
	
	# count lifetime
	lifetime += delta_modified
	
	# let the agent act is freeze timer is not running
	if $StunTimer.is_stopped():
		# sweep a raycast over vision field of view and update variables ammo, health, proximities, angles, healths, ammos
		sweep_raycast(delta_modified)
		control(delta_modified)
	
func proximity(distance):
	# scale such that a distance equal to maximum vision range is close to zero proximity (0.0025)
	return exp(-distance*7/vision_range)

func control(delta_modified):
	var inputs = [angles_forward[0], angles_forward[1], angles_side[0], angles_side[1], proximities[0], proximities[1]]
	var outputs = $Network.propagate(inputs)
	outputs[2] = clamp(outputs[2],1.0,-0.5)
	rotation_degrees += outputs[0]*delta_modified*100
	var collision = move_and_collide(Vector2(outputs[1]*delta_modified*10,outputs[2]*delta_modified*100).rotated(deg_to_rad(rotation_degrees)))
	resolve_collision(collision)


func resolve_collision(collision):
	pass
	

func update_health(amount):
	health += amount
	if health <= 0:
		type = AGENT_TYPE.CORPSE
		update_shader_param()
		score -= 10
		set_collision_layer_value(1,false)
		#$CollisionShape.disabled = true
		#print("i am become corpse")
		return true
	else:
		score -= 1
		return false


func sweep_raycast(delta_modified):
	pass
		
func mean_vec2(locs,weights):
	var n = len(locs)
	var weighted_avg = Vector2()
	for i in range(n):
		weighted_avg += weights[i]*locs[i]
	return weighted_avg/weights.reduce(sum)-get_global_position()

func sum(arg1,arg2):
	return arg1+arg2
	
func reset(type_in):
	health = max_health
	ammo = 3
	lifetime = 0
	score = 0
	type = type_in
	target_position_survivors = Vector2(0,0)
	target_position_zombies = Vector2(0,0)
	target_position_corpses = Vector2(0,0)
	$StunTimer.stop()
	#$CollisionShape.disabled = false
	set_collision_layer_value(1,true)
	set_rotation_degrees(randf_range(-180,180))
	update_shader_param()

# if the agent is clicked, highlight it and send its details to GUI
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		# iterate through all other agents and make sure they're deselected in terms of highlight
		for agent in get_parent().survivors:
			agent.get_node("Sprite2D").material.set_shader_parameter("selected",false)
		for agent in get_parent().zombies:
			agent.get_node("Sprite2D").material.set_shader_parameter("selected",false)
		# highlight this agent
		$Sprite2D.material.set_shader_parameter("selected",true)
		# send agent info to GUI
		get_parent().gui.set_agent_details([type, health, max_health])
		get_parent().selected_weights = network.get_weights()

