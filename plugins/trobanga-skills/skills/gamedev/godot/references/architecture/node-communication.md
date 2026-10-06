# Node Communication

## Contents

- Decision table
- Signal up, call down
- Groups
- Event bus (autoload)
- Autoloads
- Dependency injection

## Decision table

| Situation | Use |
|---|---|
| Child reports something happened | signal on the child, parent connects |
| Parent tells a child to act | direct method call on a typed `@onready` reference |
| Siblings | the common parent connects one sibling's signal to the other's method |
| One sender, many receivers in different scenes (enemy died → HUD, audio, quest log) | event bus autoload |
| Act on every node of a kind (all enemies, all saveables) | group |
| A node needs a collaborator it does not own | `@export` it and assign in the editor, or pass it in a `setup()` call |
| Wait for something once | `await node.signal_name` |

## Signal up, call down

```gdscript
# door.gd — knows nothing about who opens it
class_name Door
extends StaticBody2D

signal opened


func open() -> void:
	$AnimationPlayer.play("open")
	opened.emit()
```

```gdscript
# level.gd — owns both nodes, so it wires them
extends Node2D

@onready var _lever: Lever = %Lever
@onready var _door: Door = %Door


func _ready() -> void:
	_lever.pulled.connect(_door.open)
	_door.opened.connect(_on_door_opened)


func _on_door_opened() -> void:
	$Music.play()
```

Connect in code or in the editor's Node → Signals dock, not both: connecting the same callable twice is an error. Pass extra arguments with `callable.bind(x)`; `CONNECT_ONE_SHOT` disconnects after the first emission.

## Groups

```gdscript
func _ready() -> void:
	add_to_group(&"enemies")
```

```gdscript
# explosion.gd
func explode() -> void:
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Node2D
		if enemy and enemy.global_position.distance_to(global_position) < radius:
			enemy.call("take_damage", damage)
	# or, without a distance check:
	get_tree().call_group(&"enemies", "alert", global_position)
```

`get_nodes_in_group()` allocates a new array on each call; inside `_process`, keep the result and refresh it on `tree_entered`/`tree_exiting` of the members or on a timer.

## Event bus (autoload)

One autoload that only declares signals. Senders emit, receivers connect; neither knows the other.

```gdscript
# event_bus.gd — autoload EventBus, no class_name
extends Node

@warning_ignore_start("unused_signal")
signal player_died
signal enemy_killed(enemy_type: StringName, at: Vector2)
signal score_changed(score: int)
signal level_completed(level: int, time: float)
@warning_ignore_restore("unused_signal")
```

```gdscript
# enemy.gd
func _on_health_died() -> void:
	EventBus.enemy_killed.emit(&"slime", global_position)
	queue_free()

# hud.gd
func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
```

Use the bus for game-wide events only. Within one scene, the parent wiring above is easier to follow, because the connection is visible in the scene that owns both ends. `@warning_ignore_start`/`_restore` needs 4.4; on earlier versions put `@warning_ignore("unused_signal")` above each signal.

## Autoloads

| Autoload | Good fit |
|---|---|
| EventBus, SaveManager, SceneManager, AudioManager, Settings | yes: services that outlive scenes |
| Player stats, inventory | only if they must survive scene changes; otherwise a Resource held by the player |
| Enemy spawning, level logic | no: belongs to the level scene |

Autoload rules:

- No `class_name` in an autoload script; Godot already registers the autoload name globally, and a matching `class_name` is the parse error "Class "X" hides an autoload singleton".
- Every autoload is in the tree before any autoload's `_ready()` runs, but the `_ready()` calls run in the order listed in Project Settings → Globals → Autoload. An autoload that reads state another one sets up in its `_ready()` must be listed below it.
- Register an autoload as a `.tscn` when it needs child nodes or exported values set in the editor.
- An autoload that must run while the game is paused sets `process_mode = PROCESS_MODE_ALWAYS`.

## Dependency injection

Prefer an exported reference or a setup call over searching the tree:

```gdscript
# weapon.gd
class_name Weapon
extends Node2D

@export var base_damage: int = 5

var _stats: CharacterStats


func setup(stats: CharacterStats) -> void:
	_stats = stats


func damage() -> int:
	return base_damage + int(_stats.speed / 100.0)
```

```gdscript
# player.gd
func _ready() -> void:
	$Weapon.setup(stats)
```

Searching with `get_tree().root.find_child("Player", true, false)` walks the whole tree and breaks on renames; `get_tree().get_first_node_in_group(&"player")` is the cheap fallback when injection is impractical.
