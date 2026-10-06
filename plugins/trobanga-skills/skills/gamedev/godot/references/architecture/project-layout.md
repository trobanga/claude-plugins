# Project Layout

Group files by game feature, and keep a scene's script, resources and assets next to the `.tscn`. Use this layout for new projects; in an existing project, follow the layout it already has.

```
project.godot
export_presets.cfg
.gitignore
addons/                      third-party plugins, as installed
autoloads/                   one script (or .tscn) per autoload: event_bus.gd, save_manager.gd
components/                  reusable component scenes and scripts
	health_component.gd
	hitbox_component.tscn
	hitbox_component.gd
data/                        Resource class scripts and their .tres instances
	items/
		item_data.gd
		sword.tres
	enemies/
scenes/
	actors/
		player/
			player.tscn
			player.gd
			player.png
			states/          state-node scripts for this actor
		enemies/
			slime/
	levels/
		level_01/
			level_01.tscn
			tileset.tres
	ui/                      see the godot-ui skill
		hud/
		main_menu/
shared/                      art, audio, fonts and shaders used by several features
	audio/
	fonts/
	shaders/
tests/                       GUT or gdUnit4 tests, if the project has them
```

## Conventions

- File and folder names in `snake_case`; the `class_name` inside in `PascalCase` (`player_controller.gd` → `PlayerController`). Paths in an exported pack are case-sensitive even when the developer's file system is not, so mixed case breaks only after export.
- Move and rename files in the editor's FileSystem dock, which rewrites references. After a shell `mv`, move the file's `.import` or `.uid` sidecar with it (4.4+ writes `.uid` files beside scripts and shaders), so UID references still resolve, and grep `.tscn`/`.tres` files for the old `res://` path.
- Commit `*.import` and `*.uid` files; ignore `.godot/` (the import cache) and export output.
- Keep text formats (`.tscn`, `.tres`) in version control; binary `.scn`/`.res` do not diff.

```gitignore
.godot/
/build/
*.tmp
```
