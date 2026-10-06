# State Machines

## Contents

- Choosing a variant
- Enum state machine (default)
- State-node machine
- Hierarchical states
- Pushdown (stack) machine
- Transition table

## Choosing a variant

Default to the **enum** machine: one script, a `match` per frame, a setter that runs exit/enter. Switch to **state nodes** when a state needs its own child nodes (timers, raycasts, audio) or its script outgrows ~50 lines. Use a **pushdown** machine only when a state must return to whatever was active before it (pause, a dialogue that interrupts any state).

The enum below is called `Mode`, not `State`, so it never collides with the global `State` class of the node variant.

## Enum state machine (default)

```gdscript
class_name Player
extends CharacterBody2D

signal mode_changed(old_mode: Mode, new_mode: Mode)

enum Mode { IDLE, WALK, JUMP, ATTACK, HURT }

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0

var mode: Mode = Mode.IDLE:
	set(value):
		if mode == value:
			return
		var old := mode
		_exit_mode(old)
		mode = value
		_enter_mode(value)
		mode_changed.emit(old, value)

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_anim.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var input_dir := Input.get_axis("move_left", "move_right")
	match mode:
		Mode.IDLE, Mode.WALK:
			velocity.x = input_dir * move_speed
			if Input.is_action_just_pressed("jump") and is_on_floor():
				mode = Mode.JUMP
			elif Input.is_action_just_pressed("attack"):
				mode = Mode.ATTACK
			else:
				mode = Mode.WALK if input_dir != 0.0 else Mode.IDLE
		Mode.JUMP:
			velocity.x = input_dir * move_speed
			if is_on_floor() and velocity.y >= 0.0:
				mode = Mode.IDLE
		Mode.ATTACK, Mode.HURT:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
	move_and_slide()


func take_hit() -> void:
	mode = Mode.HURT


func _enter_mode(m: Mode) -> void:
	match m:
		Mode.IDLE: _anim.play("idle")
		Mode.WALK: _anim.play("walk")
		Mode.JUMP:
			velocity.y = jump_velocity
			_anim.play("jump")
		Mode.ATTACK:
			_hitbox.monitoring = true
			_anim.play("attack")
		Mode.HURT: _anim.play("hurt")


func _exit_mode(m: Mode) -> void:
	if m == Mode.ATTACK:
		_hitbox.set_deferred("monitoring", false)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name in [&"attack", &"hurt"]:
		mode = Mode.IDLE
```

`get_gravity()` on physics bodies needs 4.3; on older versions read `ProjectSettings.get_setting("physics/2d/default_gravity")`. Change `monitoring` with `set_deferred` when it can happen inside a physics callback.

## State-node machine

Each state is a child node with its own script. The machine forwards the frame callbacks to the active state only.

```gdscript
# state.gd
class_name State
extends Node

## Set by the StateMachine before the first enter().
var machine: StateMachine


func enter(_msg: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
```

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

signal state_changed(old_state: StringName, new_state: StringName)

@export var initial_state: State

var current: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.machine = self
	current = initial_state
	current.enter()


func _process(delta: float) -> void:
	current.update(delta)


func _physics_process(delta: float) -> void:
	current.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	current.handle_input(event)


func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	var next: State = _states.get(state_name)
	if next == null:
		push_error("Unknown state: %s" % state_name)
		return
	if next == current:
		return
	var old := current
	old.exit()
	current = next
	current.enter(msg)
	state_changed.emit(old.name, current.name)
```

```gdscript
# idle.gd — a concrete state; the owning body is injected, not searched for
extends State

@export var player: Player


func enter(_msg: Dictionary = {}) -> void:
	player.velocity.x = 0.0


func physics_update(_delta: float) -> void:
	if Input.get_axis("move_left", "move_right") != 0.0:
		machine.transition_to(&"Walk")


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and player.is_on_floor():
		machine.transition_to(&"Jump", {"boost": false})
```

```
Player (CharacterBody2D)
├── AnimationPlayer
└── StateMachine          initial_state → Idle
    ├── Idle (idle.gd)    player → ../..
    ├── Walk
    └── Jump
```

`Dictionary[StringName, State]` needs 4.4; on 4.3 and earlier declare `var _states: Dictionary = {}`. A parent's `_ready` runs after its children's, so `machine` is still null in every state's `_ready`; do setup that needs it in `enter()`.

## Hierarchical states

A composite state owns substates and forwards to the active one (Grounded → Idle/Walk, Airborne → Jump/Fall). Shared behaviour, such as "Jump is allowed from any grounded substate", lives once in the parent.

```gdscript
class_name CompositeState
extends State

@export var initial_substate: State

var active: State
var _substates: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			_substates[child.name] = child


func enter(msg: Dictionary = {}) -> void:
	for sub: State in _substates.values():
		sub.machine = machine
	active = initial_substate
	active.enter(msg)


func exit() -> void:
	active.exit()


func physics_update(delta: float) -> void:
	active.physics_update(delta)


func switch_substate(state_name: StringName) -> void:
	var next: State = _substates.get(state_name)
	if next == null or next == active:
		return
	active.exit()
	active = next
	active.enter()
```

## Pushdown (stack) machine

```gdscript
class_name PushdownMachine
extends Node

var _stack: Array[State] = []


func push(state: State) -> void:
	if not _stack.is_empty():
		_stack.back().exit()
	_stack.push_back(state)
	state.enter()


func pop() -> void:
	if _stack.is_empty():
		return
	var top: State = _stack.pop_back()
	top.exit()
	if not _stack.is_empty():
		_stack.back().enter({"resumed": true})


func _physics_process(delta: float) -> void:
	if not _stack.is_empty():
		_stack.back().physics_update(delta)
```

## Transition table

When illegal transitions are a real source of bugs, guard the setter with a table instead of scattering checks:

```gdscript
const ALLOWED: Dictionary = {
	Mode.IDLE: [Mode.WALK, Mode.JUMP, Mode.ATTACK],
	Mode.WALK: [Mode.IDLE, Mode.JUMP, Mode.ATTACK],
	Mode.JUMP: [Mode.IDLE],
	Mode.ATTACK: [Mode.IDLE],
}
const FROM_ANY: Array[Mode] = [Mode.HURT]


func can_enter(from: Mode, to: Mode) -> bool:
	return to in FROM_ANY or to in ALLOWED.get(from, [])
```

Call `can_enter(mode, value)` at the top of the `mode` setter and return early when it is false.
