# Save and Load

## Contents

- Default: JSON in user://
- Untrusted files: what not to load
- Save manager (autoload)
- Saveable nodes
- Versioning
- Settings with ConfigFile
- Escape hatch: binary store_var
- Gotchas

## Default: JSON in user://

Save game state as JSON under `user://`. It is data only, so loading a file a player downloaded cannot run code, and it diffs and debugs as text. Use `ConfigFile` for user settings (volume, key bindings), not game state.

JSON has no Godot types: convert `Vector2`, `Color` and the like to arrays or dictionaries, and expect every number back as a `float`; cast with `int()` where the field is an integer.

## Untrusted files: what not to load

`ResourceLoader.load()` of a `.tres`, `.res` or `.tscn` from `user://` executes any script embedded in the file, for example a sub-resource script whose `_init()` runs on load. `ConfigFile`, `str_to_var()` and `bytes_to_var_with_objects()` can also construct objects. So a save a player downloaded or edited by hand is untrusted. Keep `.tres` save files only for data that never leaves the player's machine; JSON and `FileAccess.get_var()` (without objects) cannot run code.

`FileAccess.open_encrypted_with_pass()` with a key in the source code only obfuscates: the key ships inside the exported game. Use it to deter casual editing, not as security.

## Save manager (autoload)

Register as autoload `SaveManager`; the script has no `class_name`.

```gdscript
# save_manager.gd
extends Node

signal saved(slot: int)
signal loaded(slot: int)
signal failed(slot: int, message: String)

const SAVE_DIR := "user://saves/"
const VERSION := 2


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func path_for(slot: int) -> String:
	return SAVE_DIR + "slot_%02d.json" % slot


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(path_for(slot))


func save_game(slot: int) -> Error:
	var data := {
		"version": VERSION,
		"timestamp": int(Time.get_unix_time_from_system()),
		"scene": get_tree().current_scene.scene_file_path,
		"nodes": _collect(),
	}
	# Write to a temp file, then rename, so a crash mid-write keeps the old save.
	var tmp := path_for(slot) + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		var err := FileAccess.get_open_error()
		failed.emit(slot, error_string(err))
		return err
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var err := DirAccess.rename_absolute(tmp, path_for(slot))
	if err == OK:
		saved.emit(slot)
	else:
		failed.emit(slot, error_string(err))
	return err


func load_game(slot: int) -> Error:
	var text := FileAccess.get_file_as_string(path_for(slot))
	if text.is_empty():
		failed.emit(slot, "missing or empty save")
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		failed.emit(slot, "corrupt save")
		return ERR_PARSE_ERROR
	var data: Dictionary = migrate(parsed)
	get_tree().change_scene_to_file(data["scene"])
	await get_tree().scene_changed  # 4.5+; on 4.4 and earlier: await get_tree().process_frame
	_apply(data["nodes"])
	loaded.emit(slot)
	return OK


func _collect() -> Dictionary:
	var out := {}
	for node in get_tree().get_nodes_in_group(&"saveable"):
		out[str(node.get_path())] = node.call("save_state")
	return out


func _apply(nodes: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group(&"saveable"):
		var key := str(node.get_path())
		if nodes.has(key):
			node.call("load_state", nodes[key])
```

## Saveable nodes

A node joins the group `saveable` and implements `save_state() -> Dictionary` and `load_state(data: Dictionary) -> void`. The node path is the key, so give saveable nodes stable names; nodes spawned at runtime need an explicit `id` field instead and must be re-instantiated before `_apply`.

```gdscript
# chest.gd
extends StaticBody2D

var opened: bool = false
var gold: int = 10


func _ready() -> void:
	add_to_group(&"saveable")


func save_state() -> Dictionary:
	return {"opened": opened, "gold": gold, "pos": [position.x, position.y]}


func load_state(data: Dictionary) -> void:
	opened = data.get("opened", false)
	gold = int(data.get("gold", 0))  # JSON numbers come back as float
	var pos: Array = data.get("pos", [position.x, position.y])
	position = Vector2(pos[0], pos[1])
```

## Versioning

Store `version` in every save and upgrade old dictionaries step by step on load.

```gdscript
# save_manager.gd, continued
func migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 1))
	if v < 2:
		# v1 stored "hp"; v2 renamed it to "health".
		for state: Dictionary in data["nodes"].values():
			if state.has("hp"):
				state["health"] = state["hp"]
				state.erase("hp")
		v = 2
	data["version"] = v
	return data
```

## Settings with ConfigFile

```gdscript
const SETTINGS_PATH := "user://settings.cfg"


func save_settings(music_db: float, fullscreen: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_db", music_db)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return  # first run: keep defaults
	var music_db: float = cfg.get_value("audio", "music_db", 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), music_db)
```

## Escape hatch: binary store_var

When saves grow large (big voxel worlds, thousands of entities) and JSON becomes slow, write the same dictionary with `FileAccess.store_var(data)` and read it with `get_var()`. It keeps Godot types (`Vector2`, ints stay ints), and with `allow_objects` left `false` it cannot deserialise objects, so it stays safe.

## Gotchas

- `JSON.stringify` turns `Vector2(1, 2)` into the string `"(1.0, 2.0)"`, which does not parse back; convert it yourself.
- Save at safe points (not mid-transition); `get_tree().paused` or a state flag tells you when.
- Store resource paths (`res://items/sword.tres`) or ids, never node references or object instances.
