# Bevy-Specific Development Tips

## Bevy 0.18 API Reference

Bevy 0.18 is the current target. This section covers the standard API patterns.

### Material Component Wrapper

Materials are wrapped in `MeshMaterial3d<T>`:

```rust
// Query materials with the wrapper component
Query<&MeshMaterial3d<StandardMaterial>>

// Access the inner handle with .0
fn update_materials(
    query: Query<&MeshMaterial3d<StandardMaterial>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    for material_3d in query.iter() {
        if let Some(material) = materials.get_mut(&material_3d.0) {
            material.emissive = LinearRgba::RED;
        }
    }
}
```

### Observer Pattern (Events)

Bevy uses observers for event-driven communication:

```rust
#[derive(Event, Clone)]  // Must derive Clone!
struct SpellCastEvent { spell_name: String }

app.add_observer(handle_spell_cast);  // Register observer

fn handle_spell_cast(
    trigger: Trigger<SpellCastEvent>,  // Trigger parameter
    // ... other system params
) {
    let event = trigger.event();
    info!("Cast: {}", event.spell_name);
}

fn cast_spell(mut commands: Commands) {
    commands.trigger(SpellCastEvent { spell_name: "Fireball".into() });
}
```

**Key points:**
- Events **must derive `Clone`** in addition to `Event`
- Use `add_observer(handler)` to register
- Handler takes `Trigger<T>` as first parameter, use `.event()` to access data
- Trigger with `commands.trigger()` from any system
- Observers are called directly when triggered (not scheduled like systems)

### Color Operations

Color arithmetic requires extracting components:

```rust
// Extract SRGBA components for math
let emissive = Color::srgb(
    color.to_srgba().red * 0.5,
    color.to_srgba().green * 0.5,
    color.to_srgba().blue * 0.5,
);

// Or use LinearRgba for math operations
let linear = color.to_linear();
let dimmed = LinearRgba::rgb(
    linear.red * 0.5,
    linear.green * 0.5,
    linear.blue * 0.5,
);
```

Direct arithmetic on `Color` (e.g., `color * 0.5`) is not supported. Convert to `LinearRgba` or extract SRGBA components.

---

## 0.17 → 0.18 Migration Guide

If upgrading from Bevy 0.17, these are the key breaking changes:

### Child Method Renames
```rust
// 0.17 → 0.18
clear_children()   → detach_all_children()
remove_children()  → detach_children()
remove_child()     → detach_child()
```

### AmbientLight Split
`AmbientLight` is now per-camera. For world-wide ambient lighting, use `GlobalAmbientLight`:
```rust
// 0.18: Per-camera ambient
commands.spawn((Camera3d::default(), AmbientLight { color: Color::WHITE, brightness: 300.0 }));

// 0.18: Global ambient (replaces old AmbientLight resource behavior)
commands.insert_resource(GlobalAmbientLight { color: Color::WHITE, brightness: 300.0 });
```

### BorderRadius Moved to Node
`BorderRadius` is no longer a separate component — it's a field on `Node`:
```rust
// 0.17: Separate component
commands.spawn((Node { .. }, BorderRadius::all(Val::Px(8.0))));

// 0.18: Field on Node
commands.spawn(Node {
    border_radius: BorderRadius::all(Val::Px(8.0)),
    ..default()
});
```

### LineHeight Separated
`LineHeight` is no longer part of `TextFont` — it's a separate component:
```rust
// 0.18
commands.spawn((
    Text::new("Hello"),
    TextFont { font_size: 16.0, ..default() },
    LineHeight::default(),
));
```

### State Transitions
`NextState::set()` now always fires a transition, even to the same state. Use `set_if_neq()` to avoid redundant transitions:
```rust
// 0.17: set() was a no-op if already in that state
// 0.18: set() always triggers transition
next_state.set(GameState::Playing);         // Always fires
next_state.set_if_neq(GameState::Playing);  // Only if different
```

