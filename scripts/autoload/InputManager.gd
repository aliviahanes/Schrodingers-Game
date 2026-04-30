extends Node

enum InputType {
	KEYBOARD,
	XBOX,
	DECK,
	PLAYSTATION,
	NINTENDO
}

signal change_glyphs

var current_input_type = InputType.KEYBOARD

func _input(event: InputEvent):
	if (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		# TODO: Determine controller type
		current_input_type = InputType.XBOX
	elif (event is InputEventKey or event is InputEventMouseButton):
		current_input_type = InputType.KEYBOARD
	else:
		return
	change_glyphs.emit()
