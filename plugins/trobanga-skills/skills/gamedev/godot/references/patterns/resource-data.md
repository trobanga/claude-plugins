# Resource Data

Custom `Resource` classes hold designer-editable data: items, weapons, enemy stats, dialogue lines. Define the class in a `.gd` with `class_name`, then create `.tres` instances in the editor.

## Contents

- Rules
- Read-only data
- Data with runtime state
- Collections of data

## Rules

- A Resource may have methods over its own fields (`get_dps()`, `take_damage()` on stats). It holds no references to nodes and does not reach into the scene tree.
- A loaded `.tres` is cached and **shared** by every node that loads it. Mutating it at runtime changes it for every user, and for the rest of the session. Give each user its own copy before mutating: `duplicate()` (add `true` for nested sub-resources), or tick `resource_local_to_scene` on the resource so each scene instance gets a copy.
- Exported values are applied after `_init()`, so `_init()` sees the script defaults, not the `.tres` values; initialise derived runtime state elsewhere.

## Read-only data

```gdscript
# weapon_data.gd
class_name WeaponData
extends Resource

@export var id: StringName
@export var display_name: String
@export var damage: int = 10
@export var attacks_per_second: float = 1.0
@export var attack_range: float = 32.0
@export var icon: Texture2D
@export var projectile: PackedScene
@export_multiline var description: String


func get_dps() -> float:
	return damage * attacks_per_second
```

## Data with runtime state

```gdscript
# character_stats.gd
class_name CharacterStats
extends Resource

signal health_changed(current: float, maximum: float)

@export var max_health: float = 100.0
@export var defense: float = 5.0
@export var speed: float = 200.0

var current_health: float  # runtime only: not exported, so not saved in the .tres


func reset() -> void:
	current_health = max_health


func take_damage(amount: float) -> float:
	var dealt := maxf(amount - defense, 1.0)
	current_health = maxf(current_health - dealt, 0.0)
	health_changed.emit(current_health, max_health)
	return dealt
```

```gdscript
# character.gd
class_name Character
extends CharacterBody2D

@export var base_stats: CharacterStats
@export var weapon: WeaponData

var stats: CharacterStats


func _ready() -> void:
	stats = base_stats.duplicate()  # own copy: other characters share base_stats
	stats.reset()
	stats.health_changed.connect(_on_health_changed)


func _on_health_changed(current: float, _maximum: float) -> void:
	if current <= 0.0:
		queue_free()
```

## Collections of data

Keep a list of all items in one exported array on a database resource or autoload, rather than scanning folders at runtime (exported builds remap and pack files, so `DirAccess` listings of `res://` differ from the editor):

```gdscript
# item_db.gd — autoload ItemDB, no class_name
extends Node

@export var items: Array[WeaponData] = []

var _by_id: Dictionary[StringName, WeaponData] = {}


func _ready() -> void:
	for item in items:
		_by_id[item.id] = item


func get_item(id: StringName) -> WeaponData:
	return _by_id.get(id)
```

Exports on an autoload are only settable when the autoload is registered as a `.tscn` scene, not a bare `.gd`; otherwise fill `items` with `preload()` constants.
