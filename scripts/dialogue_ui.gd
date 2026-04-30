extends Node

@onready var ClickShieldNode: Control = get_node("ClickShield")
@onready var CharacterTimer: Timer = get_node("CharacterTimer")

@onready var DialogueBoxNode: Control = get_node("DialogueBox")
@onready var DialogueMessageContentNode: RichTextLabel = get_node("DialogueBox/BoxBackground/Message/MessageContent")
@onready var DialogueCharacter1LabelNode: RichTextLabel = get_node("DialogueBox/BoxBackground/Message/Character1Label")
@onready var DialogueCharacter2LabelNode: RichTextLabel = get_node("DialogueBox/BoxBackground/Message/Character2Label")
@onready var DialogueCharacter1TextureNode: TextureRect = get_node("DialogueBox/Character1Texture")
@onready var DialogueCharacter2TextureNode: TextureRect = get_node("DialogueBox/Character2Texture")
@onready var DialogueResponseContainerNode: CenterContainer = get_node("DialogueBox/BoxBackground/Message/ResponseContainer")
@onready var DialogueResponseGridNode: GridContainer = get_node("DialogueBox/BoxBackground/Message/ResponseContainer/ResponseGrid")
@onready var DialogueResponseButtonTemplate: Button = get_node("DialogueBox/BoxBackground/Message/ResponseContainer/ResponseGrid/ResponseTemplate")
@onready var DialogueHistoryButtonNode: Button = get_node("DialogueBox/BoxBackground/Message/HistoryButton")
@onready var DialogueAutoButtonNode: Button = get_node("DialogueBox/BoxBackground/Message/AutoButton")

@onready var HistoryBoxNode: Control = get_node("HistoryBox")
@onready var HistoryMessageContainerNode: VBoxContainer = get_node("HistoryBox/BoxBackground/ScrollContainer/MessageContainer")
@onready var HistoryMessageTemplateNode: Panel = get_node("HistoryBox/BoxBackground/ScrollContainer/MessageContainer/MessageTemplate")
@onready var HistoryCloseButtonNode: TextureButton = get_node("HistoryBox/BoxBackground/CloseButton")

var message_tag_regex = RegEx.new()
var message_tag_pattern = "\\[(?<tag>speed|pause|event)=(?<value>[^\\]]+)\\]" # Unescape backslashes if you need to test pattern
var current_message_tags = {}

var auto_enabled = false
var viewing_history = false

var last_message = null
var last_speaker = -1

func _ready() -> void:
	message_tag_regex.compile(message_tag_pattern)
	Dialogue.dialogue_new_message.connect(on_dialogue_new_message)
	Dialogue.dialogue_state_changed.connect(on_dialogue_state_changed)
	DialogueBoxNode.gui_input.connect(handle_continue)
	DialogueHistoryButtonNode.pressed.connect(on_history_press)
	HistoryCloseButtonNode.pressed.connect(on_history_close_press)
	DialogueAutoButtonNode.pressed.connect(on_auto_press)
	InputManager.change_glyphs.connect(on_change_glyphs)

func _input(event: InputEvent):
	# TODO: Migrate click detection for DialogueBox to this to remove gui_input connection to handle_continue
	if (Dialogue.current_dialogue_state != Dialogue.DialogueState.CLOSED):
		if (not event is InputEventMouse and not event.is_echo()):
			if (not viewing_history):
				if (event.is_action_pressed("ui_select", false, true)):
					on_history_press()
					get_viewport().set_input_as_handled()
				elif (event.is_action_pressed("ui_select_secondary", false, true)):
					on_auto_press()
					get_viewport().set_input_as_handled()
				elif (event.is_action_pressed("ui_accept", false, true)):
					handle_continue(event)
					get_viewport().set_input_as_handled()
				elif (Dialogue.current_dialogue_state == Dialogue.DialogueState.WAITING_RESPONSE):
					if (
						(event.is_action("ui_up") or event.is_action("ui_down") or 
							event.is_action("ui_left") or event.is_action("ui_right")) and
						(get_viewport().gui_get_focus_owner() == null or
						not get_viewport().gui_get_focus_owner().name.contains("Response"))
					):
						var response = null
						if (event.is_action_pressed("ui_up", false, true) or event.is_action_pressed("ui_left", false, true)):
							response = DialogueResponseGridNode.get_node("Response0")
						elif (event.is_action_pressed("ui_down", false, true)):
							if ((DialogueResponseGridNode.get_child_count() - 1) > 2):
								response = DialogueResponseGridNode.get_node("Response3")
							else:
								response = DialogueResponseGridNode.get_node("Response0")
						elif (event.is_action_pressed("ui_right", false, true)):
							if ((DialogueResponseGridNode.get_child_count() - 1) > 2):
								response = DialogueResponseGridNode.get_node("Response1")
							else:
								response = DialogueResponseGridNode.get_node("Response0")
						else:
							return
						if (response != null):
							response.grab_focus()
						else:
							Logging.log(Logging.LogType.ERROR, "Dialogue UI", "Attempted to grab focus for a response, but it didn't exist!")
						get_viewport().set_input_as_handled()
			else:
				if (event.is_action_pressed("ui_cancel", false, true)):
					on_history_close_press()
					get_viewport().set_input_as_handled()

