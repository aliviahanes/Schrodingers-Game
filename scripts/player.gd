extends CharacterBody2D

const SPEED = 300.0

var facing_direction: Vector2 = Vector2.DOWN
var interactables = []
var interact_range = 360

func _process(delta: float) -> void:
	if Game.game_state_is_state(Game.GameState.GAMEPLAY):
		if Input.is_action_just_pressed("interact"):
			interact()

func _physics_process(delta: float) -> void:
	if Game.game_state_is_state(Game.GameState.GAMEPLAY):
		process_movement()
		move_and_slide()

func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED
	
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
	pass

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body is Interactable:
		interactables.append(body)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	interactables.erase(body)
	
func interact():
	if interactables.size() > 0:
		var target = null
		var target_score = -1
		
		for object in interactables:
			if not is_valid_interactable(object):
				continue
				
			var score_vec = (object.global_position - global_position).normalized()
			var score = facing_direction.dot(score_vec)
			
			if score > target_score:
				target = object
				target_score = score
		
		if target:
			target.interact(self)

func is_in_front(object):
	var object_vec = (object.global_position - global_position).normalized()
	var dot = facing_direction.dot(object_vec)
	
	return dot > 0.5

func is_valid_interactable(object):
	var dist = global_position.distance_to(object.global_position)
	if dist > interact_range:
		return false
	
	return is_in_front(object)
