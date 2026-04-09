extends Node

@onready var DialogueBoxNode = get_node("DialogueBox")
@onready var MessageContentNode = get_node("DialogueBox/BoxBackground/Message/MessageContent")
@onready var Character1LabelNode = get_node("DialogueBox/BoxBackground/Message/Character1Label")
@onready var Character2LabelNode = get_node("DialogueBox/BoxBackground/Message/Character2Label")
@onready var Character1TextureNode = get_node("DialogueBox/Character1Texture")
@onready var Character2TextureNode = get_node("DialogueBox/Character2Texture")

signal dialogue_ui_done_speaking
signal dialogue_ui_response(response_index: int)

func _ready() -> void:
	pass

func on_dialogue_state_changed(old_state: Dialogue.DialogueState, new_state: Dialogue.DialogueState):
	match (old_state):
		Dialogue.DialogueState.CLOSED:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				# TODO: Show and start animating
				DialogueBoxNode.visible = true
				dialogue_ui_done_speaking.emit()
			else:
				Logging.log(Logging.LogType.WARNING, "Dialogue UI", "Dialogue changed from closed to a non-speaking state; this behavior is not supported!")
		_:
			# TODO: Check other cases if necessary (RESPONSES)
			pass

func on_dialogue_new_message(message):
	MessageContentNode.text = message.get("content")
	Character1LabelNode.text = Globals.loaded_speakers.get(
		message.get("participant1")
		if message.get("participant1") != null
		else message.get("speaker")
	)
	Character2LabelNode.text = Globals.loaded_speakers.get(
		message.get("participant2")
		if message.get("participant2") != null
		else ""
	)
	# TODO: Determine who is speaking and unhighlight the non-speaker
	var mood = message.get("participant1_mood")
	mood = mood if mood != null else 0 # mood evaluates to null if not present, so this sets to 0
	Character1TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_%d.png" % [
		message.get("participant1")
			if message.get("participant1") != null
			else message.get("speaker"),
		message.get("participant1")
			if message.get("participant1") != null
			else message.get("speaker"),
		mood
	])
	# This is such a terrible repetition, but I am just him :>
	mood = message.get("participant2_mood")
	mood = mood if mood != null else 0 # mood evaluates to null if not present, so this sets to 0
	Character2TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_%d.png" % [
		message.get("participant2")
			if message.get("participant2") != null
			else "blank",
		message.get("participant2")
			if message.get("participant2") != null
			else "blank",
		mood
	])
