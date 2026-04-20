extends CollisionShape2D

func _mouse_enter():
	modulate = Color(1, 1, 0.7)

func _mouse_exit():
	modulate = Color(1, 1, 1)
