extends Node

enum DialogueState {
	IDLE,
	SPEAKING,
	WAITING_RESPONSE,
	CLOSED
}

signal dialogue_state_changed(old_state: DialogueState, new_state: DialogueState)
signal dialogue_new_message(new_message)
signal dialogue_event_triggered(name: String)

var current_dialogue_id = "none"
var current_dialogue
var current_message_speed = Globals.DIALOGUE_DEFAULT_SPEED
var current_message_index
var _current_ui_node
var current_dialogue_state = DialogueState.CLOSED

const DialogueUIScene: PackedScene = preload("res://scenes/dialogue_scene.tscn")

func _ready() -> void:
	instantiate_dialogue()
	Logging.log(Logging.LogType.INFO, "Dialogue", "Instantiated Dialogue UI!")

func instantiate_dialogue() -> bool:
	if (not has_node("/root/DialogueRoot")):
		var diag_node = DialogueUIScene.instantiate()
		diag_node.get_node("DialogueBox").set_visible(false)
		diag_node.get_node("DialogueBox").z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 2
		get_tree().root.add_child.call_deferred(diag_node)
		_current_ui_node = diag_node
		return true
	else:
		Logging.log(Logging.LogType.WARNING, "Dialogue", "Attempted to instantiate dialogue when already loaded!")
		return false

func begin_dialogue(dialogue_id: String, message_id: String = "") -> bool:
	if (not (dialogue_id in Globals.loaded_dialogue)):
		Logging.log(Logging.LogType.ERROR, "Dialogue", "The requested dialogue of ID %s was not found, so dialogue cannot begin!" % dialogue_id)
		return false
	get_node("/root/DialogueRoot/DialogueBox").set_visible(true)
	current_dialogue_id = dialogue_id
	current_dialogue = Globals.loaded_dialogue.get(current_dialogue_id)
	var message_index = 0
	if (message_id != ""):
		current_message_index = current_dialogue["messages"].find_custom(func(msg): return msg["message_id"] == message_id)
		if (current_message_index == -1):
			Logging.log(Logging.LogType.ERROR, "Dialogue", "The requested dialogue of ID %s requested to start at message ID %s, but it wasn't found!" % [current_dialogue_id, message_id])
	current_message_index = message_index
	dialogue_new_message.emit(current_dialogue["messages"][current_message_index])
	current_dialogue_state = DialogueState.SPEAKING
	dialogue_state_changed.emit(DialogueState.CLOSED, DialogueState.SPEAKING)
	return true

func iterate_dialogue(response_index: int = -1) -> bool:
	if (current_dialogue["messages"][current_message_index].get("ending")): # null will coalesce into false
		end_dialogue()
	else:
		Dialogue.current_message_speed = Globals.DIALOGUE_DEFAULT_SPEED
		if (response_index != -1):
			var next = current_dialogue["messages"][current_message_index].get("responses")[response_index].get("redirect")
			if (next == null):
				Logging.log(Logging.LogType.ERROR, "Dialogue", "A response in message %s under dialogue %s wants to proceed, but it has no redirect!" % [
					current_dialogue["messages"][current_message_index]["message_id"],
					current_dialogue_id
				])
				return false
			else:
				var oldindex = current_message_index
				current_message_index = current_dialogue["messages"].find_custom(func(msg): return msg["message_id"] == next)
				if (current_message_index == -1):
					Logging.log(Logging.LogType.ERROR, "Dialogue", "A response for message %s in dialogue %s wants to proceed into message ID %s, which does not exist!" % [
						current_dialogue["messages"][oldindex]["message_id"],
						current_dialogue_id,
						next
					])
					return false
		else:
			var next = current_dialogue["messages"][current_message_index].get("next")
			if (next == null):
				current_message_index += 1
			else:
				current_message_index = current_dialogue["messages"].find_custom(func(msg): return msg["message_id"] == next)
			if (current_message_index == -1):
				Logging.log(Logging.LogType.ERROR, "Dialogue", "A message in dialogue %s wants to proceed into message ID %s, which does not exist!" % [current_dialogue_id, next])
				return false
		dialogue_new_message.emit(current_dialogue["messages"][current_message_index])
		var oldstate = current_dialogue_state
		current_dialogue_state = DialogueState.SPEAKING
		dialogue_state_changed.emit(oldstate, DialogueState.SPEAKING)
	return true

func end_dialogue():
	current_dialogue_id = "none"
	current_dialogue = null
	current_message_index = null
	current_dialogue_state = DialogueState.CLOSED
	dialogue_state_changed.emit(DialogueState.IDLE, DialogueState.CLOSED)
