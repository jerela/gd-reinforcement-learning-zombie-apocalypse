extends Node

@export var input_nodes = 1
@export var hidden_nodes = 1
@export var output_nodes = 1

var weights_input_hidden = []
var weights_hidden_output = []
var bias_hidden = []
var bias_output = []

# Called when the node enters the scene tree for the first time.
func _ready():
	init_weights()

func reinitialize():
	for i in range(len(weights_input_hidden)):
		weights_input_hidden[i] = randf_range(-1.0,1.0)
	
	for i in range(len(weights_hidden_output)):
		weights_hidden_output[i] = randf_range(-1.0,1.0)
		
	for i in range(len(bias_hidden)):
		bias_hidden[i] = randf_range(-1.0,1.0)
		
	for i in range(len(bias_output)):
		bias_output[i] = randf_range(-1.0,1.0)

func init_weights():
	for i in range(input_nodes):
		for j in range(hidden_nodes):
			weights_input_hidden.append(randf_range(-1.0,1.0))
	
	for i in range(hidden_nodes):
		for j in range(output_nodes):
			weights_hidden_output.append(randf_range(-1.0,1.0))
		bias_hidden.append(randf_range(-1.0,1.0))
		
	for i in range(output_nodes):
		bias_output.append(randf_range(-1.0,1.0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func mutate(amount):
	
	# 50% to update any weight
	# 1% chance to zero a weight

	var rnd = 0

	for w in range(len(weights_input_hidden)):
		rnd = randi_range(1,100)
		if rnd == 1:
			weights_input_hidden[w] = 0
		elif rnd > 50:
			weights_input_hidden[w] = clamp(weights_input_hidden[w]+randf_range(-amount,amount),-1.0,1.0)
		
	for w in range(len(weights_hidden_output)):
		rnd = randi_range(1,100)
		if rnd == 1:
			weights_hidden_output[w] = 0
		elif rnd > 50:
			weights_hidden_output[w] += clamp(weights_hidden_output[w]+randf_range(-amount,amount),-1.0,1.0)
		
	for i in range(hidden_nodes):
		rnd = randi_range(1,100)
		if rnd == 1:
			bias_hidden[i] = 0
		elif rnd > 50:
			bias_hidden[i] = clamp(bias_hidden[i]+randf_range(-amount,amount),-1.0,1.0)
		
	for i in range(output_nodes):
		rnd = randi_range(1,100)
		if rnd == 1:
			bias_output[i] = 0
		elif rnd > 50:
			bias_output[i] = clamp(bias_output[i]+randf_range(-amount,amount),-1.0,1.0)

func propagate(inputs):
	
	# hidden layer output
	var hidden_outputs = []
	for j in range(hidden_nodes):
		var sum = 0
		for i in range(input_nodes):
			sum += weights_input_hidden[j*input_nodes+i]*inputs[i]
		hidden_outputs.append(activate(sum+bias_hidden[j]))
	
	# output layer output
	var final_outputs = []
	for j in range(output_nodes):
		var sum = 0
		for i in range(hidden_nodes):
			sum += weights_hidden_output[j*hidden_nodes+i]*hidden_outputs[i]
		final_outputs.append(activate(sum+bias_output[j]))

	return final_outputs

func activate(input):
	return tanh(input)

func logistic(x):
	return 1/(1+exp(-x))
	
func print_weights(): # INCLUDE BIAS
	print("Weights between input and hidden: " + var_to_str(weights_input_hidden))
	print("Weights between hidden and output: " + var_to_str(weights_hidden_output))
	
func get_weights():
	return [weights_input_hidden, weights_hidden_output, bias_hidden, bias_output]
	
func set_weights(weights_in):
	weights_input_hidden = weights_in[0]
	weights_hidden_output = weights_in[1]
	bias_hidden = weights_in[2]
	bias_output = weights_in[3]
