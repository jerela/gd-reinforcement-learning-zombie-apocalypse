# PARANNA FITNESS-EHTOJA

extends Node


var survivor_scene = load("res://Survivor.tscn")
var zombie_scene = load("res://Zombie.tscn")

@export var gui_node : NodePath

@export var survivor_spawn: Vector2 = Vector2(100,100)
@export var zombie_spawn: Vector2 = Vector2(800,100)

@export var n_survivors: int = 5
@export var n_zombies: int = 5

var spawn_separation = 200

@export var epoch_duration = 5

@export var speed_multiplier = 1.0

var epoch = 0

@export var mutation_amount = 0.05

var survivors = []
var zombies = []

var gui

var selected_weights

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn_agents()
	$Timer.start(epoch_duration)
	gui = get_node(gui_node)

func set_mutation_amount(amount):
	mutation_amount = amount
	
func set_speed_multiplier(amount):
	speed_multiplier = amount
	for agent in survivors:
		agent.set_speed_multiplier(speed_multiplier)
	for agent in zombies:
		agent.set_speed_multiplier(speed_multiplier)

func set_epoch_duration(amount):
	epoch_duration = amount

func set_spawn_separation(amount):
	spawn_separation = amount

func spawn_agents():
	for i in range(n_survivors):
		var survivor = survivor_scene.instantiate()
		survivor.set_position(survivor_spawn+Vector2(0,i*spawn_separation))
		survivor.set_speed_multiplier(speed_multiplier)
		survivors.append(survivor)
		add_child(survivor)
	
	for i in range(n_zombies):
		var zombie = zombie_scene.instantiate()
		zombie.set_position(zombie_spawn+Vector2(0,i*spawn_separation))
		zombie.set_speed_multiplier(speed_multiplier)
		zombies.append(zombie)
		add_child(zombie)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#if Input.is_action_just_pressed("next_epoch"):
	#	epoch += 1
	#	print("EPOCH " + str(epoch))
	#	evaluate_fitness()
	#	set_starting_positions()
	#	$Timer.start(epoch_duration)


func evaluate_fitness():
	
	# grant some extra score to the survivor with the greatest distance to all zombies
	var best_survivor_idx = -1
	var best_distance = 0
	var idx = 0
	# for each survivor, calculate the distance to the closest zombie
	for survivor in survivors:
		var distance_to_closest_zombie = INF
		if survivor.health > 0:
			for zombie in zombies:
				var dist = survivor.get_global_position().distance_squared_to(zombie.get_global_position())
				if dist < distance_to_closest_zombie:
					distance_to_closest_zombie = dist
			if distance_to_closest_zombie > best_distance:
				best_survivor_idx = idx
				best_distance = distance_to_closest_zombie
		idx += 1
		
	# if anyone survived, reward the most distant survivor
	if best_survivor_idx > -1:
		pass
	# if none survived, reward the one with the greatest lifetime
	else:
		var best_lifetime = 0
		idx = 0
		for survivor in survivors:
			if survivor.lifetime > best_lifetime:
				best_survivor_idx = idx
				best_lifetime = survivor.lifetime
		idx += 1
	
	survivors[best_survivor_idx].score += 5
	
	# get the network weights corresponding to the agents of the greatest fitness
	var best_weights_zombie
	var best_score_zombie = -INF
	for zombie in zombies:
		if zombie.score > best_score_zombie:
			best_weights_zombie = zombie.network.get_weights().duplicate(true)
			best_score_zombie = zombie.score

	var best_weights_survivor
	var best_score_survivor = -INF
	for survivor in survivors:
		if survivor.score > best_score_survivor:
			best_weights_survivor = survivor.network.get_weights().duplicate(true)
			best_score_survivor = survivor.score

	print("Best scoring survivor had a score of " + str(best_score_survivor))
	print("Best scoring zombie had a score of " + str(best_score_zombie))

	# set the best networks
	for zombie in zombies:
		zombie.network.set_weights(best_weights_zombie.duplicate(true))
	for survivor in survivors:
		survivor.network.set_weights(best_weights_survivor.duplicate(true))

	# mutate all but two; of the remaining two, reinitialize one and keep one
	for i in range(n_survivors-3):
		survivors[i+1].network.mutate(mutation_amount)
	survivors[n_survivors-1].network.reinitialize()
	survivors[n_survivors-2].network.reinitialize()
	for i in range(n_zombies-3):
		zombies[i+1].network.mutate(mutation_amount)
	zombies[n_zombies-1].network.reinitialize()
	zombies[n_zombies-2].network.reinitialize()

	# re-initialize the scenario
	for zombie in zombies:
		zombie.reset(1)
	for survivor in survivors:
		survivor.reset(0)
		
func set_starting_positions():
	for i in range(n_survivors):
		survivors[i].set_position(survivor_spawn+Vector2(0,i*spawn_separation))
		survivors[i].set_rotation_degrees(randf_range(-180,180))
	for i in range(n_zombies):
		zombies[i].set_position(zombie_spawn+Vector2(0,i*spawn_separation))
		zombies[i].set_rotation_degrees(randf_range(-180,180))


func _on_timer_timeout():
	epoch += 1
	print("EPOCH " + str(epoch))
	gui.set_epoch(epoch)
	evaluate_fitness()
	set_starting_positions()
	$Timer.start(epoch_duration)

func save_weights(file_name):
	var json_string = JSON.stringify(selected_weights)
	var save_weights = FileAccess.open(file_name, FileAccess.WRITE)
	save_weights.store_line(json_string)

func load_weights(file_name):
	if not FileAccess.file_exists(file_name):
		return # Error! We don't have a save to load.
	var save_weights = FileAccess.open(file_name, FileAccess.READ)
	while save_weights.get_position() < save_weights.get_length():
		var json_string = save_weights.get_line()
		
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object
		var node_data = json.get_data()
		
		print(var_to_str(node_data))