func animate_message():
	DialogueMessageContentNode.visible_characters = 0
	Dialogue.current_dialogue_state = Dialogue.DialogueState.SPEAKING
	var text_length = len(DialogueMessageContentNode.get_text())
	for i in range((text_length + 1)):
		if (Dialogue.current_dialogue_state != Dialogue.DialogueState.SPEAKING):
			return # The input handler for the dialogue has taken care of everything, just stop animation entirely
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
								# A non-oneshot timer is used to be able to end early (in case of skip)
								# This also prevents the old animation call from interfering with a new one
								CharacterTimer.set_wait_time(float(tag["value"]))
								CharacterTimer.start()
								await CharacterTimer.timeout
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
				get_viewport().gui_release_focus()
				DialogueMessageContentNode.set_visible_characters(0)
				DialogueMessageContentNode.set_visible(true)
				DialogueResponseContainerNode.set_visible(false)
				DialogueBoxNode.set_visible(true)
				desaturate_nonspeaker()
				animate_message()
			else:
				Logging.log(Logging.LogType.WARNING, "Dialogue UI", "Dialogue changed from closed to a non-speaking state; this behavior is not supported!")
		Dialogue.DialogueState.IDLE:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				DialogueMessageContentNode.set_visible_characters(0)
				DialogueMessageContentNode.set_visible(true)
				DialogueResponseContainerNode.set_visible(false)
				desaturate_nonspeaker()
				animate_message()
			elif (new_state == Dialogue.DialogueState.WAITING_RESPONSE):
				DialogueMessageContentNode.set_visible(false)
				DialogueResponseContainerNode.set_visible(true)
			elif (new_state == Dialogue.DialogueState.CLOSED):
				DialogueBoxNode.set_visible(false)
				for node in HistoryMessageContainerNode.get_children():
					node.set_visible(false)
				DialogueCharacter1TextureNode.set_position(Vector2(DialogueCharacter1TextureNode.position.x, -362.0))
				DialogueCharacter1TextureNode.set_instance_shader_parameter("desaturate_strength", 1.0)
				DialogueCharacter2TextureNode.set_position(Vector2(DialogueCharacter2TextureNode.position.x, -362.0))
				DialogueCharacter2TextureNode.set_instance_shader_parameter("desaturate_strength", 1.0)
				last_speaker = -1
				last_message = null
				ClickShieldNode.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Dialogue.DialogueState.WAITING_RESPONSE:
			if (new_state == Dialogue.DialogueState.SPEAKING):
				DialogueResponseContainerNode.set_visible(false)
				DialogueMessageContentNode.set_visible_characters(0)
				DialogueMessageContentNode.set_visible(true)
				desaturate_nonspeaker()
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
	DialogueCharacter1TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "%s/%s_%d.png" % [
		message.get("participant1", message.get("speaker")),
		message.get("participant1", message.get("speaker")),
		mood
	])
	# This is such a terrible repetition, but I am just him :>
	mood = message.get("participant2_mood", 0)
	DialogueCharacter2TextureNode.texture = load(Globals.DIALOGUE_SPRITE_PATH + "%s/%s_%d.png" % [
		message.get("participant2", "blank"),
		message.get("participant2", "blank"),
		mood
	])

func handle_continue(ev: InputEvent):
	if (ev is InputEventMouseButton):
		if (not (
			ev.button_index == MouseButton.MOUSE_BUTTON_LEFT and
			ev.pressed and
			Rect2(Vector2.ZERO, DialogueBoxNode.size).has_point(DialogueBoxNode.get_local_mouse_position())
		)):
			return
	elif (ev is InputEventMouseMotion):
		return
	else:
		if (not ev.is_action_pressed("ui_accept", false, true)):
			return
	if (Dialogue.current_dialogue_state == Dialogue.DialogueState.SPEAKING):
		Dialogue.current_dialogue_state = Dialogue.DialogueState.IDLE
		DialogueMessageContentNode.visible_characters = -1
		current_message_tags = {}
		CharacterTimer.stop()
		CharacterTimer.timeout.emit()
	elif (Dialogue.current_dialogue_state == Dialogue.DialogueState.IDLE):
		add_responses()
	elif (Dialogue.current_dialogue_state == Dialogue.DialogueState.WAITING_RESPONSE):
		if (ev.is_action_pressed("ui_accept", false, true)):
			var focused = get_viewport().gui_get_focus_owner()
			if (focused is Button):
				focused.pressed.emit()

