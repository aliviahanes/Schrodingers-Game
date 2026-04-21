extends Node

# The methods in this file are not meant to be publicly used, and this will only execute at game start

func _ready():
	# Load and validate all dialogue
	for file_name in (DirAccess.open(Globals.DIALOGUE_DATA_PATH).get_files()):
		var file = FileAccess.open(Globals.DIALOGUE_DATA_PATH + file_name, FileAccess.READ)
		var contents = JSON.parse_string(file.get_as_text())
		file.close()
		if (file_name == "speaker_map.json"):
			# this is a super duper special file that gets special treatment for being so special
			if (contents.get("speakers")):
				for speaker in contents["speakers"]:
					if (contents["speakers"][speaker].get("display") == null):
						Logging.log(Logging.LogType.WARNING, "Boot", "Speaker %s does not have a display name, using default!" % speaker)
						contents["speakers"][speaker].set("display", "DISPLAY_NOT_FOUND")
					if (contents["speakers"][speaker].get("default_message_speed")):
						if (typeof(contents["speakers"][speaker].get("default_message_speed")) != TYPE_FLOAT):
							Logging.log(Logging.LogType.WARNING, "Boot", "Speaker %s has an invalid default message speed, using default!")
							contents["speakers"][speaker].erase("default_message_speed")
				Globals.loaded_speakers = contents.get("speakers")
			continue
		if (contents != null):
			var id = contents.get("id")
			if (id == null):
				Logging.log(Logging.LogType.WARNING, "Boot", 
					"Failed to retrieve dialogue ID from the file %s; it has not been loaded!" % file_name
				)
				continue
			var messages = contents.get("messages")
			if (messages == null or typeof(messages) != TYPE_ARRAY):
				Logging.log(Logging.LogType.WARNING, "Boot",
					"Dialogue %s does not have a valid messages field; it has not been loaded!" % id
				)
				continue
			var messages_failed = false
			for message in messages:
				var message_id = message.get("message_id")
				if (message_id == null or typeof(message_id) != TYPE_STRING):
					Logging.log(Logging.LogType.WARNING, "Boot",
						"Dialogue %s has a message with no valid message ID; it has not been loaded!" % id
					)
					messages_failed = true
					break
				var message_content = message.get("content")
				if (message_content == null or typeof(message_content) != TYPE_STRING):
					Logging.log(Logging.LogType.WARNING, "Boot",
						"Message %s in dialogue %s has invalid or no content defined; it has not been loaded!" % [
							message_id,
							id
					])
					messages_failed = true
					break
				var speaker = message.get("speaker")
				var participant1 = message.get("participant1")
				if ((speaker == null or typeof(speaker) != TYPE_STRING) and (participant1 == null or typeof(participant1) != TYPE_STRING)):
					Logging.log(Logging.LogType.WARNING, "Boot",
						"Message %s in dialogue %s has an invalid or no speaker defined; it has not been loaded!" % [
							message_id,
							id
					])
					messages_failed = true
					break
				if (OS.is_debug_build()):
					# The following validations would be excessive in release builds
					pass
			if (not messages_failed):
				Globals.loaded_dialogue.set(id, contents)
