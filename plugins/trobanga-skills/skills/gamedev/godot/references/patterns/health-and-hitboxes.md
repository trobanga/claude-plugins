# Health, Hitboxes and Hurtboxes

## Contents

- Scene layout
- HealthComponent
- HitboxComponent and HurtboxComponent
- Wiring in the owner

## Scene layout

```
Enemy (CharacterBody2D, enemy.gd)
├── CollisionShape2D
├── HealthComponent (Node)
├── Hitbox (Area2D, HitboxComponent)     deals damage: monitoring on, layer "hitbox", mask "hurtbox"
│   └── CollisionShape2D
└── Hurtbox (Area2D, HurtboxComponent)   takes damage: monitorable on, layer "hurtbox", mask none
    └── CollisionShape2D
```

Put hitboxes and hurtboxes on their own physics layers (Project Settings → Layer Names → 2D Physics), so they only see each other and never the body colliders. Only the hitbox monitors; the hurtbox is passive.

## HealthComponent

```gdscript
# health_component.gd
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal damaged(amount: int, source: Node)
signal died

@export var max_health: int = 100
@export var invincibility_time: float = 0.0

var current: int:
	set(value):
		var old := current
		current = clampi(value, 0, max_health)
		if current != old:
			health_changed.emit(current, max_health)

var _invincible: bool = false


func _ready() -> void:
	current = max_health


func is_dead() -> bool:
	return current <= 0


func take_damage(amount: int, source: Node = null) -> int:
	if _invincible or is_dead():
		return 0
	var dealt := mini(amount, current)
	current -= dealt
	damaged.emit(dealt, source)
	if is_dead():
		died.emit()
	elif invincibility_time > 0.0:
		_start_invincibility()
	return dealt


func heal(amount: int) -> int:
	var healed := mini(amount, max_health - current)
	current += healed
	return healed


func _start_invincibility() -> void:
	_invincible = true
	await get_tree().create_timer(invincibility_time, false).timeout
	_invincible = false
```

`create_timer(t, false)` makes the timer stop while the tree is paused.

## HitboxComponent and HurtboxComponent

```gdscript
# hitbox_component.gd
class_name HitboxComponent
extends Area2D

signal hit(hurtbox: HurtboxComponent)

@export var damage: int = 10
@export var knockback: float = 200.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or hurtbox.owner == owner:
		return  # not a hurtbox, or our own
	hurtbox.receive_hit(self)
	hit.emit(hurtbox)
```

```gdscript
# hurtbox_component.gd
class_name HurtboxComponent
extends Area2D

signal hurt(hitbox: HitboxComponent)

@export var health: HealthComponent


func receive_hit(hitbox: HitboxComponent) -> void:
	if health:
		health.take_damage(hitbox.damage, hitbox.owner)
	hurt.emit(hitbox)
```

`owner` is the root of the scene the node was saved in, so it identifies the entity even when the box is nested deeper than one level. For boxes added in code, set `owner` yourself.

## Wiring in the owner

The owner connects to its components (signal up, call down) and decides what death means for it:

```gdscript
# enemy.gd
extends CharacterBody2D

@onready var _health: HealthComponent = $HealthComponent
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _ready() -> void:
	_health.died.connect(_on_died)
	_hurtbox.hurt.connect(_on_hurt)


func _on_hurt(hitbox: HitboxComponent) -> void:
	var away := (global_position - hitbox.global_position).normalized()
	velocity += away * hitbox.knockback


func _on_died() -> void:
	set_physics_process(false)
	_hurtbox.set_deferred("monitorable", false)
	queue_free()
```

Inside a physics callback such as `area_entered`, change `monitoring`, `monitorable` and `CollisionShape2D.disabled` with `set_deferred`; setting them directly there raises an engine error.
