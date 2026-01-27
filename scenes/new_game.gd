extends Button



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var button = Button.new()
	button.text = 'New Game'
	button.pressed.connect(_button_pressed)
	add_child(button)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _button_pressed():
	print('here')
	get_tree().change_scene_to_file("res://scenes/begin_scene.tscn")
