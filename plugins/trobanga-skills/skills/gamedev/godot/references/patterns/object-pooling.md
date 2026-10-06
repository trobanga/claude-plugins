# Object Pooling

## Contents

- When to pool
- Pool
- Pooled object
- Pool registry (autoload)
- Gotchas

## When to pool

GDScript is reference-counted and nodes are freed explicitly, so there are no garbage-collector pauses to avoid. Pool only when the profiler shows `instantiate()`/`add_child()`/`queue_free()` cost for objects spawned many times per second (bullets, hit effects, damage numbers). Otherwise instantiate and `queue_free()`.

## Pool

```gdscript
# pool.gd
class_name Pool
extends Node

@export var scene: PackedScene
@export var initial_size: int = 20
@export var max_size: int = 200

var _free: Array[Node] = []
var _in_use: Array[Node] = []


func _ready() -> void:
	for i in initial_size:
		_free.append(_create())


func acquire() -> Node:
	var obj: Node
	if not _free.is_empty():
		obj = _free.pop_back()
	elif _in_use.size() < max_size:
		obj = _create()
	else:
		push_warning("Pool exhausted: %s" % scene.resource_path)
		return null
	_in_use.append(obj)
	_set_active(obj, true)
	if obj.has_method("reset"):
		obj.call("reset")
	return obj


func release(obj: Node) -> void:
	if not _in_use.has(obj):
		return  # already released, or not ours
	_in_use.erase(obj)
	_set_active(obj, false)
	_free.append(obj)


func release_all() -> void:
	for obj in _in_use.duplicate():
		release(obj)


func _create() -> Node:
	var obj := scene.instantiate()
	add_child(obj)
	_set_active(obj, false)
	if obj.has_signal("finished"):
		obj.connect("finished", release.bind(obj))
	return obj


func _set_active(obj: Node, active: bool) -> void:
	obj.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if obj is CanvasItem or obj is Node3D:
		obj.visible = active
```

Pooled objects stay children of the pool and are placed with `global_position`. If an object must live under another node (a moving platform), `obj.reparent(new_parent)` on acquire and `obj.reparent(pool)` on release.

## Pooled object

The object signals when it is done; it never calls the pool.

```gdscript
# bullet.gd
class_name Bullet
extends Area2D

signal finished

@export var speed: float = 600.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var _age: float = 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func reset() -> void:
	_age = 0.0
	_shape.set_deferred("disabled", false)


func fire(from: Vector2, dir: Vector2) -> void:
	global_position = from
	direction = dir.normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		_finish()


func _on_body_entered(_body: Node2D) -> void:
	_finish()


func _finish() -> void:
	_shape.set_deferred("disabled", true)
	finished.emit()
```

Disabling `process_mode` stops `_process` and `_physics_process`, but an `Area2D` keeps detecting overlaps; disable its shapes as above.

## Pool registry (autoload)

For several pooled scenes, an autoload `Pools` (no `class_name`) keeps one `Pool` per scene:

```gdscript
# pools.gd
extends Node

var _pools: Dictionary[String, Pool] = {}


func register(scene: PackedScene, initial_size: int = 20, max_size: int = 200) -> void:
	if _pools.has(scene.resource_path):
		return
	var pool := Pool.new()
	pool.scene = scene
	pool.initial_size = initial_size
	pool.max_size = max_size
	pool.name = scene.resource_path.get_file().get_basename()
	add_child(pool)
	_pools[scene.resource_path] = pool


func acquire(scene: PackedScene) -> Node:
	var pool: Pool = _pools.get(scene.resource_path)
	if pool == null:
		push_error("No pool for %s; call register() first" % scene.resource_path)
		return null
	return pool.acquire()


func release_all() -> void:
	for pool: Pool in _pools.values():
		pool.release_all()
```

```gdscript
const BULLET := preload("res://scenes/projectiles/bullet.tscn")


func _ready() -> void:
	Pools.register(BULLET, 50, 300)


func shoot() -> void:
	var bullet := Pools.acquire(BULLET) as Bullet
	if bullet:
		bullet.fire(global_position, Vector2.RIGHT.rotated(rotation))
```

Call `Pools.release_all()` before changing levels, so no object is left active with a reference into the old scene.

## Gotchas

- Reset everything in `reset()`: transform, velocity, timers (`Timer.stop()`), `AnimationPlayer` (`stop()` and `seek(0)`), particles (`restart()`), and signals connected during the last use.
- `GPUParticles2D` and one-shot effects often need `emitting = true` again on acquire.
- A pooled object that calls `queue_free()` on itself leaves a freed reference in the pool; it must emit `finished` instead.
