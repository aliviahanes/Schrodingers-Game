extends Interactable

@export var num: int

func interact(player):
	Dialogue.begin_dialogue("example_dialogue")
