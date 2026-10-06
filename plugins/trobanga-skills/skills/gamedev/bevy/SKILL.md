---
name: bevy
description: Gives the current Bevy 0.19 API, the system-ordering rules and the known pitfalls for writing Rust code against the Bevy game engine. Use when writing or debugging Bevy systems, components, observers or messages, building Bevy UI, loading glTF scenes or animations, or porting code from an older Bevy release.
---

# Bevy 0.19

Your pretrained Bevy knowledge is mostly older than 0.19; where it disagrees with this file, this file wins. Before writing code, read the project's Bevy version from `Cargo.lock`. If it is not 0.19, the [migration guides](https://bevy.org/learn/migration-guides/) and `docs.rs/bevy/<version>` take precedence over this skill.

## Examples first

Bevy ships its examples inside the crate. Before writing a feature, find the example closest to it and copy its pattern:

```bash
v=$(awk '/^name = "bevy"$/{getline; gsub(/version = |"/,""); print; exit}' Cargo.lock)
ls "${CARGO_HOME:-$HOME/.cargo}"/registry/src/*/bevy-"$v"/examples
```

The directory exists once the project has been built. Search it with `rg` for the type you are about to use.

## System ordering

Systems in one `add_systems` tuple have **no defined order**. The executor runs them in parallel where their data access allows and in arbitrary order otherwise; the order you write them in means nothing. Order them explicitly:

```rust
app.add_systems(
    Update,
    (
        handle_input,
        apply_damage,
        update_health_bars,
    )
        .chain(), // runs in this order; commands of each are applied before the next
);

app.add_systems(Update, play_hit_sound.after(apply_damage));
```

Use `.chain()` for a sequence, `.before()` / `.after()` for single edges, and a `SystemSet` ordered with `app.configure_sets(Update, (A, B).chain())` for orderings across plugins. Within one schedule run, a system sees another system's `Commands` only if it is ordered after it.

## Current API

- **Observers and events.** `#[derive(Event)]` for a global event, `#[derive(EntityEvent)]` with an `entity: Entity` field for a targeted one. Trigger with `commands.trigger(ev)`; observe with `app.add_observer(f)` or `commands.entity(e).observe(f)`. The observer's first parameter is `On<E>`, which derefs to the event: `fn f(explode: On<Explode>) { explode.entity }`. Component lifecycle events are `On<Add, T>`, `Insert`, `Discard`, `Remove`, `Despawn`. Observers accept `.run_if(...)`.
- **Messages** are the buffered channel between scheduled systems: `#[derive(Message)]`, register with `app.add_message::<M>()`, write with `MessageWriter<M>::write`, read with `MessageReader<M>::read`. A message survives one frame boundary, then is dropped unread; order the reader after the writer to read it the same frame. Neither `Event` nor `Message` requires `Clone`.
- **Fallible access.** `query.single()` / `single_mut()` return `Result`. Systems may return `Result` and use `?`; `let Ok(x) = query.single() else { return };` skips a frame silently.
- **Resources are components.** `#[derive(Resource)]` implements `Component`; a type cannot derive both. Broad queries such as `Query<EntityMut>` match resource entities and can conflict with `Res`/`ResMut` — add `Without<bevy::ecs::resource::IsResource>`.
- **States.** `next_state.set(s)` always runs the transition schedules, even to the current state. To skip a same-state transition write `(*next_state).set_if_neq(s)`: on a `ResMut`, plain `next_state.set_if_neq(s)` resolves to the change-detection method `DetectChangesMut::set_if_neq` and does not compile.
- **Mouse input.** Read `Res<AccumulatedMouseMotion>` and `Res<AccumulatedMouseScroll>` (`.delta: Vec2`, scroll also has `.unit`) instead of iterating mouse messages.
- **Colors.** `Color` has no arithmetic. Convert first: `color.to_linear() * 0.5` (`LinearRgba` is a vector space; alpha is scaled too).

## Old patterns

Code from tutorials, older projects and your own priors uses these. Translate on sight.

| Old | Current | Changed in |
|---|---|---|
| `Trigger<E>`, `trigger.target()` | `On<E>`; the target is a field of the `EntityEvent` | 0.17 |
| `OnAdd`, `OnInsert`, `OnRemove`, `OnDespawn` | `Add`, `Insert`, `Remove`, `Despawn` | 0.17 |
| `OnReplace` / `Replace`, `#[component(on_replace)]` | `Discard`, `#[component(on_discard)]` | 0.17 / 0.19 |
| `world.trigger_targets(ev, entity)` | `EntityEvent` with an `entity` field, `trigger(ev)` | 0.17 |
| `EventReader`, `EventWriter`, `Events<T>`, `send_event` | `MessageReader`, `MessageWriter`, `Messages<T>`, `write_message` | 0.17 |
| `get_single()`, `get_single_mut()` | `single()`, `single_mut()` returning `Result` | 0.16 |
| `Handle<StandardMaterial>` as a component | `MeshMaterial3d<StandardMaterial>` (handle in `.0`), `Mesh3d` | 0.15 |
| `SceneRoot`, `SceneInstanceReady`, `Scene`, `DynamicScene`, `bevy::scene` | `WorldAssetRoot`, `WorldInstanceReady`, `WorldAsset`, `DynamicWorld`, `bevy::world_serialization` (`bevy::scene` is now BSN) | 0.19 |
| `clear_children`, `remove_children`, `remove_child` | `detach_all_children`, `detach_children`, `detach_child` | 0.18 |
| `AmbientLight` resource | `GlobalAmbientLight` resource; `AmbientLight` is a per-camera override component | 0.18 |
| `Camera { target, .. }` | `RenderTarget` component on the camera entity | 0.18 |
| `BorderRadius` component | `Node { border_radius, .. }` | 0.18 |
| `TextFont { font_size: 16.0, font: handle, line_height }` | `font_size: FontSize::Px(16.0)`, `font: handle.into()`, separate `LineHeight` component | 0.18 / 0.19 |
| `TextLayout::new_with_justify` etc. | `TextLayout::justify`, `linebreak`, `no_wrap` | 0.19 |
| `#[derive(Component, Resource)]` on one type | two types | 0.19 |
| adding `UiWidgetsPlugins`, `InputDispatchPlugin` | already in `DefaultPlugins` | 0.19 |
| `CoreScrollbarThumb`, `CoreSliderDragState` | `ScrollbarThumb`, `SliderDragState` | 0.19 |
| `impl Command<Result> for C` | `impl Command for C { type Out = Result; .. }` | 0.19 |
| `Gizmos::cuboid` | `Gizmos::cube` | 0.18 |

## Build and verify

- `cargo check` after every change; it is the fast compile gate.
- Build and run with `cargo run --features bevy/dynamic_linking` during development; leave the feature off for release builds.
- Keep `target/`: a clean Bevy rebuild takes minutes, so run `cargo clean` only for corrupted artifacts.
- `cargo check` cannot see rendering, layout or feel. After each visible change, ask the user to run the game and confirm what they see.

## References

- Before designing components, queries, observers or messages, or when a query panics or conflicts, read [ecs_patterns.md](references/ecs_patterns.md).
- Before building or changing UI, read [ui_development.md](references/ui_development.md).
- Before loading glTF scenes, playing animations, or adding rollback netcode with `bevy_ggrs`, read [animation_gltf.md](references/animation_gltf.md).
- Before creating a project, adding a module or plugin, or changing Bevy's cargo features or build profile, read [project_structure.md](references/project_structure.md).
