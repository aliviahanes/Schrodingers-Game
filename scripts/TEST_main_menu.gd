extends Control

@onready var ContinueButtonNode = get_node("MenuHolder/ButtonHolder/Continue")

func _ready():
	ContinueButtonNode.pressed.connect(on_press)

func on_press():
	print("Dialogue pressed!")
	Dialogue.begin_dialogue("example_dialogue")
