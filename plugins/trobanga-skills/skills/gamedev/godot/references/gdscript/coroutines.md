# Coroutines and await

## Contents

- Rules
- Sequences
- Waiting for many things
- Timeout
- Interrupting
- Freed nodes

## Rules

- A function containing `await` is a coroutine. Calling it without `await` runs it until its first `await` and returns at once; that is fine when you discard the result. Using its return value without `await` is a parse error ("is a coroutine, so it must be called with await").
- Each call starts an independent run: calling `flash()` three times in one frame runs three overlapping flashes. Guard with a flag or kill the previous tween.
- Never `await` inside `_process`/`_physics_process`: every frame starts another suspended run. Start the coroutine from an event and keep `_process` synchronous.
- `get_tree().create_timer(t)` keeps running while the tree is paused; pass `false` as the second argument (`process_always`) to pause it with the game.

## Sequences

```gdscript
func play_death() -> void:
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$AnimationPlayer.play("death")
	await $AnimationPlayer.animation_finished
	var tween := create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.4)
	await tween.finished
	queue_free()


func level_transition(next_level: String) -> void:
	await SceneManager.change_scene(next_level)
	EventBus.level_started.emit()
```

## Waiting for many things

Awaiting signals one after another in a loop misses any signal that fires before its `await` is reached (a second enemy dying before the first), and then waits forever. Count instead:

```gdscript
signal wave_cleared

var _alive: int = 0


func spawn_wave(count: int) -> void:
	for i in count:
		var enemy := ENEMY.instantiate() as EnemyBase
		_alive += 1
		enemy.tree_exited.connect(_on_enemy_gone, CONNECT_ONE_SHOT)
		$Enemies.add_child(enemy)


func _on_enemy_gone() -> void:
	_alive -= 1
	if _alive == 0:
		wave_cleared.emit()
```

## Timeout

GDScript has no `race` or `select`. Funnel both outcomes into one signal and await that:

```gdscript
signal _settled(ok: bool)


## Returns true if `sig` fired within `seconds`, false on timeout.
## `arg_count` is the number of arguments `sig` emits.
func await_with_timeout(sig: Signal, seconds: float, arg_count: int = 0) -> bool:
	var done := [false]  # an Array, because lambdas capture plain locals by value
	var finish := func(ok: bool) -> void:
		if not done[0]:
			done[0] = true
			_settled.emit(ok)
	sig.connect(finish.bind(true).unbind(arg_count), CONNECT_ONE_SHOT)
	get_tree().create_timer(seconds).timeout.connect(finish.bind(false), CONNECT_ONE_SHOT)
	return await _settled
```

`_settled` is shared by the node, so run one `await_with_timeout` per node at a time.

## Interrupting

```gdscript
var _move_tween: Tween


func move_to(target: Vector2) -> void:
	if _move_tween and _move_tween.is_valid():
		_move_tween.kill()  # the previous move_to stays suspended forever; it never resumes
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target, 0.3)
	await _move_tween.finished
```

A killed tween never emits `finished`, so the earlier caller's `await` never returns. Keep code after such an `await` free of required cleanup, or emit your own signal from both paths.

## Freed nodes

If the node running a coroutine is freed while suspended, the coroutine never resumes; the code after the `await` does not run, so `is_instance_valid(self)` after an `await` is always true when reached. Other nodes the function touches can be freed while it waits; check them after every `await`:

```gdscript
func chase(target: Node2D) -> void:
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(target):
		return
	global_position = target.global_position
```
