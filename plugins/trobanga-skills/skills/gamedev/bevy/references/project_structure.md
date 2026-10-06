# Bevy Project Structure and Build Setup

## Layout: one module and one plugin per feature

Group code by game feature, not by kind. Each feature module owns its components, messages, events and systems and exposes one plugin; `main.rs` only assembles plugins.

```
src/
├── main.rs            # App::new(), DefaultPlugins, feature plugins
├── combat/
│   ├── mod.rs         # CombatPlugin: registers everything below
│   ├── components.rs  # Health, Armor
│   ├── events.rs      # Damage (EntityEvent), Death
│   └── systems.rs     # apply_damage, check_death
├── movement/
│   └── mod.rs         # small features stay in one file
└── ui/
    ├── mod.rs         # UiPlugin
    └── hud.rs
```

```rust
// src/combat/mod.rs
pub struct CombatPlugin;

impl Plugin for CombatPlugin {
    fn build(&self, app: &mut App) {
        app.add_observer(systems::apply_damage)
            .add_systems(Update, (systems::regenerate, systems::check_death).chain());
    }
}

// src/main.rs
fn main() {
    App::new()
        .add_plugins((DefaultPlugins, combat::CombatPlugin, movement::MovementPlugin, ui::UiPlugin))
        .run();
}
```

When one plugin's systems must run before another's, export a `SystemSet` from the first and order the sets once in `main.rs` with `configure_sets`.

## Cargo features

Bevy's default features are the collections `2d`, `3d`, `ui` and `audio`. `2d` and `3d` do not pull in `ui` or `audio`, so a project with `default-features = false` lists each collection it uses:

```toml
[dependencies]
bevy = { version = "0.19", default-features = false, features = ["3d", "ui"] }
```

Optional pieces are separate features, among them `gltf_animation`, `mesh_picking`, `sprite_picking`, `ui_picking`, `free_camera`, `pan_camera`, `bevy_feathers` and `dynamic_linking`. Check the list in the `[features]` table of the `Cargo.toml` next to the examples directory.

## Build profile

From the [official setup guide](https://bevy.org/learn/quick-start/getting-started/setup/):

```toml
# Cargo.toml
[profile.dev]
opt-level = 1

[profile.dev.package."*"]
opt-level = 3
```

```toml
# .cargo/config.toml — Linux, needs clang and lld installed
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=lld"]
```

On macOS the default linker is already faster than lld; leave it.
