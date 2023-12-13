extends CanvasLayer

@export var trainer_node: NodePath
var trainer

var spinboxes = []

# Called when the node enters the scene tree for the first time.
func _ready():
	findByType(self, "SpinBox", spinboxes)
	trainer = get_node(trainer_node)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_epoch(epoch):
	$Control/PanelContainer/VBoxContainer/InfoPanel/VBoxContainer/EpochLabel.text = "EPOCH " + str(epoch)



func _on_mutation_box_value_changed(value):
	trainer.set_mutation_amount(value)
	release_foci()


func _on_speed_box_value_changed(value):
	trainer.set_speed_multiplier(value)
	release_foci()


func _on_epoch_duration_value_changed(value):
	trainer.set_epoch_duration(value)
	release_foci()

func _on_spawn_separation_value_changed(value):
	trainer.set_spawn_separation(value)
	release_foci()

func release_foci():
	for spinbox in spinboxes:	
		spinbox.get_line_edit().release_focus()

func findByType(node: Node, className : String, result : Array) -> void:
	if node.is_class(className) :
		result.push_back(node)
	for child in node.get_children():
		findByType(child, className, result)


func set_agent_details(arr_in):
	$Control/PanelContainer/VBoxContainer/AgentPanel/VBoxContainer/AgentTypeLabel.text = "Type: " + str(arr_in[0])
	$Control/PanelContainer/VBoxContainer/AgentPanel/VBoxContainer/AgentHealthLabel.text = "Health: " + str(arr_in[1]) + "/" + str(arr_in[2])


func _on_save_button_pressed():
	trainer.save_weights($Control/PanelContainer/VBoxContainer/AgentPanel/VBoxContainer/VBoxContainer/FileNameLine.text)


func _on_load_button_pressed():
	trainer.load_weights($Control/PanelContainer/VBoxContainer/AgentPanel/VBoxContainer/VBoxContainer/FileNameLine.text)
