extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var direction = Vector2()
	if Input.is_action_pressed("pan_down"):
		direction.y = 1
	elif Input.is_action_pressed("pan_up"):
		direction.y = -1
	if Input.is_action_pressed("pan_left"):
		direction.x = -1
	elif Input.is_action_pressed("pan_right"):
		direction.x = 1
	
	set_position(get_position()+1000*direction*delta/zoom.x)

	if Input.is_action_pressed("zoom_in"):
		zoom += Vector2(1,1)*0.25*delta
	elif Input.is_action_pressed("zoom_out"):
		zoom -= Vector2(1,1)*0.25*delta

	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