func add_responses():
	var responses = Dialogue.current_dialogue["messages"][Dialogue.current_message_index].get("responses");
	if (responses):
		for i in range(len(responses)):
			var resp = DialogueResponseButtonTemplate.duplicate()
			resp.text = responses[i].get("content", "RESPONSE_NOT_FOUND")
			resp.set_visible(true)
			resp.set_name("Response%d" % i)
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
	# TODO: Investigate crash when opening while speaking a message with responses
	viewing_history = true
	var response_count = 0
	if (HistoryMessageContainerNode.get_child_count() < len(Dialogue.message_history)):
		for i in range((HistoryMessageContainerNode.get_child_count()), len(Dialogue.message_history)):
			var instance = HistoryMessageTemplateNode.duplicate()
			instance.set_name("Message_%d" % i)
			HistoryMessageContainerNode.add_child(instance)
	var i = 0
	for message in Dialogue.message_history:
		var node = HistoryMessageContainerNode.get_node("Message_%d" % i)
		if (message.get("response_content")):
			i += 1
			node.get_node("MessageContent").set_text(message.get("response_content"))
			node.get_node("Character1Texture").set_visible(false)
			node.get_node("Character2Texture").set_visible(false)
			# Instance generator does not compensate for responses
			var instance = HistoryMessageTemplateNode.duplicate()
			instance.set_name("Message_%d" % (len(Dialogue.message_history) + response_count))
			HistoryMessageContainerNode.add_child(instance)
			response_count += 1
		else:
			node.get_node("MessageContent").set_text(process_custom_tags(message.get("content"), false))
			node.get_node("Character1Texture").texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_0.png" % [
				message.get("participant1", message.get("speaker", "blank")),
				message.get("participant1", message.get("speaker", "blank"))
			])
			node.get_node("Character2Texture").texture = load(Globals.DIALOGUE_SPRITE_PATH + "/%s/%s_0.png" % [
				message.get("participant2", "blank"),
				message.get("participant2", "blank")
			])
			if (message.get("participant2") == message.get("speaker")):
				node.get_node("Character1Texture").set_visible(false)
				node.get_node("Character2Texture").set_visible(true)
			else:
				node.get_node("Character1Texture").set_visible(true)
				node.get_node("Character2Texture").set_visible(false)
		i += 1
		node.set_visible(true)
	DialogueBoxNode.set_visible(false)
	HistoryBoxNode.set_visible(true)

func on_history_close_press():
	viewing_history = false
	HistoryBoxNode.set_visible(false)
	DialogueBoxNode.set_visible(true)

func on_auto_press():
	# TODO: Display whether auto is enabled!
	# TODO: Debounce inputs
	if (auto_enabled):
		Dialogue.dialogue_state_changed.disconnect(auto_on_state_changed)
	else:
		Dialogue.dialogue_state_changed.connect(auto_on_state_changed)

func on_change_glyphs():
	var history_glyph_path: String = Globals.INPUT_GLYPH_PATH + "kb/e.png"
	var auto_glyph_path: String = Globals.INPUT_GLYPH_PATH + "kb/t.png"
	var history_close_glyph_path: String = Globals.INPUT_GLYPH_PATH + "kb/c.png"
	match InputManager.current_input_type:
		InputManager.InputType.XBOX:
			history_glyph_path = Globals.INPUT_GLYPH_PATH + "xbox/y.png"
			auto_glyph_path = Globals.INPUT_GLYPH_PATH + "xbox/x.png"
			history_close_glyph_path = Globals.INPUT_GLYPH_PATH + "xbox/b.png"
		InputManager.InputType.DECK:
			history_glyph_path = Globals.INPUT_GLYPH_PATH + "deck/y.png"
			auto_glyph_path = Globals.INPUT_GLYPH_PATH + "deck/x.png"
			history_close_glyph_path = Globals.INPUT_GLYPH_PATH + "deck/b.png"
		InputManager.InputType.PLAYSTATION:
			history_glyph_path = Globals.INPUT_GLYPH_PATH + "playstation/tri.png"
			auto_glyph_path = Globals.INPUT_GLYPH_PATH + "playstation/sqr.png"
			history_close_glyph_path = Globals.INPUT_GLYPH_PATH + "playstation/cir.png"
		InputManager.InputType.NINTENDO:
			history_glyph_path = Globals.INPUT_GLYPH_PATH + "switch/x.png"
			auto_glyph_path = Globals.INPUT_GLYPH_PATH + "switch/y.png"
			history_close_glyph_path = Globals.INPUT_GLYPH_PATH + "switch/a.png"
	DialogueHistoryButtonNode.set_button_icon(load(history_glyph_path))
	DialogueAutoButtonNode.set_button_icon(load(auto_glyph_path))
	HistoryCloseButtonNode.set_texture_normal(load(history_close_glyph_path))

