extends Node

enum InputType {
	KEYBOARD,
	XBOX,
	DECK,
	PLAYSTATION,
	SWITCH
}

signal change_glyphs

var current_input_type := InputType.KEYBOARD
var preloaded_glyphs = {InputType.KEYBOARD: []}

func _ready():
	Input.joy_connection_changed.connect(on_joy_connection_changed)
	preloaded_glyphs.set(InputType.KEYBOARD, [
		load(Globals.INPUT_GLYPH_PATH + "kb/c.png"),
		load(Globals.INPUT_GLYPH_PATH + "kb/e.png"),
		load(Globals.INPUT_GLYPH_PATH + "kb/t.png")
	])

func _input(event: InputEvent):
	if (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		current_input_type = determine_joypad_type(Input.get_joy_name(event.device))
	elif (event is InputEventKey or event is InputEventMouseButton):
		current_input_type = InputType.KEYBOARD
	else:
		return
	change_glyphs.emit()

func on_joy_connection_changed(device, connected):
	if (connected):
		var type = determine_joypad_type(Input.get_joy_name(device))
		match type:
			InputType.XBOX:
				preloaded_glyphs.set(InputType.XBOX, [
					load(Globals.INPUT_GLYPH_PATH + "xbox/a.png"),
					load(Globals.INPUT_GLYPH_PATH + "xbox/b.png"),
					load(Globals.INPUT_GLYPH_PATH + "xbox/x.png"),
					load(Globals.INPUT_GLYPH_PATH + "xbox/y.png")
				])
			InputType.DECK:
				preloaded_glyphs.set(InputType.DECK, [
					load(Globals.INPUT_GLYPH_PATH + "deck/a.png"),
					load(Globals.INPUT_GLYPH_PATH + "deck/b.png"),
					load(Globals.INPUT_GLYPH_PATH + "deck/x.png"),
					load(Globals.INPUT_GLYPH_PATH + "deck/y.png")
				])
			InputType.PLAYSTATION:
				preloaded_glyphs.set(InputType.PLAYSTATION, [
					load(Globals.INPUT_GLYPH_PATH + "xbox/cir.png"),
					load(Globals.INPUT_GLYPH_PATH + "xbox/crs.png"),
					load(Globals.INPUT_GLYPH_PATH + "xbox/sqr.png"),
					load(Globals.INPUT_GLYPH_PATH + "xbox/tri.png")
				])
			InputType.SWITCH:
				preloaded_glyphs.set(InputType.SWITCH, [
					load(Globals.INPUT_GLYPH_PATH + "switch/a.png"),
					load(Globals.INPUT_GLYPH_PATH + "switch/b.png"),
					load(Globals.INPUT_GLYPH_PATH + "switch/x.png"),
					load(Globals.INPUT_GLYPH_PATH + "switch/y.png")
				])

func determine_joypad_type(joypad_name) -> InputType:
	joypad_name = joypad_name.to_lower()
	if (joypad_name.contains("xbox")):
		return InputType.XBOX
	elif (joypad_name.contains("steam")):
		return InputType.DECK
	elif (
		joypad_name.contains("sony") or
		joypad_name.contains("playstation") or
		joypad_name.contains("ps5") or
		joypad_name.contains("ps4") or
		joypad_name.contains("ps3")
	):
		return InputType.PLAYSTATION
	elif (
		joypad_name.contains("joy-con") or
		joypad_name.contains("switch")
	):
		return InputType.SWITCH
	else:
		return InputType.KEYBOARD