### RenderTarget Component
`RenderTarget` is now a component instead of a field on `Camera`:
```rust
// 0.18
commands.spawn((
    Camera3d::default(),
    RenderTarget::Window(WindowRef::Primary),
));
```

### EventReader/EventWriter → MessageReader/MessageWriter
`EventReader<T>` and `EventWriter<T>` have been renamed:
```rust
// 0.17
fn my_system(mut events: EventReader<MyEvent>, mut writer: EventWriter<MyEvent>) { ... }

// 0.18
fn my_system(mut events: MessageReader<MyEvent>, mut writer: MessageWriter<MyEvent>) { ... }
```

For mouse input, prefer the accumulated resources over manually iterating events:
```rust
use bevy::input::mouse::{AccumulatedMouseMotion, AccumulatedMouseScroll, MouseScrollUnit};

fn mouse_system(
    motion: Res<AccumulatedMouseMotion>,
    scroll: Res<AccumulatedMouseScroll>,
) {
    let mouse_delta = motion.delta;     // Vec2, aggregated per frame
    let scroll_delta = scroll.delta;    // Vec2, aggregated per frame
    let scroll_unit = scroll.unit;      // MouseScrollUnit::Line or ::Pixel
}
```

### GltfAssetLabel Lifetime Issue
`GltfAssetLabel::from_asset()` borrows its argument, so you can't use it with dynamically constructed `String` paths (the borrow outlives the local). Use the string label syntax instead:
```rust
// ❌ Lifetime error with dynamic paths
let path = format!("models/{name}.glb");
let scene = asset_server.load(GltfAssetLabel::Scene(0).from_asset(&path));

// ✅ Works with dynamic paths
let scene = asset_server.load(format!("models/{name}.glb#Scene0"));
```

### Entity Method Renames
`Entity::row()` has been renamed to `Entity::index_u32()`. `Entity::from_row()` → `Entity::from_index()`.

### Gizmos Changes
`Gizmos::cuboid()` has been renamed to `Gizmos::cube()`.

### ron Dependency
`ron` is no longer re-exported by Bevy. Add it directly to your `Cargo.toml` if needed.

### Feature Renames
Several cargo features have been renamed:
- `animation` → `gltf_animation`
- `bevy_sprite_picking_backend` → `sprite_picking`
- `bevy_ui_picking_backend` → `ui_picking`
- `bevy_mesh_picking_backend` → `mesh_picking`
- `documentation` → `reflect_documentation`
- Individual features consolidated into collection features (`2d`, `3d`, `ui`)

### LoadContext Changes
`LoadContext::path()` now returns `AssetPath` instead of `&Path`. Use `.path().path()` to get the underlying `&Path`.

### Atmosphere Restructured
`Atmosphere` component was restructured. Scattering parameters (previously 9+ fields on `Atmosphere`) are now defined via a `ScatteringMedium` asset referenced by handle:
```rust
// 0.18
Atmosphere {
    bottom_radius: 6371000.0,
    top_radius: 6471000.0,
    ground_albedo: Vec3::splat(0.1),
    medium: Handle<ScatteringMedium>,
}
```

### SimpleExecutor Removed
`SimpleExecutor` has been removed. Use `SingleThreadedExecutor` or `MultiThreadedExecutor` instead. Ensure system ordering is explicit via `before`, `after`, or `chain`.

### MaterialPlugin Changes
Custom material registration no longer requires `MaterialPlugin`. Implement trait methods directly on your material type.

---

## New in Bevy 0.18

### Camera Helpers
Built-in `FreeCamera` and `PanCamera` components for quick camera control. Requires adding the corresponding plugin:
```rust
// Add plugins
app.add_plugins(FreeCameraPlugin);
app.add_plugins(PanCameraPlugin);

// Free-fly camera with WASD + mouse (3D)
commands.spawn((Camera3d::default(), FreeCamera::default()));

// Pan camera with WASD + mouse wheel zoom (2D)
commands.spawn((Camera2d::default(), PanCamera::default()));
```

