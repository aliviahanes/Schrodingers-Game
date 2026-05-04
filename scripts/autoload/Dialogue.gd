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

var current_dialogue_id := "none"
var current_dialogue
var current_message_speed := Globals.DIALOGUE_DEFAULT_SPEED
var current_message_index: int
var _current_ui_node: Node
var current_dialogue_state := DialogueState.CLOSED
var message_history = []

const DialogueUIScene: PackedScene = preload("res://scenes/dialogue_scene.tscn")

func _ready():
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
	message_history.append(current_dialogue["messages"][current_message_index])
	dialogue_new_message.emit(current_dialogue["messages"][current_message_index])
	current_dialogue_state = DialogueState.SPEAKING
	dialogue_state_changed.emit(DialogueState.CLOSED, DialogueState.SPEAKING)
	Game.push_game_state(Game.GameState.DIALOGUE)
	return true

func iterate_dialogue(response_index: int = -1) -> bool:
	if (current_dialogue["messages"][current_message_index].get("ending")): # null will coalesce into false
		end_dialogue()
	else:
		current_message_speed = Globals.DIALOGUE_DEFAULT_SPEED
		if (response_index != -1):
			var event = current_dialogue["messages"][current_message_index].get("responses")[response_index].get("event")
			if (event != null):
				end_dialogue()
				dialogue_event_triggered.emit(event)
				return true
			else:
				var next = current_dialogue["messages"][current_message_index].get("responses")[response_index].get("redirect")
				var oldindex = current_message_index
				if (next == null):
					Logging.log(Logging.LogType.ERROR, "Dialogue", "A response in message %s under dialogue %s wants to proceed, but it has no redirect!" % [
						current_dialogue["messages"][current_message_index]["message_id"],
						current_dialogue_id
					])
					return false
				else:
					current_message_index = current_dialogue["messages"].find_custom(func(msg): return msg["message_id"] == next)
					if (current_message_index == -1):
						Logging.log(Logging.LogType.ERROR, "Dialogue", "A response for message %s in dialogue %s wants to proceed into message ID %s, which does not exist!" % [
							current_dialogue["messages"][oldindex]["message_id"],
							current_dialogue_id,
							next
						])
						return false
				message_history.append({"response_content": current_dialogue["messages"][oldindex].get("responses")[response_index].get("content")})
		else:
			var next = current_dialogue["messages"][current_message_index].get("next")
			if (next == null):
				current_message_index += 1
			else:
				current_message_index = current_dialogue["messages"].find_custom(func(msg): return msg["message_id"] == next)
			if (current_message_index == -1):
				Logging.log(Logging.LogType.ERROR, "Dialogue", "A message in dialogue %s wants to proceed into message ID %s, which does not exist!" % [current_dialogue_id, next])
				return false
			if (len(current_dialogue["messages"]) > current_message_index):
				message_history.append(current_dialogue["messages"][current_message_index])
		if (len(current_dialogue["messages"]) > current_message_index):
			dialogue_new_message.emit(current_dialogue["messages"][current_message_index])
			var oldstate = current_dialogue_state
			current_dialogue_state = DialogueState.SPEAKING
			dialogue_state_changed.emit(oldstate, DialogueState.SPEAKING)
		else:
			end_dialogue()
	return true

func end_dialogue() -> void:
	current_dialogue_id = "none"
	current_dialogue = null
	current_message_index = -1
	var oldstate = current_dialogue_state
	current_dialogue_state = DialogueState.CLOSED
	message_history.clear()
	dialogue_state_changed.emit(oldstate, DialogueState.CLOSED)
	Game.pop_game_state()
