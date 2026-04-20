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
				for speaker in contents:
					if (contents[speaker].get("display") == null):
						Logging.log(Logging.LogType.WARNING, "Boot", "Speaker %s does not have a display name, using default!" % speaker)
						contents[speaker].set("display", "DISPLAY_NOT_FOUND")
					if (contents[speaker].get("default_message_speed")):
						if (not contents[speaker].get("default_message_speed").is_valid_int()):
							Logging.log(Logging.LogType.WARNING, "Boot", "Speaker %s has an invalid default message speed, using default!")
							contents[speaker].erase("default_message_speed")
				Globals.loaded_speakers = contents.get("speakers")
			continue
		# TODO: Need to finish validations
		if (contents != null): # JSON.parse_string returns null if there is a parsing error
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
			for message in messages:
				var message_id = message.get("message_id")
				if (message_id == null or typeof(message_id) != TYPE_STRING):
					Logging.log(Logging.LogType.WARNING, "Boot",
						"Dialogue %s has a message with no valid message ID; it has not been loaded!" % id
					)
					continue
			Globals.loaded_dialogue.set(id, contents)
