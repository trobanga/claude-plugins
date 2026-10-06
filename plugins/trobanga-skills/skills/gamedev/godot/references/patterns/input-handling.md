# Input Handling

## Contents

- Actions, not keys
- Input buffer and coyote time
- Input contexts
- Rebinding and persistence
- Combo detection
- Touch
- Gotchas

## Actions, not keys

Define actions in Project Settings → Input Map and query them by name. Read continuous input (movement) by polling in `_physics_process`; react to one-shot input (pause, interact) in `_unhandled_input`, so UI that consumed the event blocks it.

```gdscript
func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		get_viewport().set_input_as_handled()
```

## Input buffer and coyote time

A buffer remembers a press for a short window, so a jump pressed just before landing still fires. Coyote time allows a jump just after walking off a ledge.

```gdscript
class_name InputBuffer
extends Node

@export var window: float = 0.12
@export var actions: Array[StringName] = [&"jump", &"attack", &"dash"]

var _pressed_at: Dictionary[StringName, float] = {}


func _unhandled_input(event: InputEvent) -> void:
	for action in actions:
		if event.is_action_pressed(action):
			_pressed_at[action] = _now()


## True once per buffered press: the press is consumed.
func consume(action: StringName) -> bool:
	if _now() - _pressed_at.get(action, -INF) <= window:
		_pressed_at.erase(action)
		return true
	return false


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
```

```gdscript
const COYOTE_TIME := 0.1

var _coyote: float = 0.0

@onready var _buffer: InputBuffer = $InputBuffer


func _physics_process(delta: float) -> void:
	_coyote = COYOTE_TIME if is_on_floor() else maxf(_coyote - delta, 0.0)
	if _coyote > 0.0 and _buffer.consume(&"jump"):
		velocity.y = jump_velocity
		_coyote = 0.0
	velocity += get_gravity() * delta
	move_and_slide()
```

## Input contexts

When the same button means different things (gameplay, menu, vehicle), keep a stack of contexts and let only the top one handle input.

```gdscript
class_name InputContext
extends RefCounted

var _bindings: Dictionary[StringName, Callable] = {}


func bind(action: StringName, callback: Callable) -> InputContext:
	_bindings[action] = callback
	return self


func handle(event: InputEvent) -> bool:
	for action in _bindings:
		if event.is_action_pressed(action):
			_bindings[action].call()
			return true
	return false
```

```gdscript
# input_router.gd — autoload InputRouter, no class_name
extends Node

var _stack: Array[InputContext] = []


func push(context: InputContext) -> void:
	_stack.push_back(context)


func pop() -> void:
	if not _stack.is_empty():
		_stack.pop_back()


func _unhandled_input(event: InputEvent) -> void:
	if not _stack.is_empty() and _stack.back().handle(event):
		get_viewport().set_input_as_handled()
```

## Rebinding and persistence

Rebind with `InputMap`, persist with `ConfigFile` (a local settings file; see the trust note in save-load). Store plain codes, not `InputEvent` objects.

```gdscript
# keybinds.gd — autoload Keybinds, no class_name
extends Node

const PATH := "user://keybinds.cfg"


func _ready() -> void:
	load_bindings()


func rebind_key(action: StringName, physical_keycode: Key) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	var key := InputEventKey.new()
	key.physical_keycode = physical_keycode
	InputMap.action_add_event(action, key)
	save_bindings()


func save_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		var keys: Array[int] = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				keys.append(ev.physical_keycode if ev.physical_keycode else ev.keycode)
		cfg.set_value("keys", action, keys)
	cfg.save(PATH)


func load_bindings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for action in cfg.get_section_keys("keys"):
		if not InputMap.has_action(action):
			continue
		var keys: Array = cfg.get_value("keys", action, [])
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		for code in keys:
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action, key)
```

`InputMap.load_from_project_settings()` restores the defaults. Joypad buttons follow the same pattern with `InputEventJoypadButton.button_index`.

## Combo detection

```gdscript
class_name ComboDetector
extends Node

signal combo(combo_name: StringName)

@export var step_window: float = 0.4
@export var tracked: Array[StringName] = [&"up", &"down", &"left", &"right", &"punch"]

var _combos: Dictionary[StringName, Array] = {}
var _history: Array[StringName] = []
var _last_time: float = 0.0


func register(combo_name: StringName, sequence: Array[StringName]) -> void:
	_combos[combo_name] = sequence


func _unhandled_input(event: InputEvent) -> void:
	for action in tracked:
		if event.is_action_pressed(action):
			_record(action)


func _record(action: StringName) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_time > step_window:
		_history.clear()
	_last_time = now
	_history.append(action)
	for combo_name in _combos:
		var seq: Array = _combos[combo_name]
		if _history.size() >= seq.size() and _history.slice(-seq.size()) == seq:
			combo.emit(combo_name)
			_history.clear()
			return
```

Register longer combos first when one is a suffix of another.

## Touch

For on-screen controls use `TouchScreenButton` with an `action` set, so touch feeds the same Input Map actions. Handle raw `InputEventScreenTouch`/`InputEventScreenDrag` only for gestures, and track fingers by `event.index`. To test touch with a mouse, enable Project Settings → Input Devices → Pointing → Emulate Touch From Mouse.

## Gotchas

- Input stops while paused unless the node's `process_mode` is `PROCESS_MODE_ALWAYS` or `PROCESS_MODE_WHEN_PAUSED`.
- Handling the same action in both `_input` and `_physics_process` fires it twice.
- World-space mouse position: `get_global_mouse_position()`; screen-space: `get_viewport().get_mouse_position()`.
