# glTF Scenes, Animation and Rollback

## Contents

- [Loading glTF scenes](#loading-gltf-scenes)
- [Patching materials on spawned scenes](#patching-materials-on-spawned-scenes)
- [Choosing animation clips](#choosing-animation-clips)
- [Playing animations](#playing-animations)
- [Cancelling root motion](#cancelling-root-motion)
- [Rollback netcode with bevy_ggrs](#rollback-netcode-with-bevy_ggrs)

## Loading glTF scenes

A glTF scene spawns as a hierarchy under a `WorldAssetRoot`; `WorldInstanceReady` fires on the root once the hierarchy exists.

```rust
let scene = asset_server.load(GltfAssetLabel::Scene(0).from_asset(path)); // path: String, passed by value
commands.spawn((WorldAssetRoot(scene), Transform::default(), Player));
```

`from_asset` takes `impl Into<AssetPath<'static>>`. Pass an owned `String` or a `&'static str`; a `&String` borrows a local and fails to compile. The string form `asset_server.load(format!("models/{name}.glb#Scene0"))` is equivalent.

## Patching materials on spawned scenes

To change materials of one scene instance, run an `Update` system on `Added<MeshMaterial3d<StandardMaterial>>` and keep only entities whose ancestor is the target. A `WorldInstanceReady` observer suits one-shot setup such as starting an animation; in practice it has missed meshes that spawn later when many instances load at once.

```rust
fn tint_player_meshes(
    new_meshes: Query<(Entity, &MeshMaterial3d<StandardMaterial>), Added<MeshMaterial3d<StandardMaterial>>>,
    parents: Query<&ChildOf>,
    players: Query<(), With<Player>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    for (entity, material) in &new_meshes {
        if !parents.iter_ancestors(entity).any(|a| players.contains(a)) {
            continue;
        }
        if let Some(mut m) = materials.get_mut(&material.0) {
            m.base_color = Color::srgb(0.2, 0.4, 1.0);
        }
    }
}
```

glTF meshes share material assets; clone the material and assign the new handle if only one instance should change.

## Choosing animation clips

`Gltf::named_animations` is a `HashMap`, so `.iter().find(|(n, _)| n.contains("idle"))` picks an arbitrary match when several names contain the substring. Look up exact keys, with a fallback chain:

```rust
let idle = gltf.named_animations.get("unarmed/idle")
    .or_else(|| gltf.named_animations.get("idle"));
```

## Playing animations

`AnimationPlayer` plays nodes of an `AnimationGraph`, even for one clip. The `AnimationPlayer` sits on a descendant of the `WorldAssetRoot`, not on the root; put the `AnimationGraphHandle` on that same entity.

```rust
let (graph, idle) = AnimationGraph::from_clip(clip);
let graph = graphs.add(graph);
for e in children.iter_descendants(scene_root) {
    if let Ok(mut player) = anim_players.get_mut(e) {
        let mut transitions = AnimationTransitions::new();
        transitions.play(&mut player, idle, Duration::ZERO).repeat();
        commands.entity(e).insert((AnimationGraphHandle(graph.clone()), transitions));
    }
}
```

Once an entity has `AnimationTransitions`, start every clip through `transitions.play(&mut player, ..)`; a direct `player.play(..)` desynchronises it. When setup code cannot borrow the player mutably, defer it with `commands.entity(e).queue(move |mut entity: EntityWorldMut| { .. })` and fetch the player there with `entity.get_mut::<AnimationPlayer>()`.

## Cancelling root motion

Root motion moves the bone entities (those with `AnimationTargetId`), not the `AnimationPlayer`. Animation is evaluated in `PostUpdate` in `AnimationSystems`, before `TransformSystems::Propagate` computes the `GlobalTransform` the renderer uses. A correction must run between the two:

```rust
#[derive(Component)]
struct InitialBoneTranslation(Vec3); // saved once per bone after the scene spawns

fn cancel_root_motion(mut bones: Query<(&InitialBoneTranslation, &mut Transform)>) {
    for (initial, mut t) in &mut bones {
        t.translation = initial.0;
    }
}

app.add_systems(
    PostUpdate,
    cancel_root_motion
        .after(bevy::app::AnimationSystems)
        .before(bevy::transform::TransformSystems::Propagate),
);
```

In `Update` the correction is overwritten by animation; in `Last` the renderer has already read the stale `GlobalTransform`.

## Rollback netcode with bevy_ggrs

`bevy_ggrs` 0.22 targets Bevy 0.19. Mark simulated entities with the `Rollback` component (or `#[require(Rollback)]` on their marker); game logic runs in `GgrsSchedule`.

- Rollback despawns `Rollback` entities that did not exist at the restored frame. A `WorldAssetRoot` or animation on such an entity is destroyed and respawned, which shows as T-poses and ghost duplicates. Split each actor into a simulation entity (`Rollback`, gameplay components, no scene) and a visual entity (`WorldAssetRoot`, animation, a component pointing at the simulation entity) that copies its `Transform` in `Update`.
- Deferred commands queued by an observer on a `Rollback` entity are lost if rollback despawns the entity before they apply.
- Guard one-time spawn systems with a resource that is not registered for rollback (`.run_if(not(resource_exists::<PlayersSpawned>))`), not with a query on `Rollback` entities.
