extends CharacterBody2D

const SPEED: float = 200.0

var score: int = 0


func _ready() -> void:
	add_to_group(&"player")


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = direction * SPEED
	move_and_slide()