### Standard Widgets
New built-in UI widgets:
- `Popover` — tooltip-like overlays
- `MenuPopup` — dropdown menus
- `RadioButton` / `RadioGroup` — radio selection
- `AutoDirectionalNavigation` — keyboard/gamepad UI navigation
- `IgnoreScroll` — opt out of scroll containers

### Font Variations
Variable font support:
- Font weight variation
- Strikethrough and underline text decorations
- OpenType feature configuration

### Safe Multi-Component Access
`EntityMut::get_components_mut()` for runtime-checked mutable access to multiple components:
```rust
fn system(mut query: Query<EntityMut>) {
    for mut entity in query.iter_mut() {
        if let Ok((health, armor)) = entity.get_components_mut::<(&mut Health, &mut Armor)>() {
            health.current -= armor.defense;
        }
    }
}
```

### Screenshot Plugin
`EasyScreenshotPlugin` for simple screenshot capture.

### Cargo Feature Collections
Simplified dependency management with collection features:
```toml
[dependencies]
bevy = { version = "0.18", features = ["3d"] }  # All 3D features
bevy = { version = "0.18", features = ["2d"] }  # All 2D features
bevy = { version = "0.18", features = ["ui"] }  # All UI features
```

---

## Using Bevy Registry Examples

**The registry examples are your bible.** Bevy ships with extensive examples that demonstrate best practices and patterns.

**Location:**
```bash
~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/bevy-0.18.0/examples
```

**When to consult registry examples:**
- Before implementing a new feature type
- When unsure about API usage
- To see working patterns for complex systems
- To understand how plugins should be structured
- For reference implementations of common game mechanics

**How to use them:**
1. Browse the examples directory for relevant use cases
2. Study the complete implementation (not just snippets)
3. Note how they structure components, systems, and plugins
4. Adapt patterns to your specific needs

There are MANY examples covering:
- 2D/3D rendering
- Animation
- Audio
- Input handling
- UI systems
- Physics
- Scenes and assets
- And much more

**Always refer to examples before diving into implementation.**

## Plugin Structure

Break your app into discrete modules using plugins whenever possible.

**Why use plugins:**
- Organizes code by feature/domain
- Makes systems reusable
- Improves code discoverability
- Enables modular development
- Follows Bevy best practices

**Plugin pattern:**
```rust
use bevy::prelude::*;

pub struct CombatPlugin;

impl Plugin for CombatPlugin {
    fn build(&self, app: &mut App) {
        app
            .add_observer(handle_damage)
            .add_systems(Startup, setup_combat)
            .add_systems(Update, (
                check_death,
                update_health_bars,
            ));
    }
}

// In main.rs
fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_plugins(CombatPlugin)
        .add_plugins(MovementPlugin)
        .add_plugins(UIPlugin)
        .run();
}
```

**References:**
- Plugin guide: https://bevy.org/learn/quick-start/getting-started/plugins/
- System sets: https://bevy-cheatbook.github.io/programming/system-sets.html

## Build Performance and Optimization

### Dynamic Linking

**Always use dynamic linking during development:**
```bash
cargo build --features bevy/dynamic_linking
```

**Why:**
- 2-3x faster compile times
- Critical for iteration speed
- Only affects development builds

**Setup in `.cargo/config.toml`:**
```toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=lld"]

[target.x86_64-apple-darwin]
rustflags = ["-C", "link-arg=-fuse-ld=/usr/local/opt/llvm/bin/ld64.lld"]
```

**Optimization levels** - See: https://bevy.org/learn/quick-start/getting-started/setup/

For faster dev builds, add to `Cargo.toml`:
```toml
[profile.dev]
opt-level = 1

[profile.dev.package."*"]
opt-level = 3
```

### Build Management

**CRITICAL: Do not delete target binaries freely!**

Bevy takes **minutes** to rebuild from scratch. Be mindful of:

