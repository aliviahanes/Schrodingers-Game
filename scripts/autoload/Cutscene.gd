extends Node

var prepared_cutscene
var prepared_meta
var current_scene
var current_meta

func prepare_cutscene(id: String) -> bool:
	if (not (id in Globals.loaded_cutscenes)):
		Logging.log(Logging.LogType.ERROR, "Cutscene", "The requested cutscene of ID %s was not found, so a cutscene cannot be prepared!" % id)
		return false
	prepared_cutscene = load(Globals.CUTSCENE_DATA_PATH + id + "/cutscene.tscn")
	prepared_meta = Globals.loaded_cutscenes.get(id)
	if (prepared_meta.get("required_level") != Game.get_current_level()):
		Game.prepare_level(prepared_meta.get("required_level"))
	return true

func start_cutscene():
	if (prepared_meta.get("required_level") != Game.get_current_level()):
		Game.load_level(prepared_meta.get("required_level"))
