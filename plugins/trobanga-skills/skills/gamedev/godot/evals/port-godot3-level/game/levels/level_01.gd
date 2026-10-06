extends Node2D

export var enemy_scene: PackedScene
export var spawn_delay = 1.5

onready var ground = $Ground
onready var camera = $Camera2D

var spawn_points = []
var level_data = {}


func _ready():
	camera.current = true
	var file = File.new()
	file.open("res://levels/level_01.json", File.READ)
	level_data = parse_json(file.get_as_text())
	file.close()
	for p in level_data["spawns"]:
		spawn_points.append(Vector2(p[0], p[1]))
	yield(get_tree().create_timer(spawn_delay), "timeout")
	spawn_wave()


func spawn_wave():
	while spawn_points.size() > 0:
		var point = spawn_points.pop_back()
		var cell = ground.world_to_map(point)
		if ground.get_cellv(cell) == -1:
			continue
		var enemy = enemy_scene.instance()
		enemy.position = point
		add_child(enemy)
		yield(get_tree().create_timer(spawn_delay), "timeout")
	open_gate()


func open_gate():
	var gate = level_data["gate"]
	ground.set_cell(gate[0], gate[1], -1)
