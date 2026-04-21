extends Node

@onready var DialogueBoxNode = get_node("DialogueBox")
@onready var ClickShieldNode = get_node("ClickShield")
@onready var BoxBackgroundNode = get_node("DialogueBox/BoxBackground")
@onready var MessageContentNode = get_node("DialogueBox/BoxBackground/Message/MessageContent")
@onready var Character1LabelNode = get_node("DialogueBox/BoxBackground/Message/Character1Label")
@onready var Character2LabelNode = get_node("DialogueBox/BoxBackground/Message/Character2Label")
@onready var Character1TextureNode = get_node("DialogueBox/Character1Texture")
@onready var Character2TextureNode = get_node("DialogueBox/Character2Texture")
@onready var ResponseContainerNode = get_node("DialogueBox/BoxBackground/Message/ResponseContainer")
@onready var ResponseGridNode = get_node("DialogueBox/BoxBackground/Message/ResponseContainer/ResponseGrid")
@onready var ResponseButtonTemplate = get_node("DialogueBox/BoxBackground/Message/ResponseContainer/ResponseGrid/ResponseTemplate")

var message_tag_regex = RegEx.new()
var message_tag_pattern = "\\[(?<tag>speed|pause|event)=(?<value>[^\\]]+)\\]" # Unescape backslashes if you need to test pattern
var current_message_tags = {}

func _ready() -> void:
	message_tag_regex.compile(message_tag_pattern)
	Dialogue.dialogue_new_message.connect(on_dialogue_new_message)
	Dialogue.dialogue_state_changed.connect(on_dialogue_state_changed)
	DialogueBoxNode.gui_input.connect(on_box_input)
	BoxBackgroundNode.set_focus_mode(Control.FocusMode.FOCUS_ALL)

func animate_message():
	MessageContentNode.visible_characters = 0
	Dialogue.current_dialogue_state = Dialogue.DialogueState.SPEAKING
	var text_length = len(MessageContentNode.get_text())
	for i in range((text_length + 1)):
		if (Dialogue.current_dialogue_state == Dialogue.DialogueState.IDLE):
			MessageContentNode.visible_characters = -1
			current_message_tags = {}
			break
		else:
			MessageContentNode.visible_characters = i
			if (current_message_tags.has(i)):
				for tag in current_message_tags[i]:
					match tag["tag"]:
						"speed":
							if (tag["value"].is_valid_int()):
								Dialogue.current_message_speed = int(tag["value"])
							else:
								Logging.log(Logging.LogType.WARNING, "Dialogue UI", "Message %s in dialogue %s wanted to set the message speed, but it didn't provide a valid integer!" % [
									Dialogue.current_dialogue["messages"][Dialogue.current_message_index]["message_id"],
									Dialogue.current_dialogue_id
								])
						"pause":
							if (tag["value"].is_valid_float()):
								await get_tree().create_timer(float(tag["value"])).timeout
							else:
								Logging.log(Logging.LogType.WARNING, "Dialogue UI", "Message %s in dialogue %s wanted to pause the message for some time, but it didn't provide a valid float!" % [
									Dialogue.current_dialogue["messages"][Dialogue.current_message_index]["message_id"],
									Dialogue.current_dialogue_id
								])
						"event":
							Dialogue.dialogue_event_triggered.emit(tag["value"])
						_:
							Logging.log(Logging.LogType.WARNING, "Dialogue UI", "Message %s in dialogue %s wanted to use the tag %s, but it isn't recognized!" % [
								Dialogue.current_dialogue["messages"][Dialogue.current_message_index]["message_id"],
								Dialogue.current_dialogue_id,
								tag["tag"]
							])
			if (i < text_length):
				await get_tree().create_timer(1.0 / Dialogue.current_message_speed).timeout
	Dialogue.current_dialogue_state = Dialogue.DialogueState.IDLE
	Dialogue.dialogue_state_changed.emit(Dialogue.DialogueState.SPEAKING, Dialogue.DialogueState.IDLE)

