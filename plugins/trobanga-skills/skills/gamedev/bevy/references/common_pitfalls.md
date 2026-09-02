# Common Bevy Pitfalls Reference

## 1. Observer Pattern Mistakes

**❌ Problem:** Forgetting `Clone` derive on events:
```rust
#[derive(Event)]  // Missing Clone!
struct MyEvent { data: String }
```

**Symptoms:**
- Compilation error: trait bound `Clone` not satisfied

**✅ Solution:**
```rust
#[derive(Event, Clone)]
struct MyEvent { data: String }

app.add_observer(handle_event);

fn handle_event(trigger: Trigger<MyEvent>) {
    let event = trigger.event();
}

fn emit_event(mut commands: Commands) {
    commands.trigger(MyEvent { data: "test".into() });
}
```

## 2. Material Handle Access

**❌ Problem:** Querying raw handles instead of the wrapper component:
```rust
Query<&Handle<StandardMaterial>>  // Won't compile
```

**Symptoms:**
- `Handle<StandardMaterial> is not a Component`
- Query trait bounds not satisfied

**✅ Solution:**
Use `MeshMaterial3d<T>`:
```rust
Query<&MeshMaterial3d<StandardMaterial>>

// Access handle with .0
for material_3d in query.iter() {
    if let Some(material) = materials.get_mut(&material_3d.0) {
        material.emissive = color;
    }
}
```

## 3. Forgetting to Register Systems

**❌ Problem:**
```rust
// Created system but forgot to add to app
pub fn my_new_system() { /* ... */ }
```

**✅ Solution:**
Always add to `main.rs`:
```rust
.add_systems(Update, my_new_system)
```

## 4. Borrowing Conflicts

**❌ Problem:**
```rust
// Can't have multiple mutable borrows
mut query1: Query<&mut Transform>,
mut query2: Query<&mut Transform>,  // Error!
```

**✅ Solution:**
```rust
// Use get_many_mut for specific entities
mut query: Query<&mut Transform>,

if let Ok([mut a, mut b]) = query.get_many_mut([entity_a, entity_b]) {
    // Can mutate both
}
```

## 5. Infinite Loops with Observers

**❌ Problem:**
```rust
// Observer triggers the same event it handles
fn handle_event(
    trigger: Trigger<MyEvent>,
    mut commands: Commands,
) {
    // Re-triggers endlessly!
    commands.trigger(MyEvent { data: "loop".into() });
}
```

**✅ Solution:**
Use different event types for input vs. output, or add a termination condition:
```rust
#[derive(Event, Clone)]
struct RawInput { action: String }

#[derive(Event, Clone)]
struct ProcessedResult { outcome: String }

fn handle_input(
    trigger: Trigger<RawInput>,
    mut commands: Commands,
) {
    // Triggers a *different* event — no loop
    commands.trigger(ProcessedResult {
        outcome: format!("Handled: {}", trigger.event().action),
    });
}
```

## 6. Not Using Changed<T>

**❌ Problem:**
```rust
// Runs every frame for every entity
fn system(query: Query<&BigFive>) {
    for traits in query.iter() {
        // Expensive calculation every frame
    }
}
```

**✅ Solution:**
```rust
// Only runs when BigFive changes
fn system(query: Query<&BigFive, Changed<BigFive>>) {
    for traits in query.iter() {
        // Only when needed
    }
}
```

## 7. Entity Queries After Despawn

**❌ Problem:**
```rust
commands.entity(entity).despawn();
// Later in same system
let component = query.get(entity).unwrap();  // Crash!
```

**✅ Solution:**
Commands apply at end of stage. Use `Ok()` pattern:
```rust
if let Ok(component) = query.get(entity) {
    // Safe
}
```

## 8. Material/Asset Handle Confusion

**❌ Problem:**
```rust
// Created material but didn't store handle
materials.add(StandardMaterial { .. });  // Handle dropped!
```

**✅ Solution:**
```rust
let material_handle = materials.add(StandardMaterial { .. });
commands.spawn((
    MeshMaterial3d(material_handle),
    // ...
));
```

## 9. System Ordering Issues

**❌ Problem:**
```rust
// UI updates before state changes
.add_systems(Update, (
    update_ui,
    process_input,  // Wrong order!
))
```

**✅ Solution:**
Order systems by dependencies:
```rust
.add_systems(Update, (
    // Input processing
    process_input,

    // State changes
    update_state,

    // UI updates (reads state)
    update_ui,
))
```

## 10. Not Filtering Queries Early

**❌ Problem:**
```rust
// Filter in loop (inefficient)
Query<(&A, Option<&B>, Option<&C>)>
// Then check in loop
```

**✅ Solution:**
```rust
// Filter in query (efficient)
Query<&A, (With<B>, Without<C>)>
```

## 11. BorderRadius as Separate Component

**❌ Problem:**
```rust
// BorderRadius as a separate component does nothing in 0.18
commands.spawn((
    Node { ..default() },
    BorderRadius::all(Val::Px(8.0)),  // Ignored!
));
```

