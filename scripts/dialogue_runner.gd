extends Node

var current_dialogue_id = "none"

func _ready():
	# Expected format of scene change parameters:
	# <dialogue_id>
	if (not typeof(Globals.scene_change_parameters) == TYPE_STRING):
		Logging.log(Logging.LogType.ERROR, "Dialogue", "The scene change parameters are not a string, so dialogue cannot begin!")
		return
