extends CharacterBody2D

const SPEED: float = 200.0

var health: int = 100
var gold: int = 0
var inventory: Array[String] = []


func _ready() -> void:
	add_to_group(&"player")


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = direction * SPEED
	move_and_slide()


func pick_up(item_id: String) -> void:
	inventory.append(item_id)
