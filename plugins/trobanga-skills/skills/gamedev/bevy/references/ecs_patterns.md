# Bevy ECS Patterns

## Contents

- [Components](#components)
- [Queries](#queries)
- [Observers and messages](#observers-and-messages)
- [Patterns](#patterns)
- [Pitfalls](#pitfalls)

## Components

Keep each component to one concern; an entity that needs `Health` but not `Armor` should not carry an unused `armor` field. Put helper methods in `impl` blocks, refer to other entities by `Entity`, and use unit structs as markers for queries.

```rust
#[derive(Component)]
pub struct Health { pub current: f32, pub max: f32 }

impl Health {
    pub fn fraction(&self) -> f32 { self.current / self.max }
}

#[derive(Component)]
#[require(Health { current: 100.0, max: 100.0 }, Transform)]
pub struct Player;
```

`#[require(...)]` inserts the listed components (with `Default` or the given value) whenever `Player` is inserted, so spawn sites need only `commands.spawn(Player)`.

## Queries

```rust
fn system(
    mut changed: Query<(&Health, &mut HealthBar), Changed<Health>>, // only entities whose Health changed
    filtered: Query<&Transform, (With<Enemy>, Without<Player>)>,  // filter in the type, not the loop
    optional: Query<(&Name, Option<&Health>)>,
) { /* ... */ }
```

Mutate two entities of one query at once with `get_many_mut`; it returns `Err` if the entities are equal or missing:

```rust
fn swap_health(ev: On<SwapHealth>, mut q: Query<&mut Health>) {
    if let Ok([mut a, mut b]) = q.get_many_mut([ev.a, ev.b]) {
        std::mem::swap(&mut a.current, &mut b.current);
    }
}
```

Mutate several components of one entity checked at runtime with `EntityMut::get_components_mut::<(&mut A, &mut B)>()`, which returns `Result`.

## Observers and messages

An observer runs immediately when its event is triggered. Use it for reactions to discrete happenings:

```rust
#[derive(EntityEvent)]
struct Damage { entity: Entity, amount: f32 }

app.add_observer(apply_damage);

fn apply_damage(damage: On<Damage>, mut q: Query<&mut Health>) {
    if let Ok(mut health) = q.get_mut(damage.entity) {
        health.current -= damage.amount;
    }
}

fn shoot(mut commands: Commands, enemies: Query<Entity, With<Enemy>>) {
    for entity in &enemies {
        commands.trigger(Damage { entity, amount: 10.0 });
    }
}
```

A lifecycle observer reacts to component changes: `fn on_spawn(add: On<Add, Player>) { add.entity }`.

A message is buffered and read by a scheduled system, so it follows system ordering. Use it for high-volume streams read once per frame:

```rust
#[derive(Message)]
struct Footstep { pos: Vec3 }

app.add_message::<Footstep>()
    .add_systems(Update, (walk, play_footsteps).chain());

fn walk(mut steps: MessageWriter<Footstep>) { steps.write(Footstep { pos: Vec3::ZERO }); }
fn play_footsteps(mut steps: MessageReader<Footstep>) { for step in steps.read() { /* ... */ } }
```

## Patterns

**Derived values.** Keep one source-of-truth component and recompute the cached one in a `Changed<Source>` system.

**Thresholds.** In a `Changed<T>` system, `insert` a marker when a value crosses a threshold and `remove::<Marker>()` when it falls back; other systems then filter with `With<Marker>`.

**State machines.** An enum component per entity, matched in one system; for app-wide modes use `States` with `OnEnter` / `OnExit` schedules and `DespawnOnExit(state)` on entities that belong to a state.

## Pitfalls

**Conflicting queries.** Two queries in one system that touch the same component mutably must be provably disjoint (`Without<Player>` on one, `With<Player>` on the other) or wrapped in a `ParamSet`; otherwise the app panics at startup.

**Observer loops.** An observer that triggers its own event type recurses forever. Trigger a different event, or add a termination condition.

**Despawned entities.** `Commands` apply later, so a despawned entity may still appear in queries this frame, and an `Entity` held in a component may point at nothing next frame. Use `query.get(e)` with `if let Ok(..)`, never `unwrap()`.

**Dropped handles.** `materials.add(..)` returns a strong `Handle`; if you drop it without storing it in a component or resource, the asset is freed.
