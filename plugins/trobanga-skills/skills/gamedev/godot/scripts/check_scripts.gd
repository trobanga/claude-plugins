# Parses every GDScript file of a Godot 4 project and exits 1 if any fails.
#
#   godot --headless --path <project> -s <this file>
#
# Why not `godot --check-only -s file.gd`: it does not register autoloads, so
# every script that names an autoload fails with "Identifier not found"
# (godotengine/godot#78587). Run as a SceneTree script, the autoloads exist.
# The parse errors themselves are printed by the engine as "SCRIPT ERROR" lines
# above the FAIL lines.
extends SceneTree

# Third-party plugins often extend editor-only classes (EditorPlugin) that do
# not exist outside the editor, which would report false failures.
const SKIPPED_DIRS: PackedStringArray = ["addons"]


func _initialize() -> void:
	# Autoloads are added to the tree after _initialize starts; wait one frame
	# so scripts that reference them resolve.
	await process_frame
	var paths := _collect("res://")
	if paths.is_empty():
		printerr("No .gd files under res:// — is --path pointing at the folder with project.godot?")
		quit(2)
		return
	var failed: PackedStringArray = []
	for path in paths:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		if script == null or not script.can_instantiate():
			failed.append(path)
	for path in failed:
		printerr("FAIL ", path)
	print("checked %d scripts, %d failed" % [paths.size(), failed.size()])
	quit(1 if not failed.is_empty() else 0)


func _collect(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir):
		if not sub.begins_with(".") and not sub in SKIPPED_DIRS:
			out.append_array(_collect(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() == "gd":
			out.append(dir.path_join(file))
	return out
