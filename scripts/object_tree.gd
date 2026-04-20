extends Area2D

func _ready():
	input_pickable = true
	connect("input_event", _on_input_event)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("CLICKED:", name)
		queue_free()

func _on_mouse_entered():
	scale = Vector2(1.05, 1.05)

func _on_mouse_exited():
	scale = Vector2(1, 1)
