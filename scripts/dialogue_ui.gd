extends Node

@onready var ClickShieldNode = get_node("ClickShield")

@onready var DialogueBoxNode = get_node("DialogueBox")
@onready var DialogueMessageContentNode = get_node("DialogueBox/BoxBackground/Message/MessageContent")
@onready var DialogueCharacter1LabelNode = get_node("DialogueBox/BoxBackground/Message/Character1Label")
@onready var DialogueCharacter2LabelNode = get_node("DialogueBox/BoxBackground/Message/Character2Label")
@onready var DialogueCharacter1TextureNode = get_node("DialogueBox/Character1Texture")
@onready var DialogueCharacter2TextureNode = get_node("DialogueBox/Character2Texture")
@onready var DialogueResponseContainerNode = get_node("DialogueBox/BoxBackground/Message/ResponseContainer")
@onready var DialogueResponseGridNode = get_node("DialogueBox/BoxBackground/Message/ResponseContainer/ResponseGrid")
@onready var DialogueResponseButtonTemplate = get_node("DialogueBox/BoxBackground/Message/ResponseContainer/ResponseGrid/ResponseTemplate")
@onready var DialogueHistoryButtonNode = get_node("DialogueBox/BoxBackground/Message/HistoryButton")
@onready var DialogueAutoButtonNode = get_node("DialogueBox/BoxBackground/Message/AutoButton")

@onready var HistoryBoxNode = get_node("HistoryBox")
@onready var HistoryMessageContainerNode = get_node("HistoryBox/BoxBackground/ScrollContainer/MessageContainer")
@onready var HistoryMessageTemplateNode = get_node("HistoryBox/BoxBackground/ScrollContainer/MessageContainer/MessageTemplate")
@onready var HistoryCloseButtonNode = get_node("HistoryBox/BoxBackground/CloseButton")

var message_tag_regex = RegEx.new()
var message_tag_pattern = "\\[(?<tag>speed|pause|event)=(?<value>[^\\]]+)\\]" # Unescape backslashes if you need to test pattern
var current_message_tags = {}

func _ready() -> void:
	message_tag_regex.compile(message_tag_pattern)
	Dialogue.dialogue_new_message.connect(on_dialogue_new_message)
	Dialogue.dialogue_state_changed.connect(on_dialogue_state_changed)
	DialogueBoxNode.gui_input.connect(on_box_input)
	DialogueHistoryButtonNode.pressed.connect(on_history_press)
	HistoryCloseButtonNode.pressed.connect(on_history_close_press)
	DialogueAutoButtonNode.pressed.connect(on_auto_press)

func animate_message():
	DialogueMessageContentNode.visible_characters = 0
	Dialogue.current_dialogue_state = Dialogue.DialogueState.SPEAKING
	var text_length = len(DialogueMessageContentNode.get_text())
	for i in range((text_length + 1)):
		if (Dialogue.current_dialogue_state == Dialogue.DialogueState.IDLE):
			DialogueMessageContentNode.visible_characters = -1
			current_message_tags = {}
			break
		else:
			DialogueMessageContentNode.visible_characters = i
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
				DialogueMessageContentNode.set_visible_characters(0)
				DialogueMessageContentNode.set_visible(true)
				DialogueResponseContainerNode.set_visible(false)
				DialogueBoxNode.set_visible(true)
				animate_message()
			else:
				Logging.log(Logging.LogType.WARNING, "Dialogue UI", "Dialogue changed from closed to a non-speaking state; this behavior is not supported!")
		Dialogue.DialogueState.IDLE:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				DialogueMessageContentNode.set_visible_characters(0)
				DialogueMessageContentNode.set_visible(true)
				DialogueResponseContainerNode.set_visible(false)
				animate_message()
			elif (new_state == Dialogue.DialogueState.WAITING_RESPONSE):
				DialogueMessageContentNode.set_visible(false)
				DialogueResponseContainerNode.set_visible(true)
			elif (new_state == Dialogue.DialogueState.CLOSED):
				DialogueBoxNode.set_visible(false)
				ClickShieldNode.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Dialogue.DialogueState.WAITING_RESPONSE:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				DialogueResponseContainerNode.set_visible(false)
				DialogueMessageContentNode.set_visible_characters(0)
				DialogueMessageContentNode.set_visible(true)
				animate_message()
		_:
			pass

func on_dialogue_new_message(message):
	current_message_tags = {}
	DialogueMessageContentNode.set_meta("original_content", message.get("content"))
	DialogueMessageContentNode.set_text(process_custom_tags(message.get("content")))
	var char1 = Globals.loaded_speakers.get(message.get("participant1", message.get("speaker")))
	if (char1 == null):
		Logging.log(Logging.LogType.ERROR, "Dialogue UI", "Couldn't find a character 1 in message %s in dialogue %s" % [
			message["message_id"],
			Dialogue.current_dialogue_id
		])
		return false
	DialogueCharacter1LabelNode.text = char1.get("display", "DISPLAY_NOT_FOUND")
	var char2 = Globals.loaded_speakers.get(message.get("participant2", "blank"), "blank")
	DialogueCharacter2LabelNode.text = char2.get("display", "DISPLAY_NOT_FOUND")
	# TODO: Determine who is speaking and unhighlight the non-speaker
	var mood = message.get("participant1_mood", 0)
	DialogueCharacter1TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_%d.png" % [
		message.get("participant1", message.get("speaker")),
		message.get("participant1", message.get("speaker")),
		mood
	])
	# This is such a terrible repetition, but I am just him :>
	mood = message.get("participant2_mood", 0)
	DialogueCharacter2TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_%d.png" % [
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
						var resp = DialogueResponseButtonTemplate.duplicate()
						resp.set_visible(true)
						resp.text = responses[i].get("content", "RESPONSE_NOT_FOUND")
						resp.pressed.connect(func(): 
							Dialogue.iterate_dialogue(i)
							clear_responses()
						)
						DialogueResponseGridNode.add_child(resp)
					var oldstate = Dialogue.current_dialogue_state
					Dialogue.current_dialogue_state = Dialogue.DialogueState.WAITING_RESPONSE
					Dialogue.dialogue_state_changed.emit(oldstate, Dialogue.current_dialogue_state)
				else:
					Dialogue.iterate_dialogue()

func on_history_press():
	var messages = []
	if (HistoryMessageContainerNode.get_child_count() < len(Dialogue.message_history)):
		for i in range((HistoryMessageContainerNode.get_child_count()), len(Dialogue.message_history)):
			var instance = HistoryMessageTemplateNode.duplicate()
			instance.set_name("Message_%d" % i)
			HistoryMessageContainerNode.add_child(instance)
	for id in Dialogue.message_history:
		pass

func on_history_close_press():
	pass

func on_auto_press():
	pass

func clear_responses():
	for item in (DialogueResponseGridNode.get_children()):
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