**✅ Solution:**
`BorderRadius` is a field on `Node`:
```rust
commands.spawn(Node {
    border_radius: BorderRadius::all(Val::Px(8.0)),
    ..default()
});
```

## 12. Renamed Child Methods

**❌ Problem:**
```rust
// These methods were renamed in 0.18
commands.entity(parent).clear_children();           // Doesn't exist
commands.entity(parent).remove_children(&[child]);  // Doesn't exist
```

**✅ Solution:**
```rust
commands.entity(parent).detach_all_children();     // Was clear_children()
commands.entity(parent).detach_children(&[child]); // Was remove_children()
```

## 13. Redundant State Transitions

**❌ Problem:**
```rust
// set() ALWAYS fires a transition, even to the current state
fn system(mut next_state: ResMut<NextState<GameState>>) {
    next_state.set(GameState::Playing);  // Fires every frame!
}
```

**✅ Solution:**
Use `set_if_neq()` to avoid redundant transitions:
```rust
fn system(mut next_state: ResMut<NextState<GameState>>) {
    next_state.set_if_neq(GameState::Playing);  // Only fires on actual change
}
```

## 14. glTF Scene Material Patching — Use Added<> + ChildOf, Not Observer

**❌ Problem:**
Using `SceneInstanceReady` observer to patch materials on glTF scenes is unreliable across multiple scene instances — materials may not all exist when the observer fires:
```rust
// Observer may miss materials that spawn in later frames
fn on_scene_ready(trigger: On<SceneInstanceReady>, ...) {
    // Patching materials here is fragile
}
```

**✅ Solution:**
Use `Added<MeshMaterial3d>` in an `Update` system with `ChildOf` parent-chain walk to scope to specific entities:
```rust
fn apply_texture(
    new_materials: Query<(Entity, &MeshMaterial3d<StandardMaterial>), Added<MeshMaterial3d<StandardMaterial>>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    parents: Query<&ChildOf>,
    players: Query<(), With<Player>>,
) {
    for (entity, mat_handle) in &new_materials {
        // Walk up parent chain to verify ancestry
        let mut current = entity;
        let is_descendant = loop {
            if players.get(current).is_ok() { break true; }
            match parents.get(current) {
                Ok(child_of) => current = child_of.parent(),
                Err(_) => break false,
            }
        };
        if !is_descendant { continue; }

        if let Some(material) = materials.get_mut(mat_handle) {
            material.base_color_texture = Some(texture.clone());
        }
    }
}
```

**Key insight:** `SceneInstanceReady` is best for one-shot setup (starting animations). `Added<>` with ancestry checks is best for material patching.

## 15. Gltf::named_animations — Use Exact Key Lookups

**❌ Problem:**
Using `.iter().find()` with `.contains()` on `named_animations` matches unpredictably because `HashMap` iteration order is non-deterministic:
```rust
// May match "falling idle" instead of "unarmed/idle"
gltf.named_animations.iter()
    .find(|(name, _)| name.contains("idle"))
```

**✅ Solution:**
Use exact key lookup with fallback chain:
```rust
let clip = gltf.named_animations.get("unarmed/idle")
    .or_else(|| gltf.named_animations.get("unarmed/idle (2)"))
    .or_else(|| {
        // Last resort: find by suffix (still non-deterministic but acceptable as fallback)
        gltf.named_animations.iter()
            .find(|(name, _)| name.ends_with("/idle"))
            .map(|(_, handle)| handle)
    });
```

## 16. AnimationGraph Required Even for Single Clips

**❌ Problem:**
Trying to play an animation clip directly without wrapping in `AnimationGraph`:
```rust
// Won't work — AnimationPlayer needs an AnimationGraph
player.play(clip_handle);  // clip_handle is Handle<AnimationClip>
```

**✅ Solution:**
Wrap in `AnimationGraph` and insert `AnimationGraphHandle` on the `AnimationPlayer` entity (a descendant of `SceneRoot`, not the root itself):
```rust
let (graph, index) = AnimationGraph::from_clip(clip_handle);
let graph_handle = graphs.add(graph);

// Find AnimationPlayer in descendants
for descendant in children.iter_descendants(scene_entity) {
    if let Ok(mut player) = animation_players.get_mut(descendant) {
        player.play(index).repeat();
        commands.entity(descendant)
            .insert(AnimationGraphHandle(graph_handle.clone()));
    }
}
```

## 17. GGRS Rollback Destroys Scene Hierarchies and Animations

**❌ Problem:**
Putting `SceneRoot`, animations, and `.add_rollback()` on the same entity. GGRS despawns `Rollback` entities during rollback if they didn't exist at the snapshot frame, destroying the scene tree:
```rust
// Everything on one entity — GGRS will destroy this periodically
commands.spawn((
    SceneRoot(scene),
    Transform::default(),
    Player { handle },
    Velocity::default(),
)).add_rollback();
```

**Symptoms:**
- T-pose (animations lost)
- Ghost trails / blur (duplicate visual entities accumulating)
- Scene hierarchy periodically destroyed and recreated

