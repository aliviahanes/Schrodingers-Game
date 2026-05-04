extends CanvasLayer

var time_actions = 3
var time_icon_list : Array[TextureRect]

func _ready() -> void:
	var icon_parent = $HBoxContainer
	for child in icon_parent.get_children():
		time_icon_list.append(child)
	
func use_action():
	if time_actions > 0:
		time_actions -= 1
		update_time_action_display()

func update_time_action_display():
	for i in range(time_icon_list.size):
		time_icon_list[i].visible = i < time_actions
