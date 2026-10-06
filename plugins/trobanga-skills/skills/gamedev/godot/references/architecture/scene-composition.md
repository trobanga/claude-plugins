# Scene Composition

## Contents

- Composition by component scenes
- Scene inheritance
- Container scenes
- Owner and unique names
- Smells

## Composition by component scenes

Build an entity from small scenes that each do one job. The root script orchestrates them; components never know about each other.

```
player.tscn
Player (CharacterBody2D, player.gd)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── HealthComponent      (health_component.tscn)
├── Hurtbox              (hurtbox_component.tscn)
├── Hitbox               (hitbox_component.tscn)
└── StateMachine
    ├── Idle
    └── Walk
```

```gdscript
# player.gd
class_name Player
extends CharacterBody2D

@onready var health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _ready() -> void:
	_hurtbox.health = health
	health.died.connect(_on_died)


func _on_died() -> void:
	EventBus.player_died.emit()
	queue_free()
```

HealthComponent, HitboxComponent and HurtboxComponent are defined in the health-and-hitboxes reference; the state machine in the state-machine reference. A component is a scene (not just a script) when it carries nodes of its own, such as an `Area2D` with a shape or a `Timer`.

## Scene inheritance

Use an inherited scene (Scene → New Inherited Scene) when variants share the same node layout and differ in values: textures, shape sizes, exported numbers. Script inheritance (`extends EnemyBase`) adds behaviour. Keep the chain one level deep; for a second axis of variation, add a component instead.

```gdscript
# enemy_base.gd
class_name EnemyBase
extends CharacterBody2D

@export var move_speed: float = 50.0

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	health.died.connect(_on_died)


func _on_died() -> void:
	queue_free()
```

```gdscript
# slime.gd — slime.tscn inherits enemy_base.tscn
extends EnemyBase

const SMALL_SLIME := preload("res://scenes/actors/enemies/slime_small.tscn")

@export var split_count: int = 2


func _on_died() -> void:
	for i in split_count:
		var child := SMALL_SLIME.instantiate() as Node2D
		child.position = position + Vector2(randf_range(-8, 8), 0)
		add_sibling.call_deferred(child)
	super()
```

`super()` inside an overriding method calls the parent's version of the same method.

## Container scenes

A level owns containers (`Enemies`, `Pickups`, `Projectiles`) and adds runtime nodes there, so nothing spawns into the root and cleanup is one `queue_free()` per container.

```gdscript
# level.gd
extends Node2D

@export var enemy_scenes: Array[PackedScene] = []

@onready var _enemies: Node2D = $Enemies
@onready var _spawn_points: Node2D = $SpawnPoints


func _ready() -> void:
	for point: Marker2D in _spawn_points.get_children():
		var enemy := enemy_scenes.pick_random().instantiate() as Node2D
		enemy.position = point.position
		_enemies.add_child(enemy)
```

## Owner and unique names

- `owner` is the root of the scene a node was saved in. A component can read its entity as `owner as CharacterBody2D`; nodes created in code have no owner until you set one.
- Mark nodes that scripts depend on as unique (right-click → Access as Unique Name) and reach them with `%Name`. A `%Name` resolves within the same scene only, not inside instanced child scenes.

## Smells

| Smell | Fix |
|---|---|
| A scene that only works under one specific parent | export its dependencies or emit signals; run it alone with F6 to check |
| A god scene with dozens of direct children and one huge script | split into component scenes |
| `get_node("../../UI/HealthBar")` from gameplay code | HUD connects to a signal or the event bus |
| Two scripts holding references to each other | one owns the other; the owned one signals back |
| Nesting deeper than 4–5 levels | flatten, or extract a sub-scene |
