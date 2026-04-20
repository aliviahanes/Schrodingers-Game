extends CharacterBody2D

var speed = 200
var direction : Vector2 = Vector2()

@onready var sprite = $Sprite2D

func _ready():
	sprite.hframes = 4
	sprite.vframes = 1

func read_input():
	direction = Vector2()

	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
		sprite.frame = 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
		sprite.frame = 0
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
		sprite.frame = 3
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		sprite.frame = 2

func _physics_process(delta: float) -> void:
	read_input()
	velocity = direction.normalized() * speed
	move_and_slide()
