extends Node

# This is only meant to validate data on startup and prepare the necessary resources

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
				if ((speaker == null or typeof(speaker) != TYPE_STRING or len(speaker) == 0) and (participant1 == null or typeof(participant1) != TYPE_STRING or len(participant1) == 0)):
					Logging.log(Logging.LogType.WARNING, "Boot",
						"Message %s in dialogue %s has an invalid or no speaker defined; it has not been loaded!" % [
							message_id,
							id
					])
					messages_failed = true
					break
				var participant2 = message.get("participant2")
				if (participant2 != null and (typeof(participant2) != TYPE_STRING or len(participant2) == 0)):
					Logging.log(Logging.LogType.WARNING, "Boot",
						"Message %s in dialogue %s has an invalid participant2 defined; they will not be shown!" % [
							message_id,
							id
					])
				if (OS.is_debug_build()):
					# The following validations would be excessive in release builds
					if (participant1):
						if (participant2):
							if (participant1 != speaker and participant2 != speaker):
								Logging.log(Logging.LogType.WARNING, "Boot",
									"Message %s in dialogue %s does not match its speaker to either participant; the speaker will be used for participant1!" % [
										message_id,
										id
								])
								message.set("participant1", speaker)
						else:
							if (participant1 != speaker):
								Logging.log(Logging.LogType.WARNING, "Boot",
									"Message %s in dialogue %s does not match its speaker and only participant; the speaker will be used!" % [
										message_id,
										id
								])
								message.set("participant1", speaker)
					var participant1_mood = message.get("participant1_mood")
					if (participant1_mood != null):
						if (typeof(participant1_mood) != TYPE_FLOAT):
							Logging.log(Logging.LogType.WARNING, "Boot",
								"Message %s in dialogue %s has an invalid participant1_mood; it has been set to default!" % [
									message_id,
									id
							])
							message.set("participant1_mood", 0)
						elif (participant1_mood < 0 or participant1_mood > 4):
							Logging.log(Logging.LogType.WARNING, "Boot",
								"Message %s in dialogue %s defined participant1_mood as %d, which is invalid; it has been set to default!" % [
									message_id,
									id,
									participant1_mood
							])
							message.set("participant1_mood", 0)
					var participant2_mood = message.get("participant2_mood")
					if (participant2_mood != null):
						if (typeof(participant2_mood) != TYPE_FLOAT):
							Logging.log(Logging.LogType.WARNING, "Boot",
								"Message %s in dialogue %s has an invalid participant2_mood; it has been set to default!" % [
									message_id,
									id
							])
							message.set("participant2_mood", 0)
						elif (participant2_mood < 0 or participant2_mood > 4):
							Logging.log(Logging.LogType.WARNING, "Boot",
								"Message %s in dialogue %s defined participant2_mood as %d, which is invalid; it has been set to default!" % [
									message_id,
									id,
									participant2_mood
							])
							message.set("participant2_mood", 0)
					var ending = message.get("ending")
					var next = message.get("next")
					if (ending != null and next != null):
						Logging.log(Logging.LogType.WARNING, "Boot",
							"Message %s in dialogue %s has defined a next and is supposed to end dialogue; it will go to the next by default!" % [
								message_id,
								id
						])
						message.erase("ending")
					elif (ending != null and typeof(ending) != TYPE_BOOL):
						Logging.log(Logging.LogType.WARNING, "Boot",
							"Message %s in dialogue %s defined a non-boolean ending value; it will end by default!" % [
								message_id,
								id
						])
						message.set("ending", true)
					elif (next != null and (typeof(next) != TYPE_STRING or len(next) == 0)):
						Logging.log(Logging.LogType.WARNING, "Boot",
							"Message %s in dialogue %s has defined an invalid next; it will progress sequentially by default!" % [
								message_id,
								id
						])
			if (not messages_failed):
				Globals.loaded_dialogue.set(id, contents)
