---
name: godot
description: "Writes and reviews Godot 4 GDScript: scene architecture, signals, resources, state machines, save systems. Use when working in a Godot project (project.godot, .gd, .tscn) on anything but UI; for Control-node UI use godot-ui."
---

# Godot 4 GDScript

Read the engine version from `config/features` in `project.godot` (e.g. `PackedStringArray("4.4", "Forward Plus")`) before you use a version-gated feature: `TileMapLayer` needs 4.3, typed `Dictionary[K, V]` needs 4.4.

## Static typing

Type every variable, parameter, return value, signal parameter and `@onready` reference. Use `:=` only where the right-hand side has a static type.

Under the default warning settings each of these is a **parse error**, so the script does not load:

| Code | Error | Write instead |
|---|---|---|
| `var x := JSON.parse_string(s)`, `var o := arr.pop_back()`, `var m := max(a, b)` | type inferred from a Variant | `var x: Variant = …`, `var o: Node = arr.pop_back()`, `maxi`/`maxf`/`clampi`/`clampf` |
| `var v := dict["k"]` on an untyped `Dictionary` | cannot infer the type | `var v: int = dict["k"]`, or a typed `Dictionary[String, int]` |
| `var r = coroutine()` without `await` | "is a coroutine, so it must be called with await" | `var r: int = await coroutine()`; a bare `coroutine()` call whose result is discarded is fine |
| `class_name EventBus` in a script autoloaded as `EventBus` | "Class "EventBus" hides an autoload singleton" | no `class_name` in autoload scripts; the autoload name is already global |
| `var nodes: Array[Node] = enemies` where `enemies: Array[Enemy]` | typed arrays are invariant | `nodes.assign(enemies)` |

`@export var speed: float = 100` is fine: an int literal converts to float.

## Rules

| Prefer | Over | Because |
|---|---|---|
| `@onready var sprite: Sprite2D = $Sprite2D` | `$Sprite2D` or `get_node()` inside `_process`; untyped `@onready` | one lookup, and the type checker sees the node |
| `%UniqueName` for nodes a script depends on | `$A/B/C/D`, `get_parent().get_parent()` | survives rearranging the tree |
| Signal up, call down: children emit, parents call children's methods | a child calling its parent | the child stays reusable in any scene |
| `died.emit()`, `died.connect(_on_died)` | `emit_signal("died")`, string `connect()` | typos fail at parse time |
| Emitting a signal when state changes | polling another node's state in `_process` | no per-frame work, no missed transitions |
| `const SCENE := preload("res://…")` for assets the script always needs | `load()` inside `_process` or a loop | `load()` blocks; loading a level uses `ResourceLoader.load_threaded_request()` |
| `is_instance_valid(node)` before using a node you do not own (a target, another entity) | calling into it unchecked | a call on a freed instance is a runtime error |
| Autoloads for cross-scene services: event bus, save, audio, scene changes | game state that belongs to a scene (player health, enemy lists) | scene-owned state dies with the scene; autoload state leaks across runs |
| Groups and `get_tree().call_group()` for one-to-many | `find_child()` over the whole tree | groups are indexed |
| Small component scenes (HealthComponent, Hitbox) composed under a root | deep script inheritance, god scenes | swap behaviour per scene without new subclasses |
| `const` or `@export` | magic numbers | named, and tunable in the inspector |
| `Array[T]`, `Dictionary[K, V]` (4.4+) | untyped containers | element access keeps its type |
| `TileMapLayer`, one node per layer | `TileMap` | `TileMap` is deprecated since 4.3 |
| `Camera2D.enabled = true` or `make_current()` | `current = true` | `current` does not exist in Godot 4 |
| Resource `.tres` files for designer data (items, stats) | dictionaries of constants in scripts | editable in the inspector, shared by reference |
| JSON in `user://` for save games | `ResourceLoader.load()` of a `.tres`/`.res` from `user://` | a resource file can embed a script that runs on load |
| `move_and_slide()` with `velocity` on `CharacterBody2D/3D` | moving bodies by setting `position` | collisions are resolved |
| Physics and movement in `_physics_process(delta)` | in `_process` | fixed timestep |

Name signals in the past tense (`health_changed`, `died`); prefix private members and signal handlers with `_` and `_on_`. The rest of naming and code order follow the official GDScript style guide.

## Reference

Read the file before you write that kind of code; each holds the one version of its pattern used in this skill.

- Before writing a player or enemy with distinct modes (idle, walk, attack), read [state-machine](references/patterns/state-machine.md).
- Before writing a save system or settings persistence, read [save-load](references/patterns/save-load.md).
- Before writing health, damage, hitboxes or hurtboxes, read [health-and-hitboxes](references/patterns/health-and-hitboxes.md).
- Before defining item, weapon or stat data as custom Resources, read [resource-data](references/patterns/resource-data.md).
- Before writing scene transitions, loading screens or threaded level loading, read [scene-manager](references/patterns/scene-manager.md).
- Before pooling bullets, effects or enemies, read [object-pooling](references/patterns/object-pooling.md).
- Before writing input buffering, rebinding, combos or touch controls, read [input-handling](references/patterns/input-handling.md).
- Before choosing how two nodes talk (signal, call, group, event bus, autoload), read [node-communication](references/architecture/node-communication.md).
- Before splitting an entity into component scenes or using scene inheritance, read [scene-composition](references/architecture/scene-composition.md).
- Before creating folders or moving files in a new project, read [project-layout](references/architecture/project-layout.md).
- Before writing `await` chains, timeouts or tween sequences, read [coroutines](references/gdscript/coroutines.md).
- When a type error or a freed-instance crash puzzles you, read [static-typing](references/gdscript/static-typing.md).

## Editing scenes and verifying

If `mcp__godot__*` tools are available, use them to create scenes, add nodes, run the project and read its debug output. Otherwise:

- Edit `.tscn` files as text. Keep `format=3`; give every new `[ext_resource]` and `[sub_resource]` an `id` that is unique in the file, and let Godot add `uid=` values on its next save rather than inventing them.
- In a fresh checkout, run `godot --headless --path <project> --import` once, so global `class_name`s resolve.
- Run [check_scripts.gd](scripts/check_scripts.gd) (run it; do not read it): `godot --headless --path <project> -s ${CLAUDE_SKILL_DIR}/scripts/check_scripts.gd`. It parses every `.gd` outside `addons/` with the autoloads registered, prints the engine's `SCRIPT ERROR` lines and one `FAIL` line per broken script, and exits 1 if any fails. Plain `--check-only` reports false "Identifier not found" errors for every script that names an autoload.
- Run the game for a few frames: `godot --headless --path <project> --quit-after 120`. It exits 0 even on runtime errors, so search its output for `SCRIPT ERROR` and `ERROR:`.

Done when `check_scripts.gd` exits 0 and the headless run prints no `SCRIPT ERROR`.