**✅ Solution:**
Split into rollback (sim) entity and visual entity. Use a resource guard instead of component query. See the **ggrs skill** for the full simulation/visual entity split pattern.

```rust
// Sim entity: GGRS-tracked, no scene
let sim = commands.spawn((Transform::default(), Player { handle }, Velocity::default()))
    .add_rollback().id();

// Visual entity: NOT tracked, scene persists
commands.spawn((SceneRoot(scene), VisualLinkedTo(sim), ...));

// Guard: resource, not component
.run_if(not(resource_exists::<PlayersSpawned>))
```

## 18. Root Motion Cancellation — Schedule Ordering Is Everything

**❌ Problem (iteration 1):** Zeroing translation on the `AnimationPlayer` entity:
```rust
fn cancel_root_motion(mut query: Query<&mut Transform, With<AnimationPlayer>>) {
    for mut t in &mut query { t.translation = Vec3::ZERO; }
}
```
Root motion isn't applied to the `AnimationPlayer` — it's applied to bone entities (children with `AnimationTargetId`). Wrong entity.

**❌ Problem (iteration 2):** Running in `Last` schedule:
```rust
.add_systems(Last, cancel_root_motion)
```
`GlobalTransform` propagation runs in `PostUpdate` (`TransformSystems::Propagate`). The renderer uses `GlobalTransform`. By `Last`, the stale values are already baked into the render data.

**✅ Solution:** Save initial bone translations at setup, restore in `PostUpdate` between `AnimationSystems` and `TransformSystems::Propagate`:
```rust
#[derive(Component)]
struct InitialBoneTranslation(Vec3);

// Setup (runs once): save initial translations on AnimationPlayer + direct
// children with AnimationTargetId
fn save_initial_bone_transforms(
    mut commands: Commands,
    anim_player_query: Query<(Entity, &Children, &Transform), With<AnimationPlayer>>,
    anim_target_query: Query<&Transform, (With<AnimationTargetId>, Without<InitialBoneTranslation>)>,
    already_saved: Query<(), With<InitialBoneTranslation>>,
) {
    for (player_entity, children, player_tf) in &anim_player_query {
        if already_saved.get(player_entity).is_ok() { continue; }
        commands.entity(player_entity).insert(InitialBoneTranslation(player_tf.translation));
        for child in children.iter() {
            if let Ok(child_tf) = anim_target_query.get(child) {
                commands.entity(child).insert(InitialBoneTranslation(child_tf.translation));
            }
        }
    }
}

// Every frame: restore after animation evaluation, before GlobalTransform propagation
fn cancel_root_motion(mut query: Query<(&InitialBoneTranslation, &mut Transform)>) {
    for (initial, mut transform) in &mut query {
        transform.translation = initial.0;
    }
}
```

```rust
// Registration — ordering is critical
.add_systems(Update, save_initial_bone_transforms)
.add_systems(
    PostUpdate,
    cancel_root_motion
        .after(bevy::app::AnimationSystems)
        .before(bevy::transform::TransformSystems::Propagate),
)
```

**Key insight:** Bevy's PostUpdate pipeline is `AnimationSystems → TransformSystems::Propagate`. Root motion corrections must slot between these two. Earlier (Update) is before animation evaluation. Later (Last) is after GlobalTransform is already computed for the renderer.

## 19. AnimationTransitions — Don't Mix with Direct AnimationPlayer Calls

**❌ Problem:** Using `player.play()` directly after inserting `AnimationTransitions`:
```rust
player.play(idle_index).repeat();
commands.entity(e).insert(AnimationTransitions::new());
// AnimationTransitions now has stale internal state — future transitions break
```

**✅ Solution:** Once `AnimationTransitions` is on an entity, always use `transitions.play()`:
```rust
let mut transitions = AnimationTransitions::new();
transitions.play(&mut player, idle_index, Duration::ZERO).repeat();
commands.entity(e).insert(transitions);
```

If you need to call `transitions.play()` at setup time when you can't borrow both mutably through queries, use `commands.queue()` with an `EntityWorldMut` closure:
```rust
commands.entity(descendant).queue(move |mut entity: EntityWorldMut| {
    if let Some(mut player) = entity.get_mut::<AnimationPlayer>() {
        transitions.play(&mut player, idx, Duration::ZERO).repeat();
    }
    entity.insert(transitions);
});
```

## 20. AmbientLight Scope

**❌ Problem:**
```rust
// AmbientLight is now per-camera, not global
commands.insert_resource(AmbientLight {
    color: Color::WHITE,
    brightness: 300.0,
});
```

**✅ Solution:**
Use `GlobalAmbientLight` for world-wide ambient, or attach `AmbientLight` to cameras:
```rust
// Global ambient (replaces old resource pattern)
commands.insert_resource(GlobalAmbientLight {
    color: Color::WHITE,
    brightness: 300.0,
});

// Or per-camera ambient
commands.spawn((
    Camera3d::default(),
    AmbientLight { color: Color::WHITE, brightness: 300.0 },
));
```