1. **Target directory management:**
   - Avoid `cargo clean` unless absolutely necessary
   - Incremental builds are your friend
   - Each clean rebuild costs valuable development time

2. **Version and dependency management:**
   - Bevy is under active development
   - Be mindful of the version you are using
   - Dependencies can get tangled easily
   - Version mismatches can force complete rebuilds
   - Stick to one Bevy version per project when possible

3. **Crate dependencies:**
   - Adding/removing dependencies triggers rebuilds
   - Changing feature flags triggers rebuilds
   - Plan dependency changes carefully
   - Batch dependency updates when possible

**Best practices:**
- Use `cargo check` for quick validation (no binary)
- Use `cargo build --features bevy/dynamic_linking` for testing
- Only use `cargo clean` when dealing with corrupted build artifacts
- Keep a stable `Cargo.lock` for consistent builds

## Domain-Driven Design for ECS

**Pure ECS structure demands careful data modeling.**

### Think Before You Code

Because it's hard to search a massive list of systems in one file, you must:

1. **Design the data model first:**
   - What entities exist in your domain?
   - What components do they need?
   - What behaviors (systems) operate on them?
   - How do components relate?

2. **Refer to docs and existing code:**
   - Check Bevy examples for similar patterns
   - Review the official docs for component design
   - Look at existing project code for consistency
   - Understand the domain before implementing

3. **Use bounded contexts:**
   - Group related components together
   - Create plugins per domain area
   - Keep systems focused on single responsibilities
   - Avoid cross-domain coupling

### Example Domain Modeling Process

**Bad approach:**
```
❌ Start coding immediately
❌ Add systems to one giant file
❌ Discover missing components mid-implementation
❌ Hard to navigate, hard to maintain
```

**Good approach:**
```
✅ Define the domain (e.g., "Combat System")
✅ List entities (Player, Enemy, Projectile)
✅ List components (Health, Damage, Armor)
✅ List events (DamageEvent, DeathEvent)
✅ List systems (process_damage, check_death, spawn_projectile)
✅ Check examples for similar implementations
✅ Create CombatPlugin
✅ Implement incrementally
✅ Test at each step
```

### File Organization for Discoverability

```
src/
├── main.rs                      # App setup only
├── plugins/
│   ├── mod.rs
│   ├── combat.rs                # CombatPlugin
│   ├── movement.rs              # MovementPlugin
│   └── inventory.rs             # InventoryPlugin
├── components/
│   ├── mod.rs
│   ├── combat.rs                # Health, Armor, Damage
│   ├── movement.rs              # Velocity, Speed
│   └── inventory.rs             # Inventory, Item
└── events.rs                    # All game events
```

**Benefits:**
- Easy to find related code
- Clear domain boundaries
- Plugin-based modularity
- Searchable by feature/domain

## Version Management

**Bevy is under active development.**

1. **Check your Bevy version:**
   ```bash
   cargo tree | rg bevy
   ```

2. **Stay on one version per project:**
   - Avoid mixing Bevy versions
   - Update all Bevy crates together
   - Test thoroughly after version updates

3. **API changes between versions:**
   - Read the migration guide when updating
   - Bevy's API evolves rapidly
   - Code from older versions may not work
   - Examples are version-specific

4. **When seeking help:**
   - Always mention your Bevy version
   - Check if examples match your version
   - Look for version-specific documentation

## Summary Checklist

**Before implementing:**
- [ ] Check registry examples for similar features
- [ ] Design the data model (entities, components, events, systems)
- [ ] Create a plugin for the feature domain
- [ ] Review existing code for patterns

**During development:**
- [ ] Use `cargo build --features bevy/dynamic_linking`
- [ ] Avoid `cargo clean` unless necessary
- [ ] Test incrementally
- [ ] Keep systems focused and organized

**After implementation:**
- [ ] Verify the feature works
- [ ] Check for code organization issues
- [ ] Document domain-specific patterns
- [ ] Update plugin structure if needed
