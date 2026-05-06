extends Control

@onready var ContinueButtonNode: Button = get_node("MenuHolder/ButtonHolder/Continue")
@onready var NewGameButtonNode: Button = get_node("MenuHolder/ButtonHolder/NewGame")
@onready var LoadGameButtonNode: Button = get_node("MenuHolder/ButtonHolder/LoadGame")
@onready var SettingsButtonNode: Button = get_node("MenuHolder/ButtonHolder/Settings")
@onready var QuitButtonNode: Button = get_node("MenuHolder/ButtonHolder/Quit")

func _ready():
	ContinueButtonNode.pressed.connect(on_continue_press)
	NewGameButtonNode.pressed.connect(on_newgame_press)
	QuitButtonNode.pressed.connect(on_quit_press)

func _unhandled_input(event: InputEvent):
	if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		if (get_viewport().gui_get_focus_owner() == null):
			ContinueButtonNode.grab_focus()

func on_continue_press():
	# TODO: This is testing code for dialogue! Remove it!!
	Dialogue.begin_dialogue("example_dialogue")

func on_newgame_press():
	self.queue_free() # This won't actually happen until after this function finishes executing
	get_tree().get_current_scene().add_child(preload("res://scenes/levels/puzzle_scene.tscn").instantiate())
	# TODO: Animate starting a new game (with loading screen?)

func on_loadgame_press():
	pass

func on_settings_press():
	pass

func on_quit_press():
	get_tree().quit()
