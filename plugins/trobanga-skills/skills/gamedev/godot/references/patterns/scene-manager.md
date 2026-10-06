# Scene Manager

## Contents

- Default: change_scene_to_file
- Scene manager with fade and threaded loading
- Notes

## Default: change_scene_to_file

Without a transition or loading screen, change scenes with the tree's own call:

```gdscript
get_tree().change_scene_to_file("res://levels/level_02.tscn")
# or, with a preloaded PackedScene:
get_tree().change_scene_to_packed(LEVEL_02)
```

The swap happens at the end of the frame. To touch the new scene, `await get_tree().scene_changed` (4.5+) first, then use `get_tree().current_scene`.

## Scene manager with fade and threaded loading

When you need a fade, a progress bar, or a level too large to load in one frame, use an autoload. Register `scene_manager.tscn` (root `Node` with this script, plus a `CanvasLayer` → `ColorRect` child for the fade) as autoload `SceneManager`; the script has no `class_name`.

```gdscript
# scene_manager.gd
extends Node

signal load_progress(ratio: float)
signal scene_ready(scene: Node)

@export var fade_time: float = 0.3

@onready var _fade: ColorRect = $CanvasLayer/Fade

var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep working while the game is paused
	_fade.color.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	await _fade_to(1.0)
	var packed := await _load(path)
	if packed:
		get_tree().change_scene_to_packed(packed)
		await get_tree().scene_changed  # 4.5+; on 4.4 and earlier: await get_tree().process_frame
		scene_ready.emit(get_tree().current_scene)
	await _fade_to(0.0)
	_busy = false


func _load(path: String) -> PackedScene:
	if ResourceLoader.has_cached(path):
		return load(path) as PackedScene
	var err := ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("Cannot start loading %s: %s" % [path, error_string(err)])
		return null
	var progress := []
	while true:
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				load_progress.emit(progress[0])
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				return ResourceLoader.load_threaded_get(path) as PackedScene
			_:
				push_error("Failed to load %s" % path)
				return null
	return null


func _fade_to(alpha: float) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP if alpha > 0.0 else Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_time)
	await tween.finished
```

Callers fire and forget: `SceneManager.change_scene("res://levels/level_02.tscn")`. A caller that must wait does `await SceneManager.change_scene(...)`.

## Notes

- Persistent nodes (music player, HUD that survives levels) live in autoloads or under the autoload, never in the level scene.
- To keep the old scene alive (return to an overworld), `remove_child()` it from `get_tree().root` instead of changing scenes, keep the reference, and `add_child()` it back later.
- `load_threaded_request()` loads dependencies on worker threads; the `PackedScene` must still be instantiated on the main thread, which `change_scene_to_packed` does.
