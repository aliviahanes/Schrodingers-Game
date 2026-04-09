extends Node

# The methods in this file are not meant to be publicly used, and this will only execute at game start

func _ready():
	# Load and validate all dialogue
	# Why validate good files in prod? To make the user think we're mining bitcoin or something idk
	for file_name in (DirAccess.open(Globals.DIALOGUE_DATA_PATH).get_files()):
		if (file_name == "speaker_map.json"):
			# this is a super duper special file that gets special treatment for being so special
			# TODO: actually validate this instead of just throwing it into a variable
			var smap = FileAccess.open(Globals.DIALOGUE_DATA_PATH + "/speaker_map.json", FileAccess.READ)
			Globals.loaded_speakers = JSON.parse_string(smap.get_as_text())
		var file = FileAccess.open(file_name, FileAccess.READ)
		var contents = JSON.parse_string(file.get_as_text())
		file.close()
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
