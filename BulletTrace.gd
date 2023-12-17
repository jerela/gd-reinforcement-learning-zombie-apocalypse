extends Node2D

func _on_life_timer_timeout():
	queue_free()

func set_target(vec):
	$Line2D.points[1] = vec