func auto_on_state_changed(oldstate: Dialogue.DialogueState, newstate: Dialogue.DialogueState):
	if (oldstate == Dialogue.DialogueState.SPEAKING and newstate == Dialogue.DialogueState.IDLE):
		if (not Dialogue.current_dialogue["messages"][Dialogue.current_message_index].get("ending")):
			CharacterTimer.set_wait_time(Globals.auto_wait_time)
			CharacterTimer.start()
			await CharacterTimer.timeout
			add_responses()

func clear_responses():
	for item in (DialogueResponseGridNode.get_children()):
		if (item.name != "ResponseTemplate"):
			item.queue_free()

func process_custom_tags(content: String, track_pos: bool = true) -> String:
	var offset = 0
	var matches = message_tag_regex.search_all(content)
	if (track_pos):
		for mat in matches:
			var final_index = mat.get_start() - offset
			if not current_message_tags.has(final_index):
				current_message_tags.set(final_index, [])
			current_message_tags[final_index].append({"tag": mat.get_string("tag"), "value": mat.get_string("value")})
			offset += (mat.get_end() - mat.get_start())
	return message_tag_regex.sub(content, "", true)

func desaturate_nonspeaker():
	var message = Dialogue.current_dialogue["messages"][Dialogue.current_message_index]
	var anim_up: TextureRect = null
	if (message.get("participant2")):
		var anim_down: TextureRect = null
		if (last_message != null):
			if (last_message.get("speaker") != message.get("speaker")):
				if (message.get("speaker") == message.get("participant1") and last_speaker != 0):
					anim_down = DialogueCharacter2TextureNode
					anim_up = DialogueCharacter1TextureNode
					last_speaker = 0
				elif (message.get("speaker") == message.get("participant2") and last_speaker != 1):
					anim_down = DialogueCharacter1TextureNode
					anim_up = DialogueCharacter2TextureNode
					last_speaker = 1
		else:
			if (message.get("speaker") == message.get("participant1") and last_speaker != 0):
				anim_up = DialogueCharacter1TextureNode
				last_speaker = 0
			elif (message.get("speaker") == message.get("participant2") and last_speaker != 1):
				anim_up = DialogueCharacter2TextureNode
				last_speaker = 1
		if (anim_up != null):
			var method = func(value): anim_up.set_instance_shader_parameter("desaturate_strength", value)
			(get_tree().create_tween()).tween_method(method, 1.0, 0.0, Globals.DIALOGUE_DESATURATION_TIME)
			(get_tree().create_tween()).tween_property(anim_up, "position", Vector2(anim_up.position.x, anim_up.position.y - 150), Globals.DIALOGUE_DESATURATION_TIME)
		if (anim_down != null):
			var method = func(value): anim_down.set_instance_shader_parameter("desaturate_strength", value)
			(get_tree().create_tween()).tween_method(method, 0.0, 1.0, Globals.DIALOGUE_DESATURATION_TIME)
			(get_tree().create_tween()).tween_property(anim_down, "position", Vector2(anim_down.position.x, anim_down.position.y + 150), Globals.DIALOGUE_DESATURATION_TIME)
	else:
		if (last_message == null):
			anim_up = DialogueCharacter1TextureNode
			var method = func(value): anim_up.set_instance_shader_parameter("desaturate_strength", value)
			(get_tree().create_tween()).tween_method(method, 1.0, 0.0, Globals.DIALOGUE_DESATURATION_TIME)
			(get_tree().create_tween()).tween_property(anim_up, "position", Vector2(anim_up.position.x, anim_up.position.y - 150), Globals.DIALOGUE_DESATURATION_TIME)
			last_speaker = 0
	last_message = message
