extends Node

enum DialogueState {
	IDLE,
	SPEAKING,
	WAITING_RESPONSE,
	CLOSED
}

signal dialogue_state_changed(old_state: DialogueState, new_state: DialogueState)
signal dialogue_new_message(new_message)

var current_dialogue_id = "none"
var current_dialogue
var current_message_index
var _current_ui_node
var current_dialogue_state = DialogueState.CLOSED

const DialogueUIScene: PackedScene = preload("res://scenes/dialogue_scene.tscn")

func _ready():
	pass

func instantiate_dialogue() -> bool:
	if (not get_node("/root/DialogueRoot")):
		var diag_node = DialogueUIScene.instantiate()
		diag_node.get_node("DialogueBox").set_visible(false)
		# TODO: This should have a high Z index to not be hidden
		get_tree().root.add_child(diag_node)
		_current_ui_node = diag_node
		return true
	else:
		Logging.log(Logging.LogType.WARNING, "Dialogue", "Attempted to instantiate dialogue when already loaded!")
		return false

func begin_dialogue(dialogue_id: String, message_id: String = "") -> bool:
	get_tree().current_scene.get_node("Dialogue/DialogueBox").set_visible(true)
	if (not (dialogue_id in Globals.loaded_dialogue)):
		Logging.log(Logging.LogType.ERROR, "Dialogue", "The requested dialogue of ID %s was not found, so dialogue cannot begin!" % Globals.scene_change_parameters)
		return false
	current_dialogue_id = dialogue_id
	current_dialogue = Globals.loaded_dialogue.get(current_dialogue_id)
	var message_index = 0
	if (message_id != ""):
		# TODO: Behavior for when a different starting message ID is chosen
		pass
	current_message_index = message_index
	return true

func iterate_dialogue(response_index: int = -1) -> bool:
	if (current_dialogue["messages"][current_message_index]["responses"]):
		# TODO: Implement responses (and add the UI for it)
		pass
	else:
		if (current_dialogue["messages"][current_message_index].get("ending")): # null will coalesce into false
			pass
	return true

func end_dialogue():
	pass
