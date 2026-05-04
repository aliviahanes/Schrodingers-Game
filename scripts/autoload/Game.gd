extends Node

enum GameState
{
	GAMEPLAY,
	DIALOGUE,
	PAUSE
}

var game_state = []

signal game_state_changed

func get_current_game_state():
	if game_state.size() == 0:
		return GameState.GAMEPLAY
	else:
		return game_state[0]

func game_state_is_state(state):
	return get_current_game_state() == state
	
func push_game_state(state):
	game_state.insert(0, state)
	game_state_changed.emit()
	
func pop_game_state():
	game_state.remove_at(0)

func return_to_menu(was_error: bool):
	return was_error