func on_dialogue_state_changed(old_state: Dialogue.DialogueState, new_state: Dialogue.DialogueState):
	match (old_state):
		Dialogue.DialogueState.CLOSED:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				ClickShieldNode.mouse_filter = Control.MOUSE_FILTER_STOP
				MessageContentNode.set_visible_characters(0)
				MessageContentNode.set_visible(true)
				ResponseContainerNode.set_visible(false)
				DialogueBoxNode.set_visible(true)
				animate_message()
			else:
				Logging.log(Logging.LogType.WARNING, "Dialogue UI", "Dialogue changed from closed to a non-speaking state; this behavior is not supported!")
		Dialogue.DialogueState.IDLE:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				MessageContentNode.set_visible_characters(0)
				MessageContentNode.set_visible(true)
				ResponseContainerNode.set_visible(false)
				animate_message()
			elif (new_state == Dialogue.DialogueState.WAITING_RESPONSE):
				MessageContentNode.set_visible(false)
				ResponseContainerNode.set_visible(true)
			elif (new_state == Dialogue.DialogueState.CLOSED):
				DialogueBoxNode.set_visible(false)
				ClickShieldNode.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Dialogue.DialogueState.WAITING_RESPONSE:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				ResponseContainerNode.set_visible(false)
				MessageContentNode.set_visible_characters(0)
				MessageContentNode.set_visible(true)
				animate_message()
		_:
			pass

func on_dialogue_new_message(message):
	current_message_tags = {}
	MessageContentNode.set_meta("original_content", message.get("content"))
	MessageContentNode.set_text(process_custom_tags(message.get("content")))
	var char1 = Globals.loaded_speakers.get(message.get("participant1"), message.get("speaker"))
	if (char1 == null):
		Logging.log(Logging.LogType.ERROR, "Dialogue UI", "Couldn't find a character 1 in message %s in dialogue %s" % [
			message["message_id"],
			Dialogue.current_dialogue_id
		])
		return false
	Character1LabelNode.text = char1.get("display", "DISPLAY_NOT_FOUND")
	var char2 = Globals.loaded_speakers.get(message.get("participant2", "blank"), "blank")
	Character2LabelNode.text = char2.get("display", "DISPLAY_NOT_FOUND")
	# TODO: Determine who is speaking and unhighlight the non-speaker
	var mood = message.get("participant1_mood", 0)
	Character1TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_%d.png" % [
		message.get("participant1", message.get("speaker")),
		message.get("participant1", message.get("speaker")),
		mood
	])
	# This is such a terrible repetition, but I am just him :>
	mood = message.get("participant2_mood", 0)
	Character2TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_%d.png" % [
		message.get("participant2", "blank"),
		message.get("participant2", "blank"),
		mood
	])

func on_box_input(ev: InputEvent):
	if (ev is InputEventMouseButton):
		if (
			ev.button_index == MouseButton.MOUSE_BUTTON_LEFT and
			ev.pressed and
			Rect2(Vector2.ZERO, DialogueBoxNode.size).has_point(DialogueBoxNode.get_local_mouse_position())
		):
			if (Dialogue.current_dialogue_state == Dialogue.DialogueState.SPEAKING):
				pass # finish talking
			elif (Dialogue.current_dialogue_state == Dialogue.DialogueState.IDLE):
				var responses = Dialogue.current_dialogue["messages"][Dialogue.current_message_index].get("responses");
				if (responses):
					for i in range(len(responses)):
						var resp = ResponseButtonTemplate.duplicate()
						resp.set_visible(true)
						resp.text = responses[i].get("content", "RESPONSE_NOT_FOUND")
						resp.pressed.connect(func(): 
							Dialogue.iterate_dialogue(i)
							clear_responses()
						)
						ResponseGridNode.add_child(resp)
					var oldstate = Dialogue.current_dialogue_state
					Dialogue.current_dialogue_state = Dialogue.DialogueState.WAITING_RESPONSE
					Dialogue.dialogue_state_changed.emit(oldstate, Dialogue.current_dialogue_state)
				else:
					Dialogue.iterate_dialogue()

func clear_responses():
	for item in (ResponseGridNode.get_children()):
		if (item.name != "ResponseTemplate"):
			item.queue_free()

func process_custom_tags(content: String) -> String:
	var offset = 0
	var matches = message_tag_regex.search_all(content)
	for mat in matches:
		var final_index = mat.get_start() - offset
		if not current_message_tags.has(final_index):
			current_message_tags.set(final_index, [])
		current_message_tags[final_index].append({"tag": mat.get_string("tag"), "value": mat.get_string("value")})
		offset += (mat.get_end() - mat.get_start())
	return message_tag_regex.sub(content, "", true)
